//
//  CSVStoreCoverageSuiteTests.swift
//  SimpleCSVTests
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation
import Testing
@testable import SimpleCSV

@Suite("CSVStore Coverage Suite")
struct CSVStoreCoverageSuiteTests {
    @Test("snapshot throws document not found")
    func snapshotThrowsDocumentNotFound() async {
        let store = CSVStore(csvCodec: CSVCodec())
        let missingID = CSVDocumentID()

        do {
            _ = try await store.snapshot(for: missingID)
            #expect(Bool(false))
        } catch let error as CSVStoreError {
            #expect(error == .documentNotFound(documentID: missingID))
        } catch {
            #expect(Bool(false))
        }
    }

    @Test("update throws document not found")
    func updateThrowsDocumentNotFound() async {
        let store = CSVStore(csvCodec: CSVCodec())
        let missingID = CSVDocumentID()
        let cell = CSVCell(
            documentID: missingID,
            rowIndex: 0,
            columnIndex: 0,
            columnName: "name",
            value: "Updated"
        )

        do {
            _ = try await store.updateCell(cell)
            #expect(Bool(false))
        } catch let error as CSVStoreError {
            #expect(error == .documentNotFound(documentID: missingID))
        } catch {
            #expect(Bool(false))
        }
    }

    @Test("persist throws document not found")
    func persistThrowsDocumentNotFound() async {
        let store = CSVStore(csvCodec: CSVCodec())
        let missingID = CSVDocumentID()

        do {
            try await store.persistDocument(missingID, to: nil)
            #expect(Bool(false))
        } catch let error as CSVStoreError {
            #expect(error == .documentNotFound(documentID: missingID))
        } catch {
            #expect(Bool(false))
        }
    }

    @Test("persist throws missing destination when document has no source")
    func persistThrowsMissingDestinationWhenDocumentHasNoSource() async throws {
        let store = CSVStore(csvCodec: CSVCodec())
        let documentID = try await store.createDocument(
            header: ["food_id", "name"],
            dataRows: [["food.apple", "Apple"]],
            fileName: "foods.csv",
            sourceURL: nil
        )

        do {
            try await store.persistDocument(documentID, to: nil)
            #expect(Bool(false))
        } catch let error as CSVStoreError {
            #expect(error == .missingDestinationURL(documentID: documentID))
        } catch {
            #expect(Bool(false))
        }
    }

    @Test("persist to explicit destination updates source for later update")
    func persistToExplicitDestinationUpdatesSourceForLaterUpdate() async throws {
        let store = CSVStore(csvCodec: CSVCodec())
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let persistedURL = directoryURL.appendingPathComponent("foods-persisted.csv")

        let documentID = try await store.createDocument(
            header: ["food_id", "name"],
            dataRows: [["food.apple", "Apple"]],
            fileName: "foods.csv",
            sourceURL: nil
        )

        try await store.persistDocument(documentID, to: persistedURL)

        let snapshot = try await store.snapshot(for: documentID)
        var nameCell = try snapshot.rowReader(at: 0).cell(for: "name")
        nameCell.value = "Pink Lady"
        _ = try await store.updateCell(nameCell)

        let reloaded = try await store.read(from: persistedURL)
        #expect(try reloaded.rowReader(at: 0).cell(for: "name").value == "Pink Lady")
    }

    @Test("createDocument header branch omits header when strategy none")
    func createDocumentHeaderBranchOmitsHeaderWhenStrategyNone() async throws {
        let store = CSVStore(
            csvCodec: CSVCodec(),
            readerConfiguration: CSVReaderConfiguration(
                headerStrategy: .none,
                rowWidthValidationStrategy: .strict
            )
        )

        let documentID = try await store.createDocument(
            header: [],
            dataRows: [["food.apple", "Apple"]],
            fileName: "foods.csv",
            sourceURL: nil
        )

        let snapshot = try await store.snapshot(for: documentID)
        #expect(snapshot.columnCount == 0)
        #expect(snapshot.rowCount == 1)
        let firstRow = try snapshot.row(at: 0)
        #expect(firstRow.rowIndex == 0)
        #expect(firstRow.cells[0].value == "food.apple")
    }

    @Test("createDocument header branch appends empty header when strategy required")
    func createDocumentHeaderBranchAppendsEmptyHeaderWhenStrategyRequired() async throws {
        let store = CSVStore(
            csvCodec: CSVCodec(),
            readerConfiguration: CSVReaderConfiguration(
                headerStrategy: .required,
                rowWidthValidationStrategy: .strict
            )
        )

        let documentID = try await store.createDocument(
            header: [],
            dataRows: [["food.apple", "Apple"]],
            fileName: "foods.csv",
            sourceURL: nil
        )
        let snapshot = try await store.snapshot(for: documentID)

        // This verifies the empty header row was consumed as header under .required.
        #expect(snapshot.columnCount == 0)
        #expect(snapshot.rowCount == 1)
        #expect(try snapshot.row(at: 0).cells[0].value == "food.apple")
        #expect(try snapshot.row(at: 0).cells[1].value == "Apple")
    }

    @Test("discarding missing document is a no-op")
    func discardingMissingDocumentIsNoOp() async {
        let store = CSVStore(csvCodec: CSVCodec())
        await store.discardDocument(CSVDocumentID())
        #expect(Bool(true))
    }

    @Test("cancelling one stream keeps other subscriber active")
    func cancellingOneStreamKeepsOtherSubscriberActive() async throws {
        let store = CSVStore(csvCodec: CSVCodec())
        let directoryURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let fileURL = directoryURL.appendingPathComponent("foods.csv")
        try "food_id,name\nfood.apple,Apple\n".write(to: fileURL, atomically: true, encoding: .utf8)

        let documentID = try await store.loadDocument(from: fileURL)
        let streamA = await store.stream(for: documentID)
        let streamB = await store.stream(for: documentID)

        let listenerA = Task<CSVStoreUpdate?, Never> {
            for await update in streamA {
                return update
            }
            return nil
        }
        let listenerB = Task<CSVStoreUpdate?, Never> {
            for await update in streamB {
                return update
            }
            return nil
        }

        listenerA.cancel()
        await Task.yield()

        let snapshot = try await store.snapshot(for: documentID)
        var cell = try snapshot.rowReader(at: 0).cell(for: "name")
        cell.value = "Honeycrisp"
        _ = try await store.updateCell(cell)

        let updateB = await listenerB.value
        #expect(updateB?.cell.value == "Honeycrisp")

        listenerB.cancel()
        await store.discardDocument(documentID)
    }

    @Test("cancelling final stream removes continuation entry")
    func cancellingFinalStreamRemovesContinuationEntry() async throws {
        let store = CSVStore(csvCodec: CSVCodec())
        let documentID = try await store.createDocument(
            header: ["food_id", "name"],
            dataRows: [["food.apple", "Apple"]],
            fileName: "foods.csv",
            sourceURL: nil
        )

        let stream = await store.stream(for: documentID)
        let listener = Task<Void, Never> {
            for await _ in stream {}
        }

        #expect(await store.hasStreamEntry(for: documentID))

        listener.cancel()

        // Allow stream termination and actor callback to complete.
        for _ in 0..<5 {
            await Task.yield()
        }

        #expect(await store.hasStreamEntry(for: documentID) == false)
        await store.discardDocument(documentID)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }
}
