import SwiftData

// 统计数据
@Model
class OrderStatistics {
    var id: UUID
    var memberId: UUID        // 成员ID
    var dishId: UUID          // 菜品ID
    var dishName: String      // 菜品名称
    var totalOrders: Int      // 总订单数
    var lastOrderedAt: Date   // 最后下单时间
    var statisticsType: StatisticsType  // 统计类型
    var createdAt: Date
    var updatedAt: Date
    @Relationship var family: Family?

    init(memberId: UUID, dishId: UUID, dishName: String, totalOrders: Int, lastOrderedAt: Date, statisticsType: StatisticsType) {
        self.id = UUID()
        self.memberId = memberId
        self.dishId = dishId
        self.dishName = dishName
        self.totalOrders = totalOrders
        self.lastOrderedAt = lastOrderedAt
        self.statisticsType = statisticsType
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    func updateWithOrder() {
        self.totalOrders += 1
        self.lastOrderedAt = Date()
        self.updatedAt = Date()
    }
}

enum StatisticsType: String, Codable, CaseIterable {
    case daily        // 今日统计
    case weekly       // 近一周统计
    case monthly      // 近一月统计
    case quarterly    // 近三月统计
    case yearly       // 近一年统计

    var displayName: String {
        switch self {
        case .daily: return "今日"
        case .weekly: return "近一周"
        case .monthly: return "近一月"
        case .quarterly: return "近三月"
        case .yearly: return "近一年"
        }
    }

    func getDateRange() -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .daily:
            let start = calendar.startOfDay(for: now)
            return (start, now)
        case .weekly:
            let start = calendar.date(byAdding: .day, value: -7, to: now)!
            return (start, now)
        case .monthly:
            let start = calendar.date(byAdding: .month, value: -1, to: now)!
            return (start, now)
        case .quarterly:
            let start = calendar.date(byAdding: .month, value: -3, to: now)!
            return (start, now)
        case .yearly:
            let start = calendar.date(byAdding: .year, value: -1, to: now)!
            return (start, now)
        }
    }
}
