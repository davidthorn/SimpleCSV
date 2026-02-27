//
//  CSVRowReader.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Reads and queries data from a `CSVRow`.
public struct CSVRowReader: CSVRowReaderProtocol {
    /// Underlying row model.
    public let row: CSVRow
    private let fileName: String

    /// Creates a row reader.
    /// - Parameters:
    ///   - row: Row model.
    ///   - fileName: Source file name used in error messages.
    public init(row: CSVRow, fileName: String) {
        self.row = row
        self.fileName = fileName
    }

    /// Number of cells in the row.
    public var columnCount: Int {
        row.cells.count
    }

    /// Returns the cell at a zero-based column index.
    public func cell(at index: Int) throws -> CSVCell {
        guard row.cells.indices.contains(index) else {
            throw CSVRowReaderError.missingValue(index: index, fileName: fileName)
        }
        return row.cells[index]
    }

    /// Returns the cell matching a column name.
    public func cell(for columnName: String) throws -> CSVCell {
        guard let cell = row.cells.first(where: { $0.columnName == columnName }) else {
            throw CSVRowReaderError.missingColumn(name: columnName, fileName: fileName)
        }
        return cell
    }

    /// Returns all cells in the row.
    public func allCells() -> [CSVCell] {
        row.cells
    }
}
