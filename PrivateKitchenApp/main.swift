import SwiftUI

@main
struct PrivateKitchenApp: App {
    // 配置数据容器
    let modelContainer = DataInitializer.configureModelContainer()

    // 初始化管理器
    @StateObject private var dataManager: DataManager
    @StateObject private var syncManager = SyncManager()
    @StateObject private var settingsManager: AppSettingsManager
    @StateObject private var themeManager = ThemeManager(settingsManager: AppSettingsManager(modelContext: modelContainer.mainContext))

    init() {
        let context = modelContainer.mainContext
        let initialData = DataInitializer.shared.initializeData(modelContext: context)
        _dataManager = StateObject(wrappedValue: initialData)

        let settingsContext = AppSettingsManager(modelContext: context)
        _settingsManager = StateObject(wrappedValue: settingsContext)
        _themeManager = StateObject(wrappedValue: ThemeManager(settingsManager: settingsContext))
    }

    var body: some Scene {
        WindowGroup {
            LaunchView()
                .modelContainer(modelContainer)
                .environmentObject(dataManager)
                .environmentObject(syncManager)
                .environmentObject(settingsManager)
                .environmentObject(themeManager)
                .preferredColorScheme(settingsManager.settings.darkMode ? .dark : .light)
        }
    }
}