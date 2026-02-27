# SimpleCSV

`SimpleCSV` is a lightweight Swift package for reading, validating, editing, and writing CSV-style tabular data.

It supports:
- Parsing and encoding CSV/TSV/SSV/PSV
- Header and row-width validation
- In-memory document editing with cell-level updates
- Async streaming of persisted cell updates
- Actor-based store concurrency

## Requirements

- Swift 6.2+
- Apple platforms defined in `Package.swift`:
  - iOS 17+
  - macOS 11+
  - watchOS 6+
  - tvOS 12+

## Installation

Add `SimpleCSV` as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/davidthorn/SimpleCSV.git", branch: "main")
]
```

And add the product to your target:

```swift
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "SimpleCSV", package: "SimpleCSV")
        ]
    )
]
```

## API Overview

Main types:
- `CSVCodec`: parse/encode raw separated text
- `CSVStore`: actor for disk + in-memory document workflows
- `CSVReaderProtocol`: read-only snapshot API
- `CSVRow`: pure row data model
- `CSVRowReaderProtocol`: row lookup behavior (`cell(at:)`, `cell(for:)`)
- `CSVCell`: mutable cell value with immutable identity metadata
- `CSVReaderConfiguration`: validation behavior
- `CSVStoreUpdate`: stream event payload

Core errors:
- `CSVCodecError`
- `CSVReaderValidationError`
- `CSVRowReaderError`
- `CSVStoreError`

## 1. Basic Parsing and Encoding

Use `CSVCodec` directly when you only need text <-> matrix conversion.

```swift
import SimpleCSV

let codec = CSVCodec(format: .csv)

let content = """
food_id,name
food.apple,Apple
food.banana,Banana
"""

let rows = try codec.decodeRows(from: content)
// rows == [["food_id", "name"], ["food.apple", "Apple"], ["food.banana", "Banana"]]

let encoded = codec.encodeRows(rows)
// encoded is CSV text with escaped values where needed
```

### Supported Formats

Built-in:
- `.csv` (`,` delimiter)
- `.tsv` (`\t`)
- `.ssv` (`;`)
- `.psv` (`|`)

Custom:

```swift
let custom = CSVFormat(
    delimiter: "|",
    quote: "\"",
    allowsWhitespaceAfterClosingQuote: true
)
let codec = CSVCodec(format: custom)
```

## 2. Read a File from Disk

Use `CSVStore.read(from:)` for validated snapshot reading.

```swift
import Foundation
import SimpleCSV

let store = CSVStore(
    csvCodec: CSVCodec(),
    readerConfiguration: .default
)

let fileURL = URL(fileURLWithPath: "/path/to/foods.csv")
let reader = try await store.read(from: fileURL)
```

## 3. Access Rows and Cells

`CSVReaderProtocol` gives both:
- `row(at:) -> CSVRow` (pure data)
- `rowReader(at:) -> CSVRowReaderProtocol` (lookup logic)

```swift
let rowReader = try reader.rowReader(at: 0) // first data row
let foodIDCell = try rowReader.cell(for: "food_id")
let nameCell = try rowReader.cell(at: 1)

print(foodIDCell.value) // food.apple
print(nameCell.value)   // Apple
```

### Row Index Semantics

- `row(at: 0)` = first data row (header excluded)
- `CSVCell.rowIndex` = underlying document row index
  - if header exists, first data row cell has `rowIndex == 1`

## 4. Validation Configuration

Configure `CSVReaderConfiguration` to control header and row-width behavior.

```swift
let config = CSVReaderConfiguration(
    headerStrategy: .required,               // .required | .optional | .none
    rowWidthValidationStrategy: .strict,     // .strict | .none
    validatesUniqueHeaderNames: true
)

let store = CSVStore(
    csvCodec: CSVCodec(format: .csv),
    readerConfiguration: config
)
```

Validation failures throw `CSVReaderValidationError`, such as:
- `.missingHeader`
- `.duplicateHeaderName`
- `.inconsistentRowWidth`

## 5. In-Memory Document Workflow

Load a document into store-managed memory:

```swift
let documentID = try await store.loadDocument(from: fileURL)
let snapshot = try await store.snapshot(for: documentID)
```

Or create a document from programmatic rows:

```swift
let documentID = try await store.createDocument(
    header: ["food_id", "name"],
    dataRows: [["food.apple", "Apple"]],
    fileName: "foods.csv",
    sourceURL: fileURL
)
```

## 6. Edit a Cell and Persist (Excel-like Flow)

Edit cell value from a snapshot, then submit back to store.

```swift
let snapshot = try await store.snapshot(for: documentID)
let rowReader = try snapshot.rowReader(at: 0)

var nameCell = try rowReader.cell(for: "name")
nameCell.value = "Green Apple"

_ = try await store.updateCell(nameCell)
```

`updateCell(_:)` currently does all of these:
1. updates in-memory document
2. persists full document to disk
3. broadcasts a `CSVStoreUpdate` event on the document stream

Important:
- `updateCell(_:)` requires the document to have a destination URL (`sourceURL`).
- If missing, it throws `CSVStoreError.missingDestinationURL`.

## 7. Listen for Real-Time Updates

Subscribe to updates per document:

```swift
let updates = await store.stream(for: documentID)

let task = Task {
    for await update in updates {
        print("Updated document:", update.documentID.rawValue)
        print("Cell row:", update.cell.rowIndex, "col:", update.cell.columnIndex)
        print("New value:", update.cell.value)
    }
}

// ...later
task.cancel()
```

Each stream event includes:
- `documentID`
- changed `cell`
- `snapshot` (`CSVReaderProtocol`) after the update

Discarding a document finishes its stream:

```swift
await store.discardDocument(documentID)
```

## 8. Explicit Persist Operations

Persist current in-memory document state:

```swift
try await store.persistDocument(documentID, to: nil) // existing sourceURL
```

Persist to a new destination:

```swift
let newURL = URL(fileURLWithPath: "/path/to/foods-copy.csv")
try await store.persistDocument(documentID, to: newURL)
```

## 9. Write Any Reader Snapshot to Disk

Use `write(_:to:)` to serialize any `CSVReaderProtocol` snapshot:

```swift
let reader = try await store.snapshot(for: documentID)
let outputURL = URL(fileURLWithPath: "/path/to/export.csv")
try await store.write(reader, to: outputURL)
```

## 10. Error Handling Patterns

### Store Errors

```swift
do {
    _ = try await store.updateCell(nameCell)
} catch let error as CSVStoreError {
    switch error {
    case .documentNotFound(let documentID):
        print("Document not found:", documentID.rawValue)
    case .rowIndexOutOfBounds(let index, let rowCount):
        print("Row index \(index) out of bounds; rowCount=\(rowCount)")
    case .columnIndexOutOfBounds(let index, let columnCount):
        print("Column index \(index) out of bounds; columnCount=\(columnCount)")
    case .missingDestinationURL(let documentID):
        print("Document has no destination URL:", documentID.rawValue)
    }
}
```

### Row Reader Errors

```swift
do {
    let _ = try rowReader.cell(for: "missing_column")
} catch let error as CSVRowReaderError {
    print(error.localizedDescription)
}
```

### Codec Errors

```swift
do {
    _ = try CSVCodec().decodeRows(from: "a,b\n\"broken")
} catch let error as CSVCodecError {
    print(error.localizedDescription)
}
```

## 11. End-to-End Example

```swift
import Foundation
import SimpleCSV

func runExample() async throws {
    let config = CSVReaderConfiguration(
        headerStrategy: .required,
        rowWidthValidationStrategy: .strict,
        validatesUniqueHeaderNames: true
    )

    let store = CSVStore(
        csvCodec: CSVCodec(format: .csv),
        readerConfiguration: config
    )

    let fileURL = URL(fileURLWithPath: "/path/to/foods.csv")
    let documentID = try await store.loadDocument(from: fileURL)

    let updates = await store.stream(for: documentID)
    let streamTask = Task {
        for await update in updates {
            print("Updated:", update.cell.columnName ?? "unknown", "=", update.cell.value)
        }
    }

    let snapshot = try await store.snapshot(for: documentID)
    let rowReader = try snapshot.rowReader(at: 0)
    var cell = try rowReader.cell(for: "name")
    cell.value = "Updated Name"
    _ = try await store.updateCell(cell)

    try await store.persistDocument(documentID, to: nil)
    await store.discardDocument(documentID)
    streamTask.cancel()
}
```

## Concurrency Notes

- `CSVStore` is an `actor`, so internal state mutations are serialized.
- This removes memory data races for store-managed dictionaries/documents.
- Semantic conflict resolution (stale snapshot write policies) is currently last-write-wins.

## Testing

Run:

```bash
swift test
```

Current suite coverage includes:
- codec parsing/encoding and malformed CSV
- reader behavior and validation rules
- store disk round-trip
- in-memory editing, persistence, and stream broadcasting
