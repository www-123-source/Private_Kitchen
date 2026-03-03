import Foundation
import SwiftData
import SwiftUI

// 同步状态枚举
enum SyncStatus: String, CaseIterable {
    case idle = "空闲"
    case syncing = "同步中"
    case success = "同步成功"
    case failed = "同步失败"
    case offline = "离线"
}

// 同步类型枚举
enum SyncType: String, CaseIterable {
    case realTime = "实时同步"
    case scheduled = "定时同步"
    case manual = "手动同步"
}

// 同步管理器
class SyncManager: ObservableObject {
    @Published var status: SyncStatus = .idle
    @Published var lastSyncTime: Date?
    @Published var syncProgress: Double = 0.0
    @Published var syncType: SyncType = .realTime
    @Published var isOnline: Bool = true
    @Published var syncSettings: SyncSettings = SyncSettings()

    private var syncTimer: Timer?
    private let networkMonitor = NetworkMonitor()

    init() {
        setupNetworkMonitoring()
        setupSyncTimer()
    }

    // 设置网络监控
    private func setupNetworkMonitoring() {
        networkMonitor.startMonitoring()
        networkMonitor.networkStatusDidChange = { [weak self] isOnline in
            self?.isOnline = isOnline
            if isOnline && self?.status == .offline {
                self?.status = .idle
            }
        }
    }

    // 设置同步定时器
    private func setupSyncTimer() {
        if syncType == .scheduled {
            setupScheduledSync()
        }
    }

    // 设置定时同步
    private func setupScheduledSync() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncSettings.syncInterval, repeats: true) { [weak self] _ in
            self?.performSync()
        }
    }

    // 执行同步
    func performSync() {
        guard isOnline else {
            status = .offline
            return
        }

        status = .syncing
        syncProgress = 0.0

        // 模拟同步过程
        DispatchQueue.global().async {
            for i in 1...10 {
                DispatchQueue.main.async {
                    self.syncProgress = Double(i) * 10.0
                }
                Thread.sleep(forTimeInterval: 0.1)
            }

            DispatchQueue.main.async {
                self.status = .success
                self.lastSyncTime = Date()
                self.syncProgress = 0.0
            }
        }
    }

    // 手动同步
    func manualSync() {
        performSync()
    }

    // 更新同步设置
    func updateSettings(_ settings: SyncSettings) {
        syncSettings = settings
        if syncType == .scheduled {
            setupScheduledSync()
        }
    }

    // 清理资源
    deinit {
        syncTimer?.invalidate()
        networkMonitor.stopMonitoring()
    }
}

// 网络监控器
class NetworkMonitor {
    var networkStatusDidChange: ((Bool) -> Void)?
    private var monitor: NWPathMonitor?
    private var queue: DispatchQueue

    init() {
        queue = DispatchQueue(label: "NetworkMonitor")
        monitor = NWPathMonitor()
    }

    func startMonitoring() {
        monitor?.pathUpdateHandler = { [weak self] path in
            let isOnline = path.status == .satisfied
            DispatchQueue.main.async {
                self?.networkStatusDidChange?(isOnline)
            }
        }
        monitor?.start(queue: queue)
    }

    func stopMonitoring() {
        monitor?.cancel()
    }
}

// 同步设置模型
struct SyncSettings: Codable {
    var syncType: SyncType = .realTime
    var syncInterval: TimeInterval = 3600 // 1小时
    var syncOnWiFiOnly: Bool = true
    var autoSync: Bool = true
}