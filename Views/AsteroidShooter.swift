//
//  AsteroidShooter.swift
//
//
//  Created by TheCodeAssassin on 9/6/25.
//

import SwiftUI
import Combine

// MARK: - Game Models
struct Bullet: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGFloat = 5.0
}

struct SpaceRock: Identifiable {
    let id = UUID()
    var position: CGPoint
    var isAlive: Bool = true
    var fallSpeed: CGFloat = 3
    var rotationAngle: Double = 0
    var size: CGFloat
}

// MARK: - Game State
@MainActor
class GameState: ObservableObject {
    @Published var playerPosition: CGFloat = 0
    @Published var bullets: [Bullet] = []
    @Published var spaceRocks: [SpaceRock] = []
    @Published var score: Int = 0
    @Published var isGameOver: Bool = false
    @Published var gameWon: Bool = false
    @Published var lives: Int = 3

    private var gameTimer: AnyCancellable?
    private var rockSpawnTimer: AnyCancellable?
    private var screenWidth: CGFloat = 400
    private var lastFireTime: Date = .distantPast
    private let fireCooldown: TimeInterval = 0.3


    func startGame(screenWidth: CGFloat) {
        self.screenWidth = screenWidth
        resetGame()
        startGameLoop()
        startRockSpawning()
    }

    private func resetGame() {
        playerPosition = 0
        bullets = []
        spaceRocks = []
        score = 0
        isGameOver = false
        gameWon = false
        lives = 3
    }

    private func startGameLoop() {
        gameTimer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateGame()
            }
    }

    private func startRockSpawning() {
        rockSpawnTimer = Timer.publish(every: 1, on: .main, in: .common) // Faster spawning
            .autoconnect()
            .sink { [weak self] _ in
                self?.spawnSpaceRock()
            }
    }

    private func spawnSpaceRock() {
        guard !isGameOver && !gameWon else { return }

        // Use full screen width for spawning (player can reach edges)
        let rockMaxPosition = screenWidth / 2 - 30 // Ensure rocks spawn within screen bounds
        let rockX = CGFloat.random(in: -rockMaxPosition...rockMaxPosition)
        let rockSize = CGFloat.random(in: 30...55)
        let fallSpeed = CGFloat.random(in: 6.0...10.0)

        let rock = SpaceRock(
            position: CGPoint(x: rockX, y: -400),
            fallSpeed: fallSpeed,
            rotationAngle: Double.random(in: 0...360),
            size: rockSize
        )

        spaceRocks.append(rock)
    }

    private func updateGame() {
        guard !isGameOver && !gameWon else { return }

        updateBullets()
        updateSpaceRocks()
        checkCollisions()
        checkRockReachedBottom()
        checkGameEnd()
    }

    private func updateBullets() {
        for i in bullets.indices {
            bullets[i].position.y -= bullets[i].velocity
        }
        bullets.removeAll { $0.position.y < -400 }
    }

    private func updateSpaceRocks() {
        for i in spaceRocks.indices {
            spaceRocks[i].position.y += spaceRocks[i].fallSpeed
            spaceRocks[i].rotationAngle += 2.0
        }
    }

    private func checkCollisions() {
        var rocksToRemove: Set<UUID> = []
        var bulletsToRemove: Set<UUID> = []

        for bullet in bullets {
            for rock in spaceRocks {
                if rock.isAlive && abs(bullet.position.x - rock.position.x) < rock.size &&
                   abs(bullet.position.y - rock.position.y) < rock.size {
                    rocksToRemove.insert(rock.id)
                    bulletsToRemove.insert(bullet.id)
                    score += 10
                }
            }
        }

        spaceRocks.removeAll { rocksToRemove.contains($0.id) }
        bullets.removeAll { bulletsToRemove.contains($0.id) }
    }

    private func checkRockReachedBottom() {
        var rocksToRemove: Set<UUID> = []

        for rock in spaceRocks {
            if rock.position.y > 400 {
                rocksToRemove.insert(rock.id)
                lives -= 1

                withAnimation(.easeInOut(duration: 0.3)) {
                    // Visual feedback for life lost
                }
            }
        }

        spaceRocks.removeAll { rocksToRemove.contains($0.id) }
    }

    private func checkGameEnd() {
        if lives <= 0 {
            isGameOver = true
            gameTimer?.cancel()
            rockSpawnTimer?.cancel()
            return
        }

        if score >= 1000 { // Win condition: reach 1000 points
            gameWon = true
            gameTimer?.cancel()
            rockSpawnTimer?.cancel()
        }
    }

    func fireBullet() {
        let now = Date()
        guard now.timeIntervalSince(lastFireTime) > fireCooldown else { return }
        lastFireTime = now

        let bullet = Bullet(position: CGPoint(x: playerPosition, y: 325))
        bullets.append(bullet)
    }

    func stopGame() {
        gameTimer?.cancel()
        rockSpawnTimer?.cancel()
    }
}

// MARK: - Main Game View
struct GameView: View {
    @StateObject private var gameState = GameState()
    @State private var joystickOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                StarFieldView()

                if !gameState.isGameOver && !gameState.gameWon {
                    PlayerShipView(position: gameState.playerPosition)

                    ForEach(gameState.spaceRocks) { rock in
                        SpaceRockView(rock: rock)
                    }

                    ForEach(gameState.bullets) { bullet in
                        BulletView(bullet: bullet)
                    }
                }

                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Score: \(gameState.score)")
                                .font(.title2)
                                .foregroundColor(.cyan)
                                .shadow(color: .cyan, radius: 4)

                            HStack {
                                Text("Lives:")
                                    .font(.title3)
                                    .foregroundColor(.white)

                                ForEach(0..<gameState.lives, id: \.self) { _ in
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.red)
                                        .shadow(color: .red, radius: 3)
                                }

                                ForEach(0..<(3 - gameState.lives), id: \.self) { _ in
                                    Image(systemName: "heart")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, 50) // Add top padding to move below safe area
                    .padding(.horizontal)

                    Spacer()

                    HStack {
                        JoystickView(offset: $joystickOffset) { offset in
                            let maxPosition = geometry.size.width / 2 - 30
                            gameState.playerPosition = min(max(offset.width * 7, -maxPosition), maxPosition)
                        }

                        Spacer()

                        FireButtonView {
                            gameState.fireBullet()
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }

                if gameState.isGameOver || gameState.gameWon {
                    GameOverView(
                        isWon: gameState.gameWon,
                        score: gameState.score,
                        reason: gameState.lives <= 0 ? "Hit by Space Rock" : "Target Score Reached!"
                    ) {
                        gameState.startGame(screenWidth: geometry.size.width)
                    }
                }
            }
            .onAppear {
                gameState.startGame(screenWidth: geometry.size.width)
            }
            .onDisappear {
                gameState.stopGame()
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}

// MARK: - Component Views
struct StarFieldView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<100, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.3...0.8)))
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
        }
    }
}

struct PlayerShipView: View {
    let position: CGFloat

    var body: some View {
        GeometryReader { geometry in
            Image("ship")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .shadow(color: .cyan, radius: 6)
                .position(x: geometry.size.width/2 + position, y: 650)
                .animation(.easeOut(duration: 0.1), value: position)
        }
    }
}

struct SpaceRockView: View {
    let rock: SpaceRock
    @State private var rotationSpeed: Double = 0

    var body: some View {
        GeometryReader { geometry in
            Image("rock")
                .resizable()
                .scaledToFit()
                .frame(width: rock.size, height: rock.size)
                .rotationEffect(.degrees(rock.rotationAngle + rotationSpeed))
                .shadow(color: .black.opacity(0.8), radius: 8, x: 3, y: 3)
                .position(x: geometry.size.width/2 + rock.position.x, y: 300 + rock.position.y)
                .onAppear {
                    rotationSpeed = Double.random(in: -4...4)
                }
        }
    }
}


struct BulletView: View {
    let bullet: Bullet

    var body: some View {
        GeometryReader { geometry in
            Capsule()
                .fill(Color.yellow)
                .frame(width: 3, height: 12)
                .shadow(color: .yellow, radius: 3)
                .position(x: geometry.size.width/2 + bullet.position.x, y: 300 + bullet.position.y)
        }
    }
}

struct JoystickView: View {
    @Binding var offset: CGSize
    let onDrag: (CGSize) -> Void

    private let baseSize: CGFloat = 80
    private let thumbSize: CGFloat = 30

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: baseSize, height: baseSize)
                .overlay(
                    Circle()
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 2)
                )

            Circle()
                .fill(Color.cyan)
                .frame(width: thumbSize, height: thumbSize)
                .shadow(color: .cyan, radius: 4)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let distance = sqrt(value.translation.width * value.translation.width + value.translation.height * value.translation.height)
                            let maxDistance = (baseSize - thumbSize) / 2

                            if distance <= maxDistance {
                                offset = CGSize(width: value.translation.width, height: 0)
                            } else {
                                let angle = atan2(value.translation.height, value.translation.width)
                                offset = CGSize(
                                    width: cos(angle) * maxDistance,
                                    height: 0
                                )
                            }
                            onDrag(offset)
                        }
                        .onEnded { _ in
                            withAnimation(.spring()) {
                                offset = .zero
                            }
                            onDrag(.zero)
                        }
                )
        }
    }
}

struct FireButtonView: View {
    let onFire: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            onFire()
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.red, .red.opacity(0.7)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .shadow(color: .red, radius: isPressed ? 15 : 8)
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .overlay(
                    Text("FIRE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
        }
    }
}

struct GameOverView: View {
    let isWon: Bool
    let score: Int
    let reason: String
    let onRestart: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(isWon ? "VICTORY!" : "GAME OVER")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(isWon ? .green : .red)
                    .shadow(color: isWon ? .green : .red, radius: 10)

                Text(reason)
                    .font(.title3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Final Score: \(score)")
                    .font(.title2)
                    .foregroundColor(.cyan)
                    .shadow(color: .cyan, radius: 5)

                Button(action: onRestart) {
                    Text("PLAY AGAIN")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.blue)
                                .shadow(color: .blue, radius: 8)
                        )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.9))
                    .stroke(Color.cyan, lineWidth: 2)
            )
        }
    }
}
