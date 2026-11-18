import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var game: GameEngine
    @Environment(\.dismiss) private var dismiss
    @State private var draftName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("DETECTIVE PROFILE") {
                    TextField("Detective name", text: $draftName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                    Button("Save profile") { game.updatePlayerName(draftName) }
                }
                Section("GAME") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Minimum iOS", value: "17.0")
                    LabeledContent("Graphics", value: "RealityKit 3D")
                }
                Section("LOCAL SAVE") {
                    Text("Your evidence and case completion are stored on this iPhone. Multiplayer room state lives on the server only while players are connected.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Reset current case", role: .destructive) { game.resetCurrentCase() }
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .onAppear { draftName = game.playerName }
        }
        .preferredColorScheme(.dark)
    }
}
