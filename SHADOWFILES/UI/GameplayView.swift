import SwiftUI
import RealityKit

struct GameplayView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ZStack {
            RealityGameView(controller: game.sceneController)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("GREYWOOD · CASE 001")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1.4)
                            .foregroundStyle(.red.opacity(0.95))
                        Text(game.missionTitle)
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Button { game.showingInvestigation = true } label: {
                        Label("CASE FILE", systemImage: "folder.fill")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(12)
                            .background(.black.opacity(0.65))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Button { game.returnToMenu() } label: {
                        Image(systemName: "pause.fill")
                            .padding(12)
                            .background(.black.opacity(0.65))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)

                Spacer()

                HStack(alignment: .bottom) {
                    VirtualJoystick { x, z in game.movePlayer(x: x, z: z) }
                        .frame(width: 142, height: 142)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 10) {
                        Text(game.missionObjective)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(.black.opacity(0.68))
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .frame(maxWidth: 205)

                        Button {
                            game.investigateCurrentArea()
                        } label: {
                            Label("SEARCH AREA", systemImage: "magnifyingglass")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .padding(.horizontal, 16)
                                .frame(height: 48)
                                .background(Color(red: 0.55, green: 0.12, blue: 0.13))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
        .sheet(isPresented: $game.showingInvestigation) { InvestigationView() }
        .statusBarHidden()
    }
}

struct RealityGameView: UIViewRepresentable {
    let controller: GameSceneController

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
                    .fill(.black.opacity(0.43))
                    .overlay(Circle().stroke(.white.opacity(0.23), lineWidth: 1.5))
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: diameter * 0.38, height: diameter * 0.38)
                    .overlay(Circle().stroke(.white.opacity(0.65), lineWidth: 1))
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
                        onMove(Float(knob.width / maxRadius), Float(knob.height / maxRadius))
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.65)) {
                            knob = .zero
                        }
                    }
            )
        }
    }
}
