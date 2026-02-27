//
//  CSVInMemoryDocument.swift
//  SimpleCSV
//
//  Created by David Thorn on 27.02.2026.
//

import Foundation

internal struct CSVInMemoryDocument: Sendable {
    internal var rows: [[String]]
    internal var fileName: String
    internal var sourceURL: URL?

    internal init(rows: [[String]], fileName: String, sourceURL: URL?) {
        self.rows = rows
        self.fileName = fileName
        self.sourceURL = sourceURL
    }
}
