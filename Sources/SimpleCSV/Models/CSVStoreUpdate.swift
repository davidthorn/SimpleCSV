//
//  CSVStoreUpdate.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

/// Broadcast payload emitted when a cell update is applied and persisted.
public struct CSVStoreUpdate: Sendable {
    /// Identifier of the updated document.
    public let documentID: CSVDocumentID
    /// The updated cell payload.
    public let cell: CSVCell
    /// Snapshot after the update was applied.
    public let snapshot: CSVReaderProtocol

    /// Creates a store update payload.
    /// - Parameters:
    ///   - documentID: Identifier of the updated document.
    ///   - cell: Updated cell payload.
    ///   - snapshot: Snapshot after update.
    public init(documentID: CSVDocumentID, cell: CSVCell, snapshot: CSVReaderProtocol) {
        self.documentID = documentID
        self.cell = cell
        self.snapshot = snapshot
    }
}
