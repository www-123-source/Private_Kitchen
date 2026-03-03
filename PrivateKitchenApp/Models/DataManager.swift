import Foundation
import SwiftUI
import SwiftData
import CloudKit

// 购物车模型
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

// 数据管理器 - 统一管理所有数据模型的CRUD操作
@MainActor
class DataManager: ObservableObject {
    @Published var currentFamily: Family?
    @Published var currentUser: FamilyMember?
    @Published var isLoading = false
    @Published var error: String?

    private let modelContext: ModelContext
    private let cloudKitManager: CloudKitManager?

    init(modelContext: ModelContext, cloudKitEnabled: Bool = true) {
        self.modelContext = modelContext
        self.cloudKitManager = cloudKitEnabled ? CloudKitManager(modelContext: modelContext) : nil
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

            // 同步到云端
            Task { await syncFamilyToCloud(family) }

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
            // 目前简化实现,假设我们知道家庭
            guard let family = currentFamily else {
                error = "请先选择家庭"
                return false
            }

            let member = FamilyMember(name: memberName, role: .member, joinedAt: Date())
            member.family = family
            family.members.append(member)

            modelContext.insert(member)
            try modelContext.save()

            // 同步到云端
            Task { await syncMemberToCloud(member) }

            currentUser = member
            return true
        } catch {
            error = "加入家庭失败: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 菜品管理

    /// 添加菜品
    func addDish(name: String, description: String, category: DishCategory, imageData: Data? = nil) -> Dish? {
        guard let family = currentFamily else {
            error = "请先选择家庭"
            return nil
        }

        do {
            let dish = Dish(
                name: name,
                description: description,
                category: category,
                image: imageData,
                isAvailable: true
            )
            dish.family = family
            family.dishes.append(dish)

            modelContext.insert(dish)
            try modelContext.save()

            // 同步到云端
            Task { await syncDishToCloud(dish) }

            return dish
        } catch {
            error = "添加菜品失败: \(error.localizedDescription)"
            return nil
        }
    }

    /// 更新菜品
    func updateDish(_ dish: Dish, name: String, description: String, category: DishCategory, imageData: Data? = nil, isAvailable: Bool = true) -> Bool {
        do {
            dish.name = name
            dish.description = description
            dish.category = category
            dish.image = imageData
            dish.isAvailable = isAvailable
            dish.updatedAt = Date()

            try modelContext.save()

            // 同步到云端
            Task { await syncDishToCloud(dish) }

            return true
        } catch {
            error = "更新菜品失败: \(error.localizedDescription)"
            return false
        }
    }

    /// 删除菜品
    func deleteDish(_ dish: Dish) -> Bool {
        do {
            // 从云端删除
            Task { await deleteDishFromCloud(dish) }

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

        // 同步到云端
        Task { await syncDishToCloud(dish) }

        return saveContext()
    }

    // MARK: - 今日餐单管理

    /// 添加今日餐单
    func addToDailyMenu(mealType: MealType, dish: Dish, note: String? = nil) -> DailyMenu? {
        guard let family = currentFamily,
              let member = currentUser else {
            error = "请先选择家庭和用户"
            return nil
        }

        do {
            let dailyMenu = DailyMenu(
                mealType: mealType,
                memberId: member.id,
                dishId: dish.id,
                dishName: dish.name,
                memberName: member.name,
                note: note
            )
            dailyMenu.family = family

            modelContext.insert(dailyMenu)
            try modelContext.save()

            // 同步到云端
            Task { await syncDailyMenuToCloud(dailyMenu) }

            return dailyMenu
        } catch {
            error = "添加今日餐单失败: \(error.localizedDescription)"
            return nil
        }
    }

    /// 获取今日餐单
    func getTodayDailyMenus() -> [DailyMenu] {
        guard let family = currentFamily else { return [] }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        return family.dailyMenus.filter {
            $0.createdAt >= today && $0.createdAt < tomorrow
        }
    }

    /// 获取今日餐单按餐次分组
    func getTodayDailyMenusByMealType() -> [MealType: [DailyMenu]] {
        let todayMenus = getTodayDailyMenus()
        var grouped: [MealType: [DailyMenu]] = [:]

        for menu in todayMenus {
            grouped[menu.mealType, default: []].append(menu)
        }

        return grouped
    }

    /// 清空今日餐单
    func clearDailyMenus() -> Bool {
        guard let family = currentFamily else {
            error = "请先选择家庭"
            return false
        }

        do {
            // 删除所有今日餐单
            let descriptor = FetchDescriptor<DailyMenu>()
            let menus = try modelContext.fetch(descriptor)

            for menu in menus {
                modelContext.delete(menu)
            }

            try modelContext.save()
            return true
        } catch {
            error = "清空今日餐单失败: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 想吃菜品管理

    /// 添加想吃菜品
    func addToWantedDish(name: String, ingredients: String, seasonings: String, cookingSteps: String, recipeId: UUID? = nil) -> WantedDish? {
        guard let family = currentFamily,
              let member = currentUser else {
            error = "请先选择家庭和用户"
            return nil
        }

        do {
            let wantedDish = WantedDish(
                memberId: member.id,
                memberName: member.name,
                name: name,
                ingredients: ingredients,
                seasonings: seasonings,
                cookingSteps: cookingSteps
            )
            wantedDish.family = family
            wantedDish.recipeId = recipeId

            modelContext.insert(wantedDish)
            try modelContext.save()

            // 同步到云端
            Task { await syncWantedDishToCloud(wantedDish) }

            return wantedDish
        } catch {
            error = "添加想吃菜品失败: \(error.localizedDescription)"
            return nil
        }
    }

    /// 获取想吃菜品列表
    func getWantedDishes() -> [WantedDish] {
        guard let family = currentFamily else { return [] }

        return family.wantedDishes.sorted { $0.createdAt > $1.createdAt }
    }

    /// 删除想吃菜品
    func deleteWantedDish(_ wantedDish: WantedDish) -> Bool {
        do {
            // 从云端删除
            Task { await deleteWantedDishFromCloud(wantedDish) }

            modelContext.delete(wantedDish)
            try modelContext.save()
            return true
        } catch {
            error = "删除想吃菜品失败: \(error.localizedDescription)"
            return false
        }
    }

    // MARK: - 统计管理

    /// 添加统计记录
    func addOrderStatistics(memberId: UUID, dishId: UUID, dishName: String, statisticsType: StatisticsType) -> OrderStatistics? {
        guard let family = currentFamily else {
            error = "请先选择家庭"
            return nil
        }

        do {
            // 检查是否已存在相同记录
            if let existing = getStatistics(memberId: memberId, dishId: dishId, statisticsType: statisticsType) {
                existing.updateWithOrder()
                try modelContext.save()

                // 同步到云端
                Task { await syncStatisticsToCloud(existing) }

                return existing
            }

            let statistics = OrderStatistics(
                memberId: memberId,
                dishId: dishId,
                dishName: dishName,
                totalOrders: 1,
                lastOrderedAt: Date(),
                statisticsType: statisticsType
            )
            statistics.family = family

            modelContext.insert(statistics)
            try modelContext.save()

            // 同步到云端
            Task { await syncStatisticsToCloud(statistics) }

            return statistics
        } catch {
            error = "添加统计记录失败: \(error.localizedDescription)"
            return nil
        }
    }

    /// 获取统计记录
    func getStatistics(memberId: UUID, dishId: UUID, statisticsType: StatisticsType) -> OrderStatistics? {
        guard let family = currentFamily else { return nil }

        return family.orderStatistics.first {
            $0.memberId == memberId &&
            $0.dishId == dishId &&
            $0.statisticsType == statisticsType
        }
    }

    /// 获取统计列表
    func getStatisticsList(statisticsType: StatisticsType) -> [OrderStatistics] {
        guard let family = currentFamily else { return [] }

        return family.orderStatistics.filter { $0.statisticsType == statisticsType }
            .sorted { $0.totalOrders > $1.totalOrders }
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

            // 同步到云端
            Task { await syncMemberToCloud(member) }

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

    /// 获取所有成员
    func getFamilyMembers() -> [FamilyMember] {
        return currentFamily?.members.sorted { $0.joinedAt < $1.joinedAt } ?? []
    }

    /// 查找菜品
    func findDish(id: UUID) -> Dish? {
        return currentFamily?.dishes.first { $0.id == id }
    }

    /// 查找成员
    func findMember(id: UUID) -> FamilyMember? {
        return currentFamily?.members.first { $0.id == id }
    }

    // MARK: - CloudKit 同步方法

    /// 手动同步所有数据
    func syncAllData() async {
        await cloudKitManager?.syncAllData()
    }

    /// 同步家庭到云端
    private func syncFamilyToCloud(_ family: Family) async {
        await cloudKitManager?.syncFamily(family)
    }

    /// 同步成员到云端
    private func syncMemberToCloud(_ member: FamilyMember) async {
        await cloudKitManager?.syncMember(member)
    }

    /// 同步菜品到云端
    private func syncDishToCloud(_ dish: Dish) async {
        await cloudKitManager?.syncDish(dish)
    }

    /// 同步今日餐单到云端
    private func syncDailyMenuToCloud(_ dailyMenu: DailyMenu) async {
        await cloudKitManager?.syncDailyMenu(dailyMenu)
    }

    /// 同步想吃菜品到云端
    private func syncWantedDishToCloud(_ wantedDish: WantedDish) async {
        await cloudKitManager?.syncWantedDish(wantedDish)
    }

    /// 同步统计数据到云端
    private func syncStatisticsToCloud(_ statistics: OrderStatistics) async {
        await cloudKitManager?.syncStatistics(statistics)
    }

    /// 从云端删除菜品
    private func deleteDishFromCloud(_ dish: Dish) async {
        await cloudKitManager?.deleteRecord(dish.id, type: .dish)
    }

    /// 从云端删除想吃菜品
    private func deleteWantedDishFromCloud(_ wantedDish: WantedDish) async {
        await cloudKitManager?.deleteRecord(wantedDish.id, type: .wantedDish)
    }

    /// 获取 CloudKit 同步状态
    var isCloudSyncing: Bool {
        return cloudKitManager?.isSyncing ?? false
    }

    /// 获取上次同步时间
    var lastSyncTime: Date? {
        return cloudKitManager?.lastSyncTime
    }

    // MARK: - 工具方法

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

    /// 生成今日餐单编号
    private func generateDailyMenuNumber() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return "DM-\(formatter.string(from: Date()))"
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
            addDish(name: "番茄炒蛋", description: "经典家常菜", category: .lunch)
            addDish(name: "红烧肉", description: "传统红烧肉", category: .dinner)
            addDish(name: "清蒸鱼", description: "新鲜海鱼", category: .dinner)
            addDish(name: "小笼包", description: "上海小笼包", category: .breakfast)
            addDish(name: "炒青菜", description: "时令青菜", category: .lunch)
            addDish(name: "冬瓜排骨汤", description: "营养汤品", category: .dinner)
            addDish(name: "小米粥", description: "养胃早餐", category: .breakfast)
            addDish(name: "鸡蛋灌饼", description: "早餐小吃", category: .breakfast)

            // 添加示例成员
            addMember(name: "张妈妈", role: .admin)
            addMember(name: "小明", role: .member)
            addMember(name: "小红", role: .member)
        }
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

    /// 获取成员点餐统计
    func getMemberOrderStats(statisticsType: StatisticsType) -> [(member: FamilyMember, orderCount: Int)] {
        guard let family = currentFamily else { return [] }

        // 获取该统计类型的所有统计记录
        let stats = getStatisticsList(statisticsType: statisticsType)

        // 按成员分组统计
        var memberStats: [UUID: (member: FamilyMember, orderCount: Int)] = [:]

        for stat in stats {
            if let member = family.members.first(where: { $0.id == stat.memberId }) {
                if var existing = memberStats[stat.memberId] {
                    memberStats[stat.memberId] = (member, existing.orderCount + stat.totalOrders)
                } else {
                    memberStats[stat.memberId] = (member, stat.totalOrders)
                }
            }
        }

        return memberStats.values.sorted { $0.orderCount > $1.orderCount }
    }

    /// 获取菜品点餐排行
    func getDishOrderRanking(statisticsType: StatisticsType) -> [(dish: Dish, orderCount: Int)] {
        guard let family = currentFamily else { return [] }

        // 获取该统计类型的所有统计记录
        let stats = getStatisticsList(statisticsType: statisticsType)

        // 按菜品分组统计
        var dishStats: [UUID: (dish: Dish, orderCount: Int)] = [:]

        for stat in stats {
            if let dish = family.dishes.first(where: { $0.id == stat.dishId }) {
                if var existing = dishStats[stat.dishId] {
                    dishStats[stat.dishId] = (dish, existing.orderCount + stat.totalOrders)
                } else {
                    dishStats[stat.dishId] = (dish, stat.totalOrders)
                }
            }
        }

        return dishStats.values.sorted { $0.orderCount > $1.orderCount }
    }

    /// 获取今日点餐统计
    func getTodayOrderStats() -> (menuCount: Int, memberCount: Int) {
        let todayMenus = getTodayDailyMenus()
        let memberIds = Set(todayMenus.map { $0.memberId })

        return (
            menuCount: todayMenus.count,
            memberCount: memberIds.count
        )
    }

    /// 获取本周点餐统计
    func getWeekOrderStats() -> (menuCount: Int, memberCount: Int) {
        guard let family = currentFamily else { return (0, 0) }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -7, to: today)!

        let weekMenus = family.dailyMenus.filter {
            $0.createdAt >= weekStart && $0.createdAt <= today
        }

        let memberIds = Set(weekMenus.map { $0.memberId })

        return (
            menuCount: weekMenus.count,
            memberCount: memberIds.count
        )
    }

    /// 按成员获取今日餐单
    func getTodayMenusByMember() -> [UUID: [DailyMenu]] {
        let todayMenus = getTodayDailyMenus()
        var grouped: [UUID: [DailyMenu]] = [:]

        for menu in todayMenus {
            grouped[menu.memberId, default: []].append(menu)
        }

        return grouped
    }

    /// 按菜品获取今日餐单
    func getTodayMenusByDish() -> [UUID: [DailyMenu]] {
        let todayMenus = getTodayDailyMenus()
        var grouped: [UUID: [DailyMenu]] = [:]

        for menu in todayMenus {
            grouped[menu.dishId, default: []].append(menu)
        }

        return grouped
    }
}
