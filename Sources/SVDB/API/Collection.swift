//
//  File.swift
//
//
//  Created by Jordan Howlett on 8/4/23.
//

import Accelerate
import CoreML
import NaturalLanguage

@available(macOS 10.15, *)
@available(iOS 13.0, *)
public class Collection {
    private var documents: [UUID: Document] = [:]
    private let name: String

    init(name: String) {
        self.name = name
    }

    public func addDocument(id: UUID? = nil, personPublicId: UUID, text: String, embedding: [Double], metadata: [String: String]) {
        let document = Document(
            id: id ?? UUID(),
            personPublicId: personPublicId,
            text: text,
            embedding: embedding,
            metadata: metadata
        )

        documents[document.id] = document
        save()
    }

    public func addDocuments(_ docs: [Document]) {
        docs.forEach { documents[$0.id] = $0 }
        save()
    }

    public func removeDocument(byId id: UUID) {
        documents[id] = nil
        save()
    }
    
    public func removeDocuments(byPersonId id: UUID) {
        let remove = documents.values.filter{$0.personPublicId == id}
        for document in remove {
            documents[document.id] = nil
        }
        save()
    }
    
    public func getDocuments(byIds ids: [UUID]) -> [Document] {
        var docs: [Document] = []
        for id in ids {
            guard let document = documents[id] else { continue }
            docs.append(document)
        }
        return docs
    }
    
    public func getDocuments(byPersonPublicId id: UUID) -> [Document] {
        return documents.values.filter{$0.personPublicId == id}
    }

    public func search(
        query: [Double],
        num_results: Int = 10,
        threshold: Double? = nil
    ) -> [SearchResult] {
        let queryMagnitude = sqrt(query.reduce(0) { $0 + $1 * $1 })

        var similarities: [SearchResult] = []
        for document in documents.values {
            let id = document.id
            let text = document.text
            let vector = document.embedding
            let magnitude = sqrt(vector.reduce(0) { $0 + $1 * $1 })
            let similarity = MathFunctions.cosineSimilarity(query, vector, magnitudeA: queryMagnitude, magnitudeB: magnitude)

            if let thresholdValue = threshold, similarity < thresholdValue {
                continue
            }

            similarities.append(
                SearchResult(
                    id: id, text: text, metadata: document.metadata,
                    createdAt: document.createdAt, score: similarity,
                    personPublicId: document.personPublicId
                )
            )
        }

        return Array(similarities.sorted(by: { $0.score > $1.score }).prefix(num_results))
    }

    private func save() {
        let svdbDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("SVDB")
        try? FileManager.default.createDirectory(at: svdbDirectory, withIntermediateDirectories: true, attributes: nil)

        let fileURL = svdbDirectory.appendingPathComponent("\(name).json")

        do {
            let encodedDocuments = try JSONEncoder().encode(documents)
            let compressedData = try (encodedDocuments as NSData).compressed(using: .zlib)
            try compressedData.write(to: fileURL)
        } catch {
            print("Failed to save documents: \(error.localizedDescription)")
        }
    }

    public func load() throws {
        let svdbDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("SVDB")
        let fileURL = svdbDirectory.appendingPathComponent("\(name).json")

        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("File does not exist for collection \(name), initializing with empty documents.")
            documents = [:]
            return
        }

        do {
            let compressedData = try Data(contentsOf: fileURL)

            let decompressedData = try (compressedData as NSData).decompressed(using: .zlib)
            documents = try JSONDecoder().decode([UUID: Document].self, from: decompressedData as Data)

            print("Successfully loaded collection: \(name)")
        } catch {
            print("Failed to load collection \(name): \(error.localizedDescription)")
            throw CollectionError.loadFailed(error.localizedDescription)
        }
    }

    public func clear() {
        documents.removeAll()
        save()
    }
}
