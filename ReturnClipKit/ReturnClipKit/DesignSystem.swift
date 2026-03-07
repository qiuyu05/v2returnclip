import SwiftUI

// MARK: - Brand Colors

extension Color {
    // Primary - Indigo gradient
    static let rcPrimary = Color(red: 79/255, green: 70/255, blue: 229/255)       // #4F46E5
    static let rcPrimaryLight = Color(red: 99/255, green: 102/255, blue: 241/255)  // #6366F1
    static let rcPrimaryDark = Color(red: 67/255, green: 56/255, blue: 202/255)    // #4338CA
    
    // Success - Emerald
    static let rcSuccess = Color(red: 16/255, green: 185/255, blue: 129/255)       // #10B981
    static let rcSuccessLight = Color(red: 52/255, green: 211/255, blue: 153/255)  // #34D399
    static let rcSuccessDark = Color(red: 5/255, green: 150/255, blue: 105/255)    // #059669
    
    // Warning - Amber
    static let rcWarning = Color(red: 245/255, green: 158/255, blue: 11/255)       // #F59E0B
    static let rcWarningLight = Color(red: 251/255, green: 191/255, blue: 36/255)  // #FBBF24
    
    // Error - Rose
    static let rcError = Color(red: 239/255, green: 68/255, blue: 68/255)          // #EF4444
    static let rcErrorLight = Color(red: 248/255, green: 113/255, blue: 113/255)   // #F87171
    
    // Surfaces
    static let rcSurface = Color(red: 248/255, green: 250/255, blue: 252/255)      // #F8FAFC
    static let rcSurfaceElevated = Color.white
    static let rcSurfaceMuted = Color(red: 241/255, green: 245/255, blue: 249/255) // #F1F5F9
    static let rcBorder = Color(red: 226/255, green: 232/255, blue: 240/255)       // #E2E8F0
    
    // Text
    static let rcTextPrimary = Color(red: 15/255, green: 23/255, blue: 42/255)     // #0F172A
    static let rcTextSecondary = Color(red: 100/255, green: 116/255, blue: 139/255) // #64748B
    static let rcTextMuted = Color(red: 148/255, green: 163/255, blue: 184/255)    // #94A3B8
}

// MARK: - Gradients

extension LinearGradient {
    static let rcPrimary = LinearGradient(
        colors: [.rcPrimary, .rcPrimaryLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let rcSuccess = LinearGradient(
        colors: [.rcSuccessDark, .rcSuccess],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let rcSurface = LinearGradient(
        colors: [.rcSurface, Color(red: 238/255, green: 242/255, blue: 255/255)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Spacing

enum RCSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Radius

enum RCRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let full: CGFloat = 999
}

// MARK: - Shadows

extension View {
    func rcShadowCard() -> some View {
        self.shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
    
    func rcShadowElevated() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    func rcShadowFloat() -> some View {
        self.shadow(color: Color.rcPrimary.opacity(0.25), radius: 24, x: 0, y: 12)
    }
}

// MARK: - Card Modifier

struct RCCardModifier: ViewModifier {
    var isSelected: Bool = false
    
    func body(content: Content) -> some View {
        content
            .padding(RCSpacing.lg)
            .background(Color.rcSurfaceElevated)
            .cornerRadius(RCRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: RCRadius.lg)
                    .stroke(isSelected ? Color.rcPrimary : Color.rcBorder.opacity(0.6), lineWidth: isSelected ? 2 : 1)
            )
            .rcShadowCard()
    }
}

extension View {
    func rcCard(isSelected: Bool = false) -> some View {
        modifier(RCCardModifier(isSelected: isSelected))
    }
}

// MARK: - Button Styles

struct RCPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, RCSpacing.xl)
            .background(
                Group {
                    if isEnabled {
                        LinearGradient.rcPrimary
                    } else {
                        LinearGradient(colors: [Color.rcTextMuted], startPoint: .leading, endPoint: .trailing)
                    }
                }
            )
            .foregroundColor(.white)
            .cornerRadius(RCRadius.lg)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .rcShadowFloat()
            .opacity(isEnabled ? 1 : 0.6)
    }
}

struct RCSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, RCSpacing.xl)
            .background(Color.rcSurfaceMuted)
            .foregroundColor(.rcTextPrimary)
            .cornerRadius(RCRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: RCRadius.lg)
                    .stroke(Color.rcBorder, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Step Indicator

struct StepIndicator: View {
    let currentStep: ReturnStep
    
    private let steps = ReturnStep.allCases
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element) { index, step in
                // Circle
                ZStack {
                    if step.rawValue < currentStep.rawValue {
                        // Completed
                        Circle()
                            .fill(LinearGradient.rcPrimary)
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else if step == currentStep {
                        // Active
                        Circle()
                            .fill(LinearGradient.rcPrimary)
                            .frame(width: 28, height: 28)
                        Text("\(step.rawValue + 1)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        // Upcoming
                        Circle()
                            .fill(Color.rcSurfaceMuted)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle().stroke(Color.rcBorder, lineWidth: 1.5)
                            )
                        Text("\(step.rawValue + 1)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.rcTextMuted)
                    }
                }
                
                // Connector line
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(
                            step.rawValue < currentStep.rawValue
                            ? Color.rcPrimary
                            : Color.rcBorder
                        )
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, RCSpacing.lg)
        .padding(.vertical, RCSpacing.md)
        .background(Color.rcSurfaceElevated)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
    }
}

// MARK: - Animated Score Ring

struct AnimatedScoreRing: View {
    let score: Int
    let color: Color
    let size: CGFloat
    
    @State private var animatedProgress: CGFloat = 0
    @State private var displayScore: Int = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 10)
                .frame(width: size, height: size)
            
            // Animated ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color.opacity(0.6), color]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            
            // Glow dot at tip
            Circle()
                .fill(color)
                .frame(width: 14, height: 14)
                .shadow(color: color.opacity(0.6), radius: 6)
                .offset(y: -size / 2)
                .rotationEffect(.degrees(Double(animatedProgress) * 360))
                .opacity(animatedProgress > 0.05 ? 1 : 0)
            
            // Score text
            VStack(spacing: 2) {
                Text("\(displayScore)")
                    .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                    .foregroundColor(.rcTextPrimary)
                Text("/ 100")
                    .font(.system(size: size * 0.1, weight: .medium, design: .rounded))
                    .foregroundColor(.rcTextSecondary)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.5, dampingFraction: 0.8).delay(0.3)) {
                animatedProgress = CGFloat(score) / 100.0
            }
            // Count-up animation
            animateScore()
        }
    }
    
    private func animateScore() {
        let duration: Double = 1.5
        let steps = 60
        let interval = duration / Double(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * interval) {
                displayScore = Int(Double(score) * Double(i) / Double(steps))
            }
        }
    }
}

// MARK: - Celebration Effect

struct CelebrationView: View {
    @State private var particles: [CelebrationParticle] = []
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .offset(
                        x: isAnimating ? particle.endX : 0,
                        y: isAnimating ? particle.endY : 0
                    )
                    .opacity(isAnimating ? 0 : 1)
                    .scaleEffect(isAnimating ? 0.3 : 1)
            }
        }
        .onAppear {
            generateParticles()
            withAnimation(.easeOut(duration: 2.0)) {
                isAnimating = true
            }
        }
    }
    
    private func generateParticles() {
        let colors: [Color] = [.rcPrimary, .rcPrimaryLight, .rcSuccess, .rcSuccessLight, .rcWarning, .rcWarningLight]
        particles = (0..<30).map { _ in
            CelebrationParticle(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 4...10),
                endX: CGFloat.random(in: -180...180),
                endY: CGFloat.random(in: -200...100)
            )
        }
    }
}

struct CelebrationParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    let endX: CGFloat
    let endY: CGFloat
}

// MARK: - Haptics

enum RCHaptics {
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

// MARK: - Animated Appear Modifier

struct BounceAppearModifier: ViewModifier {
    @State private var appeared = false
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func bounceAppear(delay: Double = 0) -> some View {
        modifier(BounceAppearModifier(delay: delay))
    }
}

// MARK: - Slide-in Modifier

struct SlideInModifier: ViewModifier {
    @State private var appeared = false
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func slideIn(delay: Double = 0) -> some View {
        modifier(SlideInModifier(delay: delay))
    }
}
