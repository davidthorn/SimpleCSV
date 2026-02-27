//
//  CSVCodecCoverageSuiteTests.swift
//  SimpleCSVTests
//
//  Created by David Thorn on 27.02.2026.
//

import Testing
@testable import SimpleCSV

@Suite("CSVCodec Coverage Suite")
struct CSVCodecCoverageSuiteTests {
    @Test("decode returns empty rows for empty content")
    func decodeReturnsEmptyRowsForEmptyContent() throws {
        let codec = CSVCodec()
        let rows = try codec.decodeRows(from: "")
        #expect(rows.isEmpty)
    }

    @Test("decode handles carriage-return only line endings")
    func decodeHandlesCarriageReturnOnlyLineEndings() throws {
        let codec = CSVCodec()
        let rows = try codec.decodeRows(from: "food_id,name\rfood.apple,Apple\rfood.banana,Banana\r")

        #expect(rows == [
            ["food_id", "name"],
            ["food.apple", "Apple"],
            ["food.banana", "Banana"]
        ])
    }

    @Test("decode handles carriage return after closing quoted field")
    func decodeHandlesCarriageReturnAfterClosingQuotedField() throws {
        let codec = CSVCodec()
        let rows = try codec.decodeRows(from: "\"Apple\"\r\"Banana\"\r")

        #expect(rows == [
            ["Apple"],
            ["Banana"]
        ])
    }

    @Test("decode handles carriage return line feed after closing quoted field")
    func decodeHandlesCarriageReturnLineFeedAfterClosingQuotedField() throws {
        let codec = CSVCodec()
        let rows = try codec.decodeRows(from: "\"Apple\"\r\n\"Banana\"\r\n")

        #expect(rows == [
            ["Apple"],
            ["Banana"]
        ])
    }

    @Test("decode handles eof after closed quoted field")
    func decodeHandlesEOFAfterClosedQuotedField() throws {
        let codec = CSVCodec()
        let rows = try codec.decodeRows(from: "\"Apple\"")

        #expect(rows == [["Apple"]])
    }

    @Test("decode handles eof after started unquoted field")
    func decodeHandlesEOFAfterStartedUnquotedField() throws {
        let codec = CSVCodec()
        let rows = try codec.decodeRows(from: "Apple")

        #expect(rows == [["Apple"]])
    }

    @Test("decode handles trailing delimiter as empty field")
    func decodeHandlesTrailingDelimiterAsEmptyField() throws {
        let codec = CSVCodec()
        let rows = try codec.decodeRows(from: "food_id,name,\n")

        #expect(rows == [["food_id", "name", ""]])
    }

    @Test("decode handles row with only delimiter")
    func decodeHandlesRowWithOnlyDelimiter() throws {
        let codec = CSVCodec()
        let rows = try codec.decodeRows(from: ",")

        #expect(rows == [["", ""]])
    }

    @Test("decode supports escaped quote in quoted field")
    func decodeSupportsEscapedQuoteInQuotedField() throws {
        let codec = CSVCodec()
        let rows = try codec.decodeRows(from: "food_id,note\nfood.apple,\"He said \"\"hi\"\"\"\n")

        #expect(rows == [
            ["food_id", "note"],
            ["food.apple", "He said \"hi\""]
        ])
    }

    @Test("decode allows whitespace after closing quote when enabled")
    func decodeAllowsWhitespaceAfterClosingQuoteWhenEnabled() throws {
        let codec = CSVCodec(
            format: CSVFormat(
                delimiter: ",",
                quote: "\"",
                allowsWhitespaceAfterClosingQuote: true
            )
        )

        let rows = try codec.decodeRows(from: "\"Apple\" \t,fruit\n")
        #expect(rows == [["Apple", "fruit"]])
    }

    @Test("decode throws invalid character after closing quote when whitespace disabled")
    func decodeThrowsInvalidCharacterAfterClosingQuoteWhenWhitespaceDisabled() {
        let codec = CSVCodec(
            format: CSVFormat(
                delimiter: ",",
                quote: "\"",
                allowsWhitespaceAfterClosingQuote: false
            )
        )

        do {
            _ = try codec.decodeRows(from: "\"Apple\" ,fruit\n")
            #expect(Bool(false))
        } catch let error as CSVCodecError {
            #expect(error == .invalidCharacterAfterClosingQuote(position: 8, character: " "))
        } catch {
            #expect(Bool(false))
        }
    }

    @Test("decode throws unexpected quote with exact position")
    func decodeThrowsUnexpectedQuoteWithExactPosition() {
        let codec = CSVCodec()

        do {
            _ = try codec.decodeRows(from: "a\"b\n")
            #expect(Bool(false))
        } catch let error as CSVCodecError {
            #expect(error == .unexpectedQuote(position: 2))
        } catch {
            #expect(Bool(false))
        }
    }

    @Test("encode returns empty string for empty row set")
    func encodeReturnsEmptyStringForEmptyRowSet() {
        let codec = CSVCodec()
        let encoded = codec.encodeRows([])
        #expect(encoded == "")
    }

    @Test("encode quotes values containing carriage return")
    func encodeQuotesValuesContainingCarriageReturn() {
        let codec = CSVCodec()
        let encoded = codec.encodeRows([["food_id", "note"], ["food.apple", "line1\rline2"]])

        #expect(encoded.contains("\"line1\rline2\""))
    }
}
