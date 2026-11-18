import Foundation
import RealityKit
import UIKit
import simd

@MainActor
final class CityScene {
    private weak var arView: ARView?
    private var worldAnchor: AnchorEntity?
    private var player = Entity()
    private var camera = PerspectiveCamera()
    private var remotePlayers: [String: Entity] = [:]
    private var clueMarkers: [String: Entity] = [:]
    private var hasBuiltWorld = false
    private var cameraYaw: Float = 0
    private var pendingClues: [EvidenceDefinition] = []
    private var pendingCollectedIDs: Set<String> = []

    var playerPosition: SIMD3<Float> { player.position }

    func attach(to view: ARView) {
        if arView === view { return }
        arView = view
        // GameplayView can be destroyed and recreated when returning to the menu.
        // Rebuild the scene for the new ARView instead of keeping an anchor attached
        // to a previous, released view.
        hasBuiltWorld = false
        worldAnchor = nil
        remotePlayers.removeAll()
        clueMarkers.removeAll()
        buildWorld(in: view)
        hasBuiltWorld = true
    }

    private func buildWorld(in view: ARView) {
        let anchor = AnchorEntity(world: .zero)
        worldAnchor = anchor

        let sun = DirectionalLight()
        sun.light = DirectionalLightComponent(color: .white, intensity: 1450)
        sun.position = [0, 22, 0]
        sun.orientation = simd_quatf(angle: -.pi / 3.1, axis: [1, 0, 0])
        anchor.addChild(sun)

        addCityGround(to: anchor)
        addBuildings(to: anchor)
        addStreetDetails(to: anchor)
        addPoliceStationSign(to: anchor)
        addPlayer(to: anchor)

        camera = PerspectiveCamera()
        anchor.addChild(camera)
        view.scene.anchors.append(anchor)
        updateCamera()
        setMissionClues(pendingClues, collectedIDs: pendingCollectedIDs)
    }

    private func addCityGround(to anchor: Entity) {
        let ground = material(UIColor(red: 0.19, green: 0.20, blue: 0.21, alpha: 1))
        let road = material(UIColor(red: 0.065, green: 0.075, blue: 0.085, alpha: 1))
        let pavement = material(UIColor(red: 0.31, green: 0.32, blue: 0.33, alpha: 1))
        let lane = material(UIColor(red: 0.78, green: 0.67, blue: 0.44, alpha: 1))

        addBox(anchor, size: [76, 0.18, 76], position: [0, -0.16, 0], mat: ground)
        addBox(anchor, size: [14, 0.035, 76], position: [0, -0.045, 0], mat: road)
        addBox(anchor, size: [76, 0.035, 14], position: [0, -0.04, 0], mat: road)

        addBox(anchor, size: [1.0, 0.025, 76], position: [-8.1, -0.01, 0], mat: lane)
        addBox(anchor, size: [1.0, 0.025, 76], position: [8.1, -0.01, 0], mat: lane)
        addBox(anchor, size: [76, 0.025, 1.0], position: [0, -0.005, -8.1], mat: lane)
        addBox(anchor, size: [76, 0.025, 1.0], position: [0, -0.005, 8.1], mat: lane)

        for offset: Float in [-11, 11] {
            addBox(anchor, size: [6, 0.12, 76], position: [offset, -0.015, 0], mat: pavement)
            addBox(anchor, size: [76, 0.12, 6], position: [0, -0.015, offset], mat: pavement)
        }

        // Crosswalk stripes at the central intersection.
        for index in 0..<7 {
            let z = -4.8 + Float(index) * 1.6
            addBox(anchor, size: [0.22, 0.025, 0.9], position: [-4.8, 0.0, z], mat: lane)
            addBox(anchor, size: [0.22, 0.025, 0.9], position: [4.8, 0.0, z], mat: lane)
        }
    }

    private func addBuildings(to anchor: Entity) {
        let stone = material(UIColor(red: 0.25, green: 0.27, blue: 0.29, alpha: 1))
        let darkStone = material(UIColor(red: 0.15, green: 0.17, blue: 0.19, alpha: 1))
        let brick = material(UIColor(red: 0.30, green: 0.20, blue: 0.18, alpha: 1))
        let glass = material(UIColor(red: 0.09, green: 0.15, blue: 0.19, alpha: 1), metallic: true)
        let litGlass = material(UIColor(red: 0.72, green: 0.48, blue: 0.25, alpha: 1), metallic: false)

        let buildings: [(SIMD3<Float>, SIMD3<Float>, SimpleMaterial)] = [
            ([-22, 5, -21], [15, 10, 16], stone),
            ([22, 7, -21], [16, 14, 16], darkStone),
            ([-22, 4, 21], [15, 8, 16], brick),
            ([22, 6, 21], [16, 12, 16], stone),
            ([-34, 5, 0], [8, 10, 19], darkStone),
            ([34, 8, 0], [8, 16, 19], brick),
            ([0, 5, -34], [20, 10, 8], stone),
            ([0, 6, 34], [20, 12, 8], darkStone)
        ]

        for (index, item) in buildings.enumerated() {
            addBox(anchor, size: item.1, position: item.0, mat: item.2)
            addFacade(anchor, center: item.0, dimensions: item.1,
                      glass: index.isMultiple(of: 3) ? litGlass : glass)
        }

        // Rooftop parapets and simple shopfronts add depth to the street.
        addBox(anchor, size: [10, 0.65, 0.35], position: [-22, 10.35, -21], mat: darkStone)
        addBox(anchor, size: [11, 0.65, 0.35], position: [22, 14.35, -21], mat: darkStone)
        addBox(anchor, size: [6, 2.2, 0.18], position: [-22, 1.15, -12.8], mat: glass)
        addBox(anchor, size: [6, 2.2, 0.18], position: [22, 1.15, -12.8], mat: glass)
    }

    private func addFacade(_ parent: Entity, center: SIMD3<Float>, dimensions: SIMD3<Float>, glass: SimpleMaterial) {
        let floors = max(1, Int(dimensions.y / 2.8))
        let columns = max(2, Int(dimensions.x / 2.8))
        for floor in 0..<floors {
            for column in 0..<columns {
                let x = center.x - dimensions.x * 0.36 + Float(column) * 2.55
                let y = 1.5 + Float(floor) * 2.65
                let z = center.z + dimensions.z * 0.501
                addBox(parent, size: [0.78, 1.0, 0.055], position: [x, y, z], mat: glass)
            }
        }
    }

    private func addStreetDetails(to anchor: Entity) {
        let darkMetal = material(UIColor(red: 0.07, green: 0.08, blue: 0.09, alpha: 1), metallic: true)
        let warm = material(UIColor(red: 0.95, green: 0.66, blue: 0.32, alpha: 1), metallic: false)
        let red = material(UIColor(red: 0.54, green: 0.08, blue: 0.09, alpha: 1), metallic: false)

        for x: Float in [-13, 13] {
            for z: Float in [-13, 13] {
                addBox(anchor, size: [0.14, 4.0, 0.14], position: [x, 2.0, z], mat: darkMetal)
                addBox(anchor, size: [0.75, 0.20, 0.38], position: [x, 4.05, z], mat: warm)
            }
        }

        // Parked civilian vehicles, represented by low-poly body and cabin meshes.
        addParkedCar(anchor, position: [-14.4, 0.0, 5.0], body: darkMetal, cabin: glass)
        addParkedCar(anchor, position: [14.5, 0.0, -5.2], body: red, cabin: glass)
        addParkedCar(anchor, position: [-15.0, 0.0, -5.4], body: stoneMaterial(), cabin: glass)

        // Benches and planters near the sidewalks.
        for z: Float in [-4, 4] {
            addBox(anchor, size: [2.0, 0.22, 0.65], position: [-13.5, 0.55, z], mat: darkMetal)
            addBox(anchor, size: [1.8, 0.35, 1.1], position: [13.5, 0.22, z], mat: material(UIColor(red: 0.16, green: 0.22, blue: 0.16, alpha: 1)))
        }
    }

    private func addPoliceStationSign(to anchor: Entity) {
        let sign = material(UIColor(red: 0.12, green: 0.20, blue: 0.28, alpha: 1))
        addBox(anchor, size: [8.0, 1.0, 0.24], position: [0, 7.0, 30.0], mat: sign)
    }

    private func addPlayer(to anchor: Entity) {
        player = makeDetectiveAvatar(primary: UIColor(red: 0.10, green: 0.12, blue: 0.15, alpha: 1),
                                     skin: UIColor(red: 0.70, green: 0.50, blue: 0.37, alpha: 1))
        player.position = [0, 0.05, 5]
        anchor.addChild(player)
    }

    private func makeDetectiveAvatar(primary: UIColor, skin: UIColor) -> Entity {
        let avatar = Entity()
        let jacket = material(primary)
        let face = material(skin)
        let trousers = material(UIColor(red: 0.075, green: 0.085, blue: 0.10, alpha: 1))
        let shoes = material(UIColor(red: 0.035, green: 0.04, blue: 0.045, alpha: 1))

        let torso = ModelEntity(mesh: .generateBox(size: [0.62, 0.86, 0.34]), materials: [jacket])
        torso.position = [0, 0.92, 0]
        let head = ModelEntity(mesh: .generateSphere(radius: 0.19), materials: [face])
        head.position = [0, 1.52, -0.015]
        let leftLeg = ModelEntity(mesh: .generateBox(size: [0.22, 0.62, 0.25]), materials: [trousers])
        leftLeg.position = [-0.16, 0.30, 0]
        let rightLeg = ModelEntity(mesh: .generateBox(size: [0.22, 0.62, 0.25]), materials: [trousers])
        rightLeg.position = [0.16, 0.30, 0]
        let leftArm = ModelEntity(mesh: .generateBox(size: [0.17, 0.68, 0.20]), materials: [jacket])
        leftArm.position = [-0.40, 0.90, 0]
        leftArm.orientation = simd_quatf(angle: -0.10, axis: [0, 0, 1])
        let rightArm = ModelEntity(mesh: .generateBox(size: [0.17, 0.68, 0.20]), materials: [jacket])
        rightArm.position = [0.40, 0.90, 0]
        rightArm.orientation = simd_quatf(angle: 0.10, axis: [0, 0, 1])
        let leftShoe = ModelEntity(mesh: .generateBox(size: [0.24, 0.12, 0.38]), materials: [shoes])
        leftShoe.position = [-0.16, 0.05, -0.045]
        let rightShoe = ModelEntity(mesh: .generateBox(size: [0.24, 0.12, 0.38]), materials: [shoes])
        rightShoe.position = [0.16, 0.05, -0.045]

        for part in [torso, head, leftLeg, rightLeg, leftArm, rightArm, leftShoe, rightShoe] {
            avatar.addChild(part)
        }
        return avatar
    }

    func setMissionClues(_ clues: [EvidenceDefinition], collectedIDs: Set<String>) {
        pendingClues = clues
        pendingCollectedIDs = collectedIDs
        guard let anchor = worldAnchor else { return }
        clueMarkers.values.forEach { $0.removeFromParent() }
        clueMarkers.removeAll()

        let gold = material(UIColor(red: 0.92, green: 0.63, blue: 0.23, alpha: 1), metallic: true)
        let halo = material(UIColor(red: 0.52, green: 0.22, blue: 0.08, alpha: 1))
        for clue in clues where !collectedIDs.contains(clue.id) {
            let marker = Entity()
            marker.name = clue.id
            let base = ModelEntity(mesh: .generateBox(size: [0.75, 0.06, 0.75]), materials: [halo])
            base.position = [0, 0.08, 0]
            let item = ModelEntity(mesh: .generateBox(size: [0.32, 0.32, 0.32]), materials: [gold])
            item.position = [0, 0.32, 0]
            item.orientation = simd_quatf(angle: .pi / 4, axis: [0, 1, 0])
            marker.addChild(base)
            marker.addChild(item)
            marker.position = [clue.x, 0.03, clue.z]
            anchor.addChild(marker)
            clueMarkers[clue.id] = marker
        }
    }

    func removeClueMarker(id: String) {
        clueMarkers[id]?.removeFromParent()
        clueMarkers.removeValue(forKey: id)
    }

    func isNearClue(_ clue: EvidenceDefinition, radius: Float = 2.5) -> Bool {
        let dx = player.position.x - clue.x
        let dz = player.position.z - clue.z
        return dx * dx + dz * dz <= radius * radius
    }

    func move(x: Float, forward: Float) {
        guard hasBuiltWorld else { return }
        let input = SIMD2<Float>(x, forward)
        let length = simd_length(input)
        guard length > 0.04 else { return }
        let normalized = input / max(length, 1)

        let right = SIMD3<Float>(cos(cameraYaw), 0, sin(cameraYaw))
        let ahead = SIMD3<Float>(sin(cameraYaw), 0, -cos(cameraYaw))
        let direction = right * normalized.x + ahead * normalized.y
        let step: Float = 0.16
        let candidateX = max(-34, min(34, player.position.x + direction.x * step))
        let candidateZ = max(-34, min(34, player.position.z + direction.z * step))
        var nextX = player.position.x
        var nextZ = player.position.z
        if !isBlocked(x: candidateX, z: player.position.z) { nextX = candidateX }
        if !isBlocked(x: nextX, z: candidateZ) { nextZ = candidateZ }
        player.position = [nextX, player.position.y, nextZ]
        player.orientation = simd_quatf(angle: atan2(direction.x, -direction.z), axis: [0, 1, 0])
        updateCamera()
    }

    private func isBlocked(x: Float, z: Float) -> Bool {
        let buildings: [(Float, Float, Float, Float)] = [
            (-22, -21, 7.5, 8), (22, -21, 8, 8),
            (-22, 21, 7.5, 8), (22, 21, 8, 8),
            (-34, 0, 4.0, 9.5), (34, 0, 4.0, 9.5),
            (0, -34, 10, 4.0), (0, 34, 10, 4.0)
        ]
        for (centerX, centerZ, halfWidth, halfDepth) in buildings {
            if abs(x - centerX) < halfWidth + 0.65 && abs(z - centerZ) < halfDepth + 0.65 {
                return true
            }
        }
        return false
    }

    func rotateCamera(deltaX: Float) {
        cameraYaw += deltaX * 0.007
        updateCamera()
    }

    func updateRemotePlayer(id: String, x: Float, z: Float) {
        guard let anchor = worldAnchor, !id.isEmpty else { return }
        let avatar: Entity
        if let existing = remotePlayers[id] {
            avatar = existing
        } else {
            avatar = makeDetectiveAvatar(primary: UIColor(red: 0.13, green: 0.22, blue: 0.32, alpha: 1),
                                         skin: UIColor(red: 0.66, green: 0.47, blue: 0.35, alpha: 1))
            remotePlayers[id] = avatar
            anchor.addChild(avatar)
        }
        avatar.position = [max(-34, min(34, x)), 0.05, max(-34, min(34, z))]
    }

    func removeRemotePlayer(id: String) {
        remotePlayers[id]?.removeFromParent()
        remotePlayers.removeValue(forKey: id)
    }

    private func updateCamera() {
        guard let anchor = worldAnchor else { return }
        let target = player.position + SIMD3<Float>(0, 1.05, 0)
        let offset = SIMD3<Float>(sin(cameraYaw) * 7.2, 3.45, cos(cameraYaw) * 7.2)
        let cameraPosition = player.position + offset
        camera.position = cameraPosition
        camera.look(at: target, from: cameraPosition, relativeTo: anchor)
    }

    private func addParkedCar(_ parent: Entity, position: SIMD3<Float>, body: SimpleMaterial, cabin: SimpleMaterial) {
        let car = Entity()
        let chassis = ModelEntity(mesh: .generateBox(size: [2.0, 0.62, 3.8]), materials: [body])
        chassis.position = [0, 0.62, 0]
        let roof = ModelEntity(mesh: .generateBox(size: [1.55, 0.70, 1.85]), materials: [cabin])
        roof.position = [0, 1.23, -0.20]
        car.addChild(chassis)
        car.addChild(roof)
        car.position = position
        parent.addChild(car)
    }

    private func addBox(_ parent: Entity, size: SIMD3<Float>, position: SIMD3<Float>, mat: SimpleMaterial) {
        let entity = ModelEntity(mesh: .generateBox(size: size), materials: [mat])
        entity.position = position
        parent.addChild(entity)
    }

    private func material(_ color: UIColor, metallic: Bool = false) -> SimpleMaterial {
        SimpleMaterial(color: color, isMetallic: metallic)
    }

    private func stoneMaterial() -> SimpleMaterial {
        material(UIColor(red: 0.31, green: 0.33, blue: 0.35, alpha: 1), metallic: true)
    }
}
