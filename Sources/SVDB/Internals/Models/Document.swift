//
//  File.swift
//
//
//  Created by Jordan Howlett on 8/4/23.
//

import Foundation

public struct Document: Codable, Identifiable {
    public let id: UUID
    public let text: String
    public let metadata: [String: String]
    public let embedding: [Double]
    public let magnitude: Double
    public let createdAt: Date
    public let personPublicId: UUID

    public init(id: UUID? = nil, personPublicId: UUID, text: String, embedding: [Double], metadata: [String:String]) {
        self.id = id ?? UUID()
        self.text = text
        self.createdAt = Date()
        self.embedding = embedding
        self.metadata = metadata
        self.magnitude = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
        self.personPublicId = personPublicId
    }
}
