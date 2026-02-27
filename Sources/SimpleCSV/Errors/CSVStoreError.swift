//
//  CSVStoreError.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Errors produced by `CSVStore` while managing in-memory documents and persistence.
public enum CSVStoreError: LocalizedError, Equatable, Sendable {
    /// The requested document is not loaded in memory.
    case documentNotFound(documentID: CSVDocumentID)
    /// The requested row index is outside valid bounds.
    case rowIndexOutOfBounds(index: Int, rowCount: Int)
    /// The requested column index is outside valid bounds.
    case columnIndexOutOfBounds(index: Int, columnCount: Int)
    /// The target document has no destination URL for persistence.
    case missingDestinationURL(documentID: CSVDocumentID)

    /// Human-readable error description.
    public var errorDescription: String? {
        switch self {
        case .documentNotFound(let documentID):
            return "Missing in-memory document \(documentID.rawValue.uuidString)."
        case .rowIndexOutOfBounds(let index, let rowCount):
            return "Row index \(index) is out of bounds. Row count is \(rowCount)."
        case .columnIndexOutOfBounds(let index, let columnCount):
            return "Column index \(index) is out of bounds. Column count is \(columnCount)."
        case .missingDestinationURL(let documentID):
            return "Missing destination URL for document \(documentID.rawValue.uuidString)."
        }
    }
}
