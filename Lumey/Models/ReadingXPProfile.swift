//
//  ReadingXPProfile.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ReadingXPProfile {
    var id: UUID = UUID()
    var totalXP: Int = 0
    var selectedTitle: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        totalXP: Int = 0,
        selectedTitle: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = UUID()
        self.totalXP = totalXP
        self.selectedTitle = selectedTitle
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
