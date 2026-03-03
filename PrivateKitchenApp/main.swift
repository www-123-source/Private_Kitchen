import SwiftUI

@main
struct PrivateKitchenApp: App {
    // 配置数据容器
    let modelContainer = DataInitializer.configureModelContainer()

    // 初始化管理器
    @StateObject private var dataManager: DataManager
    @StateObject private var syncManager = SyncManager()
    @StateObject private var paymentManager = PaymentManager()
    @StateObject private var settingsManager: AppSettingsManager
    @StateObject private var themeManager = ThemeManager(settingsManager: AppSettingsManager(modelContext: modelContainer.mainContext))

    init() {
        let context = modelContainer.mainContext
        let initialData = DataInitializer.shared.initializeData(modelContext: context)
        _dataManager = StateObject(wrappedValue: initialData)

        let settingsContext = AppSettingsManager(modelContext: context)
        _settingsManager = StateObject(wrappedValue: settingsContext)
        _themeManager = StateObject(wrappedValue: ThemeManager(settingsManager: settingsContext))

        let paymentManager = PaymentManager(modelContext: context)
        _paymentManager = StateObject(wrappedValue: paymentManager)

        let orderManager = OrderManager(modelContext: context, dataManager: initialData)
        let orderFlowManager = OrderFlowManager(
            modelContext: context,
            dataManager: initialData,
            orderManager: orderManager
        )

        _orderFlowManager = StateObject(wrappedValue: orderFlowManager)
    }

    var body: some Scene {
        WindowGroup {
            LaunchView()
                .modelContainer(modelContainer)
                .environmentObject(dataManager)
                .environmentObject(syncManager)
                .environmentObject(paymentManager)
                .environmentObject(settingsManager)
                .environmentObject(themeManager)
                .environmentObject(CartManager(modelContext: modelContainer.mainContext, dataManager: dataManager))
                .environmentObject(orderFlowManager)
                .preferredColorScheme(settingsManager.settings.darkMode ? .dark : .light)
        }
    }
}