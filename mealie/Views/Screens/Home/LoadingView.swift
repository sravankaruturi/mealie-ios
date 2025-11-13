//
//  LoadingView.swift
//  mealIO
//
//  Created by Sravan Karuturi on 11/11/25.
//

import SwiftUI

struct LoadingView: View {
    var title: String = "Cooking something tasty..."
    var subtitle: String? = "Fetching the latest from your Mealie kitchen."

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.85),
                    Color.accentColor
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                icon

                VStack(spacing: 8) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)

                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.accentColor)
                    .scaleEffect(1.1)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 30, y: 12)
            )
            .padding(.horizontal, 32)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title) \(subtitle ?? "")")
        }
        .onAppear {
            isAnimating = true
        }
    }

    private var icon: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.4), lineWidth: 2)
                .frame(width: 120, height: 120)

            Circle()
                .trim(from: 0, to: 0.85)
                .stroke(
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .foregroundColor(.white)
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 1.6).repeatForever(autoreverses: false), value: isAnimating)

            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 52))
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.white, Color.white.opacity(0.5))
        }
    }
}

#Preview {
    LoadingView()
}
