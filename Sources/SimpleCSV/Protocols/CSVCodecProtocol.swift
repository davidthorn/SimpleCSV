//
//  CSVCodecProtocol.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Defines encoding and decoding behavior for delimiter-separated text formats.
public protocol CSVCodecProtocol: Sendable {
    /// Parses raw delimited content into rows and fields.
    /// - Parameter content: Raw file content.
    /// - Returns: Parsed rows where each inner array contains field values.
    func decodeRows(from content: String) throws -> [[String]]

    /// Serializes rows and fields into delimited text content.
    /// - Parameter rows: Rows to encode.
    /// - Returns: Encoded text content.
    func encodeRows(_ rows: [[String]]) -> String
}
