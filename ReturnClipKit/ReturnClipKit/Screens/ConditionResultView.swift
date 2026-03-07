import SwiftUI

/// Screen 4: Display AI condition assessment results
struct ConditionResultView: View {
    @ObservedObject var flowState: ReturnFlowState
    
    var body: some View {
        ScrollView {
            VStack(spacing: RCSpacing.xl) {
                // Header with score
                if let assessment = flowState.conditionAssessment {
                    scoreHeader(assessment)
                        .slideIn(delay: 0.1)
                    
                    // Category breakdown
                    categoryBreakdown(assessment)
                        .slideIn(delay: 0.3)
                    
                    // Detected issues
                    if !assessment.issues.isEmpty {
                        issuesSection(assessment.issues)
                            .slideIn(delay: 0.5)
                    }
                    
                    // Policy check result
                    if let decision = flowState.refundDecision {
                        policyCheckResult(decision)
                            .slideIn(delay: 0.6)
                    }
                } else {
                    analyzingView
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, RCSpacing.lg)
            .padding(.top, RCSpacing.sm)
        }
        .background(Color.rcSurface)
    }
    
    // MARK: - Components
    
    private func scoreHeader(_ assessment: ConditionAssessment) -> some View {
        VStack(spacing: RCSpacing.lg) {
            // Animated score ring
            AnimatedScoreRing(
                score: assessment.overallQualityScore,
                color: qualityColor(assessment.qualityLevel),
                size: 160
            )
            .padding(.top, RCSpacing.lg)
            
            // Quality level badge
            HStack(spacing: RCSpacing.sm) {
                Text(assessment.qualityLevel.emoji)
                    .font(.system(size: 20))
                Text(assessment.qualityLevel.rawValue)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.rcTextPrimary)
            }
            
            // Confidence badge
            HStack(spacing: RCSpacing.xs) {
                Image(systemName: "cpu")
                    .font(.system(size: 11))
                Text("AI Confidence: \(Int(assessment.confidence * 100))%")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.rcTextMuted)
            .padding(.horizontal, RCSpacing.md)
            .padding(.vertical, RCSpacing.sm)
            .background(Color.rcSurfaceMuted)
            .cornerRadius(RCRadius.full)
        }
    }
    
    private func categoryBreakdown(_ assessment: ConditionAssessment) -> some View {
        VStack(alignment: .leading, spacing: RCSpacing.lg) {
            Text("Condition Breakdown")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.rcTextPrimary)
            
            ForEach(Array(assessment.categoryScores.enumerated()), id: \.element.category) { index, score in
                categoryRow(score, delay: Double(index) * 0.1)
            }
        }
        .rcCard()
    }
    
    private func categoryRow(_ score: CategoryScore, delay: Double = 0) -> some View {
        VStack(alignment: .leading, spacing: RCSpacing.sm) {
            HStack {
                ZStack {
                    Circle()
                        .fill(scoreColor(score.score).opacity(0.12))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: score.category.icon)
                        .foregroundColor(scoreColor(score.score))
                        .font(.system(size: 13))
                }
                
                Text(score.category.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.rcTextPrimary)
                
                Spacer()
                
                Text("\(score.score)%")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor(score.score))
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.rcSurfaceMuted)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [scoreColor(score.score).opacity(0.7), scoreColor(score.score)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(score.score) / 100, height: 6)
                }
            }
            .frame(height: 6)
            
            if let notes = score.notes {
                Text(notes)
                    .font(.system(size: 12))
                    .foregroundColor(.rcTextMuted)
            }
        }
    }
    
    private func issuesSection(_ issues: [DetectedIssue]) -> some View {
        VStack(alignment: .leading, spacing: RCSpacing.md) {
            HStack(spacing: RCSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.rcWarning.opacity(0.12))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.rcWarning)
                        .font(.system(size: 13))
                }
                
                Text("Issues Detected")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.rcTextPrimary)
            }
            
            ForEach(issues) { issue in
                issueRow(issue)
            }
        }
        .padding(RCSpacing.lg)
        .background(Color.rcWarning.opacity(0.05))
        .cornerRadius(RCRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: RCRadius.lg)
                .stroke(Color.rcWarning.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func issueRow(_ issue: DetectedIssue) -> some View {
        HStack(alignment: .top, spacing: RCSpacing.md) {
            Circle()
                .fill(severityColor(issue.severity))
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(issue.description)
                    .font(.system(size: 14))
                    .foregroundColor(.rcTextPrimary)
                
                if let location = issue.location {
                    Text("Location: \(location)")
                        .font(.system(size: 12))
                        .foregroundColor(.rcTextMuted)
                }
            }
            
            Spacer()
            
            Text(issue.severity.rawValue.capitalized)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(severityColor(issue.severity))
                .padding(.horizontal, RCSpacing.sm)
                .padding(.vertical, RCSpacing.xs)
                .background(severityColor(issue.severity).opacity(0.1))
                .cornerRadius(RCRadius.full)
        }
    }
    
    private func policyCheckResult(_ decision: RefundDecision) -> some View {
        VStack(alignment: .leading, spacing: RCSpacing.md) {
            HStack(spacing: RCSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(policyColor(decision.decision).opacity(0.12))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: policyIcon(decision.decision))
                        .foregroundColor(policyColor(decision.decision))
                        .font(.system(size: 13))
                }
                
                Text("Policy Check")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.rcTextPrimary)
                
                Spacer()
                
                // Status badge
                Text(policyStatusText(decision.decision))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, RCSpacing.sm)
                    .padding(.vertical, RCSpacing.xs)
                    .background(policyColor(decision.decision))
                    .cornerRadius(RCRadius.full)
            }
            
            Text(decision.explanation)
                .font(.system(size: 14))
                .foregroundColor(.rcTextSecondary)
                .lineSpacing(3)
            
            if !decision.policyViolations.isEmpty {
                VStack(alignment: .leading, spacing: RCSpacing.xs) {
                    ForEach(decision.policyViolations, id: \.self) { violation in
                        HStack(alignment: .top, spacing: RCSpacing.sm) {
                            Text("•")
                                .foregroundColor(.rcTextMuted)
                            Text(violation)
                                .font(.system(size: 12))
                                .foregroundColor(.rcTextMuted)
                        }
                    }
                }
            }
        }
        .padding(RCSpacing.lg)
        .background(policyColor(decision.decision).opacity(0.05))
        .cornerRadius(RCRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: RCRadius.lg)
                .stroke(policyColor(decision.decision).opacity(0.15), lineWidth: 1)
        )
    }
    
    private var analyzingView: some View {
        VStack(spacing: RCSpacing.xl) {
            ZStack {
                Circle()
                    .fill(Color.rcPrimary.opacity(0.08))
                    .frame(width: 100, height: 100)
                
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.rcPrimary)
            }
            
            VStack(spacing: RCSpacing.sm) {
                Text("Analyzing condition...")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.rcTextPrimary)
                
                Text("Our AI is reviewing your photos")
                    .font(.subheadline)
                    .foregroundColor(.rcTextSecondary)
            }
        }
        .padding(RCSpacing.xxxl)
    }
    
    // MARK: - Helpers
    
    private func qualityColor(_ level: QualityLevel) -> Color {
        switch level {
        case .excellent: return .rcSuccess
        case .good: return .rcPrimary
        case .fair: return .rcWarning
        case .poor: return .rcWarning
        case .unacceptable: return .rcError
        }
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 90...100: return .rcSuccess
        case 70..<90: return .rcPrimary
        case 50..<70: return .rcWarning
        default: return .rcError
        }
    }
    
    private func severityColor(_ severity: IssueSeverity) -> Color {
        switch severity {
        case .minor: return .rcSuccess
        case .moderate: return .rcWarning
        case .major: return .rcWarning
        case .critical: return .rcError
        }
    }
    
    private func policyIcon(_ decision: RefundType) -> String {
        switch decision {
        case .fullRefund: return "checkmark.seal.fill"
        case .partialRefund: return "minus.circle.fill"
        case .exchangeOnly: return "arrow.triangle.2.circlepath"
        case .storeCreditOnly: return "creditcard.fill"
        case .denied: return "xmark.seal.fill"
        }
    }
    
    private func policyColor(_ decision: RefundType) -> Color {
        switch decision {
        case .fullRefund: return .rcSuccess
        case .partialRefund: return .rcWarning
        case .exchangeOnly: return .rcPrimary
        case .storeCreditOnly: return .rcPrimaryLight
        case .denied: return .rcError
        }
    }
    
    private func policyStatusText(_ decision: RefundType) -> String {
        switch decision {
        case .fullRefund: return "Approved"
        case .partialRefund: return "Partial"
        case .exchangeOnly: return "Exchange"
        case .storeCreditOnly: return "Credit"
        case .denied: return "Denied"
        }
    }
}
