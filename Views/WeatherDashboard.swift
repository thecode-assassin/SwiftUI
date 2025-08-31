//
//  WeatherDashboard.swift
//  
//
//  Created by TheCodeAssassin on 8/31/25.
//

import SwiftUI

struct WeatherDashboard: View {
    @State private var currentTemp = 24
    @State private var weatherCondition = "sunny"
    @State private var isRefreshing = false
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated Background
                AnimatedWeatherBackground(condition: weatherCondition)
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Current Weather Section
                        VStack(spacing: 20) {
                            Text("San Francisco")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Text("\(currentTemp)°")
                                .font(.system(size: 80, weight: .thin))
                                .foregroundColor(.white)
                            
                            Text("Sunny")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                            
                            HStack(spacing: 30) {
                                WeatherDetailItem(icon: "wind", value: "12 km/h", label: "Wind")
                                WeatherDetailItem(icon: "humidity", value: "65%", label: "Humidity")
                                WeatherDetailItem(icon: "eye", value: "10 km", label: "Visibility")
                            }
                        }
                        .padding(.top, 60)
                        .padding(.horizontal, 20)
                        
                        // 5-Day Forecast
                        VStack(alignment: .leading, spacing: 16) {
                            Text("5-Day Forecast")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.top, 40)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(forecastData, id: \.day) { forecast in
                                    ForecastRow(forecast: forecast)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                .refreshable {
                    await refreshWeather()
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func refreshWeather() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        currentTemp = Int.random(in: 18...32)
        isRefreshing = false
    }
}

struct AnimatedWeatherBackground: View {
    let condition: String
    @State private var cloudOffset1: CGFloat = -200
    @State private var cloudOffset2: CGFloat = -150
    @State private var sunRotation: Double = 0
    @State private var rainDrops: [RainDrop] = []
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated Elements
            if condition == "sunny" {
                SunView(rotation: sunRotation)
                MovingClouds(offset1: cloudOffset1, offset2: cloudOffset2)
            } else if condition == "rainy" {
                RainView(rainDrops: rainDrops)
                MovingClouds(offset1: cloudOffset1, offset2: cloudOffset2, opacity: 0.3)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private var backgroundColors: [Color] {
        switch condition {
        case "sunny":
            return [Color.orange.opacity(0.8), Color.blue.opacity(0.6), Color.purple.opacity(0.4)]
        case "rainy":
            return [Color.gray.opacity(0.8), Color.blue.opacity(0.7), Color.indigo.opacity(0.6)]
        default:
            return [Color.blue.opacity(0.6), Color.purple.opacity(0.5)]
        }
    }
    
    private func startAnimations() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            cloudOffset1 = UIScreen.main.bounds.width + 100
            cloudOffset2 = UIScreen.main.bounds.width + 150
        }
        
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            sunRotation = 360
        }
        
        if condition == "rainy" {
            startRainAnimation()
        }
    }
    
    private func startRainAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if rainDrops.count < 50 {
                rainDrops.append(RainDrop(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: -10,
                    speed: CGFloat.random(in: 4...8)
                ))
            }
            
            rainDrops = rainDrops.compactMap { drop in
                var newDrop = drop
                newDrop.y += newDrop.speed
                return newDrop.y < UIScreen.main.bounds.height + 20 ? newDrop : nil
            }
        }
    }
}

struct SunView: View {
    let rotation: Double
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.yellow, .orange.opacity(0.8)],
                    center: .center,
                    startRadius: 5,
                    endRadius: 40
                )
            )
            .frame(width: 80, height: 80)
            .overlay(
                ForEach(0..<8) { index in
                    Rectangle()
                        .fill(.yellow.opacity(0.8))
                        .frame(width: 4, height: 20)
                        .offset(y: -50)
                        .rotationEffect(.degrees(Double(index) * 45))
                }
            )
            .rotationEffect(.degrees(rotation))
            .position(x: UIScreen.main.bounds.width * 0.8, y: 120)
    }
}

struct MovingClouds: View {
    let offset1: CGFloat
    let offset2: CGFloat
    var opacity: Double = 0.6
    
    var body: some View {
        Group {
            CloudShape()
                .fill(.white.opacity(opacity))
                .frame(width: 120, height: 60)
                .offset(x: offset1, y: 100)
            
            CloudShape()
                .fill(.white.opacity(opacity * 0.8))
                .frame(width: 100, height: 50)
                .offset(x: offset2, y: 160)
        }
    }
}

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addEllipse(in: CGRect(x: rect.width * 0.25, y: rect.height * 0.25, width: rect.width * 0.5, height: rect.height * 0.5))
            path.addEllipse(in: CGRect(x: rect.width * 0.4, y: rect.height * 0.1, width: rect.width * 0.4, height: rect.height * 0.4))
            path.addEllipse(in: CGRect(x: rect.width * 0.6, y: rect.height * 0.2, width: rect.width * 0.35, height: rect.height * 0.45))
            path.addEllipse(in: CGRect(x: 0, y: rect.height * 0.4, width: rect.width * 0.4, height: rect.height * 0.4))
            path.addEllipse(in: CGRect(x: rect.width * 0.15, y: rect.height * 0.35, width: rect.width * 0.3, height: rect.height * 0.3))
        }
    }
}

struct RainView: View {
    let rainDrops: [RainDrop]
    
    var body: some View {
        ForEach(rainDrops.indices, id: \.self) { index in
            Rectangle()
                .fill(.white.opacity(0.8))
                .frame(width: 2, height: 15)
                .position(x: rainDrops[index].x, y: rainDrops[index].y)
        }
    }
}

struct RainDrop {
    var x: CGFloat
    var y: CGFloat
    let speed: CGFloat
}

struct WeatherDetailItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

struct ForecastRow: View {
    let forecast: WeatherForecast
    
    var body: some View {
        HStack {
            Text(forecast.day)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Image(systemName: forecast.icon)
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 30)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("\(forecast.highTemp)°")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("\(forecast.lowTemp)°")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct WeatherForecast {
    let day: String
    let icon: String
    let highTemp: Int
    let lowTemp: Int
}

// Sample data
let forecastData = [
    WeatherForecast(day: "Today", icon: "sun.max.fill", highTemp: 24, lowTemp: 18),
    WeatherForecast(day: "Tomorrow", icon: "cloud.sun.fill", highTemp: 22, lowTemp: 16),
    WeatherForecast(day: "Wednesday", icon: "cloud.rain.fill", highTemp: 19, lowTemp: 14),
    WeatherForecast(day: "Thursday", icon: "cloud.fill", highTemp: 21, lowTemp: 15),
    WeatherForecast(day: "Friday", icon: "sun.max.fill", highTemp: 26, lowTemp: 19)
]

import SwiftUI

struct WeatherDashboard_Previews: PreviewProvider {
    static var previews: some View {
        WeatherDashboard()
    }
}
