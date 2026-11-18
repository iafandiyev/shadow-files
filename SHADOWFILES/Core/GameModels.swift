import Foundation

struct EvidenceDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let category: String
    let detail: String
    let x: Float
    let z: Float
}

struct CollectedEvidence: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let category: String
    let detail: String
    let collectedAt: Date

    init(definition: EvidenceDefinition, collectedAt: Date = Date()) {
        id = definition.id
        title = definition.title
        category = definition.category
        detail = definition.detail
        self.collectedAt = collectedAt
    }
}

struct MissionDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let district: String
    let briefing: String
    let suspectName: String
    let suspectDescription: String
    let clues: [EvidenceDefinition]
    let interrogationTruth: String
}

struct GameSave: Codable {
    var evidenceByMission: [String: [CollectedEvidence]] = [:]
    var completedMissionIDs: Set<String> = []
    var selectedMissionID: String = "case-001"
    var playerName: String = "Detective"
}

enum MissionCatalog {
    static let all: [MissionDefinition] = [
        MissionDefinition(
            id: "case-001", title: "THE EMPTY APARTMENT", district: "OLD TOWN",
            briefing: "A Greywood resident vanished from a locked apartment. Reconstruct the final hours and find out who visited.",
            suspectName: "Elliot Carter", suspectDescription: "A nervous neighbour who claims he stayed home all night.",
            clues: [
                EvidenceDefinition(id: "frame", title: "Broken Picture Frame", category: "PHYSICAL", detail: "The frame was broken from the inside. Someone searched behind it in a hurry.", x: -4, z: 1),
                EvidenceDefinition(id: "fingerprint", title: "Unknown Fingerprint", category: "FORENSIC", detail: "A partial print was recovered from the desk. It does not belong to the missing resident.", x: 5, z: 1),
                EvidenceDefinition(id: "receipt", title: "Dock Receipt", category: "DOCUMENT", detail: "A receipt places the visitor at Greywood Docks at 11:42 PM.", x: 1, z: -6)
            ],
            interrogationTruth: "The dock receipt contradicts Carter's alibi. He visited the apartment before the disappearance."
        ),
        MissionDefinition(
            id: "case-002", title: "BLOOD ON THE DOCKS", district: "INDUSTRIAL DISTRICT",
            briefing: "A night guard was found dead near Warehouse 6. Identify the weapon, trace the shipment, and expose the killer.",
            suspectName: "Mason Reed", suspectDescription: "A warehouse supervisor with access to restricted cargo records.",
            clues: [
                EvidenceDefinition(id: "shell", title: "Spent Cartridge", category: "BALLISTICS", detail: "A spent cartridge was found near the loading ramp. It matches a small-calibre handgun.", x: -5, z: -3),
                EvidenceDefinition(id: "glove", title: "Bloodstained Glove", category: "TRACE", detail: "A work glove carries traces of the victim's blood and industrial solvent.", x: 5, z: -3),
                EvidenceDefinition(id: "manifest", title: "Altered Manifest", category: "DOCUMENT", detail: "The manifest lists a shipment that was removed from the official inventory.", x: 0, z: 6)
            ],
            interrogationTruth: "The altered manifest and glove place Reed at the warehouse after closing."
        ),
        MissionDefinition(
            id: "case-003", title: "THE LAST WITNESS", district: "DOWNTOWN",
            briefing: "A key witness disappeared hours before giving testimony. Search the street, recover the phone trail, and locate the witness.",
            suspectName: "Nora Vale", suspectDescription: "A fixer who has been seen near the witness's apartment.",
            clues: [
                EvidenceDefinition(id: "note", title: "Torn Street Note", category: "DOCUMENT", detail: "The note contains a partial address and the words 'south entrance'.", x: -5, z: 3),
                EvidenceDefinition(id: "phone", title: "Damaged Phone", category: "DIGITAL", detail: "A recovered phone contains a final outgoing call to a warehouse number.", x: 5, z: 3),
                EvidenceDefinition(id: "badge", title: "Visitor Badge", category: "PHYSICAL", detail: "A visitor badge records an unregistered entry shortly before the witness vanished.", x: 0, z: -6)
            ],
            interrogationTruth: "The phone call and visitor badge connect Vale to the witness's disappearance."
        )
    ]

    static func mission(id: String) -> MissionDefinition {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}
