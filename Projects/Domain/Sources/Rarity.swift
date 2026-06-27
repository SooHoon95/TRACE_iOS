import Foundation

public enum RarityTier: String, Equatable, Sendable {
    case common, uncommon, rare, legendary
}

public struct Rarity: Sendable {
    public init() {}

    public func ownershipPercent(owners: Int, population: Int) -> Int {
        guard population > 0 else { return 0 }
        return Int((Double(owners) / Double(population) * 100).rounded())
    }

    public func tier(owners: Int, population: Int) -> RarityTier {
        switch ownershipPercent(owners: owners, population: population) {
        case ..<2: return .legendary
        case ..<10: return .rare
        case ..<33: return .uncommon
        default: return .common
        }
    }
}
