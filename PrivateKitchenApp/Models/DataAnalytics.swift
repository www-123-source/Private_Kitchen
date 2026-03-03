import Foundation
import SwiftUI
import SwiftData

// 数据分析器
@MainActor
class DataAnalytics: ObservableObject {
    @Published var analyticsData: AnalyticsData?
    @Published var isLoading = false
    @Published var lastUpdated: Date?

    private let modelContext: ModelContext
    private let dataManager: DataManager

    init(modelContext: ModelContext, dataManager: DataManager) {
        self.modelContext = modelContext
        self.dataManager = dataManager
    }

    /// 生成数据分析报告
    func generateReport() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let orders = dataManager.getAllOrders()
            let dishes = dataManager.getFamilyDishes()
            let members = dataManager.getFamilyMembers()

            let salesAnalytics = calculateSalesAnalytics(orders: orders, dishes: dishes)
            let customerAnalytics = calculateCustomerAnalytics(orders: orders, members: members)
            let dishAnalytics = calculateDishAnalytics(dishes: dishes, orders: orders)

            analyticsData = AnalyticsData(
                sales: salesAnalytics,
                customers: customerAnalytics,
                dishes: dishAnalytics,
                generatedAt: Date()
            )

            lastUpdated = Date()

        } catch {
            print("Error generating analytics: \(error)")
        }
    }

    // MARK: - 销售分析

    private func calculateSalesAnalytics(orders: [Order], dishes: [Dish]) -> SalesAnalytics {
        let totalRevenue = orders.reduce(0.0) { $0 + $1.totalAmount }
        let completedOrders = orders.filter { $0.status == .ready || $0.status == .delivered }
        let pendingOrders = orders.filter { $0.status == .pending }
        let cancelledOrders = orders.filter { $0.status == .cancelled }

        // 计算日/周/月销售趋势
        let dailySales = calculateDailySales(orders: completedOrders)
        let monthlySales = calculateMonthlySales(orders: completedOrders)

        return SalesAnalytics(
            totalRevenue: totalRevenue,
            orderCount: orders.count,
            completedOrderCount: completedOrders.count,
            pendingOrderCount: pendingOrders.count,
            cancelledOrderCount: cancelledOrders.count,
            completionRate: orders.isEmpty ? 0 : Double(completedOrders.count) / Double(orders.count) * 100,
            averageOrderValue: completedOrders.isEmpty ? 0 : totalRevenue / Double(completedOrders.count),
            dailySales: dailySales,
            monthlySales: monthlySales,
            topSellingDishes: getTopSellingDishes(orders: completedOrders)
        )
    }

    // MARK: - 客户分析

    private func calculateCustomerAnalytics(orders: [Order], members: [FamilyMember]) -> CustomerAnalytics {
        // 计算每个客户的订单数和消费金额
        let customerStats = members.map { member in
            let memberOrders = orders.filter { $0.member?.id == member.id }
            let totalSpent = memberOrders.reduce(0.0) { $0 + $1.totalAmount }
            let orderCount = memberOrders.count

            return CustomerStats(
                member: member,
                orderCount: orderCount,
                totalSpent: totalSpent,
                averageOrderValue: orderCount > 0 ? totalSpent / Double(orderCount) : 0
            )
        }

        // 找出VIP客户（消费最多的）
        let vipCustomers = customerStats.sorted { $0.totalSpent > $1.totalSpent }.prefix(3)

        // 计算客户活跃度
        let activeCustomers = customerStats.filter { $0.orderCount > 0 }
        let activeRate = members.isEmpty ? 0 : Double(activeCustomers.count) / Double(members.count) * 100

        return CustomerAnalytics(
            totalMembers: members.count,
            activeMembers: activeCustomers.count,
            activeRate: activeRate,
            vipCustomers: vipCustomers.map { $0.member },
            customerStats: customerStats
        )
    }

    // MARK: - 菜品分析

    private func calculateDishAnalytics(dishes: [Dish], orders: [Order]) -> DishAnalytics {
        // 计算每个菜品的销售情况
        let dishSales = dishes.map { dish in
            let dishOrders = orders.flatMap { $0.items }.filter { $0.dishId == dish.id }
            let totalQuantity = dishOrders.reduce(0) { $0 + $1.quantity }
            let totalRevenue = dishOrders.reduce(0.0) { $0 + ($1.price * Double($1.quantity)) }

            return DishSales(
                dish: dish,
                totalQuantity: totalQuantity,
                totalRevenue: totalRevenue,
                orderCount: dishOrders.count
            )
        }

        // 找出热销菜品和滞销菜品
        let topDishes = dishSales.sorted { $0.totalQuantity > $1.totalQuantity }.prefix(5)
        let slowDishes = dishSales.sorted { $0.totalQuantity < $1.totalQuantity }.filter { $0.totalQuantity < 5 }

        return DishAnalytics(
            totalDishes: dishes.count,
            availableDishes: dishes.filter { $0.isAvailable }.count,
            topSellingDishes: topDishes.map { $0.dish },
            slowMovingDishes: slowDishes.map { $0.dish },
            dishSales: dishSales
        )
    }

    // MARK: - 辅助方法

    private func calculateDailySales(orders: [Order]) -> [DailySale] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let salesByDay = Dictionary(grouping: orders, by: { dateFormatter.string(from: $0.createdAt) })

        return salesByDay.map { date, dayOrders in
            let totalRevenue = dayOrders.reduce(0.0) { $0 + $1.totalAmount }
            return DailySale(date: date, revenue: totalRevenue, orderCount: dayOrders.count)
        }.sorted { $0.date < $1.date }
    }

    private func calculateMonthlySales(orders: [Order]) -> [MonthlySale] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"

        let salesByMonth = Dictionary(grouping: orders, by: { dateFormatter.string(from: $0.createdAt) })

        return salesByMonth.map { month, monthOrders in
            let totalRevenue = monthOrders.reduce(0.0) { $0 + $1.totalAmount }
            return MonthlySale(month: month, revenue: totalRevenue, orderCount: monthOrders.count)
        }.sorted { $0.month < $1.month }
    }

    private func getTopSellingDishes(orders: [Order]) -> [Dish] {
        let dishQuantities = Dictionary(grouping: orders.flatMap { $0.items }, by: { $0.dishId })

        let sortedDishes = dishQuantities.map { dishId, items in
            let totalQuantity = items.reduce(0) { $0 + $1.quantity }
            return (dishId: dishId, totalQuantity: totalQuantity)
        }.sorted { $0.totalQuantity > $1.totalQuantity }

        return sortedDishes.compactMap { data in
            data.dishId.flatMap { dataManager.findDish(id: $0) }
        }.prefix(5).map { $0 }
    }
}

// MARK: - 数据结构

/// 销售分析
struct SalesAnalytics {
    let totalRevenue: Double
    let orderCount: Int
    let completedOrderCount: Int
    let pendingOrderCount: Int
    let cancelledOrderCount: Int
    let completionRate: Double
    let averageOrderValue: Double
    let dailySales: [DailySale]
    let monthlySales: [MonthlySale]
    let topSellingDishes: [Dish]
}

/// 日销售数据
struct DailySale {
    let date: String
    let revenue: Double
    let orderCount: Int
}

/// 月销售数据
struct MonthlySale {
    let month: String
    let revenue: Double
    let orderCount: Int
}

/// 客户分析
struct CustomerAnalytics {
    let totalMembers: Int
    let activeMembers: Int
    let activeRate: Double
    let vipCustomers: [FamilyMember]
    let customerStats: [CustomerStats]
}

/// 客户统计
struct CustomerStats {
    let member: FamilyMember
    let orderCount: Int
    let totalSpent: Double
    let averageOrderValue: Double
}

/// 菜品分析
struct DishAnalytics {
    let totalDishes: Int
    let availableDishes: Int
    let topSellingDishes: [Dish]
    let slowMovingDishes: [Dish]
    let dishSales: [DishSales]
}

/// 菜品销售数据
struct DishSales {
    let dish: Dish
    let totalQuantity: Int
    let totalRevenue: Double
    let orderCount: Int
}

/// 完整分析数据
struct AnalyticsData {
    let sales: SalesAnalytics
    let customers: CustomerAnalytics
    let dishes: DishAnalytics
    let generatedAt: Date
}