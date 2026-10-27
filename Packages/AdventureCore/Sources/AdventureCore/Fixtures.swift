import Foundation

/// Original, deterministic content. UUIDs remain stable across launches and JSON round trips.
public enum AdventureFixtures {
    public static func newSession(name: String, kind: HeroKind = .guardian, avatar: AvatarKind = .fox,
                                  premiseIndex: Int = 0) throws -> GameState {
        guard (0...1).contains(premiseIndex) else { throw RuleViolation.invalidOperation }
        let adventure = makeAdventure(index: premiseIndex)
        let guardian = kind == .guardian
        let hero = Hero(id: ID(), name: name.trimmingCharacters(in: .whitespacesAndNewlines), kind: kind, avatar: avatar,
                        abilities: guardian ? Abilities(might: 3, agility: 1, insight: 2) : Abilities(might: 1, agility: 3, insight: 2),
                        maximumHealth: guardian ? 12 : 10, health: guardian ? 12 : 10,
                        defense: guardian ? 12 : 11, attackBonus: guardian ? 3 : 2, damage: guardian ? 3 : 2,
                        inventory: adventure.items.prefix(2).map { ItemStack(itemID: $0.id, quantity: 1) })
        return try GameState(hero: hero, adventure: adventure)
    }

    private static func fixed<T>(_ number: Int) -> ID<T> {
        ID(UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", number))!)
    }

    private static func makeAdventure(index: Int) -> Adventure {
        let station = index == 1
        let offset = index * 100
        let premise = station
            ? "Старая станция глубоко в лесу подаёт сигналы, хотя поездов здесь не было много лет. Молодой механик просит вас найти источник света и вернуть пропавший журнал.\n\nУ входа видны свежие следы. Можно осмотреть закрытую дверь, расспросить механика или обойти станцию по тропе. Ветер приносит звон колокольчика с пустой платформы."
            : "Каждый вечер над бухтой загорается заброшенный маяк. Сегодня его свет остановился на вашем окне. Смотритель исчез, а в порту нашли письмо с просьбой прийти до рассвета.\n\nНа берегу вас ждёт лодка. В её борту спрятан медный ключ, но никто из рыбаков не признаётся, кому она принадлежит. Вы решаете, с кем поговорить и какой дорогой добраться до маяка."
        return Adventure(id: fixed(1 + offset), title: station ? "Тайна лесной станции" : "Маяк в тумане", premise: premise,
            scenes: [
                Scene(id: fixed(10 + offset), kind: .conversation, title: station ? "Механик" : "Рыбачка",
                      text: station ? "Механик объясняет: сигналы начались после пропажи журнала. Он даёт вам фонарь." : "Рыбачка Вея видела, как медные механизмы унесли линзу маяка. Она просит вернуть свет кораблям."),
                Scene(id: fixed(11 + offset), kind: .exploration, title: "Закрытая дверь",
                      text: "Дверь держит старый замок. Проверка ловкости с порогом 12 открывает короткий путь. При неудаче можно пройти по длинной тропе; история продолжается."),
                Scene(id: fixed(12 + offset), kind: .battle, title: "Двор механизмов",
                      text: "Медный клещ и Сигнальный страж защищают украденный прибор. Герой действует первым; затем клещ, затем страж."),
                Scene(id: fixed(13 + offset), kind: .ending, title: "Свет возвращён",
                      text: station ? "Журнал вернулся механику. Сигнал станции помогает заблудившимся выбраться из леса." : "Вы возвращаете линзу. Луч прорезает туман, и корабль благополучно входит в бухту.")
            ],
            items: [Item(id: fixed(20 + offset), name: "Фонарь"), Item(id: fixed(21 + offset), name: "Бинт"),
                    Item(id: fixed(22 + offset), name: station ? "Журнал" : "Линза")],
            enemies: [Enemy(id: fixed(30 + offset), kind: .brassMite, name: "Медный клещ", maximumHealth: 4, health: 4, defense: 10, attackBonus: 1, damage: 2),
                      Enemy(id: fixed(31 + offset), kind: .signalWarden, name: "Сигнальный страж", maximumHealth: 6, health: 6, defense: 12, attackBonus: 2, damage: 3)])
    }
}
