import SwiftData

// 想吃的菜品
@Model
class WantedDish {
    var id: UUID
    var memberId: UUID        // 添加人ID
    var memberName: String    // 添加人姓名
    var name: String          // 菜品名称
    var ingredients: String   // 原材料
    var seasonings: String    // 调味料
    var cookingSteps: String  // 烹饪步骤
    var finishedImage: Data?  // 成品图
    var createdAt: Date
    var recipeId: UUID?       // 关联的菜谱ID(如果从菜谱添加)
    @Relationship var family: Family?

    init(memberId: UUID, memberName: String, name: String, ingredients: String, seasonings: String, cookingSteps: String, createdAt: Date = Date()) {
        self.id = UUID()
        self.memberId = memberId
        self.memberName = memberName
        self.name = name
        self.ingredients = ingredients
        self.seasonings = seasonings
        self.cookingSteps = cookingSteps
        self.createdAt = createdAt
    }
}
