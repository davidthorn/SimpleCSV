//
//  TypedCSVReader.swift
//  SimpleCSV
//
//  Created by David Thorn on 28.02.2026.
//

import Foundation

/// Typed adapter that binds a CSV reader to a concrete column enum.
public struct TypedCSVReader<Column>: Sendable
where Column: CSVColumnProtocol {
    /// Underlying untyped reader.
    public let reader: CSVReaderProtocol

    /// Creates a typed reader adapter.
    /// - Parameter reader: Untyped reader to adapt.
    public init(reader: CSVReaderProtocol) {
        self.reader = reader
    }

    /// Identifier of the document represented by the wrapped snapshot.
    public var documentID: CSVDocumentID {
        reader.documentID
    }

    /// Indicates whether the wrapped snapshot contains no header and no data rows.
    public var isEmpty: Bool {
        reader.isEmpty
    }

    /// Number of data rows.
    public var rowCount: Int {
        reader.rowCount
    }

    /// Number of columns in the header.
    public var columnCount: Int {
        reader.columnCount
    }

    /// Returns the header name for a typed column.
    /// - Parameter column: Typed column identifier.
    public func columnName(for column: Column) throws -> String {
        try reader.columnName(at: column.csvColumnIndex)
    }

    /// Returns the resolved zero-based index for a typed column.
    /// - Parameter column: Typed column identifier.
    public func index(for column: Column) throws -> Int {
        try reader.index(for: column.csvColumnName)
    }

    /// Returns a data row at a zero-based data-row index.
    /// - Parameter index: Zero-based data-row index.
    public func row(at index: Int) throws -> CSVRow {
        try reader.row(at: index)
    }

    /// Returns a row reader adapter for the provided data-row index.
    /// - Parameter index: Zero-based data-row index.
    public func rowReader(at index: Int) throws -> TypedCSVRowReader<Column> {
        TypedCSVRowReader(rowReader: try reader.rowReader(at: index))
    }

    /// Returns typed row readers in data-row order for `for-in` iteration.
    public func rowReaders() throws -> TypedCSVRowReaderSequence<Column> {
        var rowReaders: [TypedCSVRowReader<Column>] = []
        rowReaders.reserveCapacity(rowCount)

        for index in 0..<rowCount {
            rowReaders.append(try rowReader(at: index))
        }

        return TypedCSVRowReaderSequence(rowReaders: rowReaders)
    }

    /// Returns all rows in snapshot order.
    public func allRows() -> [CSVRow] {
        reader.allRows()
    }

    /// Returns resolved header columns in header order.
    public func headerColumns() throws -> [CSVHeaderColumn] {
        try reader.headerColumns()
    }

    /// Returns resolved header columns, excluding the provided header names.
    /// - Parameter excludedColumnNames: Header names to exclude.
    public func headerColumns(excluding excludedColumnNames: [String]) throws -> [CSVHeaderColumn] {
        try reader.headerColumns(excluding: excludedColumnNames)
    }

    /// Maps typed row readers in data-row order.
    /// - Parameter transform: Transform applied to each typed row reader.
    public func mapRows<Result>(
        _ transform: (TypedCSVRowReader<Column>) throws -> Result
    ) throws -> [Result] {
        var results: [Result] = []
        results.reserveCapacity(rowCount)

        for rowReader in try rowReaders() {
            results.append(try transform(rowReader))
        }

        return results
    }

    /// Compact-maps typed row readers in data-row order.
    /// - Parameter transform: Transform applied to each typed row reader.
    public func compactMapRows<Result>(
        _ transform: (TypedCSVRowReader<Column>) throws -> Result?
    ) throws -> [Result] {
        var results: [Result] = []
        results.reserveCapacity(rowCount)

        for rowReader in try rowReaders() {
            if let result = try transform(rowReader) {
                results.append(result)
            }
        }

        return results
    }

    /// Reduces typed row readers in data-row order into an accumulated result.
    /// - Parameters:
    ///   - initialResult: Initial accumulated result.
    ///   - updateAccumulatingResult: Closure that mutates the accumulated result using each typed row reader.
    public func reduceRows<Result>(
        into initialResult: Result,
        _ updateAccumulatingResult: (inout Result, TypedCSVRowReader<Column>) throws -> Void
    ) throws -> Result {
        var result = initialResult

        for rowReader in try rowReaders() {
            try updateAccumulatingResult(&result, rowReader)
        }

        return result
    }
}
