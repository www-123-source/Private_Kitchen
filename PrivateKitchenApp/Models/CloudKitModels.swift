import Foundation
import CloudKit

// CloudKit 记录类型定义
enum CloudKitRecordType: String {
    case family = "Family"
    case familyMember = "FamilyMember"
    case dish = "Dish"
    case dailyMenu = "DailyMenu"
    case wantedDish = "WantedDish"
    case orderStatistics = "OrderStatistics"
    case recipe = "Recipe"
    case recipeComment = "RecipeComment"
}

// CloudKit 字段定义
enum CloudKitField: String {
    // 通用字段
    case id = "id"
    case createdAt = "createdAt"
    case updatedAt = "updatedAt"

    // Family 字段
    case familyName = "familyName"
    case adminId = "adminId"

    // FamilyMember 字段
    case memberName = "memberName"
    case avatar = "avatar"
    case role = "role"
    case joinedAt = "joinedAt"

    // Dish 字段
    case dishName = "dishName"
    case dishDescription = "dishDescription"
    case category = "category"
    case image = "image"
    case isAvailable = "isAvailable"

    // DailyMenu 字段
    case mealType = "mealType"
    case memberId = "memberId"
    case dishId = "dishId"
    case memberName = "memberName"
    case note = "note"

    // WantedDish 字段
    case ingredients = "ingredients"
    case seasonings = "seasonings"
    case cookingSteps = "cookingSteps"
    case finishedImage = "finishedImage"
    case recipeId = "recipeId"

    // OrderStatistics 字段
    case dishName = "dishName"
    case totalOrders = "totalOrders"
    case lastOrderedAt = "lastOrderedAt"
    case statisticsType = "statisticsType"

    // Recipe 字段
    case remoteId = "remoteId"
    case merchantName = "merchantName"
    case merchantLocation = "merchantLocation"
    case recipeDescription = "recipeDescription"
    case imageData = "imageData"
    case rating = "rating"
    case commentCount = "commentCount"
    case isCollected = "isCollected"
    case isLiked = "isLiked"

    // RecipeComment 字段
    case userName = "userName"
    case commentContent = "commentContent"
    case commentRating = "commentRating"
}

// CloudKit 同步状态
enum CloudKitSyncStatus: String {
    case pending = "等待同步"
    case syncing = "同步中"
    case success = "同步成功"
    case failed = "同步失败"
    case conflict = "冲突"
}

// 同步元数据
struct SyncMetadata {
    var recordID: CKRecord.ID
    var syncStatus: CloudKitSyncStatus
    var lastSyncedAt: Date
    var changeToken: CKServerChangeToken?

    init(recordID: CKRecord.ID, syncStatus: CloudKitSyncStatus = .pending) {
        self.recordID = recordID
        self.syncStatus = syncStatus
        self.lastSyncedAt = Date()
        self.changeToken = nil
    }
}

// CloudKit 操作结果
enum CloudKitResult<T> {
    case success(T)
    case failure(CloudKitError)

    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }

    var value: T? {
        switch self {
        case .success(let value): return value
        case .failure: return nil
        }
    }
}

// CloudKit 错误类型
enum CloudKitError: Error {
    case networkError
    case authenticationError
    case quotaExceeded
    case recordNotFound
    case conflictDetected
    case permissionDenied
    case unknownError(Error)

    var localizedDescription: String {
        switch self {
        case .networkError: return "网络连接失败"
        case .authenticationError: return "身份验证失败"
        case .quotaExceeded: return "存储配额已满"
        case .recordNotFound: return "记录不存在"
        case .conflictDetected: return "数据冲突"
        case .permissionDenied: return "权限不足"
        case .unknownError(let error): return error.localizedDescription
        }
    }
}
