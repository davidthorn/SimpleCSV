//
//  CSVReader.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Immutable snapshot reader for validated CSV content.
public struct CSVReader: CSVReaderProtocol {
    /// Identifier of the document represented by this snapshot.
    public let documentID: CSVDocumentID
    private let header: [String]
    private let dataRows: [[String]]
    private let columnIndices: [String: Int]
    private let fileName: String
    private let dataRowOffset: Int

    /// Creates a reader from raw rows where the first row is treated as header when present.
    /// - Parameters:
    ///   - rows: Raw rows.
    ///   - fileName: Source file name used in errors.
    ///   - documentID: Document identifier.
    public init(
        rows: [[String]],
        fileName: String,
        documentID: CSVDocumentID = CSVDocumentID()
    ) {
        self.documentID = documentID
        self.fileName = fileName

        if let header = rows.first {
            self.header = header
            self.dataRows = Array(rows.dropFirst())
        } else {
            self.header = []
            self.dataRows = []
        }
        self.dataRowOffset = self.header.isEmpty ? 0 : 1

        var indices: [String: Int] = [:]
        for (index, name) in self.header.enumerated() where indices[name] == nil {
            indices[name] = index
        }
        self.columnIndices = indices
    }

    /// Creates a reader from raw rows and validates structure using a configuration.
    /// - Parameters:
    ///   - rows: Raw rows.
    ///   - fileName: Source file name used in errors.
    ///   - documentID: Document identifier.
    ///   - configuration: Validation and parsing configuration.
    public init(
        validating rows: [[String]],
        fileName: String,
        documentID: CSVDocumentID = CSVDocumentID(),
        configuration: CSVReaderConfiguration = .default
    ) throws {
        self.documentID = documentID
        self.fileName = fileName

        let parsedRows = try CSVReader.parseRows(
            rows,
            fileName: fileName,
            configuration: configuration
        )
        self.header = parsedRows.header
        self.dataRows = parsedRows.dataRows
        self.dataRowOffset = parsedRows.header.isEmpty ? 0 : 1
        self.columnIndices = CSVReader.makeColumnIndices(from: parsedRows.header)
    }

    /// Creates a reader from explicit header and data rows.
    /// - Parameters:
    ///   - header: Header columns.
    ///   - dataRows: Data rows.
    ///   - fileName: Source file name used in errors.
    ///   - documentID: Document identifier.
    public init(
        header: [String],
        dataRows: [[String]],
        fileName: String,
        documentID: CSVDocumentID = CSVDocumentID()
    ) {
        self.documentID = documentID
        self.header = header
        self.dataRows = dataRows
        self.fileName = fileName
        self.dataRowOffset = header.isEmpty ? 0 : 1

        self.columnIndices = CSVReader.makeColumnIndices(from: header)
    }

    /// Indicates whether this snapshot contains no header and no data rows.
    public var isEmpty: Bool {
        header.isEmpty && dataRows.isEmpty
    }

    /// Number of data rows.
    public var rowCount: Int {
        dataRows.count
    }

    /// Number of columns in the header.
    public var columnCount: Int {
        header.count
    }

    /// Returns the header name at the provided column index.
    public func columnName(at index: Int) throws -> String {
        guard header.indices.contains(index) else {
            throw NSError(
                domain: "CSVReader",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Missing column index \(index) in \(fileName)"]
            )
        }

        return header[index]
    }

    /// Returns the zero-based index of a header column name.
    public func index(for columnName: String) throws -> Int {
        guard let index = columnIndices[columnName] else {
            throw NSError(
                domain: "CSVReader",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Missing column \(columnName) in \(fileName)"]
            )
        }

        return index
    }

    /// Returns a data row at a zero-based data index.
    public func row(at index: Int) throws -> CSVRow {
        guard dataRows.indices.contains(index) else {
            throw NSError(
                domain: "CSVReader",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Missing row index \(index) in \(fileName)"]
            )
        }

        return makeRow(
            rowIndex: dataRowOffset + index,
            values: dataRows[index],
            columnNames: header
        )
    }

    /// Returns a row reader for the provided data-row index.
    public func rowReader(at index: Int) throws -> CSVRowReaderProtocol {
        CSVRowReader(row: try row(at: index), fileName: fileName)
    }

    /// Returns all rows in snapshot order.
    public func allRows() -> [CSVRow] {
        var rows: [CSVRow] = []

        if header.isEmpty == false {
            rows.append(
                makeRow(
                    rowIndex: 0,
                    values: header,
                    columnNames: []
                )
            )
        }

        for (index, rowValues) in dataRows.enumerated() {
            rows.append(
                makeRow(
                    rowIndex: dataRowOffset + index,
                    values: rowValues,
                    columnNames: header
                )
            )
        }

        return rows
    }

    private static func parseRows(
        _ rows: [[String]],
        fileName: String,
        configuration: CSVReaderConfiguration
    ) throws -> (header: [String], dataRows: [[String]]) {
        let splitRows = try splitRowsByHeaderStrategy(
            rows,
            fileName: fileName,
            headerStrategy: configuration.headerStrategy
        )

        if configuration.validatesUniqueHeaderNames {
            try validateUniqueHeaderNames(
                splitRows.header,
                fileName: fileName
            )
        }

        if configuration.rowWidthValidationStrategy == .strict {
            try validateRowWidths(
                header: splitRows.header,
                dataRows: splitRows.dataRows,
                fileName: fileName
            )
        }

        return splitRows
    }

    private static func splitRowsByHeaderStrategy(
        _ rows: [[String]],
        fileName: String,
        headerStrategy: CSVHeaderStrategy
    ) throws -> (header: [String], dataRows: [[String]]) {
        switch headerStrategy {
        case .required:
            guard let header = rows.first else {
                throw CSVReaderValidationError.missingHeader(fileName: fileName)
            }
            return (header, Array(rows.dropFirst()))
        case .optional:
            guard let header = rows.first else {
                return ([], [])
            }
            return (header, Array(rows.dropFirst()))
        case .none:
            return ([], rows)
        }
    }

    private static func validateUniqueHeaderNames(
        _ header: [String],
        fileName: String
    ) throws {
        var knownNames: Set<String> = []
        for name in header {
            if knownNames.contains(name) {
                throw CSVReaderValidationError.duplicateHeaderName(
                    fileName: fileName,
                    name: name
                )
            }
            knownNames.insert(name)
        }
    }

    private static func validateRowWidths(
        header: [String],
        dataRows: [[String]],
        fileName: String
    ) throws {
        let expectedCount: Int
        let firstDataLineNumber: Int

        if header.isEmpty == false {
            expectedCount = header.count
            firstDataLineNumber = 2
        } else {
            guard let firstRow = dataRows.first else {
                return
            }
            expectedCount = firstRow.count
            firstDataLineNumber = 1
        }

        for (index, row) in dataRows.enumerated() where row.count != expectedCount {
            throw CSVReaderValidationError.inconsistentRowWidth(
                fileName: fileName,
                lineNumber: firstDataLineNumber + index,
                expected: expectedCount,
                actual: row.count
            )
        }
    }

    private static func makeColumnIndices(from header: [String]) -> [String: Int] {
        var indices: [String: Int] = [:]
        for (index, name) in header.enumerated() where indices[name] == nil {
            indices[name] = index
        }
        return indices
    }

    private func makeRow(rowIndex: Int, values: [String], columnNames: [String]) -> CSVRow {
        let cells = values.enumerated().map { index, value in
            let columnName: String?
            if columnNames.indices.contains(index) {
                columnName = columnNames[index]
            } else {
                columnName = nil
            }

            return CSVCell(
                documentID: documentID,
                rowIndex: rowIndex,
                columnIndex: index,
                columnName: columnName,
                value: value
            )
        }

        return CSVRow(documentID: documentID, rowIndex: rowIndex, cells: cells)
    }

}
