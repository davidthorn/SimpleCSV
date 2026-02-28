//
//  CSVRowReaderSequence.swift
//  SimpleCSV
//
//  Created by David Thorn on 28.02.2026.
//

import Foundation

/// Collection of row readers in data-row order.
public struct CSVRowReaderSequence: Collection, Sendable {
    /// Underlying row readers in iteration order.
    public let rowReaders: [CSVRowReaderProtocol]

    /// Creates a row-reader collection from an array of row readers.
    /// - Parameter rowReaders: Row readers in data-row order.
    public init(rowReaders: [CSVRowReaderProtocol]) {
        self.rowReaders = rowReaders
    }

    /// The position of the first element.
    public var startIndex: Int {
        rowReaders.startIndex
    }

    /// The position one past the last element.
    public var endIndex: Int {
        rowReaders.endIndex
    }

    /// Returns the index after the provided position.
    /// - Parameter index: Current collection index.
    public func index(after index: Int) -> Int {
        rowReaders.index(after: index)
    }

    /// Returns the row reader at the given collection position.
    /// - Parameter index: Collection index.
    public subscript(index: Int) -> CSVRowReaderProtocol {
        rowReaders[index]
    }
}
