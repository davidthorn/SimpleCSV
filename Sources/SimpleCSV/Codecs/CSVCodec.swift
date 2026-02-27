//
//  CSVCodec.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Default codec implementation for separated-value text parsing and encoding.
public struct CSVCodec: CSVCodecProtocol, Sendable {
    private let format: CSVFormat

    /// Creates a codec with a specific format configuration.
    /// - Parameter format: Delimiter and quote format configuration.
    public init(format: CSVFormat = .csv) {
        self.format = format
    }

    /// Decodes separated-value text into rows and fields.
    /// - Parameter content: Raw text content.
    /// - Returns: Parsed rows and fields.
    public func decodeRows(from content: String) throws -> [[String]] {
        try parseRows(normalizedInput(content))
    }

    /// Encodes rows and fields into separated-value text.
    /// - Parameter rows: Rows to encode.
    /// - Returns: Encoded text content.
    public func encodeRows(_ rows: [[String]]) -> String {
        let delimiter = String(format.delimiter)
        var content = ""
        for row in rows {
            let escapedValues = row.map { escape($0) }
            content += escapedValues.joined(separator: delimiter)
            content += "\n"
        }
        return content
    }

    private func normalizedInput(_ content: String) -> String {
        if content.first == "\u{FEFF}" {
            return String(content.dropFirst())
        }
        return content
    }

    private func parseRows(_ content: String) throws -> [[String]] {
        let scalars = Array(content.unicodeScalars)
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentValue = ""
        var inQuotes = false
        var justClosedQuote = false
        var hasStartedField = false
        var position = 0

        let quote = format.quote
        let delimiter = format.delimiter
        let lineFeed = UnicodeScalar(10)
        let carriageReturn = UnicodeScalar(13)
        let space = UnicodeScalar(32)
        let tab = UnicodeScalar(9)

        @inline(__always)
        func appendField(to row: inout [String], value: inout String, justClosedQuote: inout Bool, hasStartedField: inout Bool) {
            row.append(value)
            value = ""
            justClosedQuote = false
            hasStartedField = false
        }

        var index = 0
        while index < scalars.count {
            position += 1
            let scalar = scalars[index]
            let nextScalar: UnicodeScalar? = (index + 1 < scalars.count) ? scalars[index + 1] : nil

            if inQuotes {
                if scalar == quote {
                    if nextScalar == quote {
                        currentValue.unicodeScalars.append(quote)
                        index += 2
                        continue
                    }

                    inQuotes = false
                    justClosedQuote = true
                    index += 1
                    continue
                }

                currentValue.unicodeScalars.append(scalar)
                index += 1
                continue
            }

            if justClosedQuote {
                if scalar == delimiter {
                    appendField(to: &currentRow, value: &currentValue, justClosedQuote: &justClosedQuote, hasStartedField: &hasStartedField)
                    index += 1
                    continue
                }

                if scalar == lineFeed {
                    appendField(to: &currentRow, value: &currentValue, justClosedQuote: &justClosedQuote, hasStartedField: &hasStartedField)
                    rows.append(currentRow)
                    currentRow = []
                    index += 1
                    continue
                }

                if scalar == carriageReturn {
                    appendField(to: &currentRow, value: &currentValue, justClosedQuote: &justClosedQuote, hasStartedField: &hasStartedField)
                    rows.append(currentRow)
                    currentRow = []

                    if nextScalar == lineFeed {
                        index += 2
                    } else {
                        index += 1
                    }
                    continue
                }

                if format.allowsWhitespaceAfterClosingQuote && (scalar == space || scalar == tab) {
                    index += 1
                    continue
                }

                throw CSVCodecError.invalidCharacterAfterClosingQuote(position: position, character: Character(scalar))
            }

            if scalar == quote {
                if hasStartedField || currentValue.isEmpty == false {
                    throw CSVCodecError.unexpectedQuote(position: position)
                }

                inQuotes = true
                hasStartedField = true
                index += 1
                continue
            }

            if scalar == delimiter {
                appendField(to: &currentRow, value: &currentValue, justClosedQuote: &justClosedQuote, hasStartedField: &hasStartedField)
                index += 1
                continue
            }

            if scalar == lineFeed {
                appendField(to: &currentRow, value: &currentValue, justClosedQuote: &justClosedQuote, hasStartedField: &hasStartedField)
                rows.append(currentRow)
                currentRow = []
                index += 1
                continue
            }

            if scalar == carriageReturn {
                appendField(to: &currentRow, value: &currentValue, justClosedQuote: &justClosedQuote, hasStartedField: &hasStartedField)
                rows.append(currentRow)
                currentRow = []

                if nextScalar == lineFeed {
                    index += 2
                } else {
                    index += 1
                }
                continue
            }

            hasStartedField = true
            currentValue.unicodeScalars.append(scalar)
            index += 1
        }

        if inQuotes {
            throw CSVCodecError.unclosedQuotedField
        }

        if justClosedQuote || hasStartedField || currentValue.isEmpty == false || currentRow.isEmpty == false {
            appendField(to: &currentRow, value: &currentValue, justClosedQuote: &justClosedQuote, hasStartedField: &hasStartedField)
            rows.append(currentRow)
        }

        return rows
    }

    private func escape(_ value: String) -> String {
        let delimiterString = String(format.delimiter)
        let quoteString = String(format.quote)
        if value.contains(delimiterString) || value.contains(quoteString) || value.contains("\n") || value.contains("\r") {
            let quoted = value.replacingOccurrences(of: quoteString, with: quoteString + quoteString)
            return quoteString + quoted + quoteString
        }
        return value
    }
}
