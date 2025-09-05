//
//  NeonTicTacToe.swift
//  
//
//  Created by TheCodeAssassin on 9/5/25.
//

import SwiftUI

// UI constants for layout and styling
enum Constants {
    static let boardPadding: CGFloat = 8
    static let boardLineWidth: CGFloat = 2
    static let boardShadowRadius: CGFloat = 4
    static let cellSpacing: CGFloat = 8
    static let pieceLineWidth: CGFloat = 6
    static let pieceShadowRadius: CGFloat = 8
    static let winningShadowRadius: CGFloat = 15
    static let winningLineWidth: CGFloat = 8
    static let buttonCornerRadius: CGFloat = 20
    static let buttonLineWidth: CGFloat = 2
    static let buttonShadowRadius: CGFloat = 6
}

// Player enum for X and O
enum Player: String, CaseIterable {
    case x = "X"
    case o = "O"
}

// Neon effect for UI elements
struct NeonStyle: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .foregroundColor(color)
            .shadow(color: color, radius: radius)
    }
}

// Main Tic-Tac-Toe view
struct TicTacToeView: View {
    @StateObject private var game = TicTacToeGame()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    // Scoreboard
                    HStack(spacing: 40) {
                        VStack {
                            Text(Player.x.rawValue)
                                .font(.system(size: 24, weight: .bold))
                                .modifier(NeonStyle(color: .cyan, radius: Constants.pieceShadowRadius))
                                .accessibilityLabel("Player X")
                            Text("\(game.xScore)")
                                .font(.system(size: 32, weight: .bold))
                                .modifier(NeonStyle(color: .cyan, radius: Constants.pieceShadowRadius))
                                .accessibilityLabel("X score \(game.xScore)")
                        }

                        Text("VS")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .accessibilityHidden(true)

                        VStack {
                            Text(Player.o.rawValue)
                                .font(.system(size: 24, weight: .bold))
                                .modifier(NeonStyle(color: .pink, radius: Constants.pieceShadowRadius))
                                .accessibilityLabel("Player O")
                            Text("\(game.oScore)")
                                .font(.system(size: 32, weight: .bold))
                                .modifier(NeonStyle(color: .pink, radius: Constants.pieceShadowRadius))
                                .accessibilityLabel("O score \(game.oScore)")
                        }
                    }
                    .padding(.top, 20)

                    // Game status text
                    Text(game.gameStatus)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .modifier(NeonStyle(color: game.currentPlayer == .x ? .cyan : .pink, radius: Constants.winningShadowRadius))
                        .animation(.easeInOut(duration: 0.3), value: game.currentPlayer)
                        .accessibilityLabel(game.gameStatus)

                    // Game board
                    GameBoard(game: game)
                        .frame(width: min(geometry.size.width - 60, 300),
                               height: min(geometry.size.width - 60, 300))

                    // Control buttons
                    HStack(spacing: 20) {
                        Button(action: game.reset) {
                            Text("New Game")
                                .font(.system(size: 16, weight: .semibold))
                                .modifier(NeonStyle(color: .cyan, radius: Constants.buttonShadowRadius))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: Constants.buttonCornerRadius)
                                        .stroke(Color.cyan, lineWidth: Constants.buttonLineWidth)
                                )
                        }
                        .accessibilityLabel("Start new game")

                        Button(action: game.resetScore) {
                            Text("Reset Score")
                                .font(.system(size: 16, weight: .semibold))
                                .modifier(NeonStyle(color: .purple, radius: Constants.buttonShadowRadius))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: Constants.buttonCornerRadius)
                                        .stroke(Color.purple, lineWidth: Constants.buttonLineWidth)
                                )
                        }
                        .accessibilityLabel("Reset scores")
                    }

                    Spacer()
                }
            }
        }
    }
}

// Board view with grid and pieces
struct GameBoard: View {
    @ObservedObject var game: TicTacToeGame

    var body: some View {
        ZStack {
            // Draw horizontal lines
            VStack(spacing: 0) {
                ForEach(0..<4) { row in
                    Rectangle()
                        .fill(Color.purple)
                        .frame(height: Constants.boardLineWidth)
                        .shadow(color: .purple, radius: Constants.boardShadowRadius)
                        .opacity(row == 0 || row == 3 ? 0 : 1)
                    if row < 3 { Spacer() }
                }
            }

            // Draw vertical lines
            HStack(spacing: 0) {
                ForEach(0..<4) { col in
                    Rectangle()
                        .fill(Color.purple)
                        .frame(width: Constants.boardLineWidth)
                        .shadow(color: .purple, radius: Constants.boardShadowRadius)
                        .opacity(col == 0 || col == 3 ? 0 : 1)
                    if col < 3 { Spacer() }
                }
            }

            // Game cells
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Constants.cellSpacing) {
                ForEach(0..<9, id: \.self) { index in
                    GameCell(
                        player: game.board[index],
                        isWinningCell: game.winningLine?.contains(index) ?? false
                    ) {
                        game.makeMove(at: index)
                    }
                }
            }
            .padding(Constants.boardPadding)

            // Winning line overlay
            if let winningLine = game.winningLine {
                WinningLineView(winningLine: winningLine, winner: game.winner!)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Game board")
    }
}

// Individual cell in the board
struct GameCell: View {
    let player: Player?
    let isWinningCell: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Rectangle()
                    .fill(Color.clear)
                    .aspectRatio(1, contentMode: .fit)
                if let player = player {
                    PlayerPiece(player: player, isWinning: isWinningCell)
                }
            }
        }
        .disabled(player != nil)
        .accessibilityLabel(player == nil ? "Empty cell" : "\(player!.rawValue) cell")
    }
}

// Renders X or O piece with animation
struct PlayerPiece: View {
    let player: Player
    let isWinning: Bool
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        Group {
            if player == .x {
                XShape()
                    .stroke(Color.cyan, lineWidth: Constants.pieceLineWidth)
                    .modifier(NeonStyle(color: .cyan, radius: isWinning ? Constants.winningShadowRadius : Constants.pieceShadowRadius))
            } else {
                Circle()
                    .stroke(Color.pink, lineWidth: Constants.pieceLineWidth)
                    .modifier(NeonStyle(color: .pink, radius: isWinning ? Constants.winningShadowRadius : Constants.pieceShadowRadius))
                    .padding(10)
            }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .scaleEffect(isWinning ? 1.1 : 1.0)
        .animation(.spring(response: 0.4), value: isWinning)
        .onAppear {
            // Animate piece appearance
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// Custom shape for X piece
struct XShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset: CGFloat = rect.width * 0.2
        path.move(to: CGPoint(x: inset, y: inset))
        path.addLine(to: CGPoint(x: rect.width - inset, y: rect.height - inset))
        path.move(to: CGPoint(x: rect.width - inset, y: inset))
        path.addLine(to: CGPoint(x: inset, y: rect.height - inset))
        return path
    }
}

// Draws animated winning line
struct WinningLineView: View {
    let winningLine: [Int]
    let winner: Player
    @State private var lineProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard let start = cellCenter(for: winningLine[0], in: geometry),
                      let end = cellCenter(for: winningLine[2], in: geometry) else {
                    return
                }
                let currentEnd = CGPoint(
                    x: start.x + (end.x - start.x) * lineProgress,
                    y: start.y + (end.y - start.y) * lineProgress
                )
                path.move(to: start)
                path.addLine(to: currentEnd)
            }
            .stroke(
                winner == .x ? Color.cyan : Color.pink,
                style: StrokeStyle(lineWidth: Constants.winningLineWidth, lineCap: .round)
            )
            .modifier(NeonStyle(color: winner == .x ? .cyan : .pink, radius: Constants.winningShadowRadius))
        }
        .onAppear {
            // Animate line drawing
            withAnimation(.easeInOut(duration: 0.8)) {
                lineProgress = 1.0
            }
        }
        .accessibilityHidden(true)
    }

    // Calculates center of a cell for line drawing
    private func cellCenter(for index: Int, in geometry: GeometryProxy) -> CGPoint? {
        let cellSize = (geometry.size.width - Constants.boardPadding * 2) / 3
        let row = index / 3
        let col = index % 3
        let x = Constants.boardPadding + cellSize * CGFloat(col) + cellSize / 2
        let y = Constants.boardPadding + cellSize * CGFloat(row) + cellSize / 2
        return CGPoint(x: x, y: y)
    }
}

// Game logic and state
@MainActor
class TicTacToeGame: ObservableObject {
    @Published var board: [Player?] = Array(repeating: nil, count: 9) // Board state
    @Published var currentPlayer: Player = .x // Whose turn
    @Published var winner: Player? // Winner if any
    @Published var winningLine: [Int]? // Indices of winning cells
    @Published var xScore: Int = 0 // Score for X
    @Published var oScore: Int = 0 // Score for O

    // Checks if game is over
    var isGameOver: Bool {
        winner != nil || board.allSatisfy { $0 != nil }
    }

    // Status text for UI
    var gameStatus: String {
        if let winner = winner {
            return "\(winner.rawValue) Wins!"
        } else if board.allSatisfy({ $0 != nil }) {
            return "It's a Tie!"
        } else {
            return "\(currentPlayer.rawValue)'s Turn"
        }
    }

    // Handles a move
    func makeMove(at index: Int) {
        guard board[index] == nil && !isGameOver else { return }
        board[index] = currentPlayer
        if let line = checkForWin() {
            winner = currentPlayer
            winningLine = line
            updateScore()
        } else {
            currentPlayer = currentPlayer == .x ? .o : .x
        }
    }

    // Resets board for new game
    func reset() {
        board = Array(repeating: nil, count: 9)
        currentPlayer = .x
        winner = nil
        winningLine = nil
    }

    // Resets scores
    func resetScore() {
        xScore = 0
        oScore = 0
    }

    // Updates score for winner
    private func updateScore() {
        if winner == .x {
            xScore += 1
        } else if winner == .o {
            oScore += 1
        }
    }

    // Checks for a win and returns winning line
    private func checkForWin() -> [Int]? {
        let winPatterns = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
            [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
            [0, 4, 8], [2, 4, 6]             // Diagonals
        ]
        for pattern in winPatterns {
            let positions = pattern.compactMap { board[$0] }
            if positions.count == 3 && positions.allSatisfy({ $0 == currentPlayer }) {
                return pattern
            }
        }
        return nil
    }
}
