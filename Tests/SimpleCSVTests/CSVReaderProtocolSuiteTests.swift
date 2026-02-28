//
//  CSVReaderProtocolSuiteTests.swift
//  SimpleCSVTests
//
//  Created by David Thorn on 28.02.2026.
//

import Foundation
import Testing
@testable import SimpleCSV

@Suite("CSVReaderProtocol Suite")
struct CSVReaderProtocolSuiteTests {
    @Test("headerColumns returns resolved columns from protocol typed reader")
    func headerColumnsReturnsResolvedColumnsFromProtocolTypedReader() throws {
        let reader: CSVReaderProtocol = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [["food.apple", "Apple", "95"]],
            fileName: "foods.csv"
        )

        let columns = try reader.headerColumns()

        #expect(columns == [
            CSVHeaderColumn(name: "food_id", index: 0),
            CSVHeaderColumn(name: "name", index: 1),
            CSVHeaderColumn(name: "calories", index: 2)
        ])
    }

    @Test("headerColumns returns empty array when header is empty")
    func headerColumnsReturnsEmptyArrayWhenHeaderIsEmpty() throws {
        let reader: CSVReaderProtocol = CSVReader(
            header: [],
            dataRows: [["food.apple", "Apple"]],
            fileName: "foods.csv"
        )

        let columns = try reader.headerColumns()

        #expect(columns.isEmpty)
    }

    @Test("headerColumns excluding removes matching names")
    func headerColumnsExcludingRemovesMatchingNames() throws {
        let reader: CSVReaderProtocol = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [["food.apple", "Apple", "95"]],
            fileName: "foods.csv"
        )

        let columns = try reader.headerColumns(excluding: ["food_id", "calories"])

        #expect(columns == [
            CSVHeaderColumn(name: "name", index: 1)
        ])
    }

    @Test("headerColumns excluding ignores unknown names")
    func headerColumnsExcludingIgnoresUnknownNames() throws {
        let reader: CSVReaderProtocol = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [["food.apple", "Apple", "95"]],
            fileName: "foods.csv"
        )

        let columns = try reader.headerColumns(excluding: ["missing"])

        #expect(columns == [
            CSVHeaderColumn(name: "food_id", index: 0),
            CSVHeaderColumn(name: "name", index: 1),
            CSVHeaderColumn(name: "calories", index: 2)
        ])
    }

    @Test("typed returns typed reader bound to protocol typed reader")
    func typedReturnsTypedReaderBoundToProtocolTypedReader() throws {
        let sourceReader = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [["food.apple", "Apple", "95"]],
            fileName: "foods.csv"
        )
        let reader: CSVReaderProtocol = sourceReader

        let typedReader = reader.typed(as: TypedCSVColumn.self)

        #expect(typedReader.documentID == sourceReader.documentID)
        #expect(try typedReader.rowReader(at: 0).cell(for: .name).value == "Apple")
    }

    @Test("typed columnName overload resolves header value")
    func typedColumnNameOverloadResolvesHeaderValue() throws {
        let reader: CSVReaderProtocol = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [],
            fileName: "foods.csv"
        )

        #expect(try reader.columnName(at: TypedCSVColumnIndex.foodID) == "food_id")
        #expect(try reader.columnName(at: TypedCSVColumnIndex.name) == "name")
        #expect(try reader.columnName(at: TypedCSVColumnIndex.calories) == "calories")
    }

    @Test("typed index overload resolves column name")
    func typedIndexOverloadResolvesColumnName() throws {
        let reader: CSVReaderProtocol = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [],
            fileName: "foods.csv"
        )

        #expect(try reader.index(for: TypedCSVColumnName.foodID) == 0)
        #expect(try reader.index(for: TypedCSVColumnName.name) == 1)
        #expect(try reader.index(for: TypedCSVColumnName.calories) == 2)
    }

    @Test("typed row overload returns matching row")
    func typedRowOverloadReturnsMatchingRow() throws {
        let reader: CSVReaderProtocol = CSVReader(
            header: ["food_id", "name"],
            dataRows: [
                ["food.apple", "Apple"],
                ["food.banana", "Banana"]
            ],
            fileName: "foods.csv"
        )

        let row = try reader.row(at: TypedCSVRowIndex.second)

        #expect(row.rowIndex == 2)
        #expect(row.cells[0].value == "food.banana")
        #expect(row.cells[1].value == "Banana")
    }

    @Test("typed rowReader overload returns matching row reader")
    func typedRowReaderOverloadReturnsMatchingRowReader() throws {
        let reader: CSVReaderProtocol = CSVReader(
            header: ["food_id", "name"],
            dataRows: [
                ["food.apple", "Apple"],
                ["food.banana", "Banana"]
            ],
            fileName: "foods.csv"
        )

        let rowReader = try reader.rowReader(at: TypedCSVRowIndex.first)

        #expect(rowReader.row.rowIndex == 1)
        #expect(try rowReader.cell(for: "food_id").value == "food.apple")
        #expect(try rowReader.cell(for: "name").value == "Apple")
    }

    @Test("rowReaders returns protocol row reader sequence")
    func rowReadersReturnsProtocolRowReaderSequence() throws {
        let reader: CSVReaderProtocol = CSVReader(
            header: ["food_id", "name"],
            dataRows: [
                ["food.apple", "Apple"],
                ["food.banana", "Banana"]
            ],
            fileName: "foods.csv"
        )

        let rowReaders = try reader.rowReaders()

        #expect(rowReaders.startIndex == 0)
        #expect(rowReaders.endIndex == 2)
        #expect(rowReaders.index(after: 0) == 1)
        #expect(try rowReaders[0].cell(for: "name").value == "Apple")
        #expect(try rowReaders[1].cell(for: "name").value == "Banana")
    }

    @Test("rowReaders supports for in iteration from protocol")
    func rowReadersSupportsForInIterationFromProtocol() throws {
        let reader: CSVReaderProtocol = CSVReader(
            header: ["food_id", "name"],
            dataRows: [
                ["food.apple", "Apple"],
                ["food.banana", "Banana"]
            ],
            fileName: "foods.csv"
        )

        var names: [String] = []
        for rowReader in try reader.rowReaders() {
            names.append(try rowReader.cell(for: "name").value)
        }

        #expect(names == ["Apple", "Banana"])
    }

    @Test("rowReaders returns empty sequence for empty reader")
    func rowReadersReturnsEmptySequenceForEmptyReader() throws {
        let reader: CSVReaderProtocol = CSVReader(
            header: ["food_id", "name"],
            dataRows: [],
            fileName: "foods.csv"
        )

        let rowReaders = try reader.rowReaders()

        #expect(rowReaders.isEmpty)
    }

    @Test("mapRows maps protocol row readers into values")
    func mapRowsMapsProtocolRowReadersIntoValues() throws {
        let reader: CSVReaderProtocol = CSVReader(
            header: ["food_id", "name"],
            dataRows: [
                ["food.apple", "Apple"],
                ["food.banana", "Banana"]
            ],
            fileName: "foods.csv"
        )

        let names = try reader.mapRows { rowReader in
            try rowReader.cell(for: "name").value
        }

        #expect(names == ["Apple", "Banana"])
    }

    @Test("mapRows rethrows transform error")
    func mapRowsRethrowsTransformError() {
        let reader: CSVReaderProtocol = CSVReader(
            header: ["food_id", "name"],
            dataRows: [["food.apple", "Apple"]],
            fileName: "foods.csv"
        )

        #expect(throws: CSVReaderProtocolTestError.self) {
            _ = try reader.mapRows { _ in
                throw CSVReaderProtocolTestError.expected
            }
        }
    }

    @Test("compactMapRows filters nil values")
    func compactMapRowsFiltersNilValues() throws {
        let reader: CSVReaderProtocol = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [
                ["food.apple", "Apple", "95"],
                ["food.banana", "Banana", "105"],
                ["food.cherry", "Cherry", "77"]
            ],
            fileName: "foods.csv"
        )

        let names: [String] = try reader.compactMapRows { rowReader in
            let calories = Int(try rowReader.cell(for: "calories").value) ?? 0
            guard calories >= 100 else {
                return nil
            }
            return try rowReader.cell(for: "name").value
        }

        #expect(names == ["Banana"])
    }

    @Test("compactMapRows rethrows transform error")
    func compactMapRowsRethrowsTransformError() {
        let reader: CSVReaderProtocol = CSVReader(
            header: ["food_id", "name"],
            dataRows: [["food.apple", "Apple"]],
            fileName: "foods.csv"
        )

        #expect(throws: CSVReaderProtocolTestError.self) {
            _ = try reader.compactMapRows { _ in
                throw CSVReaderProtocolTestError.expected
            }
        }
    }

    @Test("reduceRows accumulates protocol row readers")
    func reduceRowsAccumulatesProtocolRowReaders() throws {
        let reader: CSVReaderProtocol = CSVReader(
            header: ["food_id", "name", "calories"],
            dataRows: [
                ["food.apple", "Apple", "95"],
                ["food.banana", "Banana", "105"]
            ],
            fileName: "foods.csv"
        )

        let totalCalories = try reader.reduceRows(into: 0) { total, rowReader in
            total += Int(try rowReader.cell(for: "calories").value) ?? 0
        }

        #expect(totalCalories == 200)
    }

    @Test("reduceRows rethrows transform error")
    func reduceRowsRethrowsTransformError() {
        let reader: CSVReaderProtocol = CSVReader(
            header: ["food_id", "name"],
            dataRows: [["food.apple", "Apple"]],
            fileName: "foods.csv"
        )

        #expect(throws: CSVReaderProtocolTestError.self) {
            _ = try reader.reduceRows(into: 0) { _, _ in
                throw CSVReaderProtocolTestError.expected
            }
        }
    }
}

private enum CSVReaderProtocolTestError: Error {
    case expected
}
