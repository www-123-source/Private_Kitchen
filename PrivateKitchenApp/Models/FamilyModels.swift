import SwiftData

// 家庭
@Model
class Family {
    var id: UUID
    var name: String           // 家庭名称
    var adminId: UUID         // 管理员ID
    @Relationship(deleteRule: .cascade, inverse: \FamilyMember.family)
    var members: [FamilyMember]
    @Relationship(deleteRule: .cascade, inverse: \Dish.family)
    var dishes: [Dish]

    init(id: UUID = UUID(), name: String, adminId: UUID) {
        self.id = id
        self.name = name
        self.adminId = adminId
        self.members = []
        self.dishes = []
    }
}

// 家庭成员
@Model
class FamilyMember {
    var id: UUID
    var name: String           // 成员姓名
    var avatar: Data?          // 头像
    var role: MemberRole      // admin / member
    var joinedAt: Date
    @Relationship var family: Family?

    init(id: UUID = UUID(), name: String, role: MemberRole, joinedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.role = role
        self.joinedAt = joinedAt
    }
}

enum MemberRole: String, Codable, CaseIterable {
    case admin     // 厨房管理员
    case member    // 家庭成员
}

// 菜品
@Model
class Dish {
    var id: UUID
    var name: String           // 菜名
    var description: String    // 描述
    var category: DishCategory // 分类
    var image: Data?           // 图片
    var isAvailable: Bool      // 是否上架
    var createdAt: Date
    var updatedAt: Date
    @Relationship var family: Family?

    init(id: UUID = UUID(), name: String, description: String, category: DishCategory, image: Data? = nil, isAvailable: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.image = image
        self.isAvailable = isAvailable
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum DishCategory: String, Codable, CaseIterable {
    case breakfast     // 早餐
    case lunch         // 午餐
    case dinner        // 晚餐
    case snack         // 零食
    case drink         // 饮品

    var displayName: String {
        switch self {
        case .breakfast: return "早餐"
        case .lunch: return "午餐"
        case .dinner: return "晚餐"
        case .snack: return "零食"
        case .drink: return "饮品"
        }
    }
}

// 菜谱
@Model
class Recipe {