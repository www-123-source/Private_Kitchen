# 私厨 iOS 应用 - 设计文档

**日期:** 2026-02-28
**版本:** 1.0

---

## 项目概述

"私厨"是一个基于 SwiftUI + SwiftData 的 iOS 应用（iOS 17+），为家庭提供厨房点餐服务。应用支持厨房管理员管理菜品和今日餐单，家庭成员进行点餐，并提供全国私人菜谱浏览功能。

---

## 技术栈

- **UI 框架:** SwiftUI
- **数据持久化:** SwiftData
- **最低版本:** iOS 17+
- **数据存储:** 纯本地存储（家庭厨房模块）+ 混合数据策略（私人菜谱模块）

---

## 应用架构

### 启动流程

```
启动页
  ├── 选择身份
  │     ├── 我是厨房管理员 → 管理员端
  │     └── 我是家庭成员 → 顾客端
```

### 导航结构（竖向侧边栏）

**管理员端:**
- [菜品] - 菜品管理
- [今日餐单] - 今日点餐数据展示
- [想吃] - 成员想吃的菜品管理
- [统计] - 点餐数据统计分析
- [成员] - 成员管理
- [菜谱] - 私人菜谱（通用）
- [设置] - 应用设置

**顾客端:**
- [点餐] - 菜品浏览与点餐
- [想吃] - 我想吃的菜品
- [菜谱] - 私人菜谱（通用）

---

## 数据模型

### 家庭厨房模块

```swift
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
}

enum DishCategory: String, Codable, CaseIterable {
    case breakfast     // 早餐
    case lunch         // 午餐
    case dinner        // 晚餐
    case snack         // 零食
    case drink         // 饮品
}

// 今日餐单
@Model
class DailyMenu {
    var id: UUID
    var mealType: MealType    // 餐次类型
    var memberId: UUID        // 点餐人ID
    var dishId: UUID          // 菜品ID
    var dishName: String      // 菜品名称
    var memberName: String    // 点餐人姓名
    var createdAt: Date        // 点餐时间
    @Relationship var family: Family?
}

enum MealType: String, Codable, CaseIterable {
    case breakfast   // 早餐
    case lunch       // 午餐
    case dinner      // 晚餐
}

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
}

enum StatisticsType: String, Codable, CaseIterable {
    case daily        // 今日统计
    case weekly       // 近一周统计
    case monthly      // 近一月统计
    case quarterly    // 近三月统计
    case yearly       // 近一年统计
}

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
    var recipeId: UUID?       // 关联的菜谱ID（如果从菜谱添加）
    @Relationship var family: Family?
}
```

### 私人菜谱模块

```swift
// 网络请求模型（占位）
struct RecipeAPI {
    static func fetchRecipes(page: Int, region: String?) async -> [RemoteRecipe]
    static func fetchRecipeDetail(id: String) async -> RemoteRecipeDetail
    static func postComment(recipeId: String, content: String, rating: Int) async
}

// 远程菜谱数据模型
struct RemoteRecipe: Codable, Identifiable {
    var id: String
    var merchantId: String
    var merchantName: String
    var merchantLocation: String
    var name: String
    var description: String
    var imageURL: URL?
    var rating: Double
    var commentCount: Int
    var isCollected: Bool
}

// 本地缓存的菜谱
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
}
```

---

## 核心功能

### 管理员端功能

#### 菜品管理
- 查看菜品列表（按分类筛选）
- 新增菜品
- 编辑菜品
- 上架/下架菜品

#### 今日餐单
- 查看今日点餐数据（按早/中/晚餐分组）
- 查看点餐详情（菜名、点餐人、时间）
- 每日24点自动清空今日餐单数据

#### 想吃
- 查看家庭成员想吃的菜品
- 展示菜品详细信息（名称、原材料、调味料、烹饪步骤、成品图）
- 标记为已添加到菜单（可选）
- 删除想吃的菜品

#### 统计
- 查看点餐统计数据
- 按家庭成员维度展示
- 支持不同时间维度：
  - 今日统计
  - 近一周统计
  - 近一月统计
  - 近三月统计
  - 近一年统计
- 显示每个成员点餐的菜品和次数

#### 成员管理
- 查看家庭成员列表
- 添加新成员
- 移除成员
- 查看成员点餐统计

### 顾客端功能

#### 点餐
- 浏览菜品列表（按分类筛选）
- 搜索菜品
- 查看菜品详情
- 直接点餐（添加到今日餐单）
- 选择用餐人（自己）
- 填写备注

#### 想吃
- 查看我想吃的菜品列表
- 添加新的想吃菜品（手动输入）
- 从私人菜谱添加到想吃
- 查看详情（原材料、调味料、烹饪步骤）

### 公共功能

#### 私人菜谱模块
- 浏览全国菜谱（按地区筛选）
- 搜索菜谱
- 查看菜谱详情
- 收藏/取消收藏菜谱
- 点赞菜谱
- 查看评论
- 发表评论
- **顾客端**：添加到"想吃"按钮
- **管理员端**：一键上架按钮（将菜谱添加为家庭菜品）

### 私人菜谱模块（通用）

- 浏览全国菜谱（按地区筛选）
- 搜索菜谱
- 查看菜谱详情
- 收藏/取消收藏菜谱
- 点赞菜谱
- 查看评论
- 发表评论

---

## 数据流

### 点餐流程

```
顾客浏览菜品 → 点击点餐 → 创建DailyMenu
                                    ↓
                        关联FamilyMember
                                    ↓
                        存入SwiftData
                                    ↓
                        管理员端今日餐单实时展示
```

### 每日24点数据清理流程

```
系统定时检查 → 时间到达24:00 → 清空今日餐单数据
                                    ↓
                        统计模块数据更新
                                    ↓
                        创建OrderStatistics记录
                                    ↓
                        保留历史数据供分析
```

### 添加到想吃流程

```
顾客端手动添加 / 从菜谱添加 → 创建WantedDish
                                    ↓
                        关联添加人（FamilyMember）
                                    ↓
                        存入SwiftData
                                    ↓
                        管理员端查看想吃列表
```

---

## 错误处理

| 错误场景 | 处理方式 |
|---------|---------|
| 菜品已下架 | 隐藏菜品，提示"暂不可点" |
| 今日餐单清空失败 | 记录错误，下次启动重试 |
| 添加想吃菜品失败 | 显示错误提示，重试 |
| 数据读取失败 | 显示空状态，提供刷新按钮 |
| SwiftData持久化失败 | 显示错误，提醒检查存储空间 |
| 24点定时任务失败 | 记录错误，下次重试 |

---

## 私人菜谱数据策略

- **首次启动:** 使用本地模拟数据（各地区代表性菜谱）
- **后续接入:** 保留模拟数据作为 fallback，API 成功时更新缓存
- **离线模式:** 显示缓存数据

---

## 关键特性

1. **一对多关系:** 一个厨房管理员管理多个家庭成员点餐
2. **角色区分:** 清晰的管理员/顾客角色权限
3. **独立入口:** 启动页选择进入不同端
4. **用户切换:** 支持在应用内切换不同用户（家庭成员）
5. **通用菜谱:** 私人菜谱在两端完全相同，共享数据
6. **纯本地存储:** 家庭厨房模块完全本地化
7. **混合策略:** 私人菜谱模块预留 API 结构
8. **数据生命周期:** 今日餐单每日自动清理，统计数据永久保存

---

## 待实现事项

## 待实现事项

- [ ] 搭建 SwiftUI + SwiftData 项目基础
- [ ] 实现启动页和身份选择
- [ ] 实现用户切换功能
- [ ] 实现管理员端界面
- [ ] 实现顾客端界面
- [ ] 实现私人菜谱模块
- [ ] 实现数据模型和持久化
- [ ] 实现24点定时任务
- [ ] 实现错误处理
- [ ] 准备本地模拟菜谱数据

## 详细实现计划

### 阶段一：基础架构搭建

#### 1. 项目创建和基础配置
- [ ] 创建 SwiftUI + SwiftData 项目
- [ ] 配置项目依赖和权限
- [ ] 设置多目标（管理员端/顾客端）
- [ ] 创建基础文件夹结构

#### 2. 用户系统
- [ ] 实现启动页和身份选择
- [ ] 创建用户切换界面
- [ ] 实现用户状态管理
- [ ] 创建用户偏好设置

#### 3. 数据模型更新
- [ ] 更新 FamilyMember 模型（移除价格相关）
- [ ] 创建 DailyMenu 模型
- [ ] 创建 WantedDish 模型
- [ ] 创建 OrderStatistics 模型
- [ ] 更新 Dish 模型（移除价格字段）
- [ ] 移除 Order 相关模型

### 阶段二：核心功能实现

#### 4. 管理员端
- [ ] 菜品管理模块
  - [ ] 菜品列表展示
  - [ ] 新增/编辑菜品
  - [ ] 上架/下架功能
- [ ] 今日餐单模块
  - [ ] 按餐次分组显示
  - [ ] 点餐详情展示
  - [ ] 24点自动清理逻辑
- [ ] 想吃模块
  - [ ] 成员想吃列表
  - [ ] 菜品详情展示
  - [ ] 标记处理功能
- [ ] 统计模块
  - [ ] 时间维度选择器
  - [ ] 成员统计数据
  - [ ] 图表展示
- [ ] 成员管理
  - [ ] 成员列表
  - [ ] 添加/删除成员
  - [ ] 权限管理

#### 5. 顾客端
- [ ] 点餐模块
  - [ ] 菜品浏览
  - [ ] 直接下单功能
  - [ ] 备注功能
- [ ] 想吃模块
  - [ ] 我想吃列表
  - [ ] 手动添加功能
  - [ ] 从菜谱添加
  - [ ] 详情查看

#### 6. 私人菜谱模块（两端通用）
- [ ] 菜谱列表
- [ ] 菜谱详情
- [ ] 收藏功能
- [ ] 评论功能
- [ ] 顾客端：添加到想吃按钮
- [ ] 管理员端：一键上架按钮

### 阶段三：数据处理和优化

#### 7. 24点定时任务
- [ ] 创建定时器管理
- [ ] 实现数据清理逻辑
- [ ] 实现统计更新逻辑
- [ ] 错误处理和重试机制

#### 8. 数据流实现
- [ ] 点餐数据流向今日餐单
- [ ] 今日餐单数据流向统计模块
- [ ] 想吃数据管理

#### 9. 界面优化
- [ ] 响应式设计
- [ ] 动画效果
- [ ] 加载状态
- [ ] 错误提示
- [ ] 空状态处理

### 阶段四：测试和发布

#### 10. 测试
- [ ] 单元测试
- [ ] 集成测试
- [ ] UI 测试
- [ ] 性能测试

#### 11. 发布准备
- [ ] 创建 App Store 描述
- [ ] 准备截图
- [ ] 编写更新日志
- [ ] 提交审核
