//
//  CrashManager.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2026-06-20.
//

import Foundation
import Cocoa
import KSCrashInstallations
import UniformTypeIdentifiers

class CrashManager {
    static let shared = CrashManager()
    
    private init() {}
    
    func install() {
        let installation = CrashInstallationStandard.shared
        // No URL is configured, ensuring reports remain strictly local
        let config = KSCrashConfiguration()
        config.monitors = [.machException, .signal]
        do {
            try installation.install(with: config)
        } catch {
            print("Failed to install KSCrash: \(error)")
        }
    }
    
    func hasReports() -> Bool {
        guard let reportStore = KSCrash.shared.reportStore else { return false }
        return !reportStore.reportIDs.isEmpty
    }
    
    func lastReportText() -> String? {
        guard let reportStore = KSCrash.shared.reportStore else { return nil }
        let reportIDs = reportStore.reportIDs
        guard !reportIDs.isEmpty else { return nil }
        
        // Get the latest report ID
        let sortedIDs = reportIDs.map { $0.int64Value }.sorted()
        guard let latestID = sortedIDs.last else { return nil }
        
        guard let reportDictionary = reportStore.report(for: latestID) else {
            return nil
        }
        
        // Since reportDictionary is KSCrashReportDictionary, we serialize its dictionary contents
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: reportDictionary.value, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            return "Failed to format crash report JSON: \(error.localizedDescription)"
        }
    }
    
    func checkAndNotify(mode: CrashReportingMode) {
        guard mode == .notify else { return }
        
        guard let reportStore = KSCrash.shared.reportStore else { return }
        let reportIDs = reportStore.reportIDs
        if !reportIDs.isEmpty {
            // Check if we have already notified about the current set of reports to avoid alerting repeatedly
            let sortedIDs = reportIDs.map { $0.int64Value }.sorted()
            guard let latestID = sortedIDs.last else { return }
            
            let lastNotifiedID = UserDefaults.standard.integer(forKey: "lastNotifiedCrashID")
            if Int64(lastNotifiedID) == latestID {
                return
            }
            
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Application Crash Detected"
                alert.informativeText = "AirSync encountered a crash during its previous run. You can view or save the crash report from the Help menu."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
                
                UserDefaults.standard.set(Int(latestID), forKey: "lastNotifiedCrashID")
            }
        }
    }
    
    func copyLastReport() {
        guard let reportText = lastReportText() else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(reportText, forType: .string)
    }
    
    func saveLastReport() {
        guard let reportText = lastReportText() else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.text]
        savePanel.nameFieldStringValue = "airsync_crash_report.txt"
        savePanel.title = "Save Crash Report"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try reportText.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "Error Saving Report"
                        alert.informativeText = error.localizedDescription
                        alert.alertStyle = .critical
                        alert.runModal()
                    }
                }
            }
        }
    }
}
