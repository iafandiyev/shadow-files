import SwiftUI

struct MultiplayerView: View {
    @EnvironmentObject private var game: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isConnected = false

    var body: some View {
        NavigationStack {
            Form {
                Section("SERVER") {
                    TextField("WebSocket URL", text: $game.serverAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    Text("Use your computer's LAN IP instead of 127.0.0.1 when testing from a real iPhone.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("ROOM") {
                    TextField("Room code (leave empty to create)", text: $game.roomCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Text("Room capacity: up to 8 players in this starter server.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("CONNECTION") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(game.network.status).foregroundStyle(game.network.status == "Connected" ? .green : .secondary)
                    }
                    if !game.network.assignedRoomCode.isEmpty {
                        HStack {
                            Text("ROOM CODE")
                            Spacer()
                            Text(game.network.assignedRoomCode)
                                .font(.system(.title3, design: .monospaced).bold())
                                .foregroundStyle(.red)
                                .textSelection(.enabled)
                        }
                    }
                    if !game.network.lastMessage.isEmpty {
                        Text(game.network.lastMessage).font(.caption.monospaced()).textSelection(.enabled)
                    }
                    Button(isConnected ? "Disconnect" : "Connect / Create Room") {
                        if isConnected {
                            game.network.disconnect()
                            isConnected = false
                        } else {
                            game.network.connect(address: game.serverAddress,
                                                 roomCode: game.roomCode,
                                                 playerName: game.playerName)
                            isConnected = true
                        }
                    }
                    .disabled(game.serverAddress.isEmpty)
                }
            }
            .navigationTitle("Multiplayer")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
    }
}
