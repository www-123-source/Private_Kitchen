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
    @Relationship(deleteRule: .cascade, inverse: \Order.family)
    var orders: [Order]

    init(id: UUID = UUID(), name: String, adminId: UUID) {
        self.id = id
        self.name = name
        self.adminId = adminId
        self.members = []
        self.dishes = []
        self.orders = []
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
    @Relationship(deleteRule: .nullify, inverse: \Order.member)
    var orders: [Order]

    init(id: UUID = UUID(), name: String, role: MemberRole, joinedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.role = role
        self.joinedAt = joinedAt
        self.orders = []
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
    var price: Double          // 价格
    var category: DishCategory // 分类
    var image: Data?           // 图片
    var isAvailable: Bool      // 是否上架
    var createdAt: Date
    var updatedAt: Date
    @Relationship var family: Family?

    init(id: UUID = UUID(), name: String, description: String, price: Double, category: DishCategory, image: Data? = nil, isAvailable: Bool = true) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
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

// 订单
@Model
class Order {
    var id: UUID
    var orderNumber: String   // 订单号
    var status: OrderStatus   // 状态
    var totalAmount: Double   // 总金额
    var note: String?         // 备注
    var createdAt: Date
    var completedAt: Date?
    @Relationship var member: FamilyMember?
    @Relationship(deleteRule: .cascade, inverse: \OrderItem.order)
    var items: [OrderItem]
    @Relationship var family: Family?

    init(id: UUID = UUID(), orderNumber: String, status: OrderStatus, totalAmount: Double, member: FamilyMember? = nil, note: String? = nil) {
        self.id = id
        self.orderNumber = orderNumber
        self.status = status
        self.totalAmount = totalAmount
        self.member = member
        self.note = note
        self.createdAt = Date()
        self.items = []
    }
}

enum OrderStatus: String, Codable, CaseIterable {
    case pending      // 待接单
    case confirmed    // 已确认
    case cooking      // 制作中
    case ready        // 已完成
    case delivered    // 已上菜
    case cancelled    // 已取消

    var displayName: String {
        switch self {
        case .pending: return "待接单"
        case .confirmed: return "已确认"
        case .cooking: return "制作中"
        case .ready: return "已完成"
        case .delivered: return "已上菜"
        case .cancelled: return "已取消"
        }
    }
}

// 订单项
@Model
class OrderItem {
    var id: UUID
    var dishId: UUID   // 关联菜品ID
    var dishName: String
    var price: Double
    var quantity: Int
    var note: String?  // 单项备注
    @Relationship var order: Order?

    init(id: UUID = UUID(), dishId: UUID, dishName: String, price: Double, quantity: Int = 1, note: String? = nil) {
        self.id = id
        self.dishId = dishId
        self.dishName = dishName
        self.price = price
        self.quantity = quantity
        self.note = note
    }
}

// 菜谱
@Model
class Recipe {
    var id: UUID
    var remoteId: String          // 远程ID
    var merchantName: String
    var merchantLocation: String
    var name: String
    var description: String
    var imageData: Data?          // 缓存图片
    var rating: Double
    var commentCount: Int
    var isCollected: Bool
    var isLiked: Bool
    @Relationship(deleteRule: .cascade, inverse: \RecipeComment.recipe)
    var comments: [RecipeComment]
    var updatedAt: Date

    init(id: UUID = UUID(), remoteId: String, merchantName: String, merchantLocation: String, name: String, description: String, imageData: Data? = nil, rating: Double = 0, commentCount: Int = 0, isCollected: Bool = false, isLiked: Bool = false) {
        self.id = id
        self.remoteId = remoteId
        self.merchantName = merchantName
        self.merchantLocation = merchantLocation
        self.name = name
        self.description = description
        self.imageData = imageData
        self.rating = rating
        self.commentCount = commentCount
        self.isCollected = isCollected
        self.isLiked = isLiked
        self.comments = []
        self.updatedAt = Date()
    }
}

// 菜谱评论
@Model
class RecipeComment {
    var id: UUID
    var userName: String      // 评论者
    var content: String       // 评论内容
    var rating: Int           // 评分 1-5
    var createdAt: Date
    @Relationship var recipe: Recipe?

    init(id: UUID = UUID(), userName: String, content: String, rating: Int, createdAt: Date = Date()) {
        self.id = id
        self.userName = userName
        self.content = content
        self.rating = rating
        self.createdAt = createdAt
    }
}