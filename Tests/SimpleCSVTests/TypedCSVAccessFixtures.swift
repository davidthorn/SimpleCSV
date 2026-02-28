//
//  TypedCSVAccessFixtures.swift
//  SimpleCSVTests
//
//  Created by David Thorn on 28.02.2026.
//

import Foundation

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
