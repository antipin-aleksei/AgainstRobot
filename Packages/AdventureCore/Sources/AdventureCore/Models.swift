import Foundation

public struct ID<Entity>: Hashable, Codable {
    public let rawValue: UUID
    public init(_ rawValue: UUID = UUID()) { self.rawValue = rawValue }
    public init(from decoder: Decoder) throws {
        rawValue = try decoder.singleValueContainer().decode(UUID.self)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public enum HeroKind: String, Codable, CaseIterable { case guardian, scout }
public enum AvatarKind: String, Codable, CaseIterable { case fox, moon }
public enum Ability: String, Codable { case might, agility, insight }
public enum SceneKind: String, Codable { case conversation, exploration, battle, ending }
public enum SessionPhase: String, Codable, CaseIterable { case selectingPremise, playing, awaitingRoll, combat, completed }
public enum Outcome: String, Codable { case victory, defeat }

public struct Abilities: Codable, Equatable {
    public let might: Int
    public let agility: Int
    public let insight: Int
    public func bonus(for ability: Ability) -> Int {
        switch ability { case .might: might; case .agility: agility; case .insight: insight }
    }
}
public struct Item: Codable, Equatable, Identifiable {
    public let id: ID<Item>
    public let name: String
}
public struct ItemStack: Codable, Equatable {
    public let itemID: ID<Item>
    public internal(set) var quantity: Int
}
public struct Hero: Codable, Equatable, Identifiable {
    public let id: ID<Hero>
    public let name: String
    public let kind: HeroKind
    public let avatar: AvatarKind
    public let abilities: Abilities
    public let maximumHealth: Int
    public internal(set) var health: Int
    public let defense: Int
    public let attackBonus: Int
    public let damage: Int
    public internal(set) var inventory: [ItemStack]
}
public struct Scene: Codable, Equatable, Identifiable {
    public let id: ID<Scene>
    public let kind: SceneKind
    public let title: String
    public let text: String
}
public enum EnemyKind: String, Codable { case brassMite, signalWarden }
public struct Enemy: Codable, Equatable, Identifiable {
    public let id: ID<Enemy>
    public let kind: EnemyKind
    public let name: String
    public let maximumHealth: Int
    public internal(set) var health: Int
    public let defense: Int
    public let attackBonus: Int
    public let damage: Int
}
public struct Adventure: Codable, Equatable, Identifiable {
    public let id: ID<Adventure>
    public let title: String
    public let premise: String
    public let scenes: [Scene]
    public let items: [Item]
    public let enemies: [Enemy]
}
public struct Message: Codable, Equatable, Identifiable {
    public enum Speaker: String, Codable { case narrator, player }
    public let id: ID<Message>
    public let speaker: Speaker
    public let text: String
    public init(id: ID<Message> = ID(), speaker: Speaker, text: String) {
        self.id = id; self.speaker = speaker; self.text = text
    }
}
public struct CheckRequest: Codable, Equatable, Identifiable {
    public let id: ID<CheckRequest>
    public let sceneID: ID<Scene>
    public let ability: Ability
    public let difficulty: Int
    public init(id: ID<CheckRequest> = ID(), sceneID: ID<Scene>, ability: Ability, difficulty: Int) {
        self.id = id; self.sceneID = sceneID; self.ability = ability; self.difficulty = difficulty
    }
}
public struct RollResult: Codable, Equatable, Identifiable {
    public let id: ID<RollResult>
    public let request: CheckRequest
    public let face: Int
    public let bonus: Int
    public var total: Int { face + bonus }
    public var succeeded: Bool { total >= request.difficulty }
}
public struct Combat: Codable, Equatable, Identifiable {
    public let id: ID<Combat>
    public let sceneID: ID<Scene>
    public internal(set) var enemies: [Enemy]
    // Fixed order is data for plan-7. No turn engine or random source yet.
    public let turnOrder: [Combatant]
    public let turnIndex: Int
}
public enum Combatant: Codable, Equatable { case hero(ID<Hero>), enemy(ID<Enemy>) }

public enum RuleViolation: Error, Equatable {
    case invalidState(String)
    case invalidOperation
}
