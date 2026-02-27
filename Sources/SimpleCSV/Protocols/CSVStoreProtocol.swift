//
//  CSVStoreProtocol.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Defines in-memory document lifecycle, persistence, and update streaming for CSV data.
public protocol CSVStoreProtocol: Sendable {
    /// Reads and validates a CSV file from disk, returning a snapshot reader.
    func read(from url: URL) async throws -> CSVReaderProtocol
    /// Writes a snapshot reader to disk.
    func write(_ reader: CSVReaderProtocol, to url: URL) async throws

    /// Loads a CSV file into the store's in-memory document cache.
    func loadDocument(from url: URL) async throws -> CSVDocumentID

    /// Creates an in-memory document from raw rows.
    func createDocument(rows: [[String]], fileName: String, sourceURL: URL?) async throws -> CSVDocumentID

    /// Creates an in-memory document from explicit header and data rows.
    func createDocument(header: [String], dataRows: [[String]], fileName: String, sourceURL: URL?) async throws -> CSVDocumentID

    /// Returns a validated snapshot of an in-memory document.
    func snapshot(for documentID: CSVDocumentID) async throws -> CSVReaderProtocol

    /// Updates one in-memory cell and persists the full document snapshot to disk.
    func updateCell(_ cell: CSVCell) async throws -> CSVReaderProtocol

    /// Persists an in-memory document to disk.
    func persistDocument(_ documentID: CSVDocumentID, to url: URL?) async throws

    /// Removes an in-memory document from the store cache.
    func discardDocument(_ documentID: CSVDocumentID) async

    /// Subscribes to updates for one document.
    func stream(for documentID: CSVDocumentID) async -> AsyncStream<CSVStoreUpdate>
}
