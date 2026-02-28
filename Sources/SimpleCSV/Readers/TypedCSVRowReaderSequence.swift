//
//  TypedCSVRowReaderSequence.swift
//  SimpleCSV
//
//  Created by David Thorn on 28.02.2026.
//

import Foundation

/// Collection of typed row readers in data-row order.
public struct TypedCSVRowReaderSequence<Column>: Collection, Sendable
where Column: CSVColumnProtocol {
    /// Underlying typed row readers in iteration order.
    public let rowReaders: [TypedCSVRowReader<Column>]

    /// Creates a typed row-reader collection from an array of row readers.
    /// - Parameter rowReaders: Typed row readers in data-row order.
    public init(rowReaders: [TypedCSVRowReader<Column>]) {
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

    /// Returns the typed row reader at the given collection position.
    /// - Parameter index: Collection index.
    public subscript(index: Int) -> TypedCSVRowReader<Column> {
        rowReaders[index]
    }
}
