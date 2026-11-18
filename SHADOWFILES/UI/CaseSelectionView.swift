import SwiftUI

struct CaseSelectionView: View {
    @EnvironmentObject private var game: GameEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(MissionCatalog.all) { mission in
                    let unlocked = game.isMissionUnlocked(mission)
                    let completed = game.completedMissionIDs.contains(mission.id)
                    Button {
                        guard unlocked else { return }
                        game.selectMission(mission.id)
                        dismiss()
                        game.startGame()
                    } label: {
                        HStack(spacing: 13) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.07))
                                    .frame(width: 48, height: 48)
                                Text(String(format: "%02d", (MissionCatalog.all.firstIndex(where: { $0.id == mission.id }) ?? 0) + 1))
                                    .font(.system(size: 17, weight: .black, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mission.title)
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(mission.district)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.red)
                                Text(mission.briefing)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 4)
                            if completed {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                            } else if !unlocked {
                                Image(systemName: "lock.fill").foregroundStyle(.secondary)
                            } else {
                                Image(systemName: "arrow.right.circle.fill").foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .padding(.vertical, 7)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!unlocked)
                    .listRowBackground(Color.white.opacity(0.025))
                }
            }
            .navigationTitle("Case Files")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
        .preferredColorScheme(.dark)
    }
}
