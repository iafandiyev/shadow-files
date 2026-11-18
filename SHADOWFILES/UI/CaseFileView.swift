import SwiftUI

struct CaseFileView: View {
    @EnvironmentObject private var game: GameEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("CASE BRIEFING") {
                    Text(game.currentMission.briefing)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("DISTRICT")
                        Spacer()
                        Text(game.currentMission.district)
                            .font(.caption.bold().monospaced())
                            .foregroundStyle(.red)
                    }
                    HStack {
                        Text("EVIDENCE")
                        Spacer()
                        Text("\(game.collectedCount) / \(game.totalClues)")
                            .font(.caption.bold().monospaced())
                    }
                    ProgressView(value: Double(game.collectedCount), total: Double(max(1, game.totalClues)))
                        .tint(.red)
                }

                Section("RECOVERED EVIDENCE") {
                    if game.evidence.isEmpty {
                        ContentUnavailableView("No evidence recovered", systemImage: "magnifyingglass", description: Text("Explore Greywood and approach a gold marker. Then press SEARCH AREA."))
                    } else {
                        ForEach(game.evidence) { clue in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(clue.title).font(.headline)
                                    Spacer()
                                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                                }
                                Text(clue.category)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.red)
                                Text(clue.detail).font(.subheadline).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("CASE STATUS") {
                    Label(game.caseSolved ? "Case closed" : "Active investigation",
                          systemImage: game.caseSolved ? "checkmark.seal.fill" : "scope")
                        .foregroundStyle(game.caseSolved ? .green : .orange)
                    if !game.investigationMessage.isEmpty {
                        Text(game.investigationMessage).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Detective Case File")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
