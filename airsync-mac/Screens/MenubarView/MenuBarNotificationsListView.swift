//
//  MenuBarNotificationsListView.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2025-09-02.
//

import SwiftUI

struct MenuBarNotificationsListView: View {
    @ObservedObject private var appState = AppState.shared
    private let displayLimit = 4
    
    var body: some View {
        let nonSilentNotifications = appState.notifications.filter { $0.priority != "silent" }
        return VStack(spacing: 6) {
            ForEach(nonSilentNotifications.prefix(displayLimit)) { notif in
                NotificationCardView(
                    notification: notif,
                    deleteNotification: { appState.removeNotification(notif) },
                    hideNotification: { appState.hideNotification(notif) }
                )
                .padding(6)
                .segmentStyle()
                .onTapGesture {
                    appState.handleNotificationTap(notif)
                    MenuBarManager.shared.hidePopover()
                }
            }
            
            if nonSilentNotifications.count > 0 {
                HStack(spacing: 6) {
                    if nonSilentNotifications.count > displayLimit {
                        Button {
                            AppDelegate.shared?.showAndActivateMainWindow()
                            MenuBarManager.shared.hidePopover()
                        } label: {
                            HStack(spacing: 6) {
                                Text("View more in app")
                                    .font(.system(size: 11, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .segmentStyle(cornerRadius: 20)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button {
                        appState.clearNotifications()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 28, height: 28)
 
                        if nonSilentNotifications.count <= displayLimit {
                            Text("Clear All")
                                .font(.system(size: 11, weight: .medium))
                                .padding(.trailing, 8)
                        }
                    }
                    .buttonStyle(.plain)
                    .segmentStyle(cornerRadius: 14)
                }
                .padding(.top, 4)
            }
        }
    }
}

#Preview {
    MenuBarNotificationsListView()
}
