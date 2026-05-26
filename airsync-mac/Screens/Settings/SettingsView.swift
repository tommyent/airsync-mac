import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState = AppState.shared

    var body: some View {
        Group {
            switch appState.selectedSettingsTab {
            case .myMac:
                MyMacSettingsView()
            case .sync:
                SyncSettingsView()
            case .mirroring:
                MirroringSettingsView()
            case .quickShare:
                QuickShareSettingsView()
            case .menubar:
                MenubarSettingsView()
            case .appearance:
                AppearanceSettingsView()
            case .airsyncPlus:
                AirSyncPlusSettingsView()
            }
        }
        .frame(minWidth: 300)
    }
}
