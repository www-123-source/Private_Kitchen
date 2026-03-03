import Foundation
import SwiftUI
import SwiftData

// 数据完整性检查器
@MainActor
class DataIntegrityChecker: ObservableObject {
    @Published var isChecking = false
    @Published var checkProgress: Double = 0.0
    @Published var checkResults = IntegrityCheckResults()
    @Published var errors: [DataError] = []
    @Published var warnings: [DataWarning] = []

    private let modelContext: ModelContext
    private let dataManager: DataManager

    init(modelContext: ModelContext, dataManager: DataManager) {
        self.modelContext = modelContext
        self.dataManager = dataManager
    }

    /// 执行完整性检查
    func performCheck() async {
        guard !isChecking else { return }

        isChecking = true
        checkProgress = 0.0
        checkResults = IntegrityCheckResults()
        errors = []
        warnings = []

        defer {
            isChecking = false
            checkProgress = 0.0
        }

        // 1. 检查家庭数据
        await checkFamilyData()
        checkProgress += 20

        // 2. 检查成员数据
        await checkMemberData()
        checkProgress += 20

        // 3. 检查菜品数据
        await checkDishData()
        checkProgress += 20

        // 4. 检查订单数据
        await checkOrderData()
        checkProgress += 20

        // 5. 检查数据一致性
        await checkDataConsistency()
        checkProgress += 20
    }

    // MARK: - 检查方法

    /// 检查家庭数据
    private func checkFamilyData() async {
        do {
            let families = try modelContext.fetch(FetchDescriptor<Family>())

            checkResults.familyCount = families.count

            // 检查空家庭
            let emptyFamilies = families.filter { $0.members.isEmpty && $0.dishes.isEmpty }
            if !emptyFamilies.isEmpty {
                warnings.append(DataWarning(
                    type: .family,
                    message: "\(emptyFamilies.count) 个家庭没有成员或菜品",
                    details: "可能需要清理"
                ))
            }

        } catch {
            errors.append(DataError(
                type: .family,
                message: "检查家庭数据失败",
                details: error.localizedDescription
            ))
        }
    }

    /// 检查成员数据
    private func checkMemberData() async {
        do {
            let members = try modelContext.fetch(FetchDescriptor<FamilyMember>())

            checkResults.memberCount = members.count

            // 检查没有家庭的成员
            let orphanedMembers = members.filter { $0.family == nil }
            if !orphanedMembers.isEmpty {
                errors.append(DataError(
                    type: .member,
                    message: "\(orphanedMembers.count) 个成员没有关联家庭",
                    details: "数据完整性错误"
                ))
            }

            // 检查重复成员
            let memberNames = members.map { $0.name }
            let duplicateNames = memberNames.filter { memberNames.firstIndex(of: $0) != memberNames.lastIndex(of: $0) }
            if !duplicateNames.isEmpty {
                warnings.append(DataWarning(
                    type: .member,
                    message: "发现重复的成员名称",
                    details: duplicateNames.joined(separator: ", ")
                ))
            }

        } catch {
            errors.append(DataError(
                type: .member,
                message: "检查成员数据失败",
                details: error.localizedDescription
            ))
        }
    }

    /// 检查菜品数据
    private func checkDishData() async {
        do {
            let dishes = try modelContext.fetch(FetchDescriptor<Dish>())

            checkResults.dishCount = dishes.count

            // 检查没有家庭的菜品
            let orphanedDishes = dishes.filter { $0.family == nil }
            if !orphanedDishes.isEmpty {
                errors.append(DataError(
                    type: .dish,
                    message: "\(orphanedDishes.count) 个菜品没有关联家庭",
                    details: "数据完整性错误"
                ))
            }

            // 检查异常价格
            let invalidPriceDishes = dishes.filter { $0.price <= 0 }
            if !invalidPriceDishes.isEmpty {
                warnings.append(DataWarning(
                    type: .dish,
                    message: "\(invalidPriceDishes.count) 个菜品价格异常",
                    details: "价格 <= 0"
                ))
            }

        } catch {
            errors.append(DataError(
                type: .dish,
                message: "检查菜品数据失败",
                details: error.localizedDescription
            ))
        }
    }

    /// 检查订单数据
    private func checkOrderData() async {
        do {
            let orders = try modelContext.fetch(FetchDescriptor<Order>())

            checkResults.orderCount = orders.count

            // 检查没有关联成员的订单
            let ordersWithoutMember = orders.filter { $0.member == nil }
            if !ordersWithoutMember.isEmpty {
                warnings.append(DataWarning(
                    type: .order,
                    message: "\(ordersWithoutMember.count) 个订单没有关联成员",
                    details: "可能需要清理"
                ))
            }

            // 检查空的订单项
            let emptyOrderItems = orders.flatMap { $0.items }.filter { $0.quantity <= 0 }
            if !emptyOrderItems.isEmpty {
                errors.append(DataError(
                    type: .order,
                    message: "\(emptyOrderItems.count) 个订单项数量异常",
                    details: "数量 <= 0"
                ))
            }

        } catch {
            errors.append(DataError(
                type: .order,
                message: "检查订单数据失败",
                details: error.localizedDescription
            ))
        }
    }

    /// 检查数据一致性
    private func checkDataConsistency() async {
        // 检查订单金额是否正确
        do {
            let orders = try modelContext.fetch(FetchDescriptor<Order>())
            let inconsistentOrders = orders.filter { order in
                let calculatedTotal = order.items.reduce(0.0) { total, item in
                    total + (item.price * Double(item.quantity))
                }
                return abs(calculatedTotal - order.totalAmount) > 0.01
            }

            if !inconsistentOrders.isEmpty {
                warnings.append(DataWarning(
                    type: .consistency,
                    message: "\(inconsistentOrders.count) 个订单金额不一致",
                    details: "需要重新计算"
                ))
            }

        } catch {
            errors.append(DataError(
                type: .consistency,
                message: "检查数据一致性失败",
                details: error.localizedDescription
            ))
        }
    }

    /// 修复数据问题
    func fixIssues() async {
        for error in errors {
            switch error.type {
            case .member:
                // 修复孤立的成员
                await fixOrphanedMembers()
            case .dish:
                // 修复孤立的菜品
                await fixOrphanedDishes()
            case .order:
                // 修复空的订单项
                await fixEmptyOrderItems()
            default:
                break
            }
        }

        for warning in warnings {
            switch warning.type {
            case .family:
                // 清理空家庭
                await cleanupEmptyFamilies()
            case .consistency:
                // 重新计算订单金额
                await recalculateOrderTotals()
            default:
                break
            }
        }

        // 重新检查
        await performCheck()
    }

    // MARK: - 修复方法

    private func fixOrphanedMembers() async {
        do {
            let members = try modelContext.fetch(FetchDescriptor<FamilyMember>())
            let orphanedMembers = members.filter { $0.family == nil }

            for member in orphanedMembers {
                // 将成员关联到第一个家庭
                if let firstFamily = dataManager.getFamilies().first {
                    member.family = firstFamily
                    firstFamily.members.append(member)
                }
            }

            try modelContext.save()
        } catch {
            print("Error fixing orphaned members: \(error)")
        }
    }

    private func fixOrphanedDishes() async {
        do {
            let dishes = try modelContext.fetch(FetchDescriptor<Dish>())
            let orphanedDishes = dishes.filter { $0.family == nil }

            for dish in orphanedDishes {
                // 将菜品关联到第一个家庭
                if let firstFamily = dataManager.getFamilies().first {
                    dish.family = firstFamily
                    firstFamily.dishes.append(dish)
                }
            }

            try modelContext.save()
        } catch {
            print("Error fixing orphaned dishes: \(error)")
        }
    }

    private func fixEmptyOrderItems() async {
        do {
            let orders = try modelContext.fetch(FetchDescriptor<Order>())

            for order in orders {
                // 移除空的订单项
                order.items.removeAll { $0.quantity <= 0 }

                // 重新计算订单金额
                if !order.items.isEmpty {
                    order.totalAmount = order.items.reduce(0.0) { total, item in
                        total + (item.price * Double(item.quantity))
                    }
                }
            }

            try modelContext.save()
        } catch {
            print("Error fixing empty order items: \(error)")
        }
    }

    private func cleanupEmptyFamilies() async {
        do {
            let families = try modelContext.fetch(FetchDescriptor<Family>())
            let emptyFamilies = families.filter { $0.members.isEmpty && $0.dishes.isEmpty }

            for family in emptyFamilies {
                modelContext.delete(family)
            }

            try modelContext.save()
        } catch {
            print("Error cleaning up empty families: \(error)")
        }
    }

    private func recalculateOrderTotals() async {
        do {
            let orders = try modelContext.fetch(FetchDescriptor<Order>())

            for order in orders {
                // 重新计算订单金额
                if !order.items.isEmpty {
                    order.totalAmount = order.items.reduce(0.0) { total, item in
                        total + (item.price * Double(item.quantity))
                    }
                }
            }

            try modelContext.save()
        } catch {
            print("Error recalculating order totals: \(error)")
        }
    }
}

// MARK: - 数据结构

/// 完整性检查结果
struct IntegrityCheckResults {
    var familyCount = 0
    var memberCount = 0
    var dishCount = 0
    var orderCount = 0
    var errorCount = 0
    var warningCount = 0

    var isValid: Bool {
        errorCount == 0
    }
}

/// 数据错误
struct DataError: Identifiable {
    let id = UUID()
    var type: DataType
    var message: String
    var details: String
}

/// 数据警告
struct DataWarning: Identifiable {
    let id = UUID()
    var type: DataType
    var message: String
    var details: String
}

/// 数据类型
enum DataType: String, CaseIterable {
    case family = "家庭"
    case member = "成员"
    case dish = "菜品"
    case order = "订单"
    case consistency = "数据一致性"
}