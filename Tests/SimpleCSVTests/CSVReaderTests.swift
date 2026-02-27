//
//  CSVReaderTests.swift
//  SimpleCSVTests
//
//  Created by David Thorn on 27.02.2026.
//

import Testing
@testable import SimpleCSV

@Suite("CSVReaderTests")
struct CSVReaderTests {
    @Test("reads row cells by column")
    func readsRowCellsByColumn() throws {
        let documentID = CSVDocumentID()
        let reader = CSVReader(
            header: ["food_id", "name"],
            dataRows: [["food.apple", "Apple"]],
            fileName: "foods.csv",
            documentID: documentID
        )

        #expect(reader.isEmpty == false)
        #expect(reader.rowCount == 1)
        #expect(reader.columnCount == 2)

        let rowReader = try reader.rowReader(at: 0)
        let foodID = try rowReader.cell(for: "food_id")
        let name = try rowReader.cell(at: 1)

        #expect(foodID.value == "food.apple")
        #expect(foodID.documentID == documentID)
        #expect(foodID.rowIndex == 1)
        #expect(foodID.columnIndex == 0)
        #expect(name.value == "Apple")
    }
}
