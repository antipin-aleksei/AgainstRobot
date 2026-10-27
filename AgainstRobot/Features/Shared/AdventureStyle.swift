import SwiftUI

enum AdventureStyle {
    static let accent = Color.indigo
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let background = Color(uiColor: .systemGroupedBackground)
}

struct AdventureCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(AdventureStyle.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct PrimaryAdventureButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.headline).frame(maxWidth: .infinity, minHeight: 36)
        }
        .buttonStyle(.borderedProminent)
        .tint(AdventureStyle.accent)
    }
}

struct AdventureNotice: View {
    let text: String
    var isError = false
    var body: some View {
        Label(text, systemImage: isError ? "exclamationmark.triangle" : "info.circle")
            .font(.footnote)
            .foregroundStyle(isError ? Color.primary : Color.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
