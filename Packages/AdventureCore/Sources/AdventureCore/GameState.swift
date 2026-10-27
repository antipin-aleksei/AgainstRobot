import Foundation

public enum Operation {
    case begin
    case move(ID<Scene>)
    case narrate(Message)
    case requestCheck(CheckRequest)
    case resolveCheck(ID<CheckRequest>, face: Int, resultID: ID<RollResult>)
    case changeHealth(Int)
    case addItem(ID<Item>, quantity: Int)
    case removeItem(ID<Item>, quantity: Int)
    case startCombat(ID<Combat>)
    case damageEnemy(ID<Enemy>, amount: Int)
    case finishCombat
    case complete
}

public struct GameState: Codable, Equatable {
    public internal(set) var hero: Hero
    public let adventure: Adventure
    public internal(set) var sceneID: ID<Scene>
    public internal(set) var phase: SessionPhase = .selectingPremise
    public internal(set) var messages: [Message] = []
    public internal(set) var pendingCheck: CheckRequest?
    public internal(set) var rolls: [RollResult] = []
    public internal(set) var combat: Combat?
    public internal(set) var outcome: Outcome?
    public var scene: Scene { adventure.scenes.first { $0.id == sceneID }! }

    public init(hero: Hero, adventure: Adventure) throws {
        guard let first = adventure.scenes.first else { throw RuleViolation.invalidState("No scenes") }
        self.hero = hero; self.adventure = adventure; sceneID = first.id
        try validate()
    }

    private enum CodingKeys: String, CodingKey {
        case hero, adventure, sceneID, phase, messages, pendingCheck, rolls, combat, outcome
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        hero = try values.decode(Hero.self, forKey: .hero)
        adventure = try values.decode(Adventure.self, forKey: .adventure)
        sceneID = try values.decode(ID<Scene>.self, forKey: .sceneID)
        phase = try values.decode(SessionPhase.self, forKey: .phase)
        messages = try values.decode([Message].self, forKey: .messages)
        pendingCheck = try values.decodeIfPresent(CheckRequest.self, forKey: .pendingCheck)
        rolls = try values.decode([RollResult].self, forKey: .rolls)
        combat = try values.decodeIfPresent(Combat.self, forKey: .combat)
        outcome = try values.decodeIfPresent(Outcome.self, forKey: .outcome)
        try validate()
    }

    public func validate() throws {
        func require(_ condition: Bool, _ reason: String) throws {
            if !condition { throw RuleViolation.invalidState(reason) }
        }
        func nonblank(_ text: String) -> Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        func unique<T: Hashable>(_ values: [T]) -> Bool { Set(values).count == values.count }
        func stats(health: Int, maximum: Int, defense: Int, attack: Int, damage: Int) -> Bool {
            (1...100).contains(maximum) && (0...maximum).contains(health) && (1...30).contains(defense)
                && (0...5).contains(attack) && (1...20).contains(damage)
        }
        try require(nonblank(hero.name) && stats(health: hero.health, maximum: hero.maximumHealth,
                    defense: hero.defense, attack: hero.attackBonus, damage: hero.damage), "Invalid hero")
        try require([hero.abilities.might, hero.abilities.agility, hero.abilities.insight].allSatisfy { (0...5).contains($0) }, "Invalid abilities")
        try require(nonblank(adventure.title) && nonblank(adventure.premise), "Invalid adventure")
        try require(!adventure.scenes.isEmpty && unique(adventure.scenes.map(\.id)) &&
                    adventure.scenes.allSatisfy { nonblank($0.title) && nonblank($0.text) }, "Invalid scenes")
        try require(adventure.scenes.contains { $0.id == sceneID }, "Unknown current scene")
        try require(unique(adventure.items.map(\.id)) && adventure.items.allSatisfy { nonblank($0.name) }, "Invalid items")
        try require(unique(hero.inventory.map(\.itemID)) && hero.inventory.allSatisfy { stack in
            stack.quantity > 0 && adventure.items.contains { $0.id == stack.itemID }
        }, "Invalid inventory")
        try require(unique(adventure.enemies.map(\.id)) && adventure.enemies.allSatisfy {
            nonblank($0.name) && $0.health == $0.maximumHealth && stats(health: $0.health, maximum: $0.maximumHealth,
                                                                    defense: $0.defense, attack: $0.attackBonus, damage: $0.damage)
        }, "Invalid enemies")
        try require(unique(messages.map(\.id)) && messages.allSatisfy { nonblank($0.text) }, "Invalid messages")
        func validRequest(_ request: CheckRequest) -> Bool {
            (1...30).contains(request.difficulty) && adventure.scenes.contains { $0.id == request.sceneID }
        }
        try require(unique(rolls.map(\.id)) && unique(rolls.map { $0.request.id }) && rolls.allSatisfy {
            validRequest($0.request) && (1...20).contains($0.face) && $0.bonus == hero.abilities.bonus(for: $0.request.ability)
        }, "Invalid roll history")
        try require((phase == .awaitingRoll) == (pendingCheck != nil), "Pending check phase mismatch")
        if let request = pendingCheck {
            try require(validRequest(request) && request.sceneID == sceneID && !rolls.contains { $0.request.id == request.id }, "Invalid pending check")
        }
        try require((phase == .combat) == (combat != nil), "Combat phase mismatch")
        if let combat = combat {
            try require(combat.sceneID == sceneID && scene.kind == .battle && !combat.enemies.isEmpty &&
                        unique(combat.enemies.map(\.id)) && combat.enemies.count == adventure.enemies.count, "Invalid combat scene/enemies")
            for enemy in combat.enemies {
                guard var template = adventure.enemies.first(where: { $0.id == enemy.id }) else {
                    throw RuleViolation.invalidState("Unknown combat enemy")
                }
                try require((0...template.maximumHealth).contains(enemy.health), "Invalid enemy health")
                template.health = enemy.health
                try require(template == enemy, "Changed enemy definition")
            }
            try require(combat.turnOrder == [.hero(hero.id)] + combat.enemies.map { .enemy($0.id) }
                        && combat.turnOrder.indices.contains(combat.turnIndex), "Invalid turn order")
        }
        try require((phase == .completed) == (outcome != nil), "Outcome phase mismatch")
        if phase == .completed {
            try require((outcome == .defeat && hero.health == 0) ||
                        (outcome == .victory && hero.health > 0 && scene.kind == .ending), "Invalid outcome")
        } else { try require(hero.health > 0, "Dead hero in active session") }
    }
    public mutating func apply(_ operation: Operation) throws {
        var candidate = self
        try candidate.reduce(operation)
        try candidate.validate()
        self = candidate
    }

    private mutating func reduce(_ operation: Operation) throws {
        switch operation {
        case .begin:
            guard phase == .selectingPremise else { throw RuleViolation.invalidOperation }
            phase = .playing
        case .move(let target):
            guard phase == .playing, adventure.scenes.contains(where: { $0.id == target }) else {
                throw RuleViolation.invalidOperation
            }
            sceneID = target
        case .narrate(let message):
            guard phase == .playing || phase == .awaitingRoll || phase == .combat,
                  !message.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !messages.contains(where: { $0.id == message.id }) else { throw RuleViolation.invalidOperation }
            messages.append(message)
        case .requestCheck(let request):
            guard phase == .playing, request.sceneID == sceneID, (1...30).contains(request.difficulty),
                  !rolls.contains(where: { $0.request.id == request.id }) else { throw RuleViolation.invalidOperation }
            pendingCheck = request
            phase = .awaitingRoll
        case .resolveCheck(let requestID, let face, let resultID):
            guard phase == .awaitingRoll, let request = pendingCheck, request.id == requestID,
                  (1...20).contains(face), !rolls.contains(where: { $0.id == resultID }) else {
                throw RuleViolation.invalidOperation
            }
            rolls.append(RollResult(id: resultID, request: request, face: face, bonus: hero.abilities.bonus(for: request.ability)))
            pendingCheck = nil
            phase = .playing
        case .changeHealth(let delta):
            guard phase == .playing || phase == .combat else { throw RuleViolation.invalidOperation }
            // Compare before adding so even hostile Int.min/max inputs cannot overflow.
            if delta > 0 { hero.health += min(delta, hero.maximumHealth - hero.health) }
            else if delta < 0 { hero.health = delta <= -hero.health ? 0 : hero.health + delta }
            if hero.health == 0 {
                phase = .completed; outcome = .defeat; combat = nil
            }
        case .addItem(let itemID, let quantity):
            guard phase == .playing || phase == .combat, quantity > 0,
                  adventure.items.contains(where: { $0.id == itemID }) else { throw RuleViolation.invalidOperation }
            if let index = hero.inventory.firstIndex(where: { $0.itemID == itemID }) {
                let (sum, overflow) = hero.inventory[index].quantity.addingReportingOverflow(quantity)
                guard !overflow else { throw RuleViolation.invalidOperation }
                hero.inventory[index].quantity = sum
            } else { hero.inventory.append(ItemStack(itemID: itemID, quantity: quantity)) }
        case .removeItem(let itemID, let quantity):
            guard phase == .playing || phase == .combat, quantity > 0,
                  let index = hero.inventory.firstIndex(where: { $0.itemID == itemID }),
                  hero.inventory[index].quantity >= quantity else { throw RuleViolation.invalidOperation }
            hero.inventory[index].quantity -= quantity
            if hero.inventory[index].quantity == 0 { hero.inventory.remove(at: index) }
        case .startCombat(let id):
            guard phase == .playing, scene.kind == .battle, !adventure.enemies.isEmpty else {
                throw RuleViolation.invalidOperation
            }
            combat = Combat(id: id, sceneID: sceneID, enemies: adventure.enemies,
                            turnOrder: [.hero(hero.id)] + adventure.enemies.map { .enemy($0.id) }, turnIndex: 0)
            phase = .combat
        case .damageEnemy(let id, let amount):
            guard phase == .combat, amount > 0,
                  let index = combat?.enemies.firstIndex(where: { $0.id == id }), let current = combat else {
                throw RuleViolation.invalidOperation
            }
            combat?.enemies[index].health = max(0, current.enemies[index].health - min(amount, current.enemies[index].health))
        case .finishCombat:
            guard phase == .combat, let current = combat, current.enemies.allSatisfy({ $0.health == 0 }) else {
                throw RuleViolation.invalidOperation
            }
            combat = nil; phase = .playing
        case .complete:
            guard phase == .playing, scene.kind == .ending else { throw RuleViolation.invalidOperation }
            outcome = .victory; phase = .completed
        }
    }
}
