import Foundation
import SwiftUI
import SwiftData

// 数据管理器 - 统一管理所有数据模型的CRUD操作
@MainActor
class DataManager: ObservableObject {
    @Published var currentFamily: Family?
    @Published var currentUser: FamilyMember?
    @Published var isLoading = false
    @Published var error: String?

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - 家庭管理

    /// 创建新家庭
    func createFamily(name: String, adminName: String) -> Family? {
        do {
            let family = Family(name: name, adminId: UUID())
            let admin = FamilyMember(name: adminName, role: .admin, joinedAt: Date())
            admin.family = family
            family.members.append(admin)
            family.adminId = admin.id

            modelContext.insert(family)
            modelContext.insert(admin)
            try modelContext.save()

            currentFamily = family
            currentUser = admin
            return family
        } catch {
            self.error = "创建家庭失败: \(error.localizedDescription)"
            return nil
        }
    }

    /// 加入家庭
    func joinFamily(familyCode: String, memberName: String) -> Bool {
        do {
            // 这里应该通过familyCode查找家庭
            // 目前简化实现，假设我们知道家庭
            guard let family = currentFamily else {
                error = "请先选择家庭"
                return false
            }

            let member = FamilyMember(name: memberName, role: .member, joinedAt: Date())
            member.family = family
            family.members.append(member)

            modelContext.insert(member)
            try modelContext.save()

            currentUser = member
            return true
        } catch {
            error = "加入家庭失败: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 菜品管理

    /// 添加菜品
    func addDish(name: String, description: String, price: Double, category: DishCategory, imageData: Data? = nil) -> Dish? {
        guard let family = currentFamily else {
            error = "请先选择家庭"
            return nil
        }

        do {
            let dish = Dish(
                name: name,
                description: description,
                price: price,
                category: category,
                image: imageData,
                isAvailable: true
            )
            dish.family = family
            family.dishes.append(dish)

            modelContext.insert(dish)
            try modelContext.save()

            return dish
        } catch {
            error = "添加菜品失败: \(error.localizedDescription)"
            return nil
        }
    }

    /// 更新菜品
    func updateDish(_ dish: Dish, name: String, description: String, price: Double, category: DishCategory, imageData: Data? = nil, isAvailable: Bool = true) -> Bool {
        do {
            dish.name = name
            dish.description = description
            dish.price = price
            dish.category = category
            dish.image = imageData
            dish.isAvailable = isAvailable
            dish.updatedAt = Date()

            try modelContext.save()
            return true
        } catch {
            error = "更新菜品失败: \(error.localizedDescription)"
            return false
        }
    }

    /// 删除菜品
    func deleteDish(_ dish: Dish) -> Bool {
        do {
            modelContext.delete(dish)
            try modelContext.save()
            return true
        } catch {
            error = "删除菜品失败: \(error.localizedDescription)"
            return false
        }
    }

    /// 切换菜品可用状态
    func toggleDishAvailability(_ dish: Dish) -> Bool {
        dish.isAvailable = !dish.isAvailable
        dish.updatedAt = Date()

        return saveContext()
    }

    // MARK: - 订单管理

    /// 创建订单
    func createOrder(items: [OrderItem], note: String? = nil) -> Order? {
        guard let family = currentFamily,
              let member = currentUser else {
            error = "请先选择家庭和用户"
            return nil
        }

        // 验证订单项
        guard !items.isEmpty else {
            error = "订单不能为空"
            return nil
        }

        // 验证所有菜品都可用
        let dishIDs = items.map { $0.dishId }
        let unavailableDishes = family.dishes.filter { !isDishAvailable($0, ids: dishIDs) }
        if !unavailableDishes.isEmpty {
            error = "部分菜品已下架"
            return nil
        }

        do {
            let totalAmount = items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
            let order = Order(
                orderNumber: generateOrderNumber(),
                status: .pending,
                totalAmount: totalAmount,
                member: member,
                note: note
            )
            order.family = family
            order.items = items

            modelContext.insert(order)

            // 添加订单到成员的订单列表
            member.orders.append(order)
            family.orders.append(order)

            try modelContext.save()

            return order
        } catch {
            error = "创建订单失败: \(error.localizedDescription)"
            return nil
        }
    }

    /// 更新订单状态
    func updateOrderStatus(_ order: Order, status: OrderStatus) -> Bool {
        do {
            order.status = status
            if status == .delivered {
                order.completedAt = Date()
            }

            try modelContext.save()
            return true
        } catch {
            error = "更新订单状态失败: \(error.localizedDescription)"
            return false
        }
    }

    /// 取消订单
    func cancelOrder(_ order: Order) -> Bool {
        return updateOrderStatus(order, status: .cancelled)
    }

    // MARK: - 购物车管理

    /// 创建购物车项
    func createCartItem(dish: Dish, quantity: Int = 1) -> CartItem? {
        return CartItem(dish: dish, quantity: quantity)
    }

    /// 更新购物车项数量
    func updateCartItemQuantity(_ cartItem: CartItem, quantity: Int) -> Bool {
        cartItem.quantity = quantity
        return true
    }

    /// 从购物车移除项
    func removeCartItem(_ cartItem: CartItem) -> Bool {
        // 在SwiftData中需要通过context删除
        // 这里简化处理
        return true
    }

    // MARK: - 成员管理

    /// 添加成员
    func addMember(name: String, role: MemberRole) -> FamilyMember? {
        guard let family = currentFamily else {
            error = "请先选择家庭"
            return nil
        }

        do {
            let member = FamilyMember(name: name, role: role, joinedAt: Date())
            member.family = family
            family.members.append(member)

            modelContext.insert(member)
            try modelContext.save()

            return member
        } catch {
            error = "添加成员失败: \(error.localizedDescription)"
            return nil
        }
    }

    /// 移除成员
    func removeMember(_ member: FamilyMember) -> Bool {
        guard let family = member.family else { return false }

        do {
            family.members.removeAll { $0.id == member.id }
            modelContext.delete(member)
            try modelContext.save()
            return true
        } catch {
            error = "移除成员失败: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 查询方法

    /// 获取家庭所有菜品
    func getFamilyDishes() -> [Dish] {
        return currentFamily?.dishes.filter { $0.isAvailable } ?? []
    }

    /// 获取所有订单
    func getAllOrders() -> [Order] {
        return currentFamily?.orders.sorted { $0.createdAt > $1.createdAt } ?? []
    }

    /// 获取用户订单
    func getUserOrders() -> [Order] {
        guard let member = currentUser else { return [] }
        return member.orders.sorted { $0.createdAt > $1.createdAt }
    }

    /// 获取特定状态的订单
    func getOrdersByStatus(_ status: OrderStatus) -> [Order] {
        return currentFamily?.orders.filter { $0.status == status }.sorted { $0.createdAt > $1.createdAt } ?? []
    }

    /// 获取所有成员
    func getFamilyMembers() -> [FamilyMember] {
        return currentFamily?.members.sorted { $0.joinedAt < $1.joinedAt } ?? []
    }

    /// 查找菜品
    func findDish(id: UUID) -> Dish? {
        return currentFamily?.dishes.first { $0.id == id }
    }

    /// 查找订单
    func findOrder(id: UUID) -> Order? {
        return currentFamily?.orders.first { $0.id == id }
    }

    /// 查找成员
    func findMember(id: UUID) -> FamilyMember? {
        return currentFamily?.members.first { $0.id == id }
    }

    // MARK: - 工具方法

    /// 生成订单号
    private func generateOrderNumber() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateStr = formatter.string(from: Date())
        let random = String(format: "%04d", Int.random(in: 0...9999))
        return "\(dateStr)\(random)"
    }

    /// 保存上下文
    private func saveContext() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            self.error = "保存失败: \(error.localizedDescription)"
            return false
        }
    }

    /// 加载模拟数据
    func loadSampleData() {
        isLoading = true
        defer { isLoading = false }

        // 清除现有数据
        do {
            let descriptor = FetchDescriptor<Family>()
            let families = try modelContext.fetch(descriptor)
            families.forEach { modelContext.delete($0) }

            try modelContext.save()
        } catch {
            error = "清除数据失败: \(error.localizedDescription)"
        }

        // 创建示例家庭
        let family = createFamily(name: "张家厨房", adminName: "张爸爸")

        if let family = family {
            // 添加示例菜品
            addDish(name: "番茄炒蛋", description: "经典家常菜", price: 25.00, category: .lunch)
            addDish(name: "红烧肉", description: "传统红烧肉", price: 38.00, category: .dinner)
            addDish(name: "清蒸鱼", description: "新鲜海鱼", price: 58.00, category: .dinner)
            addDish(name: "小笼包", description: "上海小笼包", price: 28.00, category: .breakfast)

            // 添加示例成员
            addMember(name: "张妈妈", role: .admin)
            addMember(name: "小明", role: .member)
            addMember(name: "小红", role: .member)
        }
    }
}

// MARK: - 购物车模型
@Model
class CartItem: Identifiable {
    var id = UUID()
    var dish: Dish
    var quantity: Int
    var addedAt: Date

    init(dish: Dish, quantity: Int = 1) {
        self.dish = dish
        self.quantity = quantity
        self.addedAt = Date()
    }
}

// MARK: - 扩展方法

extension DataManager {
    /// 获取菜品分类统计
    func getDishCategoryStats() -> [(category: DishCategory, count: Int)] {
        guard let family = currentFamily else { return [] }

        var stats: [DishCategory: Int] = [:]
        for category in DishCategory.allCases {
            stats[category] = family.dishes.filter { $0.category == category && $0.isAvailable }.count
        }

        return stats.map { (category: $0.key, count: $0.value) }
    }

    /// 获取订单统计
    func getOrderStats() -> (total: Int, pending: Int, completed: Int, cancelled: Int) {
        guard let family = currentFamily else { return (0, 0, 0, 0) }

        let orders = family.orders
        return (
            total: orders.count,
            pending: orders.filter { $0.status == .pending }.count,
            completed: orders.filter { $0.status == .ready || $0.status == .delivered }.count,
            cancelled: orders.filter { $0.status == .cancelled }.count
        )
    }

    /// 获取成员点餐统计
    func getMemberOrderStats() -> [(member: FamilyMember, orderCount: Int, totalAmount: Double)] {
        guard let family = currentFamily else { return [] }

        return family.members.map { member in
            let memberOrders = member.orders
            let totalAmount = memberOrders.reduce(0.0) { $0 + $1.totalAmount }
            return (member: member, orderCount: memberOrders.count, totalAmount: totalAmount)
        }
    }

    /// 生成订单号
    private func generateOrderNumber() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateStr = formatter.string(from: Date())
        let random = String(format: "%04d", Int.random(in: 0...9999))
        return "PK-\(dateStr)-\(random)"
    }

    /// 检查菜品是否可用
    private func isDishAvailable(_ dish: Dish, ids: [UUID]) -> Bool {
        return dish.isAvailable && ids.contains(dish.id)
    }

    /// 验证订单状态转换
    func isValidStatusTransition(from: OrderStatus, to: OrderStatus) -> Bool {
        // 定义有效的状态转换规则
        let validTransitions: [OrderStatus: [OrderStatus]] = [
            .pending: [.confirmed, .cancelled],
            .confirmed: [.cooking, .cancelled],
            .cooking: [.ready, .cancelled],
            .ready: [.delivered],
            .delivered: [], // 已完成状态不能转换
            .cancelled: [] // 已取消状态不能转换
        ]

        if let validNextStates = validTransitions[from] {
            return validNextStates.contains(to)
        }

        return false
    }

    /// 批量更新订单状态
    func batchUpdateOrdersStatus(orders: [Order], to status: OrderStatus) -> Bool {
        guard !orders.isEmpty else { return true }

        // 验证所有转换都有效
        for order in orders {
            if !isValidStatusTransition(from: order.status, to: status) {
                error = "订单 \(order.orderNumber) 的状态转换无效"
                return false
            }
        }

        do {
            for order in orders {
                order.status = status
                if status == .delivered || status == .cancelled {
                    order.completedAt = Date()
                }
            }

            try modelContext.save()
            return true
        } catch {
            self.error = "批量更新订单状态失败: \(error.localizedDescription)"
            return false
        }
    }

    /// 获取订单时间线
    func getOrderTimeline(for order: Order) -> [OrderTimeline] {
        do {
            let descriptor = FetchDescriptor<OrderTimeline>(
                predicate: #Predicate { $0.orderID == order.id },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            error = "获取订单时间线失败: \(error.localizedDescription)"
            return []
        }
    }

    /// 搜索订单
    func searchOrders(query: String) -> [Order] {
        guard let family = currentFamily else { return [] }

        let lowerQuery = query.lowercased()

        return family.orders.filter { order in
            order.orderNumber.lowercased().contains(lowerQuery) ||
            order.member?.name.lowercased().contains(lowerQuery) ?? false ||
            order.items.contains { $0.dishName.lowercased().contains(lowerQuery) }
        }.sorted { $0.createdAt > $1.createdAt }
    }

    /// 获取今日订单统计
    func getTodayOrderStats() -> (count: Int, revenue: Double) {
        guard let family = currentFamily else { return (0, 0) }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let todayOrders = family.orders.filter {
            $0.createdAt >= today && $0.createdAt < tomorrow
        }

        return (
            count: todayOrders.count,
            revenue: todayOrders.reduce(0.0) { $0 + $1.totalAmount }
        )
    }

    /// 获取本周订单统计
    func getWeekOrderStats() -> (count: Int, revenue: Double) {
        guard let family = currentFamily else { return (0, 0) }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.dateInterval(of: .weekOfMonth, for: today)?.start ?? today

        let weekOrders = family.orders.filter {
            $0.createdAt >= weekStart
        }

        return (
            count: weekOrders.count,
            revenue: weekOrders.reduce(0.0) { $0 + $1.totalAmount }
        )
    }
}