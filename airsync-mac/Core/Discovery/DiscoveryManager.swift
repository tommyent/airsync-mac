import Foundation
import Combine

class DiscoveryManager: ObservableObject {
    static let shared = DiscoveryManager()
    
    @Published var discoveredDevices: [DiscoveredDevice] = []
    
    private let bonjourAdvertiser = BonjourServiceAdvertiser()
    private let bonjourBrowser = BonjourServiceBrowser()
    private let udpDiscovery = UdpBroadcastDiscovery()
    
    private var mdnsDevices: [String: DiscoveredDevice] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    
    private init() {
        setupBonjourBrowser()
        setupUdpDiscoveryObserver()
    }
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        print("[Discovery] Starting DiscoveryManager")
        bonjourAdvertiser.start()
        bonjourBrowser.start()
        udpDiscovery.start()
    }
    
    func stop() {
        guard isRunning else { return }
        isRunning = false
        
        print("[Discovery] Stopping DiscoveryManager")
        bonjourAdvertiser.stop()
        bonjourBrowser.stop()
        udpDiscovery.stop()
        
        mdnsDevices.removeAll()
        discoveredDevices.removeAll()
    }
    
    func broadcastBurst() {
        udpDiscovery.broadcastBurst()
    }
    
    private func setupBonjourBrowser() {
        bonjourBrowser.onDeviceDiscovered = { [weak self] device in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.mdnsDevices[device.deviceId] = device
                self.mergeAndPublish()
            }
        }
        
        bonjourBrowser.onDeviceLost = { [weak self] deviceId in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.mdnsDevices.removeValue(forKey: deviceId)
                self.mergeAndPublish()
            }
        }
    }
    
    private func setupUdpDiscoveryObserver() {
        udpDiscovery.$discoveredDevices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.mergeAndPublish()
            }
            .store(in: &cancellables)
    }
    
    private func mergeAndPublish() {
        var merged: [String: DiscoveredDevice] = [:]
        
        for device in udpDiscovery.discoveredDevices {
            merged[device.deviceId] = device
        }
        
        for (_, device) in mdnsDevices {
            if let existing = merged[device.deviceId] {
                let mergedIps = existing.ips.union(device.ips)
                let mergedDevice = DiscoveredDevice(
                    deviceId: device.deviceId,
                    name: device.name,
                    ips: mergedIps,
                    port: device.port,
                    type: device.type,
                    lastSeen: max(existing.lastSeen, device.lastSeen),
                    discoverySource: .mdns
                )
                merged[device.deviceId] = mergedDevice
            } else {
                merged[device.deviceId] = device
            }
        }
        
        self.discoveredDevices = Array(merged.values)
    }
}
