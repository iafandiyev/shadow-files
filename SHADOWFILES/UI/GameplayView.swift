import SwiftUI
import RealityKit
import UIKit

struct GameplayView: View {
    @EnvironmentObject private var game: GameEngine
    @State private var lastCameraTranslation: CGFloat = 0

    var body: some View {
        ZStack {
            RealityGameView(controller: game.scene)
                .ignoresSafeArea()

            cameraGestureLayer

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GREYWOOD  ·  \(game.currentMission.district)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(Color(red: 0.88, green: 0.28, blue: 0.24))
                        Text(game.currentMission.title)
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    hudButton("CASE FILE", icon: "folder.fill") { game.showingCaseFile = true }
                    hudButton("INTERROGATE", icon: "person.text.rectangle") { game.showingInterrogation = true }
                        .disabled(!game.canInterrogate)
                    hudButton("PAUSE", icon: "pause.fill") { game.returnToMenu() }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)

                Spacer()

                HStack(alignment: .bottom) {
                    VirtualJoystick { x, forward in game.movePlayer(x: x, forward: forward) }
                        .frame(width: 136, height: 136)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 9) {
                        Text(game.missionObjective)
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.black.opacity(0.72))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .frame(maxWidth: 260)

                        if !game.investigationMessage.isEmpty {
                            Text(game.investigationMessage)
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.42))
                                .padding(8)
                                .background(.black.opacity(0.64))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .frame(maxWidth: 260)
                        }

                        Button { game.investigateCurrentArea() } label: {
                            Label("SEARCH AREA", systemImage: "magnifyingglass")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .padding(.horizontal, 17)
                                .frame(height: 46)
                                .background(Color(red: 0.53, green: 0.11, blue: 0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $game.showingCaseFile) { CaseFileView() }
        .sheet(isPresented: $game.showingInterrogation) { InterrogationView() }
        .statusBarHidden()
    }

    private var cameraGestureLayer: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                Color.clear.frame(width: proxy.size.width * 0.48)
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 2)
                            .onChanged { value in
                                let delta = value.translation.width - lastCameraTranslation
                                lastCameraTranslation = value.translation.width
                                game.rotateCamera(deltaX: Float(delta))
                            }
                            .onEnded { _ in lastCameraTranslation = 0 }
                    )
            }
        }
        .ignoresSafeArea()
    }

    private func hudButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .padding(.horizontal, 11)
                .frame(height: 38)
                .background(.black.opacity(0.68))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(.white.opacity(0.16), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }
}

struct RealityGameView: UIViewRepresentable {
    let controller: CityScene

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        controller.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

struct VirtualJoystick: View {
    let onMove: (Float, Float) -> Void
    @State private var knob = CGSize.zero

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle()
                    .fill(.black.opacity(0.42))
                    .overlay(Circle().stroke(.white.opacity(0.28), lineWidth: 1.5))
                Circle()
                    .fill(.white.opacity(0.19))
                    .frame(width: diameter * 0.38, height: diameter * 0.38)
                    .overlay(Circle().stroke(.white.opacity(0.62), lineWidth: 1))
                    .offset(knob)
            }
            .frame(width: diameter, height: diameter)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let maxRadius = diameter * 0.29
                        let dx = value.translation.width
                        let dy = value.translation.height
                        let length = max(1, sqrt(dx * dx + dy * dy))
                        let scale = min(1, maxRadius / length)
                        knob = CGSize(width: dx * scale, height: dy * scale)
                        onMove(Float(knob.width / maxRadius), Float(-knob.height / maxRadius))
                    }
                    .onEnded { _ in
                        knob = .zero
                        onMove(0, 0)
                    }
            )
        }
    }
}
