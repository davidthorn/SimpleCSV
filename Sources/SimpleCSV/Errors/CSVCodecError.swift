//
//  CSVCodecError.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Errors emitted while parsing or encoding delimited content.
public enum CSVCodecError: LocalizedError, Equatable, Sendable {
    /// A quoted field was opened but not closed.
    case unclosedQuotedField
    /// A quote appeared in an invalid position.
    case unexpectedQuote(position: Int)
    /// An invalid character was found after a closing quote.
    case invalidCharacterAfterClosingQuote(position: Int, character: Character)

    /// Human-readable error description.
    public var errorDescription: String? {
        switch self {
        case .unclosedQuotedField:
            return "Unclosed quoted field."
        case .unexpectedQuote(let position):
            return "Unexpected quote at position \(position)."
        case .invalidCharacterAfterClosingQuote(let position, let character):
            return "Invalid character '\(character)' after closing quote at position \(position)."
        }
    }
}
