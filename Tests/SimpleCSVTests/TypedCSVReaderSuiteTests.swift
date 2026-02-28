//
//  TypedCSVReaderSuiteTests.swift
//  SimpleCSVTests
//
//  Created by David Thorn on 28.02.2026.
//

import Foundation
import Testing
@testable import SimpleCSV

@Suite("TypedCSVReader Suite")
struct TypedCSVReaderSuiteTests {
    @Test("initializer stores underlying reader")
    func initializerStoresUnderlyingReader() {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [["food.apple", "Apple", "95"]],
            fileName: "foods.csv"
        )

        let typedReader = TypedCSVReader<TypedCSVColumn>(reader: reader)

        #expect(typedReader.reader.documentID == reader.documentID)
    }

    @Test("properties mirror wrapped reader")
    func propertiesMirrorWrappedReader() {
        let documentID = CSVDocumentID()
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [
                ["food.apple", "Apple", "95"],
                ["food.banana", "Banana", "105"]
            ],
            fileName: "foods.csv",
            documentID: documentID
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)

        #expect(typedReader.documentID == documentID)
        #expect(typedReader.isEmpty == false)
        #expect(typedReader.rowCount == 2)
        #expect(typedReader.columnCount == 3)
    }

    @Test("properties reflect empty wrapped reader")
    func propertiesReflectEmptyWrappedReader() {
        let reader = CSVReader(
            rows: [],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)

        #expect(typedReader.isEmpty)
        #expect(typedReader.rowCount == 0)
        #expect(typedReader.columnCount == 0)
        #expect(typedReader.allRows().isEmpty)
    }

    @Test("columnName returns matching header for typed column")
    func columnNameReturnsMatchingHeaderForTypedColumn() throws {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)

        #expect(try typedReader.columnName(for: .foodID) == "food_id")
        #expect(try typedReader.columnName(for: .name) == "name")
        #expect(try typedReader.columnName(for: .calories) == "calories")
    }

    @Test("columnName throws when header is unavailable")
    func columnNameThrowsWhenHeaderIsUnavailable() throws {
        let reader = try CSVReader(
            validating: [
                ["food.apple", "Apple", "95"]
            ],
            fileName: "foods.csv",
            configuration: CSVReaderConfiguration(
                headerStrategy: .none,
                rowWidthValidationStrategy: .strict
            )
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)

        #expect(throws: NSError.self) {
            _ = try typedReader.columnName(for: .name)
        }
    }

    @Test("index returns matching index for typed column")
    func indexReturnsMatchingIndexForTypedColumn() throws {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)

        #expect(try typedReader.index(for: .foodID) == 0)
        #expect(try typedReader.index(for: .name) == 1)
        #expect(try typedReader.index(for: .calories) == 2)
    }

    @Test("index throws when typed column name is missing")
    func indexThrowsWhenTypedColumnNameIsMissing() {
        let reader = CSVReader(
            header: ["food_id", "name"],
            dataRows: [],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)

        #expect(throws: NSError.self) {
            _ = try typedReader.index(for: .calories)
        }
    }

    @Test("row returns matching data row")
    func rowReturnsMatchingDataRow() throws {
        let documentID = CSVDocumentID()
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [
                ["food.apple", "Apple", "95"],
                ["food.banana", "Banana", "105"]
            ],
            fileName: "foods.csv",
            documentID: documentID
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)
        let row = try typedReader.row(at: 1)

        #expect(row.documentID == documentID)
        #expect(row.rowIndex == 2)
        #expect(row.cells.count == 3)
        #expect(row.cells[0].value == "food.banana")
        #expect(row.cells[1].value == "Banana")
        #expect(row.cells[2].value == "105")
    }

    @Test("row throws for invalid index")
    func rowThrowsForInvalidIndex() {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [["food.apple", "Apple", "95"]],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)

        #expect(throws: NSError.self) {
            _ = try typedReader.row(at: 1)
        }
    }

    @Test("rowReader returns typed row reader for matching row")
    func rowReaderReturnsTypedRowReaderForMatchingRow() throws {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [
                ["food.apple", "Apple", "95"],
                ["food.banana", "Banana", "105"]
            ],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)
        let rowReader = try typedReader.rowReader(at: 1)

        #expect(rowReader.row.rowIndex == 2)
        #expect(rowReader.columnCount == 3)
        #expect(try rowReader.cell(at: .foodID).value == "food.banana")
        #expect(try rowReader.cell(for: .name).value == "Banana")
        #expect(try rowReader.cell(for: .calories).value == "105")
    }

    @Test("rowReader throws for invalid index")
    func rowReaderThrowsForInvalidIndex() {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [["food.apple", "Apple", "95"]],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)

        #expect(throws: NSError.self) {
            _ = try typedReader.rowReader(at: 1)
        }
    }

    @Test("rowReaders returns typed sequence in data row order")
    func rowReadersReturnsTypedSequenceInDataRowOrder() throws {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [
                ["food.apple", "Apple", "95"],
                ["food.banana", "Banana", "105"]
            ],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)
        let rowReaders = try typedReader.rowReaders()

        #expect(rowReaders.startIndex == 0)
        #expect(rowReaders.endIndex == 2)
        #expect(rowReaders.index(after: 0) == 1)
        #expect(try rowReaders[0].cell(for: .name).value == "Apple")
        #expect(try rowReaders[1].cell(for: .name).value == "Banana")

        var names: [String] = []
        for rowReader in rowReaders {
            names.append(try rowReader.cell(for: .name).value)
        }

        #expect(names == ["Apple", "Banana"])
    }

    @Test("allRows returns header row followed by data rows")
    func allRowsReturnsHeaderRowFollowedByDataRows() {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [
                ["food.apple", "Apple", "95"],
                ["food.banana", "Banana", "105"]
            ],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)
        let rows = typedReader.allRows()

        #expect(rows.count == 3)
        #expect(rows[0].rowIndex == 0)
        #expect(rows[1].rowIndex == 1)
        #expect(rows[2].rowIndex == 2)
        #expect(rows[0].cells[0].value == "food_id")
        #expect(rows[2].cells[1].value == "Banana")
    }

    @Test("headerColumns returns resolved columns in order")
    func headerColumnsReturnsResolvedColumnsInOrder() throws {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)
        let columns = try typedReader.headerColumns()

        #expect(columns == [
            CSVHeaderColumn(name: "food_id", index: 0),
            CSVHeaderColumn(name: "name", index: 1),
            CSVHeaderColumn(name: "calories", index: 2)
        ])
    }

    @Test("headerColumns excluding filters resolved columns")
    func headerColumnsExcludingFiltersResolvedColumns() throws {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)
        let columns = try typedReader.headerColumns(excluding: ["food_id", "calories"])

        #expect(columns == [
            CSVHeaderColumn(name: "name", index: 1)
        ])
    }

    @Test("mapRows maps typed rows into values")
    func mapRowsMapsTypedRowsIntoValues() throws {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [
                ["food.apple", "Apple", "95"],
                ["food.banana", "Banana", "105"]
            ],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)
        let names = try typedReader.mapRows { rowReader in
            try rowReader.cell(for: .name).value
        }

        #expect(names == ["Apple", "Banana"])
    }

    @Test("mapRows rethrows transform error")
    func mapRowsRethrowsTransformError() {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [["food.apple", "Apple", "95"]],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)

        #expect(throws: TypedCSVReaderTestError.self) {
            _ = try typedReader.mapRows { _ in
                throw TypedCSVReaderTestError.expected
            }
        }
    }

    @Test("compactMapRows filters nil results")
    func compactMapRowsFiltersNilResults() throws {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [
                ["food.apple", "Apple", "95"],
                ["food.banana", "Banana", "105"],
                ["food.cherry", "Cherry", "77"]
            ],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)
        let highCalorieNames: [String] = try typedReader.compactMapRows { rowReader in
            let calories = Int(try rowReader.cell(for: .calories).value) ?? 0
            guard calories >= 100 else {
                return nil
            }
            return try rowReader.cell(for: .name).value
        }

        #expect(highCalorieNames == ["Banana"])
    }

    @Test("compactMapRows rethrows transform error")
    func compactMapRowsRethrowsTransformError() {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [["food.apple", "Apple", "95"]],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)

        #expect(throws: TypedCSVReaderTestError.self) {
            _ = try typedReader.compactMapRows { _ in
                throw TypedCSVReaderTestError.expected
            }
        }
    }

    @Test("reduceRows accumulates typed row values")
    func reduceRowsAccumulatesTypedRowValues() throws {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [
                ["food.apple", "Apple", "95"],
                ["food.banana", "Banana", "105"]
            ],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)
        let totalCalories = try typedReader.reduceRows(into: 0) { total, rowReader in
            total += Int(try rowReader.cell(for: .calories).value) ?? 0
        }

        #expect(totalCalories == 200)
    }

    @Test("reduceRows rethrows transform error")
    func reduceRowsRethrowsTransformError() {
        let reader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [["food.apple", "Apple", "95"]],
            fileName: "foods.csv"
        )

        let typedReader = reader.typed(as: TypedCSVColumn.self)

        #expect(throws: TypedCSVReaderTestError.self) {
            _ = try typedReader.reduceRows(into: 0) { _, _ in
                throw TypedCSVReaderTestError.expected
            }
        }
    }
}

private enum TypedCSVReaderTestError: Error {
    case expected
}
