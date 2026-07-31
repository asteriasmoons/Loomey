//
//  ReadingXPEvent.swift
//  Lumey
//

import Foundation
import SwiftData

@Model
final class ReadingXPEvent {
    var id: UUID = UUID()
    var sourceType: String = ""
    var sourceID: String = ""
    var capKey: String = ""
    var amount: Int = 0
    var reason: String = ""
    var dayKey: String = ""
    var occurredAt: Date = Date()
    var createdAt: Date = Date()
    var metadataJSON: String = "{}"

    init(
        sourceType: String = "",
        sourceID: String = "",
        capKey: String = "",
        amount: Int = 0,
        reason: String = "",
        dayKey: String = "",
        occurredAt: Date = Date(),
        metadataJSON: String = "{}"
    ) {
        self.id = UUID()
        self.sourceType = sourceType
        self.sourceID = sourceID
        self.capKey = capKey
        self.amount = amount
        self.reason = reason
        self.dayKey = dayKey
        self.occurredAt = occurredAt
        self.createdAt = Date()
        self.metadataJSON = metadataJSON
    }
}
