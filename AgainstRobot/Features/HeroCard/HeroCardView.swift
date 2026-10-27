import SwiftUI

struct HeroCardView: View {
    let session: MockAdventureSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AdventureCard {
                        Image(systemName: session.avatar.symbol)
                            .font(.largeTitle).foregroundStyle(AdventureStyle.accent)
                            .accessibilityHidden(true)
                        Text(session.heroName).font(.largeTitle.bold())
                        Text(session.hero.title).font(.title2)
                        Text(session.avatar.title).font(.headline)
                        Text(session.hero.detail)
                    }
                    if let state = session.gameState {
                        AdventureCard {
                            Text("Здоровье: \(state.hero.health)/\(state.hero.maximumHealth)")
                                .accessibilityIdentifier("hero.health")
                            Text("Сила: \(state.hero.abilities.might) · Ловкость: \(state.hero.abilities.agility) · Чутьё: \(state.hero.abilities.insight)")
                            Text("Защита: \(state.hero.defense) · Атака: +\(state.hero.attackBonus) · Урон: \(state.hero.damage)")
                            Text("Инвентарь").font(.headline)
                            ForEach(state.hero.inventory, id: \.itemID) { stack in
                                if let item = state.adventure.items.first(where: { $0.id == stack.itemID }) {
                                    Text("\(item.name) ×\(stack.quantity)")
                                }
                            }
                        }
                    }
                    AdventureNotice(text: "Упрощённые правила прототипа. Бросок в чате — фиксированный пример; боевой цикл появится позже.")
                }
                .padding()
            }
            .background(AdventureStyle.background)
            .navigationTitle("Карточка героя")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                        .accessibilityIdentifier("hero.close")
                }
            }
        }
    }
}
