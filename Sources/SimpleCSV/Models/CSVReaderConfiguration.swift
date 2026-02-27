//
//  CSVReaderConfiguration.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Validation and parsing configuration applied when building a `CSVReader`.
public struct CSVReaderConfiguration: Sendable, Equatable {
    /// Header handling behavior.
    public let headerStrategy: CSVHeaderStrategy
    /// Row-width validation behavior.
    public let rowWidthValidationStrategy: CSVRowWidthValidationStrategy
    /// Whether duplicate header names are rejected.
    public let validatesUniqueHeaderNames: Bool

    /// Creates a reader configuration.
    /// - Parameters:
    ///   - headerStrategy: Header handling behavior.
    ///   - rowWidthValidationStrategy: Row-width validation behavior.
    ///   - validatesUniqueHeaderNames: Whether duplicate header names are rejected.
    public init(
        headerStrategy: CSVHeaderStrategy = .required,
        rowWidthValidationStrategy: CSVRowWidthValidationStrategy = .strict,
        validatesUniqueHeaderNames: Bool = true
    ) {
        self.headerStrategy = headerStrategy
        self.rowWidthValidationStrategy = rowWidthValidationStrategy
        self.validatesUniqueHeaderNames = validatesUniqueHeaderNames
    }

    /// Default strict validation configuration.
    public static let `default` = CSVReaderConfiguration()
}
