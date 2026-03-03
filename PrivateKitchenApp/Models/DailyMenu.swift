import SwiftData

// 今日餐单
@Model
class DailyMenu {
    var id: UUID
    var mealType: MealType
    var memberId: UUID
    var dishId: UUID
    var dishName: String
    var memberName: String
    var createdAt: Date
    var note: String?
    @Relationship var family: Family?

    init(mealType: MealType, memberId: UUID, dishId: UUID, dishName: String, memberName: String, createdAt: Date = Date(), note: String? = nil) {
        self.id = UUID()
        self.mealType = mealType
        self.memberId = memberId
        self.dishId = dishId
        self.dishName = dishName
        self.memberName = memberName
        self.createdAt = createdAt
        self.note = note
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast   // 早餐
    case lunch       // 午餐
    case dinner      // 晚餐

    var displayName: String {
        switch self {
        case .breakfast: return "早餐"
        case .lunch: return "午餐"
        case .dinner: return "晚餐"
        }
    }
}
