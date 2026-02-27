//
//  CSVCodecTests.swift
//  SimpleCSVTests
//
//  Created by David Thorn on 27.02.2026.
//

import Testing
@testable import SimpleCSV

@Suite("CSVCodecTests")
struct CSVCodecTests {
    @Test("encodes and decodes quoted values")
    func encodesAndDecodesQuotedValues() throws {
        let codec = CSVCodec()
        let rows: [[String]] = [
            ["name", "note"],
            ["Apple", "Sweet, crisp"],
            ["Quote", "He said \"hello\""]
        ]

        let encoded = codec.encodeRows(rows)
        let decoded = try codec.decodeRows(from: encoded)

        #expect(decoded == rows)
    }

    @Test("decodes utf8 bom with crlf line endings")
    func decodesBOMAndCRLF() throws {
        let codec = CSVCodec()
        let content = "\u{FEFF}food_id,name\r\nfood.apple,Apple\r\nfood.banana,Banana\r\n"

        let decoded = try codec.decodeRows(from: content)

        #expect(decoded == [
            ["food_id", "name"],
            ["food.apple", "Apple"],
            ["food.banana", "Banana"]
        ])
    }

    @Test("decodes embedded newline and comma inside quoted field")
    func decodesEmbeddedNewlineAndComma() throws {
        let codec = CSVCodec()
        let content = "food_id,notes\nfood.apple,\"line one\nline two, still quoted\"\n"

        let decoded = try codec.decodeRows(from: content)

        #expect(decoded == [
            ["food_id", "notes"],
            ["food.apple", "line one\nline two, still quoted"]
        ])
    }

    @Test("throws when quote appears in unquoted field")
    func throwsOnUnexpectedQuote() {
        let codec = CSVCodec()
        let content = "food_id\nfood\".apple\n"

        #expect(throws: CSVCodecError.self) {
            _ = try codec.decodeRows(from: content)
        }
    }

    @Test("throws when quoted field is not closed")
    func throwsOnUnclosedQuotedField() {
        let codec = CSVCodec()
        let content = "food_id,name\nfood.apple,\"Apple\n"

        #expect(throws: CSVCodecError.self) {
            _ = try codec.decodeRows(from: content)
        }
    }

    @Test("decodes semicolon separated values")
    func decodesSemicolonSeparatedValues() throws {
        let codec = CSVCodec(format: .ssv)
        let content = "food_id;name\nfood.apple;Apple\n"

        let decoded = try codec.decodeRows(from: content)

        #expect(decoded == [
            ["food_id", "name"],
            ["food.apple", "Apple"]
        ])
    }

    @Test("decodes tab separated values")
    func decodesTabSeparatedValues() throws {
        let codec = CSVCodec(format: .tsv)
        let content = "food_id\tname\nfood.apple\tApple\n"

        let decoded = try codec.decodeRows(from: content)

        #expect(decoded == [
            ["food_id", "name"],
            ["food.apple", "Apple"]
        ])
    }

    @Test("encodes and decodes pipe separated values")
    func encodesAndDecodesPipeSeparatedValues() throws {
        let codec = CSVCodec(format: .psv)
        let rows: [[String]] = [
            ["food_id", "note"],
            ["food.apple", "A|B"]
        ]

        let encoded = codec.encodeRows(rows)
        let decoded = try codec.decodeRows(from: encoded)

        #expect(decoded == rows)
    }
}
