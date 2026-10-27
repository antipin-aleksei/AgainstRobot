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
                    AdventureNotice(text: "Карточка тестового героя. Характеристики, здоровье и инвентарь появятся вместе с правилами.")
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
