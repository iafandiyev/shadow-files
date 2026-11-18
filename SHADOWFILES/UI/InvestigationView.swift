import SwiftUI

struct InvestigationView: View {
    @EnvironmentObject private var game: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("THE EMPTY APARTMENT")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                        Text("A resident has disappeared. Search the apartment and identify what happened.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        ProgressView(value: Double(game.evidence.count), total: 3)
                            .tint(.red)
                        Text("\(game.evidence.count) / 3 clues recovered")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                Section("COLLECTED EVIDENCE") {
                    if game.evidence.isEmpty {
                        ContentUnavailableView("No evidence yet", systemImage: "magnifyingglass", description: Text("Return to the scene and use SEARCH AREA."))
                    } else {
                        ForEach(game.evidence) { clue in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(clue.title).font(.headline)
                                    Spacer()
                                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                                }
                                Text(clue.category.uppercased())
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.red)
                                Text(clue.detail).font(.subheadline).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .navigationTitle("Case Notebook")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
    }
}
