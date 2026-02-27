//
//  CSVRowReaderError.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Typed errors emitted by `CSVRowReader`.
public enum CSVRowReaderError: LocalizedError, Equatable, Sendable {
    /// The requested column index does not exist in the row.
    case missingValue(index: Int, fileName: String)
    /// The requested column name does not exist in the row.
    case missingColumn(name: String, fileName: String)

    /// Human-readable error description.
    public var errorDescription: String? {
        switch self {
        case .missingValue(let index, let fileName):
            return "Missing value at index \(index) in \(fileName) row."
        case .missingColumn(let name, let fileName):
            return "Missing column \(name) in \(fileName)."
        }
    }
}
