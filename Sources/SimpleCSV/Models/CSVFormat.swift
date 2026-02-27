//
//  CSVFormat.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Describes delimiter and quoting rules for separated-value text formats.
public struct CSVFormat: Sendable, Equatable {
    /// Field separator character.
    public let delimiter: UnicodeScalar
    /// Quote character used for escaped fields.
    public let quote: UnicodeScalar
    /// Whether whitespace is accepted after a closing quote before delimiter/newline.
    public let allowsWhitespaceAfterClosingQuote: Bool

    /// Creates a format descriptor.
    /// - Parameters:
    ///   - delimiter: Field separator character.
    ///   - quote: Quote character.
    ///   - allowsWhitespaceAfterClosingQuote: Whether whitespace after a closing quote is accepted.
    public init(
        delimiter: UnicodeScalar = ",",
        quote: UnicodeScalar = "\"",
        allowsWhitespaceAfterClosingQuote: Bool = true
    ) {
        self.delimiter = delimiter
        self.quote = quote
        self.allowsWhitespaceAfterClosingQuote = allowsWhitespaceAfterClosingQuote
    }

    /// Comma-separated values format.
    public static let csv = CSVFormat(delimiter: ",")
    /// Tab-separated values format.
    public static let tsv = CSVFormat(delimiter: "\t")
    /// Semicolon-separated values format.
    public static let ssv = CSVFormat(delimiter: ";")
    /// Pipe-separated values format.
    public static let psv = CSVFormat(delimiter: "|")
}
