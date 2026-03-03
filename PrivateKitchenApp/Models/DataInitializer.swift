import Foundation
import SwiftUI
import SwiftData

// 数据初始化器 - 处理应用启动时的数据设置
@MainActor
class DataInitializer {
    static let shared = DataInitializer()

    private init() {}

    // 配置 SwiftData 容器
    static func configureModelContainer() -> ModelContainer {
        let schema = Schema([
            Family.self,
            FamilyMember.self,
            Dish.self,
            Order.self,
            OrderItem.self,
            Recipe.self,
            RecipeComment.self,
            CartItem.self,
            PaymentRecord.self
        ])

        let config = ModelConfiguration(schema: schema, isPersistent: true)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not configure ModelContainer: \(error)")
        }
    }

    // 检查并初始化应用数据
    func initializeData(modelContext: ModelContext) -> DataManager {
        let dataManager = DataManager(modelContext: modelContext)

        // 检查是否有家庭数据
        let families = dataManager.getFamilies()

        if families.isEmpty {
            // 没有家庭数据，加载示例数据
            dataManager.loadSampleData()
        } else {
            // 有家庭数据，设置当前家庭
            dataManager.currentFamily = families.first

            // 设置当前用户（第一个管理员或第一个成员）
            if let family = dataManager.currentFamily {
                if let admin = family.members.first(where: { $0.role == .admin }) {
                    dataManager.currentUser = admin
                } else {
                    dataManager.currentUser = family.members.first
                }
            }
        }

        return dataManager
    }
}

// MARK: - 扩展 DataManager
extension DataManager {
    /// 获取所有家庭
    func getFamilies() -> [Family] {
        do {
            let descriptor = FetchDescriptor<Family>()
            return try modelContext.fetch(descriptor)
        } catch {
            error = "获取家庭列表失败: \(error.localizedDescription)"
            return []
        }
    }

    /// 查找家庭
    func findFamily(id: UUID) -> Family? {
        do {
            let descriptor = FetchDescriptor<Family>(predicate: #Predicate { $0.id == id })
            return try modelContext.fetch(descriptor).first
        } catch {
            error = "查找家庭失败: \(error.localizedDescription)"
            return nil
        }
    }

    /// 设置当前家庭
    func setCurrentFamily(_ family: Family) {
        currentFamily = family

        // 同时设置当前用户为该家庭的第一个管理员
        if let admin = family.members.first(where: { $0.role == .admin }) {
            currentUser = admin
        } else {
            currentUser = family.members.first
        }
    }

    /// 检查用户是否是管理员
    func isAdmin(_ member: FamilyMember) -> Bool {
        return member.role == .admin
    }

    /// 获取家庭成员数量
    func getMemberCount() -> Int {
        return currentFamily?.members.count ?? 0
    }

    /// 获取菜品数量
    func getDishCount() -> Int {
        return currentFamily?.dishes.filter { $0.isAvailable }.count ?? 0
    }

    /// 获取订单数量
    func getOrderCount() -> Int {
        return currentFamily?.orders.count ?? 0
    }
}