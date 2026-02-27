//
//  CSVRow.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Represents one CSV row as pure data.
public struct CSVRow: Sendable, Equatable {
    /// The owning document identifier.
    public let documentID: CSVDocumentID
    /// Zero-based row index in the full document.
    public let rowIndex: Int
    /// Cells that belong to this row.
    public let cells: [CSVCell]

    /// Creates a row value.
    /// - Parameters:
    ///   - documentID: Owning document identifier.
    ///   - rowIndex: Zero-based row index.
    ///   - cells: Row cells.
    public init(documentID: CSVDocumentID, rowIndex: Int, cells: [CSVCell]) {
        self.documentID = documentID
        self.rowIndex = rowIndex
        self.cells = cells
    }
}
