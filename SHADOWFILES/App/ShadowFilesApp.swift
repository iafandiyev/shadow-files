import SwiftUI

@main
struct ShadowFilesApp: App {
    @StateObject private var game = GameViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(game)
                .preferredColorScheme(.dark)
        }
    }
}
