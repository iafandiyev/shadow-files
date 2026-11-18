import Foundation
import SwiftUI
import simd

@MainActor
final class GameViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var showingInvestigation = false
    @Published var playerName = UserDefaults.standard.string(forKey: "playerName") ?? "Detective"
    @Published var evidence: [Evidence] = []
    @Published var missionTitle = "THE EMPTY APARTMENT"
    @Published var missionObjective = "Search the apartment for evidence."
    @Published var serverAddress = "ws://127.0.0.1:8080/ws"
    @Published var roomCode = ""

    let sceneController = GameSceneController()
    let network = NetworkClient()

    init() {
        network.onRemotePlayerState = { [weak self] id, x, z in
            self?.sceneController.updateRemotePlayer(id: id, x: x, z: z)
        }
        network.onRemotePlayerLeft = { [weak self] id in
            self?.sceneController.removeRemotePlayer(id: id)
        }
        loadEvidence()
    }

    func startGame() {
        isPlaying = true
    }

    func returnToMenu() {
        isPlaying = false
    }

    func movePlayer(x: Float, z: Float) {
        sceneController.move(x: x, z: z)
        network.sendPlayerState(x: sceneController.playerPosition.x,
                                z: sceneController.playerPosition.z)
    }

    func investigateCurrentArea() {
        guard evidence.count < 3 else {
            missionObjective = "You have collected all available evidence here."
            return
        }

        let clues = [
            Evidence(title: "Broken Picture Frame", category: "Physical evidence", detail: "A damaged frame lies near the entrance. The glass is broken from the inside."),
            Evidence(title: "Unknown Fingerprint", category: "Forensic evidence", detail: "A partial fingerprint was found on the desk. It has not been matched to a suspect."),
            Evidence(title: "Torn Receipt", category: "Document", detail: "A receipt from Greywood Docks was found in the apartment. The time is 11:42 PM.")
        ]

        let clue = clues[evidence.count]
        evidence.append(clue)
        saveEvidence()
        missionObjective = "Evidence collected: \(clue.title)"
        network.sendEvidence(id: clue.id.uuidString, title: clue.title)
    }

    func clearLocalProgress() {
        evidence.removeAll()
        saveEvidence()
        missionObjective = "Search the apartment for evidence."
    }

    private func saveEvidence() {
        do {
            try SaveManager.save(evidence)
        } catch {
            print("[Save] Could not write case file: \(error.localizedDescription)")
        }
    }

    private func loadEvidence() {
        do {
            evidence = try SaveManager.load([Evidence].self)
        } catch {
            evidence = []
        }
    }
}
