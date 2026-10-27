import SwiftUI

struct GameView: View {
    let session: MockAdventureSession
    let onHome: () -> Void
    @State private var input = ""
    @State private var showsHero = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            AdventureNotice(text: session.isDemoHistory
                ? "Это пример истории. Сохранения появятся позже."
                : "Локальный пример. Ответы и бросок заранее заданы. Бой появится позже.")
                .padding(.horizontal).padding(.vertical, 8)
            if let issue = session.issueMessage {
                AdventureNotice(text: issue).padding(.horizontal)
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(session.messages) { message in
                            AdventureCard {
                                Text(message.speaker == .player ? session.heroName : "Мастер · пример")
                                    .font(.caption.bold()).foregroundStyle(AdventureStyle.accent)
                                Text(message.text).font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .id(message.id)
                        }
                        Color.clear.frame(height: 1).id("latest")
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: session.messages.count) {
                    proxy.scrollTo("latest", anchor: .bottom)
                }
            }
        }
        .background(AdventureStyle.background)
        .navigationTitle("Игра")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Герой", systemImage: "person.crop.circle") { showsHero = true }
                    .accessibilityIdentifier("game.hero")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("На главную", systemImage: "house") { onHome() }
                    .accessibilityIdentifier("game.home")
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                if session.isAwaitingRoll {
                    Text("Проверка замка · результат примера: 14").font(.footnote)
                    PrimaryAdventureButton(title: "Тестовый бросок") { session.roll() }
                        .accessibilityIdentifier("game.roll")
                }
                HStack(alignment: .center) {
                    TextField("Ваше действие", text: $input)
                        .textFieldStyle(.roundedBorder)
                        .focused($inputFocused)
                        .submitLabel(.done)
                        .onSubmit { inputFocused = false }
                        .accessibilityIdentifier("game.input")
                    Button("Отправить", systemImage: "arrow.up.circle.fill") {
                        inputFocused = false
                        session.send(input)
                        input = ""
                    }
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .frame(minWidth: 44, minHeight: 44)
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || session.isAwaitingRoll)
                    .accessibilityIdentifier("game.send")
                }
                Text(session.isAwaitingRoll ? "Сначала завершите тестовый бросок." : "Голосовой ввод пока недоступен.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding().background(.regularMaterial)
        }
        .sheet(isPresented: $showsHero) { HeroCardView(session: session) }
    }
}
