//
//  CSVHeaderColumn.swift
//  SimpleCSV
//
//  Created by David Thorn on 28.02.2026.
//

import Foundation

/// Describes one resolved header column by name and zero-based index.
public struct CSVHeaderColumn: Sendable, Equatable {
    /// Header name.
    public let name: String
    /// Zero-based column index.
    public let index: Int

    /// Creates a resolved header column value.
    /// - Parameters:
    ///   - name: Header name.
    ///   - index: Zero-based column index.
    public init(name: String, index: Int) {
        self.name = name
        self.index = index
    }
}
