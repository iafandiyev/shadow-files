import Foundation
import RealityKit
import UIKit
import simd

@MainActor
final class GameSceneController {
    private weak var arView: ARView?
    private var worldAnchor: AnchorEntity?
    private var player = Entity()
    private var camera = PerspectiveCamera()
    private var remotePlayers: [String: Entity] = [:]
    private var hasBuiltWorld = false

    var playerPosition: SIMD3<Float> { player.position }

    func attach(to view: ARView) {
        arView = view
        guard !hasBuiltWorld else { return }
        buildWorld(in: view)
        hasBuiltWorld = true
    }

    private func buildWorld(in view: ARView) {
        let anchor = AnchorEntity(world: .zero)
        worldAnchor = anchor

        let sun = DirectionalLight()
        sun.light = DirectionalLightComponent(color: .white, intensity: 1500)
        sun.position = [0, 18, 0]
        sun.orientation = simd_quatf(angle: -.pi / 3, axis: [1, 0, 0])
        anchor.addChild(sun)

        let asphalt = material(UIColor(red: 0.105, green: 0.12, blue: 0.14, alpha: 1))
        let concrete = material(UIColor(red: 0.24, green: 0.25, blue: 0.26, alpha: 1))
        let buildingA = material(UIColor(red: 0.25, green: 0.27, blue: 0.30, alpha: 1))
        let buildingB = material(UIColor(red: 0.19, green: 0.21, blue: 0.24, alpha: 1))
        let warmWindow = material(UIColor(red: 0.95, green: 0.68, blue: 0.32, alpha: 1))
        let darkWindow = material(UIColor(red: 0.055, green: 0.075, blue: 0.09, alpha: 1))
        let sidewalk = material(UIColor(red: 0.34, green: 0.35, blue: 0.36, alpha: 1))

        addBox(to: anchor, size: [70, 0.12, 70], position: [0, -0.12, 0], material: concrete)
        addBox(to: anchor, size: [13, 0.04, 70], position: [0, -0.035, 0], material: asphalt)
        addBox(to: anchor, size: [70, 0.04, 13], position: [0, -0.03, 0], material: asphalt)
        addBox(to: anchor, size: [2.5, 0.045, 70], position: [0, -0.005, 0], material: darkWindow)
        addBox(to: anchor, size: [70, 0.045, 2.5], position: [0, 0, 0], material: darkWindow)

        // Sidewalks frame the central intersection.
        addBox(to: anchor, size: [7, 0.12, 70], position: [-10, 0.02, 0], material: sidewalk)
        addBox(to: anchor, size: [7, 0.12, 70], position: [10, 0.02, 0], material: sidewalk)
        addBox(to: anchor, size: [70, 0.12, 7], position: [0, 0.02, -10], material: sidewalk)
        addBox(to: anchor, size: [70, 0.12, 7], position: [0, 0.02, 10], material: sidewalk)

        let buildings: [(SIMD3<Float>, SIMD3<Float>, SimpleMaterial)] = [
            ([-19, 5, -18], [12, 10, 13], buildingA),
            ([19, 7, -18], [13, 14, 12], buildingB),
            ([-20, 4, 18], [11, 8, 14], buildingB),
            ([20, 6, 18], [12, 12, 14], buildingA),
            ([-31, 5, -2], [8, 10, 17], buildingA),
            ([31, 8, 1], [8, 16, 18], buildingB),
            ([-2, 4, -30], [15, 8, 8], buildingB),
            ([2, 6, 30], [17, 12, 8], buildingA)
        ]

        for (index, building) in buildings.enumerated() {
            addBox(to: anchor, size: building.1, position: building.0, material: building.2)
            addFacadeWindows(
                to: anchor,
                center: building.0,
                dimensions: building.1,
                windowMaterial: index.isMultiple(of: 2) ? warmWindow : darkWindow
            )
        }

        // Street lamps and small roadside details.
        for x: Float in [-13, 13] {
            for z: Float in [-13, 13] {
                addBox(to: anchor, size: [0.16, 3.5, 0.16], position: [x, 1.8, z], material: darkWindow)
                addBox(to: anchor, size: [0.65, 0.18, 0.35], position: [x, 3.55, z], material: warmWindow)
            }
        }

        addPlayer(to: anchor)

        camera.position = [0, 3.4, 7.5]
        anchor.addChild(camera)
        camera.look(at: [0, 1, 0], from: camera.position, relativeTo: anchor)

        view.scene.anchors.append(anchor)
        updateCamera()
    }

    private func addPlayer(to anchor: AnchorEntity) {
        player = Entity()
        player.position = [0, 0.05, 5]

        let coat = material(UIColor(red: 0.10, green: 0.12, blue: 0.15, alpha: 1))
        let skin = material(UIColor(red: 0.72, green: 0.54, blue: 0.40, alpha: 1))

        // Use generateBox instead of generateCylinder: generateCylinder is iOS 18+,
        // while this project supports iOS 17 and newer.
        let torso = ModelEntity(mesh: .generateBox(size: [0.48, 0.85, 0.34]), materials: [coat])
        torso.position = [0, 0.88, 0]
        let head = ModelEntity(mesh: .generateSphere(radius: 0.19), materials: [skin])
        head.position = [0, 1.48, 0]
        let legs = ModelEntity(mesh: .generateBox(size: [0.43, 0.55, 0.25]), materials: [coat])
        legs.position = [0, 0.27, 0]

        player.addChild(torso)
        player.addChild(head)
        player.addChild(legs)
        anchor.addChild(player)
    }

    private func addFacadeWindows(
        to anchor: Entity,
        center: SIMD3<Float>,
        dimensions: SIMD3<Float>,
        windowMaterial: SimpleMaterial
    ) {
        let floors = max(1, Int(dimensions.y / 3.0))
        let columns = max(1, Int(dimensions.x / 3.0))
        for floor in 0..<floors {
            for column in 0..<columns {
                let x = center.x - dimensions.x * 0.32 + Float(column) * 2.6
                let y = 1.4 + Float(floor) * 2.6
                let z = center.z + dimensions.z * 0.501
                addBox(to: anchor, size: [0.75, 1.05, 0.045], position: [x, y, z], material: windowMaterial)
            }
        }
    }

    private func addBox(
        to parent: Entity,
        size: SIMD3<Float>,
        position: SIMD3<Float>,
        material: SimpleMaterial
    ) {
        let entity = ModelEntity(mesh: .generateBox(size: size), materials: [material])
        entity.position = position
        parent.addChild(entity)
    }

    private func material(_ color: UIColor) -> SimpleMaterial {
        SimpleMaterial(color: color, isMetallic: false)
    }

    func move(x: Float, z: Float) {
        guard hasBuiltWorld else { return }
        let magnitude = min(1, sqrt(x * x + z * z))
        guard magnitude > 0.02 else { return }

        let speed: Float = 0.22
        let nextX = max(-29, min(29, player.position.x + x * speed))
        let nextZ = max(-29, min(29, player.position.z + z * speed))
        player.position = [nextX, player.position.y, nextZ]
        player.orientation = simd_quatf(angle: atan2(x, z), axis: [0, 1, 0])
        updateCamera()
    }

    func updateRemotePlayer(id: String, x: Float, z: Float) {
        guard let anchor = worldAnchor, !id.isEmpty else { return }
        let entity: Entity
        if let existing = remotePlayers[id] {
            entity = existing
        } else {
            entity = makeRemoteAvatar()
            remotePlayers[id] = entity
            anchor.addChild(entity)
        }
        entity.position = [max(-29, min(29, x)), 0.05, max(-29, min(29, z))]
    }

    func removeRemotePlayer(id: String) {
        remotePlayers[id]?.removeFromParent()
        remotePlayers.removeValue(forKey: id)
    }

    private func makeRemoteAvatar() -> Entity {
        let avatar = Entity()
        let jacket = material(UIColor(red: 0.16, green: 0.25, blue: 0.34, alpha: 1))
        let skin = material(UIColor(red: 0.68, green: 0.49, blue: 0.37, alpha: 1))

        // Keep remote avatars compatible with the iOS 17 deployment target.
        let torso = ModelEntity(mesh: .generateBox(size: [0.48, 0.85, 0.34]), materials: [jacket])
        torso.position = [0, 0.88, 0]
        let head = ModelEntity(mesh: .generateSphere(radius: 0.19), materials: [skin])
        head.position = [0, 1.48, 0]
        let legs = ModelEntity(mesh: .generateBox(size: [0.43, 0.55, 0.25]), materials: [jacket])
        legs.position = [0, 0.27, 0]

        avatar.addChild(torso)
        avatar.addChild(head)
        avatar.addChild(legs)
        return avatar
    }

    private func updateCamera() {
        guard let anchor = worldAnchor else { return }
        let target = player.position + SIMD3<Float>(0, 1.1, 0)
        let cameraPosition = player.position + SIMD3<Float>(0, 3.5, 7.2)
        camera.position = cameraPosition
        camera.look(at: target, from: cameraPosition, relativeTo: anchor)
    }
}
