//
//  CSVReaderProtocol.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Provides read-only access to a CSV snapshot.
public protocol CSVReaderProtocol: Sendable {
    /// Identifier of the document represented by this snapshot.
    var documentID: CSVDocumentID { get }
    /// Indicates whether this snapshot contains no header and no data rows.
    var isEmpty: Bool { get }
    /// Number of data rows.
    var rowCount: Int { get }
    /// Number of columns in the header.
    var columnCount: Int { get }

    /// Returns the header name at the provided column index.
    func columnName(at index: Int) throws -> String
    /// Returns the column index for a given header name.
    func index(for columnName: String) throws -> Int
    /// Returns a row data model at the provided data-row index.
    func row(at index: Int) throws -> CSVRow
    /// Returns a row reader for the provided data-row index.
    func rowReader(at index: Int) throws -> CSVRowReaderProtocol
    /// Returns all rows in snapshot order.
    func allRows() -> [CSVRow]
}
