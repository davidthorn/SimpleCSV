//
//  CSVCell.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Represents one mutable CSV table cell with immutable identity metadata.
public struct CSVCell: Sendable, Equatable {
    /// The owning document identifier.
    public let documentID: CSVDocumentID
    /// Zero-based row index in the full document.
    public let rowIndex: Int
    /// Zero-based column index in the row.
    public let columnIndex: Int
    /// Optional column name resolved from the header row.
    public let columnName: String?
    /// Cell text value.
    public var value: String

    /// Creates a cell value.
    /// - Parameters:
    ///   - documentID: Owning document identifier.
    ///   - rowIndex: Zero-based row index.
    ///   - columnIndex: Zero-based column index.
    ///   - columnName: Optional column name.
    ///   - value: Cell text value.
    public init(
        documentID: CSVDocumentID,
        rowIndex: Int,
        columnIndex: Int,
        columnName: String?,
        value: String
    ) {
        self.documentID = documentID
        self.rowIndex = rowIndex
        self.columnIndex = columnIndex
        self.columnName = columnName
        self.value = value
    }
}
