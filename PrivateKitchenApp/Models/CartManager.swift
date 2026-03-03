import Foundation
import SwiftUI
import SwiftData

// 购物车管理器
@MainActor
class CartManager: ObservableObject {
    @Published var cartItems: [CartItem] = []
    @Published var isEmpty: Bool = true
    @Published var totalPrice: Double = 0.0
    @Published var totalQuantity: Int = 0
    @Published var isLoading = false
    @Published var error: String?

    private let modelContext: ModelContext
    private let dataManager: DataManager

    init(modelContext: ModelContext, dataManager: DataManager) {
        self.modelContext = modelContext
        self.dataManager = dataManager
        loadCart()
    }

    // MARK: - 公共方法

    /// 添加商品到购物车
    func addItem(_ dish: Dish, quantity: Int = 1, note: String? = nil) -> Bool {
        // 检查菜品是否可用
        guard dish.isAvailable else {
            error = "\(dish.name) 已下架"
            return false
        }

        // 查找是否已存在该菜品
        if let existingIndex = cartItems.firstIndex(where: { $0.dish.id == dish.id }) {
            // 如果已存在，增加数量
            cartItems[existingIndex].quantity += quantity
        } else {
            // 创建新的购物车项
            let cartItem = CartItem(dish: dish, quantity: quantity)
            cartItems.append(cartItem)
            modelContext.insert(cartItem)
        }

        saveCart()
        updateSummary()

        // 发送通知
        NotificationCenter.default.post(name: .cartItemAdded, object: dish.name)

        return true
    }

    /// 更新购物车项数量
    func updateQuantity(_ cartItem: CartItem, newQuantity: Int) -> Bool {
        guard let index = cartItems.firstIndex(where: { $0.id == cartItem.id }) else {
            error = "找不到购物车项"
            return false
        }

        if newQuantity <= 0 {
            // 如果数量为0或负数，移除该项
            removeItem(at: index)
        } else {
            cartItems[index].quantity = newQuantity
            saveCart()
            updateSummary()
        }

        return true
    }

    /// 移除购物车项
    func removeItem(_ cartItem: CartItem) -> Bool {
        guard let index = cartItems.firstIndex(where: { $0.id == cartItem.id }) else {
            return false
        }

        return removeItem(at: index)
    }

    /// 根据索引移除购物车项
    private func removeItem(at index: Int) -> Bool {
        let removedItem = cartItems.remove(at: index)
        modelContext.delete(removedItem)

        saveCart()
        updateSummary()

        // 发送通知
        NotificationCenter.default.post(name: .cartItemRemoved, object: removedItem.dish.name)

        return true
    }

    /// 清空购物车
    func clearCart() -> Bool {
        do {
            // 逐个删除购物车项
            for cartItem in cartItems {
                modelContext.delete(cartItem)
            }

            cartItems.removeAll()
            saveCart()
            updateSummary()

            // 发送通知
            NotificationCenter.default.post(name: .cartCleared)

            return true
        } catch {
            error = "清空购物车失败: \(error.localizedDescription)"
            return false
        }
    }

    /// 从购物车移除已下架的菜品
    func removeUnavailableItems() {
        let unavailableItems = cartItems.filter { !$0.dish.isAvailable }

        for item in unavailableItems {
            guard let index = cartItems.firstIndex(where: { $0.id == item.id }) else { continue }
            removeItem(at: index)
        }

        if !unavailableItems.isEmpty {
            error = "已从购物车移除 \(unavailableItems.count) 个已下架的商品"
        }
    }

    /// 获取菜品在购物车中的数量
    func getQuantity(of dish: Dish) -> Int {
        return cartItems.first(where: { $0.dish.id == dish.id })?.quantity ?? 0
    }

    /// 检查菜品是否已在购物车中
    func contains(_ dish: Dish) -> Bool {
        return cartItems.contains { $0.dish.id == dish.id }
    }

    /// 检查购物车是否可以结算
    func canCheckout() -> Bool {
        return !cartItems.isEmpty && cartItems.allSatisfy { $0.dish.isAvailable }
    }

    /// 获取购物车摘要
    func getCartSummary() -> CartSummary {
        return CartSummary(
            items: cartItems,
            totalPrice: totalPrice,
            totalQuantity: totalQuantity,
            itemCount: cartItems.count
        )
    }

    // MARK: - 私有方法

    /// 加载购物车
    private func loadCart() {
        // 在实际应用中，这里可以从持久化存储加载购物车
        // 目前使用内存中的数据
        updateSummary()
    }

    /// 保存购物车
    private func saveCart() {
        do {
            try modelContext.save()
        } catch {
            error = "保存购物车失败: \(error.localizedDescription)"
        }
    }

    /// 更新购物车摘要
    private func updateSummary() {
        totalPrice = cartItems.reduce(0) { total, item in
            total + (item.dish.price * Double(item.quantity))
        }

        totalQuantity = cartItems.reduce(0) { total, item in
            total + item.quantity
        }

        isEmpty = cartItems.isEmpty

        // 检查是否有已下架的菜品
        if cartItems.contains(where: { !$0.dish.isAvailable }) {
            removeUnavailableItems()
        }
    }
}

// MARK: - 购物车摘要
struct CartSummary {
    let items: [CartItem]
    let totalPrice: Double
    let totalQuantity: Int
    let itemCount: Int

    var isEmpty: Bool {
        return items.isEmpty
    }

    var formattedTotalPrice: String {
        return "$\(totalPrice, specifier: "%.2f")"
    }
}

// MARK: - 扩展通知
extension Notification.Name {
    static let cartItemAdded = Notification.Name("cartItemAdded")
    static let cartItemRemoved = Notification.Name("cartItemRemoved")
    static let cartCleared = Notification.Name("cartCleared")
    static let cartUpdated = Notification.Name("cartUpdated")
}