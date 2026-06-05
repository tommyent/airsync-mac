//
//  AppleIntelligenceSettingsView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2026-06-05.
//

import SwiftUI

struct AppleIntelligenceSettingsView: View {
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Section 1: Disable AI
                headerSection(title: L("settings.appleIntelligence"), icon: "sparkles")
                VStack {
                    SettingsToggleView(
                        name: L("settings.notifications.ai.disableAll"),
                        icon: "sparkles.slash",
                        isOn: $appState.disableAllAIFeatures
                    )
                }
                .padding()
                .glassBoxIfAvailable(radius: 18)
                
                // Section 2: Notification summaries
                if !appState.disableAllAIFeatures {
                    headerSection(title: "Notification summaries", icon: "doc.text.magnifyingglass")
                    VStack {
                        SettingsToggleView(
                            name: L("settings.notifications.ai.showToolbarButton"),
                            icon: "sparkles",
                            isOn: $appState.showAIToolbarButton
                        )
                    }
                    .padding()
                    .glassBoxIfAvailable(radius: 18)
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func headerSection(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 8)
    }
}
