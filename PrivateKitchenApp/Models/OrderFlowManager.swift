import Foundation
import SwiftUI
import SwiftData

// 订单流程管理器 - 管理订单的生命周期和状态流转
@MainActor
class OrderFlowManager: ObservableObject {
    @Published var currentOrders: [Order] = []
    @Published var activeTimers: [UUID: Timer] = [:]
    @Published var orderNotifications: [OrderNotification] = []

    private let modelContext: ModelContext
    private let dataManager: DataManager
    private let orderManager: OrderManager
    private let notificationManager = NotificationManager()

    init(modelContext: ModelContext, dataManager: DataManager, orderManager: OrderManager) {
        self.modelContext = modelContext
        self.dataManager = dataManager
        self.orderManager = orderManager

        // 监听订单状态变化
        setupOrderStatusMonitoring()
    }

    deinit {
        // 清理所有定时器
        activeTimers.values.forEach { $0.invalidate() }
    }

    // MARK: - 订单创建流程

    /// 从购物车创建订单
    func createOrderFromCart(cartItems: [CartItem], note: String? = nil) -> Order? {
        // 生成订单号
        let orderNumber = generateOrderNumber()

        // 验证购物车项
        let validItems = cartItems.filter { $0.dish.isAvailable }
        if validItems.isEmpty {
            return nil
        }

        // 创建订单
        let order = dataManager.createOrder(
            items: validItems.map { cartItem -> OrderItem in
                OrderItem(
                    dishId: cartItem.dish.id,
                    dishName: cartItem.dish.name,
                    price: cartItem.dish.price,
                    quantity: cartItem.quantity,
                    note: nil
                )
            },
            note: note
        )

        guard let order = order else { return nil }

        // 设置初始状态
        order.status = .pending
        order.orderNumber = orderNumber

        // 记录初始状态时间线
        addOrderTimeline(order: order, status: .pending, message: "订单已创建")

        // 保存订单
        do {
            try modelContext.save()
        } catch {
            print("Error saving order: \(error)")
            return nil
        }

        // 添加到当前订单列表
        currentOrders.append(order)

        // 发送订单创建通知
        sendOrderNotification(order, type: .created, message: "新订单 #\(order.orderNumber)")

        return order
    }

    // MARK: - 支付集成

    /// 处理支付成功
    func handlePaymentSuccess(for order: Order, paymentMethod: PaymentMethod) {
        // 更新订单状态为已确认
        if orderManager.confirmOrder(order) {
            // 记录支付成功
            addOrderTimeline(order: order, status: .confirmed, message: "已通过\(paymentMethod.rawValue)支付")

            // 发送支付成功通知
            sendOrderNotification(order, type: .confirmed, message: "订单已确认，开始制作")

            // 启动烹饪定时器（如果配置了）
            startCookingTimer(for: order)
        }
    }

    // MARK: - 状态流转管理

    /// 开始烹饪
    func startCooking(for order: Order) {
        guard order.status == .confirmed else { return }

        if orderManager.startCooking(order) {
            addOrderTimeline(order: order, status: .cooking, message: "开始制作")
            sendOrderNotification(order, type: .cooking, message: "正在制作您的订单")

            // 设置烹饪完成定时器（默认30分钟）
            startCookingTimer(for: order, duration: 30 * 60)
        }
    }

    /// 完成制作
    func completeOrder(for order: Order) {
        guard order.status == .cooking else { return }

        if orderManager.completeOrder(order) {
            addOrderTimeline(order: order, status: .ready, message: "制作完成，可以上菜了")
            sendOrderNotification(order, type: .ready, message: "订单已完成，可以上菜")

            // 取消烹饪定时器
            cancelCookingTimer(for: order)
        }
    }

    /// 上菜
    func deliverOrder(for order: Order) {
        guard order.status == .ready else { return }

        if orderManager.deliverOrder(order) {
            addOrderTimeline(order: order, status: .delivered, message: "已上菜")
            sendOrderNotification(order, type: .delivered, message: "订单已送达")

            // 清理定时器
            cancelCookingTimer(for: order)

            // 记录完成时间
            order.completedAt = Date()

            // 保存状态
            saveOrder(order)
        }
    }

    /// 取消订单
    func cancelOrder(for order: Order, reason: String = "用户取消") {
        if orderManager.cancelOrder(order) {
            addOrderTimeline(order: order, status: .cancelled, message: "订单已取消: \(reason)")
            sendOrderNotification(order, type: .cancelled, message: "订单已取消")

            // 取消定时器
            cancelCookingTimer(for: order)

            // 清理订单
            currentOrders.removeAll { $0.id == order.id }
        }
    }

    // MARK: - 定时器管理

    /// 启动烹饪定时器
    private func startCookingTimer(for order: Order, duration: TimeInterval = 30 * 60) {
        // 取消现有定时器
        cancelCookingTimer(for: order)

        let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.handleCookingTimeout(for: order)
        }

        activeTimers[order.id] = timer
    }

    /// 取消烹饪定时器
    private func cancelCookingTimer(for order: Order) {
        if let timer = activeTimers.removeValue(forKey: order.id) {
            timer.invalidate()
        }
    }

    /// 处理烹饪超时
    private func handleCookingTimeout(for order: Order) {
        guard order.status == .cooking else { return }

        addOrderTimeline(order: order, status: .cooking, message: "制作超时，请尽快完成")
        sendOrderNotification(order, type: .warning, message: "订单制作已超时")
    }

    // MARK: - 订单时间线管理

    /// 添加订单时间线记录
    private func addOrderTimeline(order: Order, status: OrderStatus, message: String) {
        let timeline = OrderTimeline(
            orderID: order.id,
            status: status,
            message: message,
            timestamp: Date()
        )

        modelContext.insert(timeline)
    }

    // MARK: - 通知管理

    /// 发送订单通知
    private func sendOrderNotification(_ order: Order, type: OrderNotificationType, message: String) {
        let notification = OrderNotification(
            orderID: order.id,
            type: type,
            message: message,
            timestamp: Date()
        )

        orderNotifications.append(notification)

        // 发送系统通知
        notificationManager.sendOrderNotification(notification)
    }

    // MARK: - 监控设置

    /// 设置订单状态监控
    private func setupOrderStatusMonitoring() {
        // 监听支付成功事件
        NotificationCenter.default.addObserver(
            forName: .paymentSuccess,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let orderID = notification.userInfo?["orderID"] as? UUID,
               let paymentMethod = notification.userInfo?["paymentMethod"] as? PaymentMethod,
               let order = self?.dataManager.findOrder(id: orderID) {
                self?.handlePaymentSuccess(for: order, paymentMethod: paymentMethod)
            }
        }
    }

    // MARK: - 工具方法

    /// 生成订单号
    private func generateOrderNumber() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateStr = formatter.string(from: Date())
        let random = String(format: "%04d", Int.random(in: 0...9999))
        return "PK-\(dateStr)-\(random)"
    }

    /// 保存订单
    private func saveOrder(_ order: Order) {
        do {
            try modelContext.save()
        } catch {
            print("Error saving order: \(error)")
        }
    }

    // MARK: - 公共接口

    /// 获取订单的所有时间线
    func getOrderTimeline(for order: Order) -> [OrderTimeline] {
        do {
            let descriptor = FetchDescriptor<OrderTimeline>(
                predicate: #Predicate { $0.orderID == order.id },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching timeline: \(error)")
            return []
        }
    }

    /// 获取待处理的订单
    func getPendingOrders() -> [Order] {
        return currentOrders.filter { $0.status == .pending || $0.status == .confirmed }
    }

    /// 获取正在制作的订单
    func getCookingOrders() -> [Order] {
        return currentOrders.filter { $0.status == .cooking }
    }

    /// 清理已完成的订单
    func cleanupCompletedOrders() {
        currentOrders = currentOrders.filter { $0.status != .delivered }
    }
}

// MARK: - 订单时间线模型
@Model
class OrderTimeline: Identifiable {
    var id = UUID()
    var orderID: UUID
    var status: OrderStatus
    var message: String
    var timestamp: Date

    init(orderID: UUID, status: OrderStatus, message: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.orderID = orderID
        self.status = status
        self.message = message
        self.timestamp = timestamp
    }
}

// MARK: - 订单通知模型
struct OrderNotification: Identifiable {
    let id = UUID()
    var orderID: UUID
    var type: OrderNotificationType
    var message: String
    var timestamp: Date
    var isRead: Bool = false

    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.string(for: timestamp) ?? ""
    }
}

// MARK: - 通知类型
enum OrderNotificationType: String, CaseIterable {
    case created = "订单创建"
    case confirmed = "订单确认"
    case cooking = "制作中"
    case ready = "制作完成"
    case delivered = "已送达"
    case cancelled = "已取消"
    case warning = "警告"

    var color: Color {
        switch self {
        case .created: return .orange
        case .confirmed: return .blue
        case .cooking: return .yellow
        case .ready: return .green
        case .delivered: return .purple
        case .cancelled: return .red
        case .warning: return .orange
        }
    }
}

// MARK: - 通知管理器
class NotificationManager {
    func sendOrderNotification(_ notification: OrderNotification) {
        // 在实际应用中，这里会集成推送通知服务
        // 目前使用打印和系统通知

        print("Order Notification: \(notification.type.rawValue) - \(notification.message)")

        // 发送本地通知
        let content = UNMutableNotificationContent()
        content.title = "Private Kitchen"
        content.body = notification.message
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error)")
            }
        }
    }
}

// MARK: - 通知扩展
extension Notification.Name {
    static let paymentSuccess = Notification.Name("paymentSuccess")
}