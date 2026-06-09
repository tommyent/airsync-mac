import Foundation
import Combine
import Network

class DiscoveryManager: ObservableObject {
    static let shared = DiscoveryManager()
    
    @Published var discoveredDevices: [DiscoveredDevice] = []
    
    private let bonjourAdvertiser = BonjourServiceAdvertiser()
    private let bonjourBrowser = BonjourServiceBrowser()
    private let udpDiscovery = UdpBroadcastDiscovery()
    
    private var mdnsDevices: [String: DiscoveredDevice] = [:]
    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    private var networkMonitor: NWPathMonitor?
    
    private init() {
        setupBonjourBrowser()
        setupUdpDiscoveryObserver()
        setupNetworkMonitor()
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
            let filteredIps = device.ips.filter { isIPOnLocalNetwork($0) }
            if !filteredIps.isEmpty {
                var d = device
                d.ips = filteredIps
                merged[device.deviceId] = d
            }
        }
        
        for (_, device) in mdnsDevices {
            let filteredIps = device.ips.filter { isIPOnLocalNetwork($0) }
            guard !filteredIps.isEmpty else { continue }
            
            var d = device
            d.ips = filteredIps
            
            if let existing = merged[device.deviceId] {
                let mergedIps = existing.ips.union(d.ips)
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
                merged[device.deviceId] = d
            }
        }
        
        self.discoveredDevices = Array(merged.values)
    }
    
    private func isIPOnLocalNetwork(_ targetIP: String) -> Bool {
        if targetIP == "Bluetooth LE" || targetIP == "Nearby" {
            return true
        }
        
        let adapters = WebSocketServer.shared.getAvailableNetworkAdapters()
        guard !adapters.isEmpty else { return false }
        
        for adapter in adapters {
            if areOnSameSubnet(targetIP, adapter.address) {
                return true
            }
        }
        return false
    }
    
    private func areOnSameSubnet(_ ip1: String, _ ip2: String) -> Bool {
        let p1 = ip1.split(separator: ".")
        let p2 = ip2.split(separator: ".")
        guard p1.count == 4 && p2.count == 4 else { return false }
        
        if ip1.hasPrefix("100.") && ip2.hasPrefix("100.") {
            return true
        }
        if ip1.hasPrefix("192.168.") && ip2.hasPrefix("192.168.") {
            return p1[0] == p2[0] && p1[1] == p2[1] && p1[2] == p2[2]
        }
        return p1[0] == p2[0] && p1[1] == p2[1]
    }
    
    private func setupNetworkMonitor() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            print("[DiscoveryManager] Network path update: \(path.status)")
            
            DispatchQueue.main.async {
                // Clear out stale network devices on network change/disconnect
                self.mdnsDevices.removeAll()
                self.udpDiscovery.discoveredDevices.removeAll()
                self.mergeAndPublish()
                
                // Restart Bonjour browser to trigger fresh searches on the new interface
                if self.isRunning {
                    self.bonjourBrowser.stop()
                    self.bonjourBrowser.start()
                }
            }
        }
        self.networkMonitor = monitor
        monitor.start(queue: DispatchQueue(label: "com.airsync.discoveryManager.network"))
    }
}
