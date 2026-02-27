//
//  CSVStoreTests.swift
//  SimpleCSVTests
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation
import Testing
@testable import SimpleCSV

@Suite("CSVStoreTests")
struct CSVStoreTests {
    @Test("writes and reads csv through store")
    func writesAndReadsCSVThroughStore() async throws {
        let store = CSVStore(csvCodec: CSVCodec())

        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let fileURL = directoryURL.appendingPathComponent("foods.csv")
        let sourceReader = CSVReader(
            header: ["food_id", "name"],
            dataRows: [["food.apple", "Apple"]],
            fileName: "foods.csv"
        )

        try await store.write(sourceReader, to: fileURL)
        let loadedReader = try await store.read(from: fileURL)

        #expect(loadedReader.rowCount == 1)
        let rowReader = try loadedReader.rowReader(at: 0)
        #expect(try rowReader.cell(for: "food_id").value == "food.apple")
        #expect(try rowReader.cell(for: "name").value == "Apple")
    }

    @Test("read uses reader configuration validation")
    func readUsesReaderConfigurationValidation() async throws {
        let store = CSVStore(
            csvCodec: CSVCodec(),
            readerConfiguration: CSVReaderConfiguration(
                headerStrategy: .required,
                rowWidthValidationStrategy: .strict
            )
        )

        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let fileURL = directoryURL.appendingPathComponent("foods.csv")
        try "food_id,name\nfood.apple\n".write(to: fileURL, atomically: true, encoding: .utf8)

        await #expect(throws: CSVReaderValidationError.self) {
            _ = try await store.read(from: fileURL)
        }
    }
}
