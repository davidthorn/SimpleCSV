//
//  TypedCSVAccessFixtures.swift
//  SimpleCSVTests
//
//  Created by David Thorn on 28.02.2026.
//

import Foundation
@testable import SimpleCSV

enum TypedCSVRowIndex: Int {
    case first = 0
    case second = 1
}

enum TypedCSVColumnIndex: Int {
    case foodID = 0
    case name = 1
    case calories = 2
}

enum TypedCSVColumnName: String {
    case foodID = "food_id"
    case name = "name"
    case calories = "calories"
}

enum TypedCSVColumn: Int, CSVColumnProtocol {
    case foodID = 0
    case name = 1
    case calories = 2

    var csvColumnName: String {
        switch self {
        case .foodID:
            "food_id"
        case .name:
            "name"
        case .calories:
            "calories"
        }
    }

    var csvColumnIndex: Int {
        rawValue
    }
}
