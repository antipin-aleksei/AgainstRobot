import SwiftUI

@main
struct AgainstRobotApp: App {
    @State private var configuration = AppConfiguration()

    var body: some Scene {
        WindowGroup {
            HomeView(configuration: $configuration)
        }
    }
}
