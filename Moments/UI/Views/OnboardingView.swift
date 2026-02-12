import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("defaultAccentColor") private var selectedAccentColor = "#007AFF"
    @AppStorage("defaultLiveActivity") private var defaultLiveActivity = true
    @AppStorage("defaultLiveActivityThresholdMinutes") private var defaultLiveActivityThreshold = 1440
    @State private var enableLiveActivities = true
    
    let steps: [OnboardingStep] = [
        OnboardingStep(
            icon: "hourglass.circle.fill",
            title: "Welcome to Moments",
            description: "Count down to what matters most. Create moments and track your progress with beautiful, dynamic countdowns.",
            color: .blue
        ),
        OnboardingStep(
            icon: "plus.circle.fill",
            title: "Create Moments",
            description: "Add a moment by tapping the plus button. Set a target date, choose when to be reminded, and personalize with an icon.",
            color: .purple
        ),
        OnboardingStep(
            icon: "chart.line.uptrend.xyaxis",
            title: "Track Progress",
            description: "Watch your moments update in real-time. See how much time remains with beautiful progress bars and countdowns.",
            color: .green
        ),
        OnboardingStep(
            icon: "bell.badge.fill",
            title: "Stay Informed",
            description: "Receive notifications at key moments. Live Activities keep your countdown on the Lock Screen for quick glances.",
            color: .orange
        ),
        OnboardingStep(
            icon: "waveform.circle.fill",
            title: "Live Activities",
            description: "Choose whether to enable Live Activities by default for all new moments.",
            color: .pink
        ),
        OnboardingStep(
            icon: "square.grid.2x2.fill",
            title: "Organize & Customize",
            description: "Keep your moments organized and customize your experience with your favorite accent color.",
            color: .red
        )
    ]
    
    var body: some View {
        ZStack {
            // Gradient background based on current step
            LinearGradient(
                colors: [
                    steps[currentStep].color.opacity(0.08),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Spacer()
                    Button(action: { completeOnboarding() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                }
                
                Spacer()
                
                // Main content card
                VStack(spacing: 28) {
                    // Icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        steps[currentStep].color.opacity(0.2),
                                        steps[currentStep].color.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: steps[currentStep].icon)
                            .font(.system(size: 60))
                            .foregroundStyle(steps[currentStep].color)
                    }
                    
                    // Text content
                    VStack(spacing: 16) {
                        Text(steps[currentStep].title)
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundStyle(.primary)
                        
                        Text(steps[currentStep].description)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.secondary)
                            .lineSpacing(1.2)
                    }
                    .multilineTextAlignment(.center)
                    
                    // Step-specific interactive content
                    if currentStep == steps.count - 2 {
                        VStack(spacing: 12) {
                            Toggle(isOn: $enableLiveActivities) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Enable Live Activities")
                                        .font(.headline)
                                    
                                    Text("Show countdowns on Lock Screen")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .tint(steps[currentStep].color)
                        }
                        .padding(16)
                        .background(.regularMaterial)
                        .cornerRadius(12)
                    } else if currentStep == steps.count - 1 {
                        VStack(spacing: 16) {
                            Text("Choose Your Accent Color")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            InlineColorPickerGrid(selectedColorHex: $selectedAccentColor)
                        }
                        .padding(16)
                        .background(.regularMaterial)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Progress indicator dots
                HStack(spacing: 6) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Capsule()
                            .fill(
                                index <= currentStep
                                    ? steps[currentStep].color
                                    : Color(.systemGray4)
                            )
                            .frame(height: 6)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                
                // Navigation buttons
                HStack(spacing: 12) {
                    if currentStep > 0 {
                        Button(action: { 
                            withAnimation(.easeInOut) {
                                currentStep -= 1
                            }
                        }) {
                            Text("Back")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.systemGray5))
                                .foregroundStyle(.primary)
                                .cornerRadius(12)
                        }
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut) {
                            if currentStep < steps.count - 1 {
                                currentStep += 1
                            } else {
                                completeOnboarding()
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(currentStep == steps.count - 1 ? "Get Started" : "Next")
                                .fontWeight(.semibold)
                            
                            if currentStep < steps.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [
                                    steps[currentStep].color,
                                    steps[currentStep].color.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .transition(.opacity)
    }
    
    private func completeOnboarding() {
        // Set Live Activity default based on user choice
        defaultLiveActivity = enableLiveActivities
        if !enableLiveActivities {
            defaultLiveActivityThreshold = 0 // Disable by default
        } else {
            defaultLiveActivityThreshold = 1440 // 1 day
        }
        
        withAnimation(.easeInOut) {
            hasCompletedOnboarding = true
        }
        dismiss()
    }
}

// MARK: - Data Model

struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

#Preview {
    OnboardingView()
}
