//
//  SudokuDojo.swift
//
//
//  Created by TheCodeAssassin on 9/3/25.
//

import SwiftUI

struct CellState {
    let value: Int?
    let isGiven: Bool
    let isSelected: Bool
    let isWrong: Bool
}

struct GameButton: View {
    let title: String
    let color: Color
    let width: CGFloat
    let height: CGFloat
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: width, height: height)
                .background(isSelected ? color : color.opacity(0.5))
                .cornerRadius(8)
                .shadow(radius: 3)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(0.95)
        .animation(.easeOut(duration: 0.1), value: false)
    }
}

struct NumberButton: View {
    let number: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color.blue.opacity(0.8))
                .frame(width: 45, height: 45)
                .overlay(
                    Text("\(number)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
                .shadow(radius: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DojoButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.orange : Color.gray.opacity(0.3))
                    .cornerRadius(8)
            )
            .foregroundColor(isSelected ? .white : .primary)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SudokuDojoMainView: View {
    @StateObject private var gameState = GameState()

    var body: some View {
        VStack(spacing: 0) {
            dojoHeaderPlaceholder
            Spacer()
            BoardView(gameState: gameState)
            Spacer()
            NumberPadView(gameState: gameState)
                .padding(.bottom, 20)
        }
        .background(dojoBackgroundPlaceholder)
        .ignoresSafeArea(.all, edges: .bottom)
    }

    private var dojoHeaderPlaceholder: some View {
        VStack {
            Rectangle()
                .fill(Color.black.opacity(0.8))
                .frame(height: 100)
                .overlay(
                    HStack(spacing: 16) {
                        Image("assassin")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 85, height: 85)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(radius: 4)
                        Text("SUDOKU DOJO ⚔️")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                )
            HStack(spacing: 15) {
                Button("Apprentice (4x4)") {
                    withAnimation(.easeOut(duration: 0.5)) {
                        gameState.switchToLevel(4)
                    }
                }
                .buttonStyle(DojoButtonStyle(isSelected: gameState.boardSize == 4))

                Button("Warrior (6x6)") {
                    withAnimation(.easeOut(duration: 0.5)) {
                        gameState.switchToLevel(6)
                    }
                }
                .buttonStyle(DojoButtonStyle(isSelected: gameState.boardSize == 6))

                Button("Assassin (9x9)") {
                    withAnimation(.easeOut(duration: 0.5)) {
                        gameState.switchToLevel(9)
                    }
                }
                .buttonStyle(DojoButtonStyle(isSelected: gameState.boardSize == 9))
            }
            .padding(.vertical, 10)
        }
    }

    private var dojoBackgroundPlaceholder: some View {
        Image("backgroundImage") // Replace with your image asset name
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}

struct BoardView: View {
    @ObservedObject var gameState: GameState

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 1) {
            ForEach(0..<gameState.boardSize, id: \.self) { row in
                ForEach(0..<gameState.boardSize, id: \.self) { col in
                    CellView(row: row, col: col, gameState: gameState)
                        .id("\(row)-\(col)-\(gameState.boardSize)")
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.brown.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black, lineWidth: 3)
        )
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 1), count: gameState.boardSize)
    }
}

struct CellView: View {
    let row: Int
    let col: Int
    @ObservedObject var gameState: GameState

    private var cellState: CellState {
        // Ensure we don't access out-of-bounds indices
        guard row < gameState.boardSize && col < gameState.boardSize,
              row < gameState.playerGrid.count && col < gameState.playerGrid[row].count else {
            return CellState(value: nil, isGiven: false, isSelected: false, isWrong: false)
        }

        let value = gameState.playerGrid[row][col]
        let isGiven = gameState.givenGrid[row][col]
        let isSelected = gameState.selectedCell?.row == row && gameState.selectedCell?.col == col
        let isWrong = gameState.wrongCells.contains("\(row),\(col)")
        return CellState(value: value, isGiven: isGiven, isSelected: isSelected, isWrong: isWrong)
    }

    var body: some View {
        Button(action: {
            withAnimation(.easeOut(duration: 0.2)) {
                gameState.selectCell(row: row, col: col)
            }
        }) {
            ZStack {
                Rectangle()
                    .fill(cellState.isSelected ? Color.cyan.opacity(0.3) : Color.white)
                    .frame(width: cellSize, height: cellSize)
                    .border(cellState.isSelected ? Color.cyan : Color.gray, width: cellState.isSelected ? 2 : 1)
                if cellState.isWrong {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .blur(radius: 20)
                        .opacity(0.5)
                        .animation(.easeOut(duration: 0.5), value: cellState.isWrong)
                }
                if let value = cellState.value {
                    Text("\(value)")
                        .font(.title2)
                        .fontWeight(cellState.isGiven ? .bold : .medium)
                        .foregroundColor(cellState.isGiven ? .black : .blue)
                        .opacity(cellState.isGiven ? 0.6 : 1.0)
                        .shadow(color: cellState.isGiven ? .clear : .blue, radius: cellState.isGiven ? 0 : 4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeOut(duration: 0.5), value: cellState.isSelected)
        .animation(.easeOut(duration: 0.5), value: cellState.isWrong)
    }

    private var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let padding: CGFloat = 60
        let spacing: CGFloat = CGFloat(gameState.boardSize - 1)
        return (screenWidth - padding - spacing) / CGFloat(gameState.boardSize)
    }
}

struct NumberPadView: View {
    @ObservedObject var gameState: GameState

    var body: some View {
        VStack(spacing: 15) {
            LazyVGrid(columns: gridColumns, spacing: 10) {
                ForEach(1...gameState.boardSize, id: \.self) { number in
                    NumberButton(number: number) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            gameState.inputNumber(number)
                        }
                    }
                }
            }
            GameButton(title: "Clear", color: .red.opacity(0.8), width: 80, height: 40) {
                withAnimation(.easeOut(duration: 0.3)) {
                    gameState.clearSelectedCell()
                }
            }

        }
        .padding(.horizontal, 20)
    }

    private var gridColumns: [GridItem] {
        let columns = gameState.boardSize <= 6 ? gameState.boardSize : 6
        return Array(repeating: GridItem(.flexible()), count: columns)
    }
}

// MARK: - Game State Model

class SudokuDojo: ObservableObject {
    @Published var selectedCell: (row: Int, col: Int)? = nil
    @Published var boardSize: Int = 4
    @Published var playerGrid: [[Int?]] = []
    @Published var givenGrid: [[Bool]] = []
    @Published var wrongCells: Set<String> = []

    init() {
        setupSamplePuzzle()
    }

    func setupSamplePuzzle() {
        // Always reinitialize arrays to match boardSize
        playerGrid = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
        givenGrid = Array(repeating: Array(repeating: false, count: boardSize), count: boardSize)
        wrongCells.removeAll()
        selectedCell = nil

        if boardSize == 4 {
            let sampleData: [(Int, Int, Int)] = [
                (0, 0, 1), (0, 2, 3),
                (1, 1, 2), (1, 3, 4),
                (2, 0, 4), (2, 2, 1),
                (3, 1, 3), (3, 3, 2)
            ]
            for (row, col, value) in sampleData {
                playerGrid[row][col] = value
                givenGrid[row][col] = true
            }
        } else if boardSize == 6 {
            // Valid 6x6 puzzle with 2x3 sub-grids
            let sampleData: [(Int, Int, Int)] = [
                (0, 0, 1), (0, 2, 3), (0, 4, 5),
                (1, 1, 2), (1, 3, 6), (1, 5, 4),
                (2, 0, 5), (2, 1, 4), (2, 3, 2),
                (3, 2, 6), (3, 4, 1), (3, 5, 3),
                (4, 0, 3), (4, 2, 2), (4, 4, 6),
                (5, 1, 1), (5, 3, 5), (5, 5, 2)
            ]
            for (row, col, value) in sampleData {
                playerGrid[row][col] = value
                givenGrid[row][col] = true
            }
        } else if boardSize == 9 {
            let sampleData: [(Int, Int, Int)] = [
                (0,0,5),(0,1,3),(0,4,7),
                (1,0,6),(1,3,1),(1,4,9),(1,5,5),
                (2,1,9),(2,2,8),(2,7,6),
                (3,0,8),(3,4,6),(3,8,3),
                (4,0,4),(4,3,8),(4,5,3),(4,8,1),
                (5,0,7),(5,4,2),(5,8,6),
                (6,1,6),(6,6,2),(6,7,8),
                (7,3,4),(7,4,1),(7,5,9),(7,8,5),
                (8,4,8),(8,7,7),(8,8,9)
            ]
            for (row, col, value) in sampleData {
                playerGrid[row][col] = value
                givenGrid[row][col] = true
            }
        }
    }

    func switchToLevel(_ size: Int) {
        boardSize = size
        setupSamplePuzzle()
    }

    func selectCell(row: Int, col: Int) {
        guard row < boardSize && col < boardSize else { return }
        if !givenGrid[row][col] {
            selectedCell = (row, col)
        }
    }

    func inputNumber(_ number: Int) {
        guard let selected = selectedCell,
              selected.row < boardSize && selected.col < boardSize else { return }
        if givenGrid[selected.row][selected.col] { return }

        playerGrid[selected.row][selected.col] = number
        let cellKey = "\(selected.row),\(selected.col)"
        if isValidMove(row: selected.row, col: selected.col, number: number) {
            wrongCells.remove(cellKey)
        } else {
            wrongCells.insert(cellKey)
        }
    }

    func clearSelectedCell() {
        guard let selected = selectedCell,
              selected.row < boardSize && selected.col < boardSize else { return }
        if !givenGrid[selected.row][selected.col] {
            playerGrid[selected.row][selected.col] = nil
            wrongCells.remove("\(selected.row),\(selected.col)")
        }
    }

    private func isValidMove(row: Int, col: Int, number: Int) -> Bool {
        guard row < boardSize && col < boardSize else { return false }

        // Check row
        for c in 0..<boardSize {
            if c != col && playerGrid[row][c] == number {
                return false
            }
        }

        // Check column
        for r in 0..<boardSize {
            if r != row && playerGrid[r][col] == number {
                return false
            }
        }

        // Check sub-grid with proper dimensions
        let (subRows, subCols) = getSubGridDimensions()
        let subRow = (row / subRows) * subRows
        let subCol = (col / subCols) * subCols

        for r in subRow..<min(subRow + subRows, boardSize) {
            for c in subCol..<min(subCol + subCols, boardSize) {
                if (r != row || c != col) && playerGrid[r][c] == number {
                    return false
                }
            }
        }
        return true
    }

    private func getSubGridDimensions() -> (rows: Int, cols: Int) {
        switch boardSize {
        case 4: return (2, 2)
        case 6: return (2, 3)
        case 9: return (3, 3)
        default: return (2, 2)
        }
    }
}
