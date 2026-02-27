//
//  CSVReaderValidationTests.swift
//  SimpleCSVTests
//
//  Created by David Thorn on 27.02.2026.
//

import Testing
@testable import SimpleCSV

@Suite("CSVReaderValidationTests")
struct CSVReaderValidationTests {
    @Test("required header throws on empty rows")
    func requiredHeaderThrowsOnEmptyRows() {
        let configuration = CSVReaderConfiguration(headerStrategy: .required)

        #expect(throws: CSVReaderValidationError.self) {
            _ = try CSVReader(
                validating: [],
                fileName: "foods.csv",
                configuration: configuration
            )
        }
    }

    @Test("duplicate header names throw when validation is enabled")
    func duplicateHeaderNamesThrow() {
        let configuration = CSVReaderConfiguration(
            headerStrategy: .required,
            rowWidthValidationStrategy: .strict,
            validatesUniqueHeaderNames: true
        )

        #expect(throws: CSVReaderValidationError.self) {
            _ = try CSVReader(
                validating: [
                    ["food_id", "food_id"],
                    ["food.apple", "Apple"]
                ],
                fileName: "foods.csv",
                configuration: configuration
            )
        }
    }

    @Test("strict row width throws when data row has fewer columns than header")
    func strictRowWidthThrowsForHeaderMismatch() {
        let configuration = CSVReaderConfiguration(
            headerStrategy: .required,
            rowWidthValidationStrategy: .strict
        )

        #expect(throws: CSVReaderValidationError.self) {
            _ = try CSVReader(
                validating: [
                    ["food_id", "name", "calories"],
                    ["food.apple", "Apple"]
                ],
                fileName: "foods.csv",
                configuration: configuration
            )
        }
    }

    @Test("no header strategy validates width against first data row")
    func noHeaderStrategyValidatesAgainstFirstDataRow() {
        let configuration = CSVReaderConfiguration(
            headerStrategy: .none,
            rowWidthValidationStrategy: .strict
        )

        #expect(throws: CSVReaderValidationError.self) {
            _ = try CSVReader(
                validating: [
                    ["food.apple", "Apple"],
                    ["food.banana"]
                ],
                fileName: "foods.csv",
                configuration: configuration
            )
        }
    }

    @Test("optional header with no rows yields empty reader")
    func optionalHeaderWithNoRowsBuildsEmptyReader() throws {
        let configuration = CSVReaderConfiguration(
            headerStrategy: .optional,
            rowWidthValidationStrategy: .strict
        )

        let reader = try CSVReader(
            validating: [],
            fileName: "foods.csv",
            configuration: configuration
        )

        #expect(reader.isEmpty)
        #expect(reader.rowCount == 0)
        #expect(reader.columnCount == 0)
    }

    @Test("optional header uses first row as header when rows exist")
    func optionalHeaderUsesFirstRowAsHeaderWhenRowsExist() throws {
        let configuration = CSVReaderConfiguration(
            headerStrategy: .optional,
            rowWidthValidationStrategy: .strict
        )

        let reader = try CSVReader(
            validating: [
                ["food_id", "name"],
                ["food.apple", "Apple"]
            ],
            fileName: "foods.csv",
            configuration: configuration
        )

        #expect(reader.columnCount == 2)
        #expect(reader.rowCount == 1)
        #expect(try reader.columnName(at: 0) == "food_id")
        #expect(try reader.columnName(at: 1) == "name")
        #expect(try reader.rowReader(at: 0).cell(for: "name").value == "Apple")
    }
}
