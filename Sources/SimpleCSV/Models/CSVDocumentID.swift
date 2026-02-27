//
//  CSVDocumentID.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Stable identifier for an in-memory CSV document managed by `CSVStore`.
public struct CSVDocumentID: Hashable, Sendable, Equatable {
    /// Underlying UUID value.
    public let rawValue: UUID

    /// Creates a new document identifier.
    public init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}
