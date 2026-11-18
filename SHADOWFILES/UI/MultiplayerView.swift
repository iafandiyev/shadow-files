import SwiftUI

struct MultiplayerView: View {
    @EnvironmentObject private var game: GameEngine
    @Environment(\.dismiss) private var dismiss
    @State private var serverURL = "ws://127.0.0.1:8080/ws"
    @State private var joinCode = ""
    @State private var chatDraft = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 13) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("SERVER ADDRESS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    TextField("ws://192.168.1.10:8080/ws", text: $serverURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .textFieldStyle(.roundedBorder)
                    Text("On a real iPhone, use your computer's LAN IP instead of 127.0.0.1. Internet play requires a deployed WSS server.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 9) {
                    Button {
                        game.multiplayer.connect(serverURL: serverURL, requestedRoom: "", playerName: game.playerName)
                    } label: {
                        Label("CREATE ROOM", systemImage: "plus")
                            .frame(maxWidth: .infinity, minHeight: 43)
                    }
                    .buttonStyle(PrimaryDetectiveButton())
                    TextField("ROOM CODE", text: $joinCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 110)
                    Button {
                        game.multiplayer.connect(serverURL: serverURL, requestedRoom: joinCode, playerName: game.playerName)
                    } label: {
                        Text("JOIN").frame(minWidth: 58, minHeight: 43)
                    }
                    .buttonStyle(PrimaryDetectiveButton())
                    .disabled(joinCode.trimmingCharacters(in: .whitespacesAndNewlines).count != 6)
                }

                HStack {
                    Circle()
                        .fill(game.multiplayer.status == "Connected" ? .green : .orange)
                        .frame(width: 8, height: 8)
                    Text(game.multiplayer.status)
                        .font(.caption.monospaced())
                    Spacer()
                    if !game.multiplayer.roomCode.isEmpty {
                        Text("ROOM \(game.multiplayer.roomCode)")
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(.red)
                            .textSelection(.enabled)
                    }
                    Button("Disconnect") { game.multiplayer.disconnect() }
                        .font(.caption.bold())
                        .disabled(game.multiplayer.status == "Offline")
                }
                .padding(10)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 7) {
                    Text("TEAM RADIO")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 7) {
                                ForEach(game.multiplayer.messages.indices, id: \.self) { index in
                                    Text(game.multiplayer.messages[index])
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.85))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .id(index)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .onChange(of: game.multiplayer.messages.count) { _, count in
                            if count > 0 { proxy.scrollTo(count - 1, anchor: .bottom) }
                        }
                    }
                    .padding(10)
                    .frame(maxHeight: .infinity)
                    .background(Color.black.opacity(0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                HStack(spacing: 8) {
                    TextField("Send a team message…", text: $chatDraft)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(sendChat)
                    Button("SEND", action: sendChat)
                        .buttonStyle(PrimaryDetectiveButton())
                        .frame(width: 76, height: 40)
                        .disabled(chatDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || game.multiplayer.status != "Connected")
                }
            }
            .padding(18)
            .navigationTitle("Online Multiplayer")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
    }

    private func sendChat() {
        game.multiplayer.sendChat(chatDraft)
        chatDraft = ""
    }
}
