//
//  CSVColumnProtocol.swift
//  SimpleCSV
//
//  Created by David Thorn on 28.02.2026.
//

import Foundation

/// Describes a typed CSV column by both its header name and zero-based index.
public protocol CSVColumnProtocol: Sendable {
    /// Header name for the column.
    var csvColumnName: String { get }
    /// Zero-based index for the column.
    var csvColumnIndex: Int { get }
}
