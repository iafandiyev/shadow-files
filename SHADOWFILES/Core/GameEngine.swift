import Foundation
import SwiftUI
import simd

@MainActor
final class GameEngine: ObservableObject {
    @Published var isPlaying = false
    @Published var showingCaseFile = false
    @Published var showingMultiplayer = false
    @Published var showingInterrogation = false
    @Published var showingCases = false
    @Published var showingSettings = false
    @Published var playerName: String
    @Published var selectedMissionID: String
    @Published var evidence: [CollectedEvidence] = []
    @Published var completedMissionIDs: Set<String>
    @Published var missionObjective = "Search the area for evidence."
    @Published var investigationMessage = ""
    @Published var interrogationFeedback = "The suspect is waiting for your questions."
    @Published var suspectPressure = 0
    @Published var caseSolved = false

    let scene = CityScene()
    let multiplayer = MultiplayerClient()
    private var save: GameSave

    init() {
        save = SaveStore.load()
        playerName = save.playerName
        selectedMissionID = save.selectedMissionID
        completedMissionIDs = save.completedMissionIDs
        evidence = save.evidenceByMission[save.selectedMissionID] ?? []

        multiplayer.onRemotePlayerState = { [weak self] id, x, z in
            self?.scene.updateRemotePlayer(id: id, x: x, z: z)
        }
        multiplayer.onRemotePlayerLeft = { [weak self] id in
            self?.scene.removeRemotePlayer(id: id)
        }
        scene.setMissionClues(currentMission.clues, collectedIDs: Set(evidence.map(\.id)))
        refreshObjective()
    }

    var currentMission: MissionDefinition {
        MissionCatalog.mission(id: selectedMissionID)
    }

    var collectedCount: Int { evidence.count }
    var totalClues: Int { currentMission.clues.count }
    var canInterrogate: Bool { collectedCount >= totalClues && !caseSolved }

    func isMissionUnlocked(_ mission: MissionDefinition) -> Bool {
        guard let index = MissionCatalog.all.firstIndex(where: { $0.id == mission.id }) else { return false }
        return index == 0 || completedMissionIDs.contains(MissionCatalog.all[index - 1].id)
    }

    func selectMission(_ missionID: String) {
        let mission = MissionCatalog.mission(id: missionID)
        guard isMissionUnlocked(mission) else {
            investigationMessage = "Complete the previous case to unlock this file."
            return
        }
        selectedMissionID = mission.id
        evidence = save.evidenceByMission[mission.id] ?? []
        caseSolved = completedMissionIDs.contains(mission.id)
        suspectPressure = 0
        interrogationFeedback = "The suspect is waiting for your questions."
        scene.setMissionClues(mission.clues, collectedIDs: Set(evidence.map(\.id)))
        missionObjective = caseSolved ? "CASE CLOSED — select another investigation." : "Search the area for evidence."
        save.selectedMissionID = mission.id
        persist()
    }

    func startGame() {
        isPlaying = true
        showingCases = false
        scene.setMissionClues(currentMission.clues, collectedIDs: Set(evidence.map(\.id)))
        refreshObjective()
    }

    func returnToMenu() {
        isPlaying = false
        showingCaseFile = false
        showingInterrogation = false
    }

    func movePlayer(x: Float, forward: Float) {
        scene.move(x: x, forward: forward)
        let position = scene.playerPosition
        multiplayer.sendPlayerState(x: position.x, z: position.z)
    }

    func rotateCamera(deltaX: Float) {
        scene.rotateCamera(deltaX: deltaX)
    }

    func investigateCurrentArea() {
        guard !caseSolved else {
            investigationMessage = "This case has already been closed."
            return
        }
        let collected = Set(evidence.map(\.id))
        guard let clue = currentMission.clues.first(where: { !collected.contains($0.id) && scene.isNearClue($0) }) else {
            investigationMessage = "No evidence within reach. Move closer to a gold evidence marker."
            return
        }

        let item = CollectedEvidence(definition: clue)
        evidence.append(item)
        save.evidenceByMission[currentMission.id] = evidence
        scene.removeClueMarker(id: clue.id)
        persist()
        multiplayer.sendEvidence(id: clue.id, title: clue.title)
        investigationMessage = "Evidence secured: \(clue.title)"
        refreshObjective()
    }

    func chooseInterrogationAction(_ action: Int) {
        guard canInterrogate else {
            interrogationFeedback = "Collect all evidence before confronting the suspect."
            return
        }

        switch action {
        case 0:
            suspectPressure += 1
            interrogationFeedback = "\(currentMission.suspectName) repeats the original alibi, but avoids explaining the timeline."
        case 1:
            suspectPressure += 2
            interrogationFeedback = "You present the evidence. The suspect notices the contradiction and changes their story."
        case 2:
            if suspectPressure >= 2 {
                solveCurrentCase()
                interrogationFeedback = currentMission.interrogationTruth
            } else {
                interrogationFeedback = "The accusation is premature. Ask about the alibi and present the evidence first."
            }
        default:
            break
        }
    }

    func solveCurrentCase() {
        guard canInterrogate, suspectPressure >= 2 else { return }
        caseSolved = true
        completedMissionIDs.insert(currentMission.id)
        save.completedMissionIDs = completedMissionIDs
        missionObjective = "CASE CLOSED — evidence has been filed."
        investigationMessage = "Case solved. The next case is now available."
        persist()
    }

    func resetCurrentCase() {
        evidence = []
        caseSolved = false
        suspectPressure = 0
        save.evidenceByMission[currentMission.id] = []
        completedMissionIDs.remove(currentMission.id)
        save.completedMissionIDs = completedMissionIDs
        scene.setMissionClues(currentMission.clues, collectedIDs: [])
        missionObjective = "Search the area for evidence."
        investigationMessage = "Case progress reset."
        persist()
    }

    func updatePlayerName(_ newName: String) {
        let cleaned = String(newName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(24))
        playerName = cleaned.isEmpty ? "Detective" : cleaned
        save.playerName = playerName
        persist()
    }

    private func refreshObjective() {
        if caseSolved {
            missionObjective = "CASE CLOSED — select another investigation."
        } else if collectedCount >= totalClues {
            missionObjective = "All clues recovered. Return to the suspect and interrogate."
        } else {
            missionObjective = "Recover evidence: \(collectedCount)/\(totalClues)"
        }
    }

    private func persist() {
        save.selectedMissionID = selectedMissionID
        save.playerName = playerName
        save.evidenceByMission[selectedMissionID] = evidence
        save.completedMissionIDs = completedMissionIDs
        SaveStore.write(save)
    }
}
