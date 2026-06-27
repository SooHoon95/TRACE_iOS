import Foundation

public struct Trace: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let creatorID: UUID
    public let photoRef: String
    public let note: String
    public let vibe: VibeTag
    public let coordinate: Coordinate
    public let createdAt: Date
    public private(set) var collectCount: Int

    public init(id: UUID, creatorID: UUID, photoRef: String, note: String,
                vibe: VibeTag, coordinate: Coordinate, createdAt: Date,
                collectCount: Int) {
        self.id = id; self.creatorID = creatorID; self.photoRef = photoRef
        self.note = note; self.vibe = vibe; self.coordinate = coordinate
        self.createdAt = createdAt; self.collectCount = collectCount
    }

    public mutating func incrementCollect() { collectCount += 1 }
}
