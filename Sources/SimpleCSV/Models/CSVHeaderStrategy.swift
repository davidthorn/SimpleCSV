//
//  CSVHeaderStrategy.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Defines how headers are interpreted when creating a CSV reader snapshot.
public enum CSVHeaderStrategy: Sendable, Equatable {
    /// A header row must be present.
    case required
    /// A header row is used when present.
    case optional
    /// No header row is expected.
    case none
}
