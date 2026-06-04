//
//  NotificationsSettingsView.swift
//  AirSync
//
//  Created by Antigravity on 2026-06-04.
//

import SwiftUI
import UserNotifications

struct NotificationsSettingsView: View {
    @ObservedObject var appState = AppState.shared



    // State for notification permissions
    @State private var notificationsGranted = false
    @State private var notificationsChecked = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Notifications Sync
                headerSection(title: "Notifications Sync", icon: "bell.badge")
                VStack {
                    SettingsToggleView(name: "Sync notification dismissals", icon: "bell.badge", isOn: $appState.dismissNotif)

                    HStack {
                        Label("System Notifications", systemImage: "bell.badge")
                        Spacer()

                        if notificationsGranted {
                            Picker("", selection: $appState.notificationSound) {
                                Text("Default").tag("default")
                                ForEach(SystemSounds.availableSounds, id: \.self) { sound in
                                    Text(sound).tag(sound)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(minWidth: 100)

                            Button(action: {
                                SystemSounds.playSound(appState.notificationSound)
                            }) {
                                Image(systemName: "play.circle")
                            }
                            .buttonStyle(.borderless)
                            .help("Test notification sound")
                        } else {
                            GlassButtonView(
                                label: "Grant Permission",
                                systemImage: "bell.badge",
                                primary: true,
                                action: {
                                    openNotificationSettings()
                                }
                            )
                        }
                    }
                }
                .padding()
                .glassBoxIfAvailable(radius: 18)
                .onAppear {
                    checkNotificationPermissions()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    checkNotificationPermissions()
                }

                // 2. Call Alerts
                headerSection(title: "Call Alerts", icon: "phone")
                VStack {
                    HStack {
                        Label("Call Alert", systemImage: "phone")
                        Spacer()

                        Picker("", selection: $appState.callNotificationMode) {
                            ForEach(CallNotificationMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(minWidth: 120)
                    }

                    SettingsToggleView(name: "Ring for calls", icon: "speaker.wave.3", isOn: $appState.ringForCalls)
                }
                .padding()
                .glassBoxIfAvailable(radius: 18)
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

    // MARK: - Notification Permission Helpers
    func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsGranted = (settings.authorizationStatus == .authorized)
                notificationsChecked = true
            }
        }
    }

    func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}
