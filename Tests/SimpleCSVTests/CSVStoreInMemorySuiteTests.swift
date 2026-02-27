//
//  CSVStoreInMemorySuiteTests.swift
//  SimpleCSVTests
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation
import Testing
@testable import SimpleCSV

@Suite("CSVStore In Memory Suite")
struct CSVStoreInMemorySuiteTests {
    @Test("updates a returned cell and persists update")
    func updatesReturnedCellAndPersists() async throws {
        let store = CSVStore(csvCodec: CSVCodec())
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let fileURL = directoryURL.appendingPathComponent("foods.csv")
        try "food_id,name\nfood.apple,Apple\n".write(to: fileURL, atomically: true, encoding: .utf8)

        let documentID = try await store.loadDocument(from: fileURL)
        let snapshot = try await store.snapshot(for: documentID)
        let rowReader = try snapshot.rowReader(at: 0)
        var cell = try rowReader.cell(for: "name")
        cell.value = "Green Apple"

        let updatedSnapshot = try await store.updateCell(cell)
        let updatedRowReader = try updatedSnapshot.rowReader(at: 0)
        #expect(try updatedRowReader.cell(for: "name").value == "Green Apple")
    }

    @Test("persists in-memory updates back to disk")
    func persistsInMemoryUpdatesToDisk() async throws {
        let store = CSVStore(csvCodec: CSVCodec())

        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let fileURL = directoryURL.appendingPathComponent("foods.csv")
        try "food_id,name\nfood.apple,Apple\n".write(to: fileURL, atomically: true, encoding: .utf8)

        let documentID = try await store.loadDocument(from: fileURL)
        let snapshot = try await store.snapshot(for: documentID)
        var nameCell = try snapshot.rowReader(at: 0).cell(for: "name")
        nameCell.value = "Pink Lady"
        _ = try await store.updateCell(nameCell)

        let updatedReader = try await store.read(from: fileURL)
        let updatedRowReader = try updatedReader.rowReader(at: 0)
        #expect(try updatedRowReader.cell(for: "name").value == "Pink Lady")
    }

    @Test("update throws when document has no source destination")
    func updateThrowsWithoutSourceDestination() async throws {
        let store = CSVStore(csvCodec: CSVCodec())
        let documentID = try await store.createDocument(
            header: ["food_id", "name"],
            dataRows: [["food.apple", "Apple"]],
            fileName: "foods.csv",
            sourceURL: nil
        )
        let snapshot = try await store.snapshot(for: documentID)
        var cell = try snapshot.rowReader(at: 0).cell(for: "name")
        cell.value = "Updated"

        await #expect(throws: CSVStoreError.self) {
            _ = try await store.updateCell(cell)
        }
    }

    @Test("update throws for invalid row and column indices")
    func updateThrowsForInvalidIndices() async throws {
        let store = CSVStore(csvCodec: CSVCodec())
        let documentID = try await store.createDocument(
            header: ["food_id", "name"],
            dataRows: [["food.apple", "Apple"]],
            fileName: "foods.csv",
            sourceURL: nil
        )

        var invalidRowCell = CSVCell(
            documentID: documentID,
            rowIndex: 9,
            columnIndex: 1,
            columnName: "name",
            value: "Invalid"
        )

        await #expect(throws: CSVStoreError.self) {
            _ = try await store.updateCell(invalidRowCell)
        }

        invalidRowCell = CSVCell(
            documentID: documentID,
            rowIndex: 1,
            columnIndex: 9,
            columnName: "name",
            value: "Invalid"
        )

        await #expect(throws: CSVStoreError.self) {
            _ = try await store.updateCell(invalidRowCell)
        }
    }

    @Test("store broadcasts updated cell to stream subscribers")
    func storeBroadcastsUpdatedCellToSubscribers() async throws {
        let store = CSVStore(csvCodec: CSVCodec())

        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let fileURL = directoryURL.appendingPathComponent("foods.csv")
        try "food_id,name\nfood.apple,Apple\n".write(to: fileURL, atomically: true, encoding: .utf8)

        let documentID = try await store.loadDocument(from: fileURL)
        let stream = await store.stream(for: documentID)

        let listener = Task<CSVStoreUpdate?, Never> {
            for await update in stream {
                return update
            }
            return nil
        }

        let snapshot = try await store.snapshot(for: documentID)
        var cell = try snapshot.rowReader(at: 0).cell(for: "name")
        cell.value = "Honeycrisp"
        _ = try await store.updateCell(cell)

        let update = await listener.value
        #expect(update?.cell.value == "Honeycrisp")
        #expect(update?.documentID == documentID)
        #expect(update?.snapshot.documentID == documentID)
        listener.cancel()
        await store.discardDocument(documentID)
    }

    @Test("stream finishes when document is discarded")
    func streamFinishesWhenDocumentIsDiscarded() async throws {
        let store = CSVStore(csvCodec: CSVCodec())
        let documentID = try await store.createDocument(
            header: ["food_id", "name"],
            dataRows: [["food.apple", "Apple"]],
            fileName: "foods.csv",
            sourceURL: nil
        )

        let stream = await store.stream(for: documentID)
        let listener = Task<Bool, Never> {
            for await _ in stream {
                return false
            }
            return true
        }

        await store.discardDocument(documentID)
        let didFinish = await listener.value
        #expect(didFinish)
    }
}
