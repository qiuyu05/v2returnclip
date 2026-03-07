import SwiftUI

/// Screen 4: Display AI condition assessment results
struct ConditionResultView: View {
    @ObservedObject var flowState: ReturnFlowState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with score
                if let assessment = flowState.conditionAssessment {
                    scoreHeader(assessment)
                    
                    // Category breakdown
                    categoryBreakdown(assessment)
                    
                    // Detected issues
                    if !assessment.issues.isEmpty {
                        issuesSection(assessment.issues)
                    }
                    
                    // Policy check result
                    if let decision = flowState.refundDecision {
                        policyCheckResult(decision)
                    }
                } else {
                    analyzingView
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
    
    // MARK: - Components
    
    private func scoreHeader(_ assessment: ConditionAssessment) -> some View {
        VStack(spacing: 16) {
            // Quality badge
            ZStack {
                Circle()
                    .fill(qualityColor(assessment.qualityLevel).opacity(0.2))
                    .frame(width: 140, height: 140)
                
                Circle()
                    .stroke(qualityColor(assessment.qualityLevel), lineWidth: 8)
                    .frame(width: 140, height: 140)
                
                VStack {
                    Text("\(assessment.overallQualityScore)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("/ 100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Quality level label
            HStack {
                Text(assessment.qualityLevel.emoji)
                Text(assessment.qualityLevel.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            // Confidence
            Text("AI Confidence: \(Int(assessment.confidence * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top)
    }
    
    private func categoryBreakdown(_ assessment: ConditionAssessment) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Condition Breakdown")
                .font(.headline)
            
            ForEach(assessment.categoryScores, id: \.category) { score in
                categoryRow(score)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func categoryRow(_ score: CategoryScore) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: score.category.icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(score.category.displayName)
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(score.score)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(scoreColor(score.score))
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(scoreColor(score.score))
                        .frame(width: geo.size.width * CGFloat(score.score) / 100, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
            
            if let notes = score.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func issuesSection(_ issues: [DetectedIssue]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Issues Detected")
                    .font(.headline)
            }
            
            ForEach(issues) { issue in
                issueRow(issue)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func issueRow(_ issue: DetectedIssue) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(severityColor(issue.severity))
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(issue.description)
                    .font(.subheadline)
                
                if let location = issue.location {
                    Text("Location: \(location)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(issue.severity.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(severityColor(issue.severity))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(severityColor(issue.severity).opacity(0.1))
                .cornerRadius(4)
        }
    }
    
    private func policyCheckResult(_ decision: RefundDecision) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: policyIcon(decision.decision))
                    .foregroundColor(policyColor(decision.decision))
                Text("Policy Check")
                    .font(.headline)
            }
            
            Text(decision.explanation)
                .font(.subheadline)
            
            if !decision.policyViolations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(decision.policyViolations, id: \.self) { violation in
                        HStack(alignment: .top) {
                            Text("•")
                            Text(violation)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(policyColor(decision.decision).opacity(0.1))
        .cornerRadius(12)
    }
    
    private var analyzingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Analyzing condition...")
                .font(.headline)
            
            Text("Our AI is reviewing your photos")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(40)
    }
    
    // MARK: - Helpers
    
    private func qualityColor(_ level: QualityLevel) -> Color {
        switch level {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .orange
        case .unacceptable: return .red
        }
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 90...100: return .green
        case 70..<90: return .blue
        case 50..<70: return .yellow
        default: return .red
        }
    }
    
    private func severityColor(_ severity: IssueSeverity) -> Color {
        switch severity {
        case .minor: return .green
        case .moderate: return .yellow
        case .major: return .orange
        case .critical: return .red
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
        case .fullRefund: return .green
        case .partialRefund: return .yellow
        case .exchangeOnly: return .blue
        case .storeCreditOnly: return .purple
        case .denied: return .red
        }
    }
}
