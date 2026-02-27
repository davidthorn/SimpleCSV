//
//  CSVStore.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Actor-backed CSV store for disk persistence, in-memory editing, and update streaming.
public actor CSVStore: CSVStoreProtocol {
    private let csvCodec: CSVCodecProtocol
    private let readerConfiguration: CSVReaderConfiguration
    private var documents: [CSVDocumentID: CSVInMemoryDocument]
    private var updateContinuations: [CSVDocumentID: [UUID: AsyncStream<CSVStoreUpdate>.Continuation]]

    /// Creates a store with injected codec and reader validation configuration.
    /// - Parameters:
    ///   - csvCodec: Codec used for parsing and encoding.
    ///   - readerConfiguration: Reader validation configuration.
    public init(
        csvCodec: CSVCodecProtocol,
        readerConfiguration: CSVReaderConfiguration = .default
    ) {
        self.csvCodec = csvCodec
        self.readerConfiguration = readerConfiguration
        self.documents = [:]
        self.updateContinuations = [:]
    }

    /// Reads and validates a CSV file from disk.
    public func read(from url: URL) async throws -> CSVReaderProtocol {
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = try csvCodec.decodeRows(from: content)
        return try CSVReader(
            validating: rows,
            fileName: url.lastPathComponent,
            documentID: CSVDocumentID(),
            configuration: readerConfiguration
        )
    }

    /// Writes a CSV reader snapshot to disk.
    public func write(_ reader: CSVReaderProtocol, to url: URL) async throws {
        let rows = reader.allRows().map { row in
            row.cells.map(\.value)
        }
        let content = csvCodec.encodeRows(rows)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Loads a disk CSV file into in-memory document state.
    public func loadDocument(from url: URL) async throws -> CSVDocumentID {
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = try csvCodec.decodeRows(from: content)
        _ = try CSVReader(
            validating: rows,
            fileName: url.lastPathComponent,
            documentID: CSVDocumentID(),
            configuration: readerConfiguration
        )

        let documentID = CSVDocumentID()
        documents[documentID] = CSVInMemoryDocument(
            rows: rows,
            fileName: url.lastPathComponent,
            sourceURL: url
        )
        return documentID
    }

    /// Creates an in-memory document from raw rows.
    public func createDocument(
        rows: [[String]],
        fileName: String,
        sourceURL: URL? = nil
    ) async throws -> CSVDocumentID {
        let documentID = CSVDocumentID()
        _ = try CSVReader(
            validating: rows,
            fileName: fileName,
            documentID: documentID,
            configuration: readerConfiguration
        )

        documents[documentID] = CSVInMemoryDocument(
            rows: rows,
            fileName: fileName,
            sourceURL: sourceURL
        )
        return documentID
    }

    /// Creates an in-memory document from explicit header and data rows.
    public func createDocument(
        header: [String],
        dataRows: [[String]],
        fileName: String,
        sourceURL: URL? = nil
    ) async throws -> CSVDocumentID {
        var rows: [[String]] = []
        if header.isEmpty == false || readerConfiguration.headerStrategy != .none {
            rows.append(header)
        }
        rows.append(contentsOf: dataRows)
        return try await createDocument(rows: rows, fileName: fileName, sourceURL: sourceURL)
    }

    /// Returns a validated snapshot for an in-memory document.
    public func snapshot(for documentID: CSVDocumentID) async throws -> CSVReaderProtocol {
        let document = try requireDocument(documentID)
        return try CSVReader(
            validating: document.rows,
            fileName: document.fileName,
            documentID: documentID,
            configuration: readerConfiguration
        )
    }

    /// Applies a cell update, persists the document, and broadcasts a snapshot update.
    public func updateCell(_ cell: CSVCell) async throws -> CSVReaderProtocol {
        var document = try requireDocument(cell.documentID)

        guard document.rows.indices.contains(cell.rowIndex) else {
            throw CSVStoreError.rowIndexOutOfBounds(index: cell.rowIndex, rowCount: document.rows.count)
        }

        let row = document.rows[cell.rowIndex]
        guard row.indices.contains(cell.columnIndex) else {
            throw CSVStoreError.columnIndexOutOfBounds(index: cell.columnIndex, columnCount: row.count)
        }

        guard let destinationURL = document.sourceURL else {
            throw CSVStoreError.missingDestinationURL(documentID: cell.documentID)
        }

        document.rows[cell.rowIndex][cell.columnIndex] = cell.value

        let reader = try CSVReader(
            validating: document.rows,
            fileName: document.fileName,
            documentID: cell.documentID,
            configuration: readerConfiguration
        )

        let content = csvCodec.encodeRows(document.rows)
        try content.write(to: destinationURL, atomically: true, encoding: .utf8)

        documents[cell.documentID] = document

        broadcast(
            CSVStoreUpdate(
                documentID: cell.documentID,
                cell: cell,
                snapshot: reader
            )
        )
        return reader
    }

    /// Persists an in-memory document to disk.
    public func persistDocument(_ documentID: CSVDocumentID, to url: URL? = nil) async throws {
        guard var document = documents[documentID] else {
            throw CSVStoreError.documentNotFound(documentID: documentID)
        }

        guard let destinationURL = url ?? document.sourceURL else {
            throw CSVStoreError.missingDestinationURL(documentID: documentID)
        }

        _ = try CSVReader(
            validating: document.rows,
            fileName: document.fileName,
            configuration: readerConfiguration
        )

        let content = csvCodec.encodeRows(document.rows)
        try content.write(to: destinationURL, atomically: true, encoding: .utf8)

        document.sourceURL = destinationURL
        document.fileName = destinationURL.lastPathComponent
        documents[documentID] = document
    }

    /// Discards an in-memory document and finishes its active streams.
    public func discardDocument(_ documentID: CSVDocumentID) async {
        documents.removeValue(forKey: documentID)
        if let continuations = updateContinuations.removeValue(forKey: documentID) {
            for continuation in continuations.values {
                continuation.finish()
            }
        }
    }

    /// Subscribes to updates for a specific document.
    public func stream(for documentID: CSVDocumentID) async -> AsyncStream<CSVStoreUpdate> {
        AsyncStream { continuation in
            let continuationID = UUID()
            var continuations = updateContinuations[documentID, default: [:]]
            continuations[continuationID] = continuation
            updateContinuations[documentID] = continuations

            continuation.onTermination = { [weak self] _ in
                Task {
                    await self?.removeContinuation(continuationID, for: documentID)
                }
            }
        }
    }

    private func requireDocument(_ documentID: CSVDocumentID) throws -> CSVInMemoryDocument {
        guard let document = documents[documentID] else {
            throw CSVStoreError.documentNotFound(documentID: documentID)
        }
        return document
    }

    private func removeContinuation(_ continuationID: UUID, for documentID: CSVDocumentID) {
        guard var continuations = updateContinuations[documentID] else {
            return
        }
        continuations.removeValue(forKey: continuationID)
        if continuations.isEmpty {
            updateContinuations.removeValue(forKey: documentID)
        } else {
            updateContinuations[documentID] = continuations
        }
    }

    private func broadcast(_ update: CSVStoreUpdate) {
        guard let continuations = updateContinuations[update.documentID] else {
            return
        }
        for continuation in continuations.values {
            continuation.yield(update)
        }
    }

    internal func hasStreamEntry(for documentID: CSVDocumentID) -> Bool {
        updateContinuations[documentID] != nil
    }
}
