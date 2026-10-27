import SwiftUI

struct CharacterView: View {
    @Bindable var session: MockAdventureSession
    let onContinue: () -> Void
    @FocusState private var nameFocused: Bool

    var body: some View {
        Form {
            Section("Готовый герой") {
                ForEach(HeroPreset.allCases) { hero in
                    Button {
                        session.hero = hero
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: hero.symbol).frame(width: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(hero.title).font(.headline)
                                Text(hero.detail).font(.body).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            if session.hero == hero { Image(systemName: "checkmark.circle.fill") }
                        }
                        .foregroundStyle(.primary)
                        .padding(.vertical, 4)
                    }
                    .accessibilityIdentifier("hero.\(hero.rawValue)")
                    .accessibilityAddTraits(session.hero == hero ? [.isSelected] : [])
                }
            }
            Section("Имя героя") {
                TextField("Введите имя", text: $session.name)
                    .accessibilityIdentifier("character.name")
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .onSubmit { nameFocused = false }
                if !session.canContinue {
                    Text("Имя нужно, чтобы начать приключение.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            Section("Локальный аватар") {
                ForEach(AvatarPreset.allCases) { avatar in
                    Button {
                        session.avatar = avatar
                    } label: {
                        HStack {
                            Label(avatar.title, systemImage: avatar.symbol)
                            Spacer()
                            if session.avatar == avatar { Image(systemName: "checkmark.circle.fill") }
                        }
                        .frame(minHeight: 32)
                    }
                    .accessibilityIdentifier("avatar.\(avatar.rawValue)")
                    .accessibilityAddTraits(session.avatar == avatar ? [.isSelected] : [])
                }
                AdventureNotice(text: "Это символы из приложения. Загрузка фотографий пока недоступна.")
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Персонаж")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            PrimaryAdventureButton(title: "Выбрать завязку", action: onContinue)
                .disabled(!session.canContinue)
                .accessibilityIdentifier("character.continue")
                .padding().background(.regularMaterial)
        }
    }
}
