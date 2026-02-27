//
//  CSVReaderValidationError.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Errors emitted when validating row/header structure for `CSVReader`.
public enum CSVReaderValidationError: LocalizedError, Equatable, Sendable {
    /// Header was required but missing.
    case missingHeader(fileName: String)
    /// Header contains duplicate names.
    case duplicateHeaderName(fileName: String, name: String)
    /// A row has a width different from expected.
    case inconsistentRowWidth(fileName: String, lineNumber: Int, expected: Int, actual: Int)

    /// Human-readable error description.
    public var errorDescription: String? {
        switch self {
        case .missingHeader(let fileName):
            return "Missing header row in \(fileName)."
        case .duplicateHeaderName(let fileName, let name):
            return "Duplicate header \"\(name)\" in \(fileName)."
        case .inconsistentRowWidth(let fileName, let lineNumber, let expected, let actual):
            return "Inconsistent row width in \(fileName) at line \(lineNumber). Expected \(expected) values, found \(actual)."
        }
    }
}
