import SwiftUI

struct PremiseView: View {
    @Bindable var session: MockAdventureSession
    let onAccept: () -> Void
    @State private var isPreparing = false
    @State private var preparation: Task<Void, Never>?
    @FocusState private var hintFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AdventureNotice(text: "Локальная завязка · два готовых примера, без ИИ")
                AdventureCard {
                    Text(session.premiseTitle).font(.title2.bold())
                    Text(session.premiseDescription).font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text("Пожелание игрока").font(.headline)
                TextField("Например, больше загадок", text: $session.hint)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("premise.hint")
                    .focused($hintFocused)
                    .submitLabel(.done)
                    .onSubmit { hintFocused = false }
                if isPreparing {
                    ProgressView("Готовим локальный пример…")
                }
                Button("Другой пример завязки", systemImage: "arrow.clockwise") {
                    hintFocused = false
                    isPreparing = true
                    preparation = Task {
                        do { try await Task.sleep(for: .milliseconds(300)) }
                        catch { return }
                        session.regeneratePremise()
                        isPreparing = false
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isPreparing)
                .accessibilityIdentifier("premise.regenerate")
            }
            .padding()
        }
        .background(AdventureStyle.background)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Завязка")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            PrimaryAdventureButton(title: "Начать приключение", action: onAccept)
                .disabled(isPreparing)
                .accessibilityIdentifier("premise.accept")
                .padding().background(.regularMaterial)
        }
        .onDisappear {
            preparation?.cancel()
            isPreparing = false
        }
    }
}
