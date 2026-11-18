import SwiftUI

struct RootView: View {
    @EnvironmentObject private var game: GameEngine

    var body: some View {
        Group {
            if game.isPlaying {
                GameplayView()
            } else {
                MainMenuView()
            }
        }
        .animation(.easeInOut(duration: 0.22), value: game.isPlaying)
    }
}

struct MainMenuView: View {
    @EnvironmentObject private var game: GameEngine

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.035, green: 0.045, blue: 0.06), .black],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("GREYWOOD POLICE DEPARTMENT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(2.2)
                        .foregroundStyle(Color(red: 0.76, green: 0.22, blue: 0.20))
                    Spacer().frame(height: 18)
                    Text("SHADOW\nFILES")
                        .font(.system(size: 62, weight: .black, design: .rounded))
                        .tracking(-2.5)
                        .lineSpacing(-8)
                        .foregroundStyle(.white)
                    Text("EVERY CITY HAS SECRETS.")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .tracking(1.8)
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.top, 12)
                    Spacer()
                    Text("DETECTIVE: \(game.playerName.uppercased())")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("BUILD 1.0.0  ·  GREYWOOD")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.top, 5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 48)
                .padding(.vertical, 34)

                VStack(spacing: 12) {
                    menuButton("CONTINUE INVESTIGATION", icon: "play.fill") {
                        game.startGame()
                    }
                    menuButton("CASE FILES", icon: "folder.fill") {
                        game.showingCases = true
                    }
                    menuButton("MULTIPLAYER", icon: "person.2.fill") {
                        game.showingMultiplayer = true
                    }
                    menuButton("SETTINGS", icon: "gearshape.fill", secondary: true) {
                        game.showingSettings = true
                    }
                }
                .frame(width: 300)
                .padding(.trailing, 48)
            }
        }
        .sheet(isPresented: $game.showingCases) { CaseSelectionView() }
        .sheet(isPresented: $game.showingMultiplayer) { MultiplayerView() }
        .sheet(isPresented: $game.showingSettings) { SettingsView() }
    }

    private func menuButton(_ title: String, icon: String, secondary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: icon).frame(width: 20)
                Text(title).font(.system(size: 12, weight: .bold, design: .monospaced))
                Spacer()
                Image(systemName: "arrow.right").font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(secondary ? .white.opacity(0.72) : .white)
            .padding(.horizontal, 17)
            .frame(height: 54)
            .background(secondary ? Color.white.opacity(0.035) : Color.white.opacity(0.075))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.13), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
