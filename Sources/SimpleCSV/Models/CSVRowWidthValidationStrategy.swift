//
//  CSVRowWidthValidationStrategy.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Defines row-width validation behavior for CSV snapshots.
public enum CSVRowWidthValidationStrategy: Sendable, Equatable {
    /// Enforces consistent row width.
    case strict
    /// Skips row-width validation.
    case none
}
