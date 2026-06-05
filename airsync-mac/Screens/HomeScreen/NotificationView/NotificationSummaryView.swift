//
//  NotificationSummaryView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2026-06-05.
//

import SwiftUI
import FoundationModels
import Combine

struct SummaryLine: Identifiable {
    let id = UUID()
    let text: String
    let isHeader: Bool
}

class NotificationSummaryViewModel: ObservableObject {
    @Published var summaryText: String = ""
    @Published var isGeneratingSummary: Bool = false
    @Published var showSummary: Bool = false
    
    func generateSummary(notifications: [Notification], androidApps: [String: AndroidApp]) {
        let filtered = AppState.shared.includeSilentInAIOption ? notifications : notifications.filter { $0.priority != "silent" }
        guard !filtered.isEmpty else { return }
        isGeneratingSummary = true
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showSummary = true
        }
        summaryText = ""
        
        var notificationsText = ""
        let grouped = Dictionary(grouping: filtered) { notif in
            androidApps[notif.package]?.name ?? "Android Device"
        }
        
        for (appName, notifs) in grouped {
            notificationsText += "\n[\(appName)]:\n"
            for notif in notifs {
                let title = notif.title
                let body = notif.body
                notificationsText += "- \(title): \(body)\n"
            }
        }
        
        let prompt = """
        Please provide a concise, high-level summary of the following notifications from my phone:
        \(notificationsText)
        Group them logically and highlight important alerts or action items.
        """
        
        Task {
            do {
                if #available(macOS 26.0, *) {
                    let session = LanguageModelSession(instructions: "You are an assistant that summarizes phone notifications. Write an extremely brief summary of active notifications. Group them by category using simple headers starting with '##' (e.g. '## Important Alerts') followed by brief lines. Do not mention specific app names. Never use conversational filler, keep it to 2-3 items max.")
                    let response = try await session.respond(to: prompt)
                    let cleaned = response.content.replacingOccurrences(of: "\r\n", with: "\n")
                    await animateWritingText(cleaned)
                } else {
                    await MainActor.run {
                        summaryText = "AI summaries require macOS 26.0 or later."
                    }
                }
            } catch {
                await MainActor.run {
                    summaryText = "Error generating response: \(error.localizedDescription)"
                }
            }
            await MainActor.run {
                isGeneratingSummary = false
            }
        }
    }
    
    @MainActor
    private func animateWritingText(_ fullText: String) async {
        summaryText = ""
        for char in fullText {
            summaryText.append(char)
            try? await Task.sleep(nanoseconds: 15_000_000) // 15ms per character
        }
    }
}

struct NotificationSummaryView: View {
    @ObservedObject var viewModel: NotificationSummaryViewModel
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.accentColor)
                Text("Summary")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.showSummary = false
                        viewModel.summaryText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: isHovering)
            }
            
            if viewModel.isGeneratingSummary && viewModel.summaryText.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Analyzing notifications...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 2) {
                        let lines: [SummaryLine] = viewModel.summaryText.components(separatedBy: "\n")
                            .map { line -> SummaryLine in
                                let trimmed = line.trimmingCharacters(in: .whitespaces)
                                if trimmed.hasPrefix("#") {
                                    let clean = trimmed.replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
                                    return SummaryLine(text: clean, isHeader: true)
                                } else {
                                    let clean = trimmed
                                        .replacingOccurrences(of: "^[\\*\\-\\•]\\s*", with: "", options: .regularExpression)
                                        .replacingOccurrences(of: "\\*", with: "")
                                    return SummaryLine(text: clean, isHeader: false)
                                }
                            }
                            .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                        ForEach(lines) { line in
                            Text(LocalizedStringKey(line.isHeader ? "**\(line.text)**" : line.text))
                                .font(line.isHeader ? .body : .subheadline)
                                .textSelection(.enabled)
                                .lineLimit(nil)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, line.isHeader ? 6 : 0)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 140)
            }
        }
        .padding(16)
        .applyGlassViewIfAvailable(cornerRadius: 20)
        .modifier(AIGlowModifier(isGenerating: viewModel.isGeneratingSummary))
        .onHover { hovering in
            isHovering = hovering
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct AIGlowModifier: ViewModifier {
    let isGenerating: Bool
    @State private var glowOpacity: Double = 0.15
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.accentColor, lineWidth: isGenerating ? 2.0 : 1.0)
                    .opacity(glowOpacity)
            )
            .shadow(
                color: Color.accentColor.opacity(glowOpacity),
                radius: isGenerating ? 12 : 6,
                x: 0,
                y: 0
            )
            .onAppear {
                updateGlowState(isGenerating: isGenerating)
            }
            .onChange(of: isGenerating) { _, newValue in
                updateGlowState(isGenerating: newValue)
            }
    }
    
    private func updateGlowState(isGenerating: Bool) {
        if isGenerating {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowOpacity = 0.8
            }
        } else {
            withAnimation(.easeOut(duration: 2.0)) {
                glowOpacity = 0.15
            }
        }
    }
}
