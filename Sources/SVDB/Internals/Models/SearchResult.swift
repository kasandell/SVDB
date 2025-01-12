//
//  File.swift
//
//
//  Created by Jordan Howlett on 8/4/23.
//

import Foundation

public struct SearchResult: Hashable {
    public let id: UUID
    public let text: String
    public let metadata: [String: String]
    public let createdAt: Date
    public let score: Double
    public let personPublicId: UUID
}
