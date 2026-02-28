//
//  TypedCSVRowReader.swift
//  SimpleCSV
//
//  Created by David Thorn on 28.02.2026.
//

import Foundation

/// Typed adapter that binds a row reader to a concrete column enum.
public struct TypedCSVRowReader<Column>: Sendable
where Column: CSVColumnProtocol {
    /// Underlying untyped row reader.
    public let rowReader: CSVRowReaderProtocol

    /// Creates a typed row reader adapter.
    /// - Parameter rowReader: Untyped row reader to adapt.
    public init(rowReader: CSVRowReaderProtocol) {
        self.rowReader = rowReader
    }

    /// The underlying row model.
    public var row: CSVRow {
        rowReader.row
    }

    /// Number of cells in the row.
    public var columnCount: Int {
        rowReader.columnCount
    }

    /// Returns the cell at a typed zero-based column index.
    /// - Parameter column: Typed column identifier.
    public func cell(at column: Column) throws -> CSVCell {
        try rowReader.cell(at: column.csvColumnIndex)
    }

    /// Returns the cell matching a typed column name.
    /// - Parameter column: Typed column identifier.
    public func cell(for column: Column) throws -> CSVCell {
        try rowReader.cell(for: column.csvColumnName)
    }

    /// Returns all cells for the row.
    public func allCells() -> [CSVCell] {
        rowReader.allCells()
    }
}
