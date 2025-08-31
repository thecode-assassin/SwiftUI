//
//  ShurikenShape.swift
//  
//
//  Created by TheCodeAssassin on 8/30/25.
//

import SwiftUI
import Foundation

struct ShurikenShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let bladeLength = r * 0.9
        let bladeWidth = r * 0.25
        var path = Path()

        for i in 0..<4 {
            let angle = CGFloat(i) * .pi / 2

            // Calculate blade points
            let tip = CGPoint(
                x: center.x + bladeLength * cos(angle),
                y: center.y + bladeLength * sin(angle)
            )
            let leftBase = CGPoint(
                x: center.x + bladeWidth * cos(angle - .pi / 2),
                y: center.y + bladeWidth * sin(angle - .pi / 2)
            )
            let rightBase = CGPoint(
                x: center.x + bladeWidth * cos(angle + .pi / 2),
                y: center.y + bladeWidth * sin(angle + .pi / 2)
            )

            // Draw blade
            if i == 0 {
                path.move(to: leftBase)
            }
            path.addLine(to: tip)
            path.addLine(to: rightBase)

            // Connect to next blade's left base
            let nextAngle = CGFloat((i + 1) % 4) * .pi / 2
            let nextLeftBase = CGPoint(
                x: center.x + bladeWidth * cos(nextAngle - .pi / 2),
                y: center.y + bladeWidth * sin(nextAngle - .pi / 2)
            )
            path.addLine(to: nextLeftBase)
        }

        path.closeSubpath()

        // Center hole - this will create a cutout when using eoFill
        let holeRadius = r * 0.15
        path.addEllipse(in: CGRect(
            x: center.x - holeRadius,
            y: center.y - holeRadius,
            width: holeRadius * 2,
            height: holeRadius * 2
        ))

        return path
    }
}

struct ShurikenSpinnerView: View {
    @State private var isSpinning = false
    @State private var textOpacity: Double = 0.5

    // Customizable properties
    let size: CGFloat
    let spinDuration: Double
    let message: String
    let accentColor: Color

    init(
        size: CGFloat = 120,
        spinDuration: Double = 1.2,
        message: String = "Sharpening skills…",
        accentColor: Color = .gray
    ) {
        self.size = size
        self.spinDuration = spinDuration
        self.message = message
        self.accentColor = accentColor
    }

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: size * 0.2) {
                // Shuriken Shape
                ShurikenShape()
                    .fill(style: FillStyle(eoFill: true))
                    .frame(width: size, height: size)
                    .foregroundStyle(accentColor)
                    .rotationEffect(.degrees(isSpinning ? 360 : 0))
                    .shadow(color: .white.opacity(0.4), radius: 8)

                // Loading Text
                Text(message)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .opacity(textOpacity)
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityLabel("Loading spinner")
        .accessibilityValue(message)
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            stopAnimations()
        }
    }

    private func startAnimations() {
        // Synchronized animation start
        withAnimation(
            .linear(duration: spinDuration)
            .repeatForever(autoreverses: false)
        ) {
            isSpinning = true
        }

        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            textOpacity = 1.0
        }
    }

    private func stopAnimations() {
        withAnimation(.easeOut(duration: 0.3)) {
            isSpinning = false
            textOpacity = 0.5
        }
    }
}

#Preview {
    ShurikenSpinnerView()
}

#Preview("Custom") {
    ShurikenSpinnerView(
        size: 80,
        spinDuration: 0.8,
        message: "Loading ninja skills…",
        accentColor: .red
    )
}

#Preview("Blue Large") {
    ShurikenSpinnerView(
        size: 160,
        spinDuration: 2.0,
        message: "Stealth mode…",
        accentColor: .blue
    )
}
