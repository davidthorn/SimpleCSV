//
//  CSVRowReaderProtocol.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Provides lookup operations for a single CSV row.
public protocol CSVRowReaderProtocol: Sendable {
    /// The underlying row model.
    var row: CSVRow { get }
    /// Number of cells in the row.
    var columnCount: Int { get }

    /// Returns the cell at a zero-based column index.
    func cell(at index: Int) throws -> CSVCell
    /// Returns the cell matching a column name.
    func cell(for columnName: String) throws -> CSVCell
    /// Returns all cells for the row.
    func allCells() -> [CSVCell]
}

public extension CSVRowReaderProtocol {
    /// Returns the cell at a typed zero-based column index.
    /// - Parameter column: Enum-backed zero-based column index.
    func cell<Column>(at column: Column) throws -> CSVCell
    where Column: RawRepresentable, Column.RawValue == Int {
        try cell(at: column.rawValue)
    }

    /// Returns the cell matching a typed column name.
    /// - Parameter column: Enum-backed column name.
    func cell<Column>(for column: Column) throws -> CSVCell
    where Column: RawRepresentable, Column.RawValue == String {
        try cell(for: column.rawValue)
    }
}
