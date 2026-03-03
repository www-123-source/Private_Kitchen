import Foundation
import SwiftUI
import SwiftData

// 订单管理器 - 处理订单相关的业务逻辑
@MainActor
class OrderManager: ObservableObject {
    @Published var currentOrders: [Order] = []
    @Published var isLoading = false
    @Published var error: String?

    private let modelContext: ModelContext
    private let dataManager: DataManager

    init(modelContext: ModelContext, dataManager: DataManager) {
        self.modelContext = modelContext
        self.dataManager = dataManager
        loadCurrentOrders()
    }

    // 加载当前订单
    private func loadCurrentOrders() {
        currentOrders = dataManager.getOrdersByStatus(.pending) + dataManager.getOrdersByStatus(.confirmed)
    }

    // 创建新订单
    func createOrderFromCart(cartItems: [CartItem]) -> Order? {
        guard let member = dataManager.currentUser else {
            error = "请先登录"
            return nil
        }

        // 转换购物车项为订单项
        let orderItems = cartItems.map { cartItem -> OrderItem in
            OrderItem(
                dishId: cartItem.dish.id,
                dishName: cartItem.dish.name,
                price: cartItem.dish.price,
                quantity: cartItem.quantity,
                note: "请加快制作"
            )
        }

        return dataManager.createOrder(items: orderItems, note: "通过购物车下单")
    }

    // 更新订单状态
    func updateOrderStatus(_ order: Order, newStatus: OrderStatus) -> Bool {
        return dataManager.updateOrderStatus(order, status: newStatus)
    }

    // 确认订单（管理员操作）
    func confirmOrder(_ order: Order) -> Bool {
        return updateOrderStatus(order, status: .confirmed)
    }

    // 开始制作（管理员操作）
    func startCooking(_ order: Order) -> Bool {
        return updateOrderStatus(order, status: .cooking)
    }

    // 完成制作（管理员操作）
    func completeOrder(_ order: Order) -> Bool {
        return updateOrderStatus(order, status: .ready)
    }

    // 上菜（管理员操作）
    func deliverOrder(_ order: Order) -> Bool {
        return updateOrderStatus(order, status: .delivered)
    }

    // 取消订单
    func cancelOrder(_ order: Order) -> Bool {
        return updateOrderStatus(order, status: .cancelled)
    }

    // 订单支付成功后的处理
    func handlePaymentSuccess(for order: Order) -> Bool {
        // 更新订单状态
        if updateOrderStatus(order, status: .confirmed) {
            // 发送通知
            sendOrderNotification(order, message: "订单已确认，开始制作")

            // 记录日志
            logOrderEvent(order, event: "Payment Success", details: "Order confirmed after payment")

            return true
        }

        return false
    }

    // 发送订单通知
    private func sendOrderNotification(_ order: Order, message: String) {
        // 这里可以集成推送通知服务
        print("Notification for order \(order.orderNumber): \(message)")
    }

    // 记录订单事件
    private func logOrderEvent(_ order: Order, event: String, details: String) {
        // 这里可以集成日志服务
        print("Order Event - \(event): Order \(order.orderNumber) - \(details)")
    }

    // 获取订单统计信息
    func getOrderStatistics() -> OrderStatistics {
        let allOrders = dataManager.getAllOrders()
        let pendingOrders = dataManager.getOrdersByStatus(.pending)
        let confirmedOrders = dataManager.getOrdersByStatus(.confirmed)
        let cookingOrders = dataManager.getOrdersByStatus(.cooking)
        let completedOrders = dataManager.getOrdersByStatus(.ready) + dataManager.getOrdersByStatus(.delivered)
        let cancelledOrders = dataManager.getOrdersByStatus(.cancelled)

        return OrderStatistics(
            total: allOrders.count,
            pending: pendingOrders.count,
            confirmed: confirmedOrders.count,
            cooking: cookingOrders.count,
            completed: completedOrders.count,
            cancelled: cancelledOrders.count,
            totalRevenue: completedOrders.reduce(0.0) { $0 + $1.totalAmount },
            averageOrderAmount: completedOrders.isEmpty ? 0 : completedOrders.reduce(0.0) { $0 + $1.totalAmount } / Double(completedOrders.count)
        )
    }
}

// 订单统计信息
struct OrderStatistics {
    let total: Int
    let pending: Int
    let confirmed: Int
    let cooking: Int
    let completed: Int
    let cancelled: Int
    let totalRevenue: Double
    let averageOrderAmount: Double

    var completionRate: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total) * 100
    }

    var cancellationRate: Double {
        guard total > 0 else { return 0 }
        return Double(cancelled) / Double(total) * 100
    }
}