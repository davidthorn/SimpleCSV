//
//  CSVRowReaderCoverageSuiteTests.swift
//  SimpleCSVTests
//
//  Created by David Thorn on 27.02.2026.
//

import Testing
@testable import SimpleCSV

@Suite("CSVRowReader Coverage Suite")
struct CSVRowReaderCoverageSuiteTests {
    @Test("initializer keeps row and column count")
    func initializerKeepsRowAndColumnCount() {
        let row = makeRow()
        let rowReader = CSVRowReader(row: row, fileName: "foods.csv")

        #expect(rowReader.row == row)
        #expect(rowReader.columnCount == 2)
    }

    @Test("cell at valid index returns exact cell")
    func cellAtValidIndexReturnsExactCell() throws {
        let row = makeRow()
        let rowReader = CSVRowReader(row: row, fileName: "foods.csv")

        let cell = try rowReader.cell(at: 1)
        #expect(cell == row.cells[1])
        #expect(cell.columnName == "name")
        #expect(cell.value == "Apple")
    }

    @Test("cell at invalid index throws missing value error")
    func cellAtInvalidIndexThrowsMissingValueError() {
        let rowReader = CSVRowReader(row: makeRow(), fileName: "foods.csv")

        do {
            _ = try rowReader.cell(at: 9)
            #expect(Bool(false))
        } catch let error as CSVRowReaderError {
            #expect(error == .missingValue(index: 9, fileName: "foods.csv"))
        } catch {
            #expect(Bool(false))
        }
    }

    @Test("cell for existing column returns matching cell")
    func cellForExistingColumnReturnsMatchingCell() throws {
        let rowReader = CSVRowReader(row: makeRow(), fileName: "foods.csv")

        let cell = try rowReader.cell(for: "food_id")
        #expect(cell.columnIndex == 0)
        #expect(cell.value == "food.apple")
    }

    @Test("typed column index returns matching cell")
    func typedColumnIndexReturnsMatchingCell() throws {
        let rowReader = CSVRowReader(row: makeRow(), fileName: "foods.csv")

        let cell = try rowReader.cell(at: TypedCSVColumnIndex.name)
        #expect(cell.columnIndex == 1)
        #expect(cell.value == "Apple")
    }

    @Test("typed column name returns matching cell")
    func typedColumnNameReturnsMatchingCell() throws {
        let rowReader = CSVRowReader(row: makeRow(), fileName: "foods.csv")

        let cell = try rowReader.cell(for: TypedCSVColumnName.foodID)
        #expect(cell.columnIndex == 0)
        #expect(cell.value == "food.apple")
    }

    @Test("cell for missing column throws missing column error")
    func cellForMissingColumnThrowsMissingColumnError() {
        let rowReader = CSVRowReader(row: makeRow(), fileName: "foods.csv")

        do {
            _ = try rowReader.cell(for: "missing")
            #expect(Bool(false))
        } catch let error as CSVRowReaderError {
            #expect(error == .missingColumn(name: "missing", fileName: "foods.csv"))
        } catch {
            #expect(Bool(false))
        }
    }

    @Test("allCells returns row cells unchanged")
    func allCellsReturnsRowCellsUnchanged() {
        let row = makeRow()
        let rowReader = CSVRowReader(row: row, fileName: "foods.csv")

        let cells = rowReader.allCells()
        #expect(cells == row.cells)
    }

    @Test("cell for duplicated column name returns first matching cell")
    func cellForDuplicatedColumnNameReturnsFirstMatchingCell() throws {
        let documentID = CSVDocumentID()
        let row = CSVRow(
            documentID: documentID,
            rowIndex: 1,
            cells: [
                CSVCell(
                    documentID: documentID,
                    rowIndex: 1,
                    columnIndex: 0,
                    columnName: "name",
                    value: "Apple"
                ),
                CSVCell(
                    documentID: documentID,
                    rowIndex: 1,
                    columnIndex: 1,
                    columnName: "name",
                    value: "Green Apple"
                )
            ]
        )

        let rowReader = CSVRowReader(row: row, fileName: "foods.csv")
        let cell = try rowReader.cell(for: "name")
        #expect(cell.columnIndex == 0)
        #expect(cell.value == "Apple")
    }

    private func makeRow() -> CSVRow {
        let documentID = CSVDocumentID()
        return CSVRow(
            documentID: documentID,
            rowIndex: 1,
            cells: [
                CSVCell(
                    documentID: documentID,
                    rowIndex: 1,
                    columnIndex: 0,
                    columnName: "food_id",
                    value: "food.apple"
                ),
                CSVCell(
                    documentID: documentID,
                    rowIndex: 1,
                    columnIndex: 1,
                    columnName: "name",
                    value: "Apple"
                )
            ]
        )
    }
}
