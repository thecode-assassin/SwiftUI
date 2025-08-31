//
//  AnimatedGradientLoginScreen.swift
//
//
//  Created by TheCodeAssassin on 8/31/25.
//

import SwiftUI

struct AnimatedGradientLoginScreen: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSecured = true
    @State private var showingSocialLogin = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated gradient background
                AnimatedGradientBackground()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Main content
                    VStack(spacing: 32) {
                        logoSection
                        loginForm
                        socialLoginButtons
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 48)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Bottom section
                    bottomSection
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: "bolt.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: 8) {
                Text("Katana")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                Text("Slice through your goals")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var loginForm: some View {
        VStack(spacing: 20) {
            CustomTextField(
                text: $email,
                placeholder: "Email",
                icon: "envelope.fill"
            )
            
            CustomSecureField(
                text: $password,
                placeholder: "Password",
                icon: "lock.fill",
                isSecured: $isSecured
            )
            
            HStack {
                Spacer()
                Button("Forgot Password?") {
                    // Handle forgot password
                }
                .font(.callout)
                .foregroundColor(.cyan)
            }
            
            Button(action: {
                // Handle login
            }) {
                HStack {
                    Text("Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
    }
    
    private var socialLoginButtons: some View {
        VStack(spacing: 16) {
            HStack {
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(height: 1)
                
                Text("or continue with")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(height: 1)
            }
            
            HStack(spacing: 16) {
                SocialButton(icon: "applelogo", color: .black)
                SocialButton(icon: "globe", color: .blue)
                SocialButton(icon: "person.2.fill", color: .green)
            }
        }
    }
    
    private var bottomSection: some View {
        HStack {
            Text("Don't have an account?")
                .foregroundColor(.white.opacity(0.7))
            
            Button("Sign Up") {
                // Handle sign up
            }
            .foregroundColor(.cyan)
            .fontWeight(.semibold)
        }
        .font(.footnote)
        .padding(.bottom, 32)
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(.white.opacity(0.5))
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    @Binding var isSecured: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            Group {
                if isSecured {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(PlainTextFieldStyle())
            .placeholder(when: text.isEmpty) {
                Text(placeholder)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: isSecured ? "eye.slash" : "eye")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct SocialButton: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // Handle social login
        }) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(.white.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
}

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [.purple.opacity(0.8), .blue.opacity(0.8), .cyan.opacity(0.8)],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    AnimatedGradientLoginScreen()
}
