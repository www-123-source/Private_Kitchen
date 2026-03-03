import Foundation
import CloudKit
import SwiftUI
import SwiftData

// CloudKit 同步管理器
@MainActor
class CloudKitManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    @Published var syncError: Error?
    @Published var syncProgress: Double = 0.0

    // MARK: - Private Properties
    private let container: CKContainer
    private let database: CKDatabase
    private let modelContext: ModelContext
    private var pendingOperations = [CKDatabaseOperation]()
    private var syncQueue = DispatchQueue(label: "com.privatekitchen.cloudkit.sync")
    private var changeTokens: [String: CKServerChangeToken] = [:]

    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.container = CKContainer(identifier: "iCloud.com.privatekitchen")
        self.database = container.privateCloudDatabase

        // 加载本地保存的 change tokens
        loadChangeTokens()
    }

    // MARK: - Public Methods

    /// 手动触发同步
    func syncAllData() async {
        guard !isSyncing else {
            print("Sync already in progress")
            return
        }

        isSyncing = true
        syncProgress = 0.0
        syncError = nil

        defer {
            isSyncing = false
            lastSyncTime = Date()
        }

        do {
            try await syncFamilies()
            syncProgress = 0.16
            try await syncFamilyMembers()
            syncProgress = 0.33
            try await syncDishes()
            syncProgress = 0.50
            try await syncDailyMenus()
            syncProgress = 0.66
            try await syncWantedDishes()
            syncProgress = 0.83
            try await syncOrderStatistics()
            syncProgress = 1.0
        } catch {
            syncError = error
            print("Sync error: \(error)")
        }
    }

    /// 同步单个家庭数据
    func syncFamily(_ family: Family) async throws {
        let record = try family.toCKRecord()
        try await saveRecord(record)
    }

    /// 同步单个成员数据
    func syncMember(_ member: FamilyMember) async throws {
        guard let family = member.family else {
            throw CloudKitError.recordNotFound
        }
        let record = try member.toCKRecord(familyID: family.id)
        try await saveRecord(record)
    }

    /// 同步单个菜品数据
    func syncDish(_ dish: Dish) async throws {
        guard let family = dish.family else {
            throw CloudKitError.recordNotFound
        }
        let record = try dish.toCKRecord(familyID: family.id)
        try await saveRecord(record)
    }

    /// 同步单个今日餐单数据
    func syncDailyMenu(_ dailyMenu: DailyMenu) async throws {
        guard let family = dailyMenu.family else {
            throw CloudKitError.recordNotFound
        }
        let record = try dailyMenu.toCKRecord(familyID: family.id)
        try await saveRecord(record)
    }

    /// 同步单个想吃菜品数据
    func syncWantedDish(_ wantedDish: WantedDish) async throws {
        guard let family = wantedDish.family else {
            throw CloudKitError.recordNotFound
        }
        let record = try wantedDish.toCKRecord(familyID: family.id)
        try await saveRecord(record)
    }

    /// 同步单个统计数据
    func syncStatistics(_ statistics: OrderStatistics) async throws {
        guard let family = statistics.family else {
            throw CloudKitError.recordNotFound
        }
        let record = try statistics.toCKRecord(familyID: family.id)
        try await saveRecord(record)
    }

    /// 删除云端记录
    func deleteRecord(_ id: UUID, type: CloudKitRecordType) async throws {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        _ = try await database.deleteRecord(withID: recordID)
    }

    // MARK: - Private Methods

    /// 同步所有家庭数据
    private func syncFamilies() async throws {
        try await fetchAndSaveRecords(ofType: .family) { [weak self] record in
            try await self?.handleFamilyRecord(record)
        }
    }

    /// 同步所有成员数据
    private func syncFamilyMembers() async throws {
        try await fetchAndSaveRecords(ofType: .familyMember) { [weak self] record in
            try await self?.handleFamilyMemberRecord(record)
        }
    }

    /// 同步所有菜品数据
    private func syncDishes() async throws {
        try await fetchAndSaveRecords(ofType: .dish) { [weak self] record in
            try await self?.handleDishRecord(record)
        }
    }

    /// 同步所有今日餐单数据
    private func syncDailyMenus() async throws {
        try await fetchAndSaveRecords(ofType: .dailyMenu) { [weak self] record in
            try await self?.handleDailyMenuRecord(record)
        }
    }

    /// 同步所有想吃菜品数据
    private func syncWantedDishes() async throws {
        try await fetchAndSaveRecords(ofType: .wantedDish) { [weak self] record in
            try await self?.handleWantedDishRecord(record)
        }
    }

    /// 同步所有统计数据
    private func syncOrderStatistics() async throws {
        try await fetchAndSaveRecords(ofType: .orderStatistics) { [weak self] record in
            try await self?.handleOrderStatisticsRecord(record)
        }
    }

    /// 从云端获取并保存记录
    private func fetchAndSaveRecords<T>(
        ofType type: CloudKitRecordType,
        handler: @escaping (CKRecord) async throws -> Void
    ) async throws {
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: changeTokens[type.rawValue])

        var recordIDs = [CKRecord.ID]()
        operation.recordZoneWithIDChangedBlock = { _, changeToken in
            self.changeTokens[type.rawValue] = changeToken
        }

        operation.recordChangedBlock = { recordID in
            recordIDs.append(recordID)
        }

        operation.fetchDatabaseChangesCompletionBlock = { [weak self] token, _, error in
            if let error = error {
                self?.syncError = error
                throw error
            }
            if let token = token {
                self?.changeTokens[type.rawValue] = token
                self?.saveChangeTokens()
            }
        }

        // 批量获取记录
        if !recordIDs.isEmpty {
            let fetchOperation = CKFetchRecordsOperation(recordIDs: recordIDs)
            fetchOperation.perRecordCompletionBlock = { record, _, error in
                if let record = record, error == nil {
                    Task.detached {
                        try? await handler(record)
                    }
                }
            }
            try await database.add(fetchOperation)
        }
    }

    /// 保存 CloudKit 记录
    private func saveRecord(_ record: CKRecord) async throws {
        _ = try await database.save(record)
    }

    // MARK: - Record Handlers

    private func handleFamilyRecord(_ record: CKRecord) async throws {
        let family = Family.fromCKRecord(record)
        modelContext.insert(family)
        try modelContext.save()
    }

    private func handleFamilyMemberRecord(_ record: CKRecord) async throws {
        let member = FamilyMember.fromCKRecord(record)
        modelContext.insert(member)
        try modelContext.save()
    }

    private func handleDishRecord(_ record: CKRecord) async throws {
        let dish = Dish.fromCKRecord(record)
        modelContext.insert(dish)
        try modelContext.save()
    }

    private func handleDailyMenuRecord(_ record: CKRecord) async throws {
        let dailyMenu = DailyMenu.fromCKRecord(record)
        modelContext.insert(dailyMenu)
        try modelContext.save()
    }

    private func handleWantedDishRecord(_ record: CKRecord) async throws {
        let wantedDish = WantedDish.fromCKRecord(record)
        modelContext.insert(wantedDish)
        try modelContext.save()
    }

    private func handleOrderStatisticsRecord(_ record: CKRecord) async throws {
        let statistics = OrderStatistics.fromCKRecord(record)
        modelContext.insert(statistics)
        try modelContext.save()
    }

    // MARK: - Change Token Management

    private func loadChangeTokens() {
        if let data = UserDefaults.standard.data(forKey: "cloudKitChangeTokens"),
           let tokens = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String: CKServerChangeToken] {
            self.changeTokens = tokens
        }
    }

    private func saveChangeTokens() {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: changeTokens, requiringSecureCoding: false) {
            UserDefaults.standard.set(data, forKey: "cloudKitChangeTokens")
        }
    }
}

// MARK: - CloudKit 扩展

extension Family {
    func toCKRecord() throws -> CKRecord {
        let record = CKRecord(recordType: CloudKitRecordType.family.rawValue, recordID: CKRecord.ID(recordName: id.uuidString))
        record[CloudKitField.familyName.rawValue] = name as CKRecordValue
        record[CloudKitField.adminId.rawValue] = adminId.uuidString as CKRecordValue
        record[CloudKitField.createdAt.rawValue] = createdAt as CKRecordValue
        record[CloudKitField.updatedAt.rawValue] = updatedAt as CKRecordValue
        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> Family {
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let name = record[CloudKitField.familyName.rawValue] as? String ?? "Unknown"
        let adminId = UUID(uuidString: record[CloudKitField.adminId.rawValue] as? String ?? "") ?? UUID()
        return Family(id: id, name: name, adminId: adminId)
    }
}

extension FamilyMember {
    func toCKRecord(familyID: UUID) throws -> CKRecord {
        let record = CKRecord(recordType: CloudKitRecordType.familyMember.rawValue, recordID: CKRecord.ID(recordName: id.uuidString))
        record[CloudKitField.memberName.rawValue] = name as CKRecordValue
        record[CloudKitField.avatar.rawValue] = avatar as CKRecordValue
        record[CloudKitField.role.rawValue] = role.rawValue as CKRecordValue
        record[CloudKitField.joinedAt.rawValue] = joinedAt as CKRecordValue
        record[CloudKitField.createdAt.rawValue] = joinedAt as CKRecordValue
        record["familyID"] = familyID.uuidString as CKRecordValue
        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> FamilyMember {
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let name = record[CloudKitField.memberName.rawValue] as? String ?? "Unknown"
        let roleRaw = record[CloudKitField.role.rawValue] as? String ?? "member"
        let role = MemberRole(rawValue: roleRaw) ?? .member
        let joinedAt = record[CloudKitField.joinedAt.rawValue] as? Date ?? Date()
        return FamilyMember(id: id, name: name, role: role, joinedAt: joinedAt)
    }
}

extension Dish {
    func toCKRecord(familyID: UUID) throws -> CKRecord {
        let record = CKRecord(recordType: CloudKitRecordType.dish.rawValue, recordID: CKRecord.ID(recordName: id.uuidString))
        record[CloudKitField.dishName.rawValue] = name as CKRecordValue
        record[CloudKitField.dishDescription.rawValue] = description as CKRecordValue
        record[CloudKitField.category.rawValue] = category.rawValue as CKRecordValue
        record[CloudKitField.image.rawValue] = image as CKRecordValue
        record[CloudKitField.isAvailable.rawValue] = isAvailable as CKRecordValue
        record[CloudKitField.createdAt.rawValue] = createdAt as CKRecordValue
        record[CloudKitField.updatedAt.rawValue] = updatedAt as CKRecordValue
        record["familyID"] = familyID.uuidString as CKRecordValue
        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> Dish {
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let name = record[CloudKitField.dishName.rawValue] as? String ?? "Unknown"
        let description = record[CloudKitField.dishDescription.rawValue] as? String ?? ""
        let categoryRaw = record[CloudKitField.category.rawValue] as? String ?? "breakfast"
        let category = DishCategory(rawValue: categoryRaw) ?? .breakfast
        let image = record[CloudKitField.image.rawValue] as? Data
        let isAvailable = record[CloudKitField.isAvailable.rawValue] as? Bool ?? true
        let createdAt = record[CloudKitField.createdAt.rawValue] as? Date ?? Date()
        let updatedAt = record[CloudKitField.updatedAt.rawValue] as? Date ?? Date()
        return Dish(id: id, name: name, description: description, category: category, image: image, isAvailable: isAvailable)
    }
}

extension DailyMenu {
    func toCKRecord(familyID: UUID) throws -> CKRecord {
        let record = CKRecord(recordType: CloudKitRecordType.dailyMenu.rawValue, recordID: CKRecord.ID(recordName: id.uuidString))
        record[CloudKitField.mealType.rawValue] = mealType.rawValue as CKRecordValue
        record[CloudKitField.memberId.rawValue] = memberId.uuidString as CKRecordValue
        record[CloudKitField.dishId.rawValue] = dishId.uuidString as CKRecordValue
        record[CloudKitField.dishName.rawValue] = dishName as CKRecordValue
        record[CloudKitField.memberName.rawValue] = memberName as CKRecordValue
        record[CloudKitField.note.rawValue] = note as CKRecordValue
        record[CloudKitField.createdAt.rawValue] = createdAt as CKRecordValue
        record["familyID"] = familyID.uuidString as CKRecordValue
        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> DailyMenu {
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let mealTypeRaw = record[CloudKitField.mealType.rawValue] as? String ?? "breakfast"
        let mealType = MealType(rawValue: mealTypeRaw) ?? .breakfast
        let memberId = UUID(uuidString: record[CloudKitField.memberId.rawValue] as? String ?? "") ?? UUID()
        let dishId = UUID(uuidString: record[CloudKitField.dishId.rawValue] as? String ?? "") ?? UUID()
        let dishName = record[CloudKitField.dishName.rawValue] as? String ?? "Unknown"
        let memberName = record[CloudKitField.memberName.rawValue] as? String ?? "Unknown"
        let note = record[CloudKitField.note.rawValue] as? String
        let createdAt = record[CloudKitField.createdAt.rawValue] as? Date ?? Date()
        return DailyMenu(mealType: mealType, memberId: memberId, dishId: dishId, dishName: dishName, memberName: memberName, createdAt: createdAt, note: note)
    }
}

extension WantedDish {
    func toCKRecord(familyID: UUID) throws -> CKRecord {
        let record = CKRecord(recordType: CloudKitRecordType.wantedDish.rawValue, recordID: CKRecord.ID(recordName: id.uuidString))
        record[CloudKitField.memberId.rawValue] = memberId.uuidString as CKRecordValue
        record[CloudKitField.memberName.rawValue] = memberName as CKRecordValue
        record[CloudKitField.dishName.rawValue] = name as CKRecordValue
        record[CloudKitField.ingredients.rawValue] = ingredients as CKRecordValue
        record[CloudKitField.seasonings.rawValue] = seasonings as CKRecordValue
        record[CloudKitField.cookingSteps.rawValue] = cookingSteps as CKRecordValue
        record[CloudKitField.finishedImage.rawValue] = finishedImage as CKRecordValue
        record[CloudKitField.recipeId.rawValue] = recipeId?.uuidString as CKRecordValue
        record[CloudKitField.createdAt.rawValue] = createdAt as CKRecordValue
        record["familyID"] = familyID.uuidString as CKRecordValue
        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> WantedDish {
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let memberId = UUID(uuidString: record[CloudKitField.memberId.rawValue] as? String ?? "") ?? UUID()
        let memberName = record[CloudKitField.memberName.rawValue] as? String ?? "Unknown"
        let name = record[CloudKitField.dishName.rawValue] as? String ?? "Unknown"
        let ingredients = record[CloudKitField.ingredients.rawValue] as? String ?? ""
        let seasonings = record[CloudKitField.seasonings.rawValue] as? String ?? ""
        let cookingSteps = record[CloudKitField.cookingSteps.rawValue] as? String ?? ""
        let finishedImage = record[CloudKitField.finishedImage.rawValue] as? Data
        let recipeId = UUID(uuidString: record[CloudKitField.recipeId.rawValue] as? String ?? "")
        let createdAt = record[CloudKitField.createdAt.rawValue] as? Date ?? Date()
        return WantedDish(memberId: memberId, memberName: memberName, name: name, ingredients: ingredients, seasonings: seasonings, cookingSteps: cookingSteps, createdAt: createdAt)
    }
}

extension OrderStatistics {
    func toCKRecord(familyID: UUID) throws -> CKRecord {
        let record = CKRecord(recordType: CloudKitRecordType.orderStatistics.rawValue, recordID: CKRecord.ID(recordName: id.uuidString))
        record[CloudKitField.memberId.rawValue] = memberId.uuidString as CKRecordValue
        record[CloudKitField.dishId.rawValue] = dishId.uuidString as CKRecordValue
        record[CloudKitField.dishName.rawValue] = dishName as CKRecordValue
        record[CloudKitField.totalOrders.rawValue] = totalOrders as CKRecordValue
        record[CloudKitField.lastOrderedAt.rawValue] = lastOrderedAt as CKRecordValue
        record[CloudKitField.statisticsType.rawValue] = statisticsType.rawValue as CKRecordValue
        record[CloudKitField.createdAt.rawValue] = createdAt as CKRecordValue
        record[CloudKitField.updatedAt.rawValue] = updatedAt as CKRecordValue
        record["familyID"] = familyID.uuidString as CKRecordValue
        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> OrderStatistics {
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let memberId = UUID(uuidString: record[CloudKitField.memberId.rawValue] as? String ?? "") ?? UUID()
        let dishId = UUID(uuidString: record[CloudKitField.dishId.rawValue] as? String ?? "") ?? UUID()
        let dishName = record[CloudKitField.dishName.rawValue] as? String ?? "Unknown"
        let totalOrders = record[CloudKitField.totalOrders.rawValue] as? Int ?? 0
        let lastOrderedAt = record[CloudKitField.lastOrderedAt.rawValue] as? Date ?? Date()
        let statisticsTypeRaw = record[CloudKitField.statisticsType.rawValue] as? String ?? "daily"
        let statisticsType = StatisticsType(rawValue: statisticsTypeRaw) ?? .daily
        let createdAt = record[CloudKitField.createdAt.rawValue] as? Date ?? Date()
        let updatedAt = record[CloudKitField.updatedAt.rawValue] as? Date ?? Date()
        return OrderStatistics(memberId: memberId, dishId: dishId, dishName: dishName, totalOrders: totalOrders, lastOrderedAt: lastOrderedAt, statisticsType: statisticsType)
    }
}
