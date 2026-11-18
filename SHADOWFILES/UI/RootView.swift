import SwiftUI

struct RootView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        Group {
            if game.isPlaying {
                GameplayView()
            } else {
                MainMenuView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: game.isPlaying)
    }
}

struct MainMenuView: View {
    @EnvironmentObject private var game: GameViewModel
    @State private var showMultiplayer = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.035, green: 0.045, blue: 0.06), .black],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                Spacer()
                Text("GREYWOOD POLICE DEPARTMENT")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(.red.opacity(0.85))

                Text("SHADOW\nFILES")
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .tracking(-2)
                    .lineSpacing(-8)
                    .foregroundStyle(.white)

                Text("EVERY CITY HAS SECRETS.")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.55))

                Spacer()

                menuButton("CONTINUE INVESTIGATION", icon: "play.fill") {
                    game.startGame()
                }
                menuButton("MULTIPLAYER", icon: "person.2.fill") {
                    showMultiplayer = true
                }
                menuButton("SETTINGS", icon: "gearshape.fill", secondary: true) {
                    showSettings = true
                }

                HStack {
                    Text("BUILD 0.1.0 · GREYWOOD")
                    Spacer()
                    Text("UNOFFICIAL CASE FILE")
                }
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.32))
                .padding(.top, 18)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 30)
        }
        .sheet(isPresented: $showMultiplayer) { MultiplayerView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    private func menuButton(_ title: String, icon: String, secondary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).frame(width: 20)
                Text(title).font(.system(size: 13, weight: .bold, design: .monospaced))
                Spacer()
                Image(systemName: "arrow.right").font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(secondary ? .white.opacity(0.7) : .white)
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(secondary ? Color.white.opacity(0.045) : Color.white.opacity(0.09))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.white.opacity(0.12), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var game: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("PLAYER") {
                    TextField("Detective name", text: $game.playerName)
                        .textInputAutocapitalization(.words)
                        .onChange(of: game.playerName) { _, value in
                            UserDefaults.standard.set(value, forKey: "playerName")
                        }
                }
                Section("PROGRESS") {
                    Text("Evidence collected: \(game.evidence.count)")
                    Button("Reset local case progress", role: .destructive) {
                        game.clearLocalProgress()
                    }
                }
                Section {
                    Text("This build is an early playable prototype. Visual quality and content will expand as licensed 3D assets and animations are added.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
    }
}
