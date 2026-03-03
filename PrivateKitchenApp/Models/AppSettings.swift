import Foundation
import SwiftUI
import SwiftData

// 应用设置
@Model
class AppSettings: ObservableObject {
    var id = UUID()
    var darkMode: Bool = false
    var language: String = "zh-CN"
    var currency: String = "CNY"
    var syncOnWiFiOnly: Bool = true
    autoSync: Bool = true
    syncInterval: TimeInterval = 3600 // 1小时
    notificationEnabled: Bool = true
    soundEnabled: Bool = true
    hapticEnabled: Bool = true
    lastSyncTime: Date?

    // 支付设置
    defaultPaymentMethod: String = "wechat"
    paymentPassword: String?

    // 显示设置
    showImages: Bool = true
    fontSize: Int = 17
    compactLayout: Bool = false

    // 数据备份设置
    autoBackup: Bool = false
    backupInterval: TimeInterval = 86400 // 24小时

    init() {
        self.id = UUID()
    }
}

// 应用配置管理器
@MainActor
class AppSettingsManager: ObservableObject {
    @Published var settings: AppSettings
    @Published var isLoading = false
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.settings = AppSettings()
        loadSettings()
    }

    // 加载设置
    private func loadSettings() {
        do {
            let descriptor = FetchDescriptor<AppSettings>()
            let settings = try modelContext.fetch(descriptor)
            if let existingSettings = settings.first {
                self.settings = existingSettings
            } else {
                // 创建默认设置
                self.createDefaultSettings()
            }
        } catch {
            print("Error loading settings: \(error)")
        }
    }

    // 创建默认设置
    private func createDefaultSettings() {
        do {
            let defaultSettings = AppSettings()
            modelContext.insert(defaultSettings)
            try modelContext.save()
            self.settings = defaultSettings
        } catch {
            print("Error creating default settings: \(error)")
        }
    }

    // 保存设置
    func saveSettings() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            print("Error saving settings: \(error)")
            return false
        }
    }

    // MARK: - 设置更新方法

    // 外观设置
    func updateAppearance(darkMode: Bool) {
        settings.darkMode = darkMode
        saveSettings()
    }

    // 同步设置
    func updateSyncSettings(autoSync: Bool, syncOnWiFiOnly: Bool, syncInterval: TimeInterval) {
        settings.autoSync = autoSync
        settings.syncOnWiFiOnly = syncOnWiFiOnly
        settings.syncInterval = syncInterval
        saveSettings()
    }

    // 通知设置
    func updateNotificationSettings(enabled: Bool, sound: Bool, haptic: Bool) {
        settings.notificationEnabled = enabled
        settings.soundEnabled = sound
        settings.hapticEnabled = haptic
        saveSettings()
    }

    // 支付设置
    func updatePaymentSettings(method: String) {
        settings.defaultPaymentMethod = method
        saveSettings()
    }

    // 显示设置
    func updateDisplaySettings(showImages: Bool, fontSize: Int, compactLayout: Bool) {
        settings.showImages = showImages
        settings.fontSize = fontSize
        settings.compactLayout = compactLayout
        saveSettings()
    }

    // MARK: - 获取设置值

    var isDarkMode: Bool {
        return settings.darkMode
    }

    var isSyncEnabled: Bool {
        return settings.autoSync
    }

    var isWiFiOnly: Bool {
        return settings.syncOnWiFiOnly
    }

    var syncIntervalHours: Double {
        return settings.syncInterval / 3600
    }

    var isNotificationEnabled: Bool {
        return settings.notificationEnabled
    }

    // MARK: - 主题管理

    // 获取应用主题
    var appTheme: AppTheme {
        return AppTheme(
            primaryColor: Color.orange,
            secondaryColor: Color.orange.opacity(0.7),
            backgroundColor: Color(UIColor.systemBackground),
            textColor: Color.primary,
            accentColor: Color.orange,
            shadowColor: Color.black.opacity(0.1)
        )
    }
}

// 应用主题结构
struct AppTheme {
    let primaryColor: Color
    let secondaryColor: Color
    let backgroundColor: Color
    let textColor: Color
    let accentColor: Color
    let shadowColor: Color
}

// 主题管理器
@MainActor
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme
    private let settingsManager: AppSettingsManager

    init(settingsManager: AppSettingsManager) {
        self.settingsManager = settingsManager
        self.currentTheme = settingsManager.appTheme
    }

    // 更新主题
    func updateTheme() {
        currentTheme = settingsManager.appTheme
    }
}