//
//  WhatsNewTourManager.swift
//  AirSync
//
//  Created by Sameera Sandakelum on 2026-05-29.
//

import Foundation
import Combine
import SwiftUI

enum WhatsNewTourItem: String, CaseIterable {
    case settings = "whatsnew_settings"
    case scanQR = "whatsnew_scan_qr"
    case nearbyDevices = "whatsnew_nearby_devices"
    case connectionPill = "whatsnew_connection_pill"
    case desktopMode = "whatsnew_desktop_mode"
    case firstNotification = "whatsnew_first_notification"
    case appsGrid = "whatsnew_apps_grid"
    
    var titleKey: String {
        switch self {
        case .settings: return "whatsnew.settings.title"
        case .scanQR: return "whatsnew.scan.title"
        case .nearbyDevices: return "whatsnew.nearby.title"
        case .connectionPill: return "whatsnew.connection.title"
        case .desktopMode: return "whatsnew.desktop.title"
        case .firstNotification: return "whatsnew.notification.title"
        case .appsGrid: return "whatsnew.apps.title"
        }
    }
    
    var messageKey: String {
        switch self {
        case .settings: return "whatsnew.settings.message"
        case .scanQR: return "whatsnew.scan.message"
        case .nearbyDevices: return "whatsnew.nearby.message"
        case .connectionPill: return "whatsnew.connection.message"
        case .desktopMode: return "whatsnew.desktop.message"
        case .firstNotification: return "whatsnew.notification.message"
        case .appsGrid: return "whatsnew.apps.message"
        }
    }
}

class WhatsNewTourManager: ObservableObject {
    static let shared = WhatsNewTourManager()
    
    @Published var activeItem: WhatsNewTourItem? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Observe AppState changes to re-evaluate active tour items dynamically
        AppState.shared.$selectedTab
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.evaluateActiveItem()
            }
            .store(in: &cancellables)
            
        AppState.shared.$device
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.evaluateActiveItem()
            }
            .store(in: &cancellables)
            
        AppState.shared.$adbConnected
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.evaluateActiveItem()
            }
            .store(in: &cancellables)

        AppState.shared.$notifications
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.evaluateActiveItem()
            }
            .store(in: &cancellables)

        AppState.shared.$isOnboardingActive
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.evaluateActiveItem()
            }
            .store(in: &cancellables)
    }
    
    func isDismissed(_ item: WhatsNewTourItem) -> Bool {
        UserDefaults.standard.bool(forKey: item.rawValue + "_dismissed")
    }
    
    func dismiss(_ item: WhatsNewTourItem) {
        UserDefaults.standard.set(true, forKey: item.rawValue + "_dismissed")
        evaluateActiveItem()
    }
    
    func resetAll() {
        for item in WhatsNewTourItem.allCases {
            UserDefaults.standard.set(false, forKey: item.rawValue + "_dismissed")
        }
        evaluateActiveItem()
    }
    
    private var hasNearbyDevices: Bool {
        let hasUdp = !UDPDiscoveryManager.shared.discoveredDevices.isEmpty
        let hasBle = AppState.shared.isBLEEnabled && !BLECentralManager.shared.discoveredBLEDevices.isEmpty
        return hasUdp || hasBle
    }
    
    func evaluateActiveItem() {
        let appState = AppState.shared
        
        // Do not show any popovers until onboarding is fully completed
        if UserDefaults.standard.needsOnboarding || appState.isOnboardingActive {
            activeItem = nil
            return
        }
        
        // Settings Tab tour
        if !isDismissed(.settings) && appState.selectedTab == .settings {
            activeItem = .settings
            return
        }
        
        // Scan QR tour (when not connected and scanner view is active)
        if !isDismissed(.scanQR) && appState.device == nil && appState.selectedTab == .qr {
            activeItem = .scanQR
            return
        }
        
        // Nearby devices list tour (when not connected, scanner view is active, and nearby devices discovered)
        if !isDismissed(.nearbyDevices) && appState.device == nil && appState.selectedTab == .qr && hasNearbyDevices {
            activeItem = .nearbyDevices
            return
        }
        
        // Connection status pill tour (when connected, settings tab not active, home/screen view active)
        if !isDismissed(.connectionPill) && appState.device != nil && appState.selectedTab != .settings {
            activeItem = .connectionPill
            return
        }
        
        // Desktop Mode button tour (when connected, adb connected, settings tab not active, home/screen view active)
        if !isDismissed(.desktopMode) && appState.device != nil && appState.adbConnected && appState.selectedTab != .settings {
            activeItem = .desktopMode
            return
        }
        
        // Notifications list tour (when connected, notifications tab is active, and there's at least one notification)
        if !isDismissed(.firstNotification) && appState.device != nil && appState.selectedTab == .notifications && !appState.notifications.isEmpty {
            activeItem = .firstNotification
            return
        }
        
        // Apps grid tour (when connected, apps tab is active)
        if !isDismissed(.appsGrid) && appState.device != nil && appState.selectedTab == .apps {
            activeItem = .appsGrid
            return
        }
        
        activeItem = nil
    }
}
