import SwiftUI

struct InterrogationView: View {
    @EnvironmentObject private var game: GameEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.07))
                        Image(systemName: "person.crop.square.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white.opacity(0.78))
                    }
                    .frame(width: 76, height: 76)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(game.currentMission.suspectName.uppercased())
                            .font(.system(size: 17, weight: .black, design: .rounded))
                        Text(game.currentMission.suspectDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text("PRESSURE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Spacer()
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index < game.suspectPressure ? Color.red : Color.white.opacity(0.12))
                            .frame(width: 11, height: 11)
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.045))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                ScrollView {
                    Text(game.interrogationFeedback)
                        .font(.system(size: 15, weight: .medium, design: .serif))
                        .lineSpacing(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.white.opacity(0.055))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .frame(maxHeight: .infinity)

                if game.caseSolved {
                    Label("CASE CLOSED", systemImage: "checkmark.seal.fill")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundStyle(.green)
                    Text(game.currentMission.interrogationTruth)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Return to Greywood") { dismiss() }
                        .buttonStyle(PrimaryDetectiveButton())
                } else {
                    VStack(spacing: 9) {
                        actionButton("ASK ABOUT THE ALIBI", icon: "text.bubble", action: 0)
                        actionButton("PRESENT THE EVIDENCE", icon: "doc.text.magnifyingglass", action: 1)
                        actionButton("CONFRONT THE SUSPECT", icon: "exclamationmark.shield", action: 2)
                    }
                }
            }
            .padding(20)
            .navigationTitle("Interrogation")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func actionButton(_ title: String, icon: String, action: Int) -> some View {
        Button { game.chooseInterrogationAction(action) } label: {
            Label(title, systemImage: icon)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .frame(maxWidth: .infinity, minHeight: 46)
        }
        .buttonStyle(PrimaryDetectiveButton())
    }
}

struct PrimaryDetectiveButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(configuration.isPressed ? Color(red: 0.36, green: 0.08, blue: 0.09) : Color(red: 0.50, green: 0.105, blue: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}
