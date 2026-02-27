//
//  CSVReaderCoverageSuiteTests.swift
//  SimpleCSVTests
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation
import Testing
@testable import SimpleCSV

@Suite("CSVReader Coverage Suite")
struct CSVReaderCoverageSuiteTests {
    @Test("rows initializer handles empty rows")
    func rowsInitializerHandlesEmptyRows() throws {
        let documentID = CSVDocumentID()
        let reader = CSVReader(
            rows: [],
            fileName: "foods.csv",
            documentID: documentID
        )

        #expect(reader.documentID == documentID)
        #expect(reader.isEmpty)
        #expect(reader.rowCount == 0)
        #expect(reader.columnCount == 0)
        #expect(reader.allRows().isEmpty)

        #expect(throws: NSError.self) {
            _ = try reader.columnName(at: 0)
        }
        #expect(throws: NSError.self) {
            _ = try reader.index(for: "food_id")
        }
        #expect(throws: NSError.self) {
            _ = try reader.row(at: 0)
        }
    }

    @Test("rows initializer splits header and data rows and keeps document id")
    func rowsInitializerSplitsHeaderAndDataRowsAndKeepsDocumentID() throws {
        let documentID = CSVDocumentID()
        let reader = CSVReader(
            rows: [
                ["food_id", "name"],
                ["food.apple", "Apple"],
                ["food.banana", "Banana"]
            ],
            fileName: "foods.csv",
            documentID: documentID
        )

        #expect(reader.documentID == documentID)
        #expect(reader.isEmpty == false)
        #expect(reader.columnCount == 2)
        #expect(reader.rowCount == 2)
        #expect(try reader.columnName(at: 0) == "food_id")
        #expect(try reader.columnName(at: 1) == "name")

        let firstDataRow = try reader.row(at: 0)
        #expect(firstDataRow.rowIndex == 1)
        #expect(firstDataRow.cells[0].value == "food.apple")
        #expect(firstDataRow.cells[0].documentID == documentID)
        #expect(firstDataRow.cells[1].value == "Apple")
    }

    @Test("header and dataRows initializer handles empty header")
    func headerAndDataRowsInitializerHandlesEmptyHeader() throws {
        let documentID = CSVDocumentID()
        let reader = CSVReader(
            header: [],
            dataRows: [
                ["food.apple", "Apple"],
                ["food.banana", "Banana"]
            ],
            fileName: "foods.csv",
            documentID: documentID
        )

        #expect(reader.documentID == documentID)
        #expect(reader.columnCount == 0)
        #expect(reader.rowCount == 2)
        #expect(reader.isEmpty == false)

        let rows = reader.allRows()
        #expect(rows.count == 2)
        #expect(rows[0].rowIndex == 0)
        #expect(rows[1].rowIndex == 1)
        #expect(rows[0].cells[0].columnName == nil)
        #expect(rows[1].cells[1].columnName == nil)

        let firstRow = try reader.row(at: 0)
        #expect(firstRow.rowIndex == 0)
        #expect(firstRow.cells[0].value == "food.apple")
        #expect(firstRow.cells[0].documentID == documentID)

        #expect(throws: NSError.self) {
            _ = try reader.columnName(at: 0)
        }
        #expect(throws: NSError.self) {
            _ = try reader.index(for: "food_id")
        }
    }

    @Test("allRows includes header row followed by data rows")
    func allRowsIncludesHeaderAndDataRows() throws {
        let documentID = CSVDocumentID()
        let reader = CSVReader(
            header: ["food_id", "name"],
            dataRows: [
                ["food.apple", "Apple"],
                ["food.banana", "Banana"]
            ],
            fileName: "foods.csv",
            documentID: documentID
        )

        let rows = reader.allRows()
        #expect(rows.count == 3)
        #expect(rows[0].rowIndex == 0)
        #expect(rows[1].rowIndex == 1)
        #expect(rows[2].rowIndex == 2)
        #expect(rows[0].cells[0].columnName == nil)
        #expect(rows[1].cells[0].columnName == "food_id")
        #expect(rows[1].cells[1].columnName == "name")
        #expect(rows[2].cells[1].value == "Banana")
        #expect(rows[2].documentID == documentID)
    }

    @Test("allRows without header uses row zero for first data row")
    func allRowsWithoutHeaderUsesZeroBasedDataRows() throws {
        let reader = try CSVReader(
            validating: [
                ["food.apple", "Apple"],
                ["food.banana", "Banana"]
            ],
            fileName: "foods.csv",
            configuration: CSVReaderConfiguration(
                headerStrategy: .none,
                rowWidthValidationStrategy: .strict
            )
        )

        let rows = reader.allRows()
        #expect(rows.count == 2)
        #expect(rows[0].rowIndex == 0)
        #expect(rows[1].rowIndex == 1)
        #expect(rows[0].cells[0].columnName == nil)
        #expect(rows[1].cells[1].value == "Banana")
    }

    @Test("columnName throws for invalid index")
    func columnNameThrowsForInvalidIndex() {
        let reader = CSVReader(
            header: ["food_id"],
            dataRows: [],
            fileName: "foods.csv"
        )

        #expect(throws: NSError.self) {
            _ = try reader.columnName(at: 9)
        }
    }

    @Test("columnName returns header value for valid index")
    func columnNameReturnsHeaderValueForValidIndex() throws {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [],
            fileName: "foods.csv"
        )

        #expect(try reader.columnName(at: 0) == "food_id")
        #expect(try reader.columnName(at: 1) == "name")
        #expect(try reader.columnName(at: 2) == "calories")
    }

    @Test("columnName throws when no header is configured")
    func columnNameThrowsWhenNoHeaderIsConfigured() throws {
        let reader = try CSVReader(
            validating: [
                ["food.apple", "Apple"]
            ],
            fileName: "foods.csv",
            configuration: CSVReaderConfiguration(
                headerStrategy: .none,
                rowWidthValidationStrategy: .strict
            )
        )

        #expect(reader.columnCount == 0)
        #expect(throws: NSError.self) {
            _ = try reader.columnName(at: 0)
        }
    }

    @Test("index throws for missing column")
    func indexThrowsForMissingColumn() {
        let reader = CSVReader(
            header: ["food_id"],
            dataRows: [],
            fileName: "foods.csv"
        )

        #expect(throws: NSError.self) {
            _ = try reader.index(for: "name")
        }
    }

    @Test("row throws for invalid row index")
    func rowThrowsForInvalidRowIndex() {
        let reader = CSVReader(
            header: ["food_id"],
            dataRows: [["food.apple"]],
            fileName: "foods.csv"
        )

        #expect(throws: NSError.self) {
            _ = try reader.row(at: 9)
        }
    }

    @Test("rowReader returns row reader with same row content")
    func rowReaderReturnsRowReaderWithSameRowContent() throws {
        let reader = CSVReader(
            header: ["food_id", "name"],
            dataRows: [["food.apple", "Apple"]],
            fileName: "foods.csv"
        )

        let row = try reader.row(at: 0)
        let rowReader = try reader.rowReader(at: 0)

        #expect(rowReader.row == row)
        #expect(rowReader.columnCount == 2)
        #expect(try rowReader.cell(for: "food_id").value == "food.apple")
    }

    @Test("index uses first duplicate header occurrence")
    func indexUsesFirstDuplicateHeaderOccurrence() throws {
        let reader = CSVReader(
            header: ["food_id", "name", "name"],
            dataRows: [["food.apple", "Apple", "A"]],
            fileName: "foods.csv"
        )

        let index = try reader.index(for: "name")
        #expect(index == 1)
    }

    @Test("rowReader cell lookup throws typed row reader error")
    func rowReaderCellLookupThrowsTypedError() throws {
        let reader = CSVReader(
            header: ["food_id"],
            dataRows: [["food.apple"]],
            fileName: "foods.csv"
        )
        let rowReader = try reader.rowReader(at: 0)

        #expect(throws: CSVRowReaderError.self) {
            _ = try rowReader.cell(for: "missing")
        }
    }
}
