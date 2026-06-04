//
//  AppNotificationSettingsView.swift
//  AirSync
//
//  Created by Antigravity on 2026-06-04.
//

import SwiftUI

struct AppNotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let app: AndroidApp

    var body: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
            
            VStack(spacing: 0) {
                // Header (Title & Icon on left, Close button on right end)
                HStack(spacing: 12) {
                    if let iconPath = app.iconUrl,
                       let image = Image(filePath: iconPath) {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .cornerRadius(5)
                    } else {
                        Image(systemName: "app.badge")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.gray)
                    }
                    
                    Text(String(format: L("settings.notifications.app.settings"), app.name))
                        .font(.headline)
                        .bold()
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                Divider()
                
                VStack(spacing: 12) {
                    Spacer()
                    Text(L("settings.notifications.app.noSettings"))
                        .foregroundColor(.secondary)
                        .font(.body)
                    Spacer()
                }
                .padding(16)
            }
        }
        .frame(width: 450, height: 250)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(radius: 20)
    }
}
