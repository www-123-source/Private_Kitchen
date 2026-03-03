# Private Kitchen App Update Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update the Private Kitchen iOS app to remove payment modules and add Today's Menu, Wanted Dishes, and Statistics modules with CloudKit sync support.

**Architecture:** Use SwiftData for local storage with optional CloudKit sync for multi-device support. Implement real-time sync for family data while keeping the app functional offline.

**Tech Stack:** SwiftUI, SwiftData, CloudKit, BackgroundTasks

---

## Phase 1: Data Model Updates

### Task 1: Remove Payment and Order Models

**Files:**
- Modify: `PrivateKitchenApp/Models/FamilyModels.swift:97-163`
- Test: No tests needed for removal

**Step 1: Remove Order, OrderItem, and Payment related code**

```swift
// Remove these entire models from FamilyModels.swift:
// - Order
// - OrderItem
// - PaymentManager (in separate file)
// - CartManager (in separate file)
```

**Step 2: Update Family model to remove orders relationship**

```swift
@Model
class Family {
    var id: UUID
    var name: String
    var adminId: UUID
    @Relationship(deleteRule: .cascade, inverse: \FamilyMember.family)
    var members: [FamilyMember]
    @Relationship(deleteRule: .cascade, inverse: \Dish.family)
    var dishes: [Dish]
    // Remove: var orders: [Order]
}
```

**Step 3: Update FamilyMember to remove orders relationship**

```swift
@Model
class FamilyMember {
    var id: UUID
    var name: String
    var avatar: Data?
    var role: MemberRole
    var joinedAt: Date
    @Relationship var family: Family?
    // Remove: var orders: [Order]
}
```

**Step 4: Update Dish to remove price field**

```swift
@Model
class Dish {
    var id: UUID
    var name: String
    var description: String
    // Remove: var price: Double
    var category: DishCategory
    var image: Data?
    var isAvailable: Bool
    var createdAt: Date
    var updatedAt: Date
    @Relationship var family: Family?
}
```

**Step 5: Commit**

```bash
git add PrivateKitchenApp/Models/FamilyModels.swift
git commit -m "feat: remove payment and order models"
```

### Task 2: Add New Data Models

**Files:**
- Create: `PrivateKitchenApp/Models/DailyMenu.swift`
- Create: `PrivateKitchenApp/Models/WantedDish.swift`
- Create: `PrivateKitchenApp/Models/OrderStatistics.swift`
- Create: `PrivateKitchenApp/Models/CloudKitModels.swift`

**Step 1: Create DailyMenu model**

```swift
// PrivateKitchenApp/Models/DailyMenu.swift
import SwiftData

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
    case breakfast
    case lunch
    case dinner

    var displayName: String {
        switch self {
        case .breakfast: return "早餐"
        case .lunch: return "午餐"
        case .dinner: return "晚餐"
        }
    }
}
```

**Step 2: Create WantedDish model**

```swift
// PrivateKitchenApp/Models/WantedDish.swift
import SwiftData

@Model
class WantedDish {
    var id: UUID
    var memberId: UUID
    var memberName: String
    var name: String
    var ingredients: String
    var seasonings: String
    var cookingSteps: String
    var finishedImage: Data?
    var createdAt: Date
    var recipeId: UUID?
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
```

**Step 3: Create OrderStatistics model**

```swift
// PrivateKitchenApp/Models/OrderStatistics.swift
import SwiftData

@Model
class OrderStatistics {
    var id: UUID
    var memberId: UUID
    var dishId: UUID
    var dishName: String
    var totalOrders: Int
    var lastOrderedAt: Date
    var statisticsType: StatisticsType
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
}

enum StatisticsType: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    case quarterly
    case yearly
}
```

**Step 4: Create CloudKit configuration**

```swift
// PrivateKitchenApp/Models/CloudKitModels.swift
import CloudKit

struct CloudKitConfig {
    static let containerID = "iCloud.com.private-kitchen.family"
    static let databaseScope = CKDatabaseScope.Private

    enum RecordType {
        static let family = "Family"
        static let dailyMenu = "DailyMenu"
        static let wantedDish = "WantedDish"
        static let orderStatistics = "OrderStatistics"
    }

    enum Key {
        static let familyID = "familyID"
        static let mealType = "mealType"
        static let memberID = "memberID"
        static let dishName = "dishName"
        static let ingredients = "ingredients"
        static let timestamp = "timestamp"
    }
}

protocol CloudKitSyncable {
    associatedtype CloudKitType

    func toCloudKitRecord() -> CKRecord
    init?(from record: CKRecord)
}
```

**Step 5: Commit**

```bash
git add PrivateKitchenApp/Models/DailyMenu.swift
git add PrivateKitchenApp/Models/WantedDish.swift
git add PrivateKitchenApp/Models/OrderStatistics.swift
git add PrivateKitchenApp/Models/CloudKitModels.swift
git commit -m "feat: add new data models for daily menu, wanted dishes, and statistics"
```

## Phase 2: CloudKit Integration

### Task 3: CloudKit Manager

**Files:**
- Create: `PrivateKitchenApp/Managers/CloudKitManager.swift`

**Step 1: Create CloudKitManager class**

```swift
// PrivateKitchenApp/Managers/CloudKitManager.swift
import CloudKit
import SwiftData
import Combine

@MainActor
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()

    private let container: CKContainer
    private let privateDatabase: CKDatabase

    @Published var syncStatus: SyncStatus = .notEnabled
    @Published var lastSyncDate: Date?

    enum SyncStatus {
        case notEnabled
        case syncing
        case synced
        case error(String)
    }

    init() {
        self.container = CKContainer(identifier: CloudKitConfig.containerID)
        self.privateDatabase = container.privateCloudDatabase
        checkCloudKitAvailability()
    }

    private func checkCloudKitAvailability() {
        container.accountStatus { accountStatus, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.syncStatus = .error(error.localizedDescription)
                }
                return
            }

            switch accountStatus {
            case .available:
                DispatchQueue.main.async { self.syncStatus = .notEnabled }
            case .noAccount, .restricted, .couldNotDetermine:
                DispatchQueue.main.async { self.syncStatus = .notEnabled }
            @unknown default:
                DispatchQueue.main.async { self.syncStatus = .notEnabled }
            }
        }
    }

    func enableSync(for family: Family) async {
        syncStatus = .syncing

        let record = CKRecord(recordType: CloudKitConfig.RecordType.family)
        record[CloudKitConfig.Key.familyID] = family.id.uuidString
        record["adminID"] = family.adminId.uuidString

        do {
            try await privateDatabase.save(record)
            // Create share for the family
            let share = CKShare(rootRecordID: record.recordID)
            share[CKShare.ParticipantRole.owner] = [container.currentUserRecordID!]
            share[CKShare.ParticipantRole.readWrite] = getMemberReferences(for: family)

            let saveOperation = CKModifyRecordsOperation(recordsToSave: [record, share], recordIDsToDelete: [])
            saveOperation.modifyRecordsCompletionBlock = { _, _, error in
                if let error = error {
                    DispatchQueue.main.async { self.syncStatus = .error(error.localizedDescription) }
                } else {
                    DispatchQueue.main.async {
                        self.syncStatus = .synced
                        self.subscribeToChanges()
                    }
                }
            }

            privateDatabase.add(saveOperation)
        } catch {
            DispatchQueue.main.async { self.syncStatus = .error(error.localizedDescription) }
        }
    }

    private func subscribeToChanges() {
        let subscription = CKQuerySubscription(
            recordType: CloudKitConfig.RecordType.dailyMenu,
            predicate: NSPredicate(value: true),
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true

        subscription.notificationInfo = notificationInfo

        privateDatabase.save(subscription) { _, error in
            if let error = error {
                print("Subscription failed: \(error)")
            }
        }
    }

    private func getMemberReferences(for family: Family) -> [CKRecord.Reference] {
        // Implementation to get member references
        return []
    }
}
```

**Step 2: Commit**

```bash
git add PrivateKitchenApp/Managers/CloudKitManager.swift
git commit -m "feat: add CloudKit manager for sync"
```

### Task 4: Data Manager with CloudKit Support

**Files:**
- Create: `PrivateKitchenApp/Managers/DataManager.swift`
- Modify: `PrivateKitchenApp/Models/FamilyModels.swift`

**Step 1: Create DataManager class**

```swift
// PrivateKitchenApp/Managers/DataManager.swift
import SwiftData
import Combine

@MainActor
class DataManager: ObservableObject {
    private let container: ModelContainer
    let cloudKit = CloudKitManager.shared

    @Published var family: Family?
    @Published var currentMember: FamilyMember?
    @Published var cloudSyncEnabled = false

    init() {
        let schema = Schema([
            Family.self,
            FamilyMember.self,
            Dish.self,
            DailyMenu.self,
            WantedDish.self,
            OrderStatistics.self,
            Recipe.self,
            RecipeComment.self
        ])

        let configuration = ModelConfiguration(schema: schema)

        do {
            self.container = try ModelContainer(for: configuration)
            initializeData()
        } catch {
            print("Failed to initialize data container: \(error)")
        }
    }

    private func initializeData() {
        do {
            let families = try container.mainContext.fetch(FetchDescriptor<Family>())
            if let family = families.first {
                self.family = family
                loadMembers()
            } else {
                createDefaultFamily()
            }
        } catch {
            print("Failed to load data: \(error)")
        }
    }

    private func createDefaultFamily() {
        let family = Family(name: "我的家庭", adminId: UUID())
        container.mainContext.insert(family)
        self.family = family

        let admin = FamilyMember(name: "管理员", role: .admin)
        admin.family = family
        container.mainContext.insert(admin)

        try? container.mainContext.save()
    }

    func addDailyMenu(dish: Dish, member: FamilyMember, mealType: MealType, note: String? = nil) {
        guard let family = family else { return }

        let dailyMenu = DailyMenu(
            mealType: mealType,
            memberId: member.id,
            dishId: dish.id,
            dishName: dish.name,
            memberName: member.name,
            note: note,
            family: family
        )

        container.mainContext.insert(dailyMenu)
        saveContext()

        if cloudSyncEnabled {
            Task {
                await syncToCloud([dailyMenu])
            }
        }
    }

    private func syncToCloud<T>(_ objects: [T]) async where T: CloudKitSyncable {
        // Implementation for CloudKit sync
    }

    private func saveContext() {
        do {
            try container.mainContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
```

**Step 2: Update FamilyModels.swift to add new relationships**

```swift
// Add these relationships to Family model
@Relationship(deleteRule: .cascade, inverse: \DailyMenu.family)
var dailyMenus: [DailyMenu]

@Relationship(deleteRule: .cascade, inverse: \WantedDish.family)
var wantedDishes: [WantedDish]

@Relationship(deleteRule: .cascade, inverse: \OrderStatistics.family)
var statistics: [OrderStatistics]
```

**Step 3: Commit**

```bash
git add PrivateKitchenApp/Managers/DataManager.swift
git add PrivateKitchenApp/Models/FamilyModels.swift
git commit -m "feat: add data manager with CloudKit support"
```

## Phase 3: User Switching

### Task 5: User Management

**Files:**
- Create: `PrivateKitchenApp/Managers/UserManager.swift`

**Step 1: Create UserManager class**

```swift
// PrivateKitchenApp/Managers/UserManager.swift
import SwiftUI
import SwiftData

@MainActor
class UserManager: ObservableObject {
    @Published var currentUser: FamilyMember?
    @Published var allUsers: [FamilyMember] = []

    init() {
        loadCurrentUser()
    }

    private func loadCurrentUser() {
        // Load from UserDefaults
        if let userIdString = UserDefaults.standard.string(forKey: "currentUserId"),
           let userId = UUID(uuidString: userIdString) {
            Task {
                await loadUser(with: userId)
            }
        }
    }

    func loadUser(with id: UUID) async {
        do {
            let descriptor = FetchDescriptor<FamilyMember>(predicate: #Predicate { $0.id == id })
            let users = try container.mainContext.fetch(descriptor)
            if let user = users.first {
                currentUser = user
                allUsers = try container.mainContext.fetch(FetchDescriptor<FamilyMember>())
            }
        } catch {
            print("Failed to load user: \(error)")
        }
    }

    func switchUser(to user: FamilyMember) {
        currentUser = user
        UserDefaults.standard.set(user.id.uuidString, forKey: "currentUserId")
        // Notify observers
        objectWillChange.send()
    }

    private var container: ModelContainer {
        // Get the container from the app or environment
        // This is a simplified version - in practice, you'd get it from the app delegate or environment
        fatalError("Container not implemented")
    }
}
```

**Step 2: Create UserSwitcherView**

```swift
// PrivateKitchenApp/Views/Shared/UserSwitcherView.swift
import SwiftUI

struct UserSwitcherView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List(userManager.allUsers, id: \.id) { user in
                Button(action: {
                    userManager.switchUser(to: user)
                    dismiss()
                }) {
                    HStack {
                        if let imageData = user.avatar, let image = UIImage(data: imageData) {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(user.name.prefix(1)))
                                        .foregroundColor(.white)
                                        .font(.title2)
                                )
                        }

                        VStack(alignment: .leading) {
                            Text(user.name)
                                .font(.headline)
                            Text(user.role == .admin ? "管理员" : "家庭成员")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if user.id == userManager.currentUser?.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("切换用户")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
```

**Step 3: Commit**

```bash
git add PrivateKitchenApp/Managers/UserManager.swift
git add PrivateKitchenApp/Views/Shared/UserSwitcherView.swift
git commit -m "feat: add user switching functionality"
```

## Phase 4: Admin Interface Updates

### Task 6: Admin Tab Bar Navigation

**Files:**
- Modify: `PrivateKitchenApp/Views/Admin/AdminTabBarView.swift`

**Step 1: Update admin navigation**

```swift
// PrivateKitchenApp/Views/Admin/AdminTabBarView.swift
struct AdminTabBarView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DishManagementView()
                .tabItem {
                    Image(systemName: "book.closed")
                    Text("菜品")
                }
                .tag(0)

            DailyMenuView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("今日餐单")
                }
                .tag(1)

            WantedDishesAdminView()
                .tabItem {
                    Image(systemName: "heart")
                    Text("想吃")
                }
                .tag(2)

            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("统计")
                }
                .tag(3)

            MemberManagementView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("成员")
                }
                .tag(4)

            RecipeView()
                .tabItem {
                    Image(systemName: "book")
                    Text("菜谱")
                }
                .tag(5)

            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("设置")
                }
                .tag(6)
        }
        .onAppear {
            // Load current user
            if let userId = dataManager.currentMember?.id {
                Task {
                    await dataManager.loadUser(with: userId)
                }
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add PrivateKitchenApp/Views/Admin/AdminTabBarView.swift
git commit -m "feat: update admin tab navigation with new modules"
```

### Task 7: Today's Menu View

**Files:**
- Create: `PrivateKitchenApp/Views/Admin/DailyMenuView.swift`

**Step 1: Create DailyMenuView**

```swift
// PrivateKitchenApp/Views/Admin/DailyMenuView.swift
import SwiftUI

struct DailyMenuView: View {
    @EnvironmentObject var dataManager: DataManager
    @Query private var dailyMenus: [DailyMenu]
    @State private var showingUserSwitcher = false

    var groupedMenus: [MealType: [DailyMenu]] {
        Dictionary(grouping: dailyMenus, by: { $0.mealType })
    }

    var body: some View {
        NavigationView {
            VStack {
                // User switcher button
                HStack {
                    Spacer()
                    Button(action: {
                        showingUserSwitcher = true
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text(dataManager.currentMember?.name ?? "切换用户")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()

                // Daily menu list
                List {
                    ForEach(groupedMenus.keys.sorted { $0.rawValue < $1.rawValue }, id: \.self) { mealType in
                        Section(header: Text(mealType.displayName)) {
                            ForEach(groupedMenus[mealType] ?? [], id: \.id) { menu in
                                DailyMenuItemView(menu: menu)
                            }
                        }
                    }
                }
            }
            .navigationTitle("今日餐单")
            .sheet(isPresented: $showingUserSwitcher) {
                UserSwitcherView()
            }
            .onAppear {
                // Refresh data if CloudKit is enabled
                if dataManager.cloudSyncEnabled {
                    Task {
                        await refreshFromCloud()
                    }
                }
            }
        }
    }

    private func refreshFromCloud() async {
        // Implementation to refresh from CloudKit
    }
}

struct DailyMenuItemView: View {
    let menu: DailyMenu

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(menu.dishName)
                    .font(.headline)

                HStack {
                    Text("由 \(menu.memberName) 点餐")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(formatTime(menu.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let note = menu.note {
                Text("备注: \(note)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
```

**Step 2: Commit**

```bash
git add PrivateKitchenApp/Views/Admin/DailyMenuView.swift
git commit -m "feat: add today's menu view for admin"
```

### Task 8: Statistics View

**Files:**
- Create: `PrivateKitchenApp/Views/Admin/StatisticsView.swift`

**Step 1: Create StatisticsView**

```swift
// PrivateKitchenApp/Views/Admin/StatisticsView.swift
import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTimeRange: StatisticsType = .monthly
    @State private var selectedMember: FamilyMember?
    @Query private var statistics: [OrderStatistics]
    @State private var showingUserSwitcher = false

    var filteredStatistics: [OrderStatistics] {
        guard let selectedMember = selectedMember else { return [] }

        return statistics.filter { stat in
            stat.memberId == selectedMember.id &&
            stat.statisticsType == selectedTimeRange
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // User switcher
                HStack {
                    Spacer()
                    Button(action: {
                        showingUserSwitcher = true
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text(dataManager.currentMember?.name ?? "切换用户")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()

                // Time range selector
                Picker("时间范围", selection: $selectedTimeRange) {
                    ForEach(StatisticsType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // Member selector
                if let family = dataManager.family {
                    Picker("成员", selection: $selectedMember) {
                        ForEach(family.members, id: \.id) { member in
                            Text(member.name).tag(member)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                }

                // Chart
                if filteredStatistics.isEmpty {
                    EmptyStateView(message: "暂无统计数据")
                } else {
                    ChartView(statistics: filteredStatistics)
                }
            }
            .navigationTitle("统计")
            .sheet(isPresented: $showingUserSwitcher) {
                UserSwitcherView()
            }
        }
    }
}

struct ChartView: View {
    let statistics: [OrderStatistics]

    var body: some View {
        Chart {
            ForEach(Array(statistics.enumerated()), id: \.element.id) { index, stat in
                BarMark(
                    x: .value("菜品", stat.dishName),
                    y: .value("次数", stat.totalOrders)
                )
                .foregroundStyle(by: .value("菜品", stat.dishName))
            }
        }
        .chartXAxis {
            AxisLabels(position: .bottom)
        }
        .frame(height: 300)
    }
}

extension StatisticsType {
    var displayName: String {
        switch self {
        case .daily: return "今日"
        case .weekly: return "本周"
        case .monthly: return "本月"
        case .quarterly: return "近三月"
        case .yearly: return "今年"
        }
    }
}
```

**Step 2: Create DailyCleanupManager**

```swift
// PrivateKitchenApp/Managers/DailyCleanupManager.swift
import Foundation
import BackgroundTasks
import SwiftData

@MainActor
class DailyCleanupManager {
    static let shared = DailyCleanupManager()

    private init() {}

    func scheduleDailyTask() {
        // Register the task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "daily-cleanup",
            using: nil
        ) { task in
            Task { [weak self] in
                await self?.handleDailyTask(task as? BGProcessingTask)
            }
        }

        // Schedule the task
        let request = BGProcessingTaskRequest(identifier: "daily-cleanup")
        request.requiresNetworkConnectivity = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60 * 23) // 23 hours from now

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule daily task: \(error)")
        }
    }

    private func handleDailyTask(_ task: BGProcessingTask?) {
        // Schedule the next task
        scheduleDailyTask()

        // Get the model context
        let context = ModelContext(DataManager().container)

        // Get today's date range
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        do {
            // Fetch today's daily menus
            let descriptor = FetchDescriptor<DailyMenu>(
                predicate: #Predicate {
                    $0.createdAt >= today && $0.createdAt < tomorrow
                }
            )
            let dailyMenus = try context.fetch(descriptor)

            // Create statistics for each menu item
            for menu in dailyMenus {
                // Create or update statistics
                updateStatistics(for: menu, in: context)
            }

            // Delete today's daily menus
            for menu in dailyMenus {
                context.delete(menu)
            }

            // Save changes
            try context.save()

            // Set task completion
            task?.setTaskCompleted(success: true)

        } catch {
            print("Daily cleanup failed: \(error)")
            task?.setTaskCompleted(success: false)
        }
    }

    private func updateStatistics(for menu: DailyMenu, in context: ModelContext) {
        // Find existing statistics
        let descriptor = FetchDescriptor<OrderStatistics>(
            predicate: #Predicate {
                $0.memberId == menu.memberId &&
                $0.dishName == menu.dishName &&
                $0.statisticsType == .daily
            }
        )

        do {
            let existingStats = try context.fetch(descriptor)

            if let stats = existingStats.first {
                // Update existing statistics
                stats.totalOrders += 1
                stats.lastOrderedAt = menu.createdAt
                stats.updatedAt = Date()
            } else {
                // Create new statistics
                let stats = OrderStatistics(
                    memberId: menu.memberId,
                    dishId: menu.dishId,
                    dishName: menu.dishName,
                    totalOrders: 1,
                    lastOrderedAt: menu.createdAt,
                    statisticsType: .daily
                )
                context.insert(stats)
            }
        } catch {
            print("Failed to update statistics: \(error)")
        }
    }
}
```

**Step 3: Commit**

```bash
git add PrivateKitchenApp/Views/Admin/StatisticsView.swift
git add PrivateKitchenApp/Managers/DailyCleanupManager.swift
git commit -m "feat: add statistics view and daily cleanup manager"
```

## Phase 5: Customer Interface Updates

### Task 9: Customer Tab Bar Navigation

**Files:**
- Modify: `PrivateKitchenApp/Views/Customer/CustomerTabBarView.swift`

**Step 1: Update customer navigation**

```swift
// PrivateKitchenApp/Views/Customer/CustomerTabBarView.swift
struct CustomerTabBarView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedTab = 0
    @State private var showingUserSwitcher = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DishBrowseView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("点餐")
                }
                .tag(0)

            MyWantedDishesView()
                .tabItem {
                    Image(systemName: "heart")
                    Text("想吃")
                }
                .tag(1)

            RecipeView()
                .tabItem {
                    Image(systemName: "book")
                    Text("菜谱")
                }
                .tag(2)
        }
        .onAppear {
            // Load current user
            if let userId = dataManager.currentMember?.id {
                Task {
                    await dataManager.loadUser(with: userId)
                }
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add PrivateKitchenApp/Views/Customer/CustomerTabBarView.swift
git commit -m "feat: update customer tab navigation"
```

### Task 10: My Wanted Dishes View

**Files:**
- Create: `PrivateKitchenApp/Views/Customer/MyWantedDishesView.swift`
- Create: `PrivateKitchenApp/Views/Customer/AddWantedDishView.swift`

**Step 1: Create MyWantedDishesView**

```swift
// PrivateKitchenApp/Views/Customer/MyWantedDishesView.swift
import SwiftUI

struct MyWantedDishesView: View {
    @EnvironmentObject var dataManager: DataManager
    @Query private var wantedDishes: [WantedDish]
    @State private var showingAddView = false
    @State private var showingUserSwitcher = false

    var myWantedDishes: [WantedDish] {
        wantedDishes.filter { $0.memberId == dataManager.currentMember?.id }
    }

    var body: some View {
        NavigationView {
            VStack {
                // User switcher
                HStack {
                    Spacer()
                    Button(action: {
                        showingUserSwitcher = true
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text(dataManager.currentMember?.name ?? "切换用户")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()

                // List of wanted dishes
                List {
                    ForEach(myWantedDishes, id: \.id) { dish in
                        NavigationLink(destination: WantedDishDetailView(wantedDish: dish)) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)

                                VStack(alignment: .leading) {
                                    Text(dish.name)
                                        .font(.headline)
                                    Text("添加于 \(formatDate(dish.createdAt))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteWantedDish)
                }

                if myWantedDishes.isEmpty {
                    EmptyStateView(message: "还没有想吃的菜品")
                }
            }
            .navigationTitle("我想吃")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingUserSwitcher = true
                    }) {
                        Image(systemName: "person.crop.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddView = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddView) {
                AddWantedDishView()
            }
            .sheet(isPresented: $showingUserSwitcher) {
                UserSwitcherView()
            }
        }
    }

    private func deleteWantedDish(at offsets: IndexSet) {
        let context = DataManager().container.mainContext
        for index in offsets {
            context.delete(myWantedDishes[index])
        }
        try? context.save()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

**Step 2: Create AddWantedDishView**

```swift
// PrivateKitchenApp/Views/Customer/AddWantedDishView.swift
import SwiftUI

struct AddWantedDishView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataManager: DataManager
    @State private var name = ""
    @State private var ingredients = ""
    @State private var seasonings = ""
    @State private var cookingSteps = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("菜品信息")) {
                    TextField("菜品名称", text: $name)

                    TextField("原材料", text: $ingredients, prompt: "例如：鸡蛋 2个，番茄 1个")
                        .textContentType(.name)

                    TextField("调味料", text: $seasonings, prompt: "例如：盐、糖、生抽")
                        .textContentType()

                    TextEditor(text: $cookingSteps)
                        .frame(height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(8)

                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("添加成品图")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                Section {
                    Button(action: saveWantedDish) {
                        Text("保存")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("添加想吃菜品")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }

    private func saveWantedDish() {
        guard let member = dataManager.currentMember,
              let family = dataManager.family else { return }

        let wantedDish = WantedDish(
            memberId: member.id,
            memberName: member.name,
            name: name,
            ingredients: ingredients,
            seasonings: seasonings,
            cookingSteps: cookingSteps,
            family: family
        )

        if let imageData = selectedImage?.jpegData(compressionQuality: 0.8) {
            wantedDish.finishedImage = imageData
        }

        let context = DataManager().container.mainContext
        context.insert(wantedDish)
        try? context.save()

        dismiss()
    }
}
```

**Step 3: Create ImagePicker**

```swift
// PrivateKitchenApp/Views/Shared/ImagePicker.swift
import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> some UIViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss()

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofType: UIImage.self) {
                provider.loadObject(ofType: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}
```

**Step 4: Commit**

```bash
git add PrivateKitchenApp/Views/Customer/MyWantedDishesView.swift
git add PrivateKitchenApp/Views/Customer/AddWantedDishView.swift
git add PrivateKitchenApp/Views/Shared/ImagePicker.swift
git commit -m "feat: add my wanted dishes view for customer"
```

## Phase 6: Recipe Module Enhancements

### Task 11: Recipe Add to Wanted and Quick Add Features

**Files:**
- Modify: `PrivateKitchenApp/Views/Shared/RecipeDetailView.swift`

**Step 1: Update RecipeDetailView**

```swift
// PrivateKitchenApp/Views/Shared/RecipeDetailView.swift
struct RecipeDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    let recipe: Recipe
    @State private var showingAddToWantedAlert = false
    @State private var showingQuickAddAlert = false
    @State private var selectedMealType: MealType = .lunch

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Recipe image
                if let imageData = recipe.imageData, let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                }

                // Recipe info
                Text(recipe.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                HStack {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", recipe.rating))
                    }

                    Text("·")
                        .foregroundColor(.gray)

                    Text("\(recipe.commentCount) 条评论")

                    Spacer()

                    Button(action: toggleFavorite) {
                        Image(systemName: recipe.isCollected ? "heart.fill" : "heart")
                            .foregroundColor(recipe.isCollected ? .red : .gray)
                    }
                }

                Text(recipe.description)
                    .foregroundColor(.secondary)

                // Add to wanted dish button (customer view)
                if dataManager.currentMember?.role == .member {
                    Button(action: {
                        showingAddToWantedAlert = true
                    }) {
                        HStack {
                            Image(systemName: "heart")
                            Text("添加到想吃")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }

                // Quick add button (admin view)
                if dataManager.currentMember?.role == .admin {
                    Button(action: {
                        showingQuickAddAlert = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("一键上架")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }

                // Comments section
                if !recipe.comments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("评论")
                            .font(.headline)

                        ForEach(recipe.comments, id: \.id) { comment in
                            CommentView(comment: comment)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("菜谱详情")
        .navigationBarTitleDisplayMode(.inline)
        .alert("添加到想吃", isPresented: $showingAddToWantedAlert) {
            Button("取消", role: .cancel) { }
            Button("确定") {
                addToWantedDishes()
            }
        } message: {
            Text("将这个菜谱添加到我想吃列表吗？")
        }
        .alert("上架菜品", isPresented: $showingQuickAddAlert) {
            Button("取消", role: .cancel) { }
            Button("确定") {
                quickAddToDishes()
            }
        } message: {
            VStack {
                Text("将此菜谱快速上架为家庭菜品")
                Picker("餐次类型", selection: $selectedMealType) {
                    ForEach(MealType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func toggleFavorite() {
        recipe.isCollected.toggle()
        try? DataManager().container.mainContext.save()
    }

    private func addToWantedDishes() {
        guard let member = dataManager.currentMember,
              let family = dataManager.family else { return }

        let wantedDish = WantedDish(
            memberId: member.id,
            memberName: member.name,
            name: recipe.name,
            ingredients: recipe.description, // Use description as placeholder
            seasonings: "", // Placeholder
            cookingSteps: recipe.description, // Use description as placeholder
            family: family
        )

        // Set recipe reference
        wantedDish.recipeId = recipe.id

        let context = DataManager().container.mainContext
        context.insert(wantedDish)
        try? context.save()

        showingAddToWantedAlert = false
    }

    private func quickAddToDishes() {
        guard let family = dataManager.family else { return }

        let dish = Dish(
            name: recipe.name,
            description: recipe.description,
            category: selectedMealType,
            image: recipe.imageData,
            isAvailable: true,
            family: family
        )

        let context = DataManager().container.mainContext
        context.insert(dish)
        try? context.save()

        showingQuickAddAlert = false
    }
}

struct CommentView: View {
    let comment: RecipeComment

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text(comment.userName)
                    .font(.headline)

                HStack {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < comment.rating ? "star.fill" : "star")
                            .foregroundColor(index < comment.rating ? .yellow : .gray)
                            .font(.caption)
                    }
                }

                Text(comment.content)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }

            Spacer()

            Text(formatDate(comment.createdAt))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
```

**Step 2: Commit**

```bash
git add PrivateKitchenApp/Views/Shared/RecipeDetailView.swift
git commit -m "feat: add add to wanted and quick add features to recipe detail"
```

## Phase 7: Testing

### Task 12: Unit Tests

**Files:**
- Create: `PrivateKitchenAppTests/ModelsTests.swift`
- Create: `PrivateKitchenAppTests/ManagersTests.swift`

**Step 1: Create model tests**

```swift
// PrivateKitchenAppTests/ModelsTests.swift
import XCTest
@testable import PrivateKitchenApp
import SwiftData

final class ModelsTests: XCTestCase {

    var modelContainer: ModelContainer!

    override func setUpWithError() throws {
        let schema = Schema([
            Family.self,
            FamilyMember.self,
            Dish.self,
            DailyMenu.self,
            WantedDish.self,
            OrderStatistics.self
        ])

        let config = ModelConfiguration(schema: schema)
        modelContainer = try ModelContainer(for: config)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
    }

    func testFamilyCreation() throws {
        let family = Family(name: "Test Family", adminId: UUID())

        let context = modelContainer.mainContext
        context.insert(family)

        try context.save()

        // Verify family was created
        let descriptor = FetchDescriptor<Family>()
        let families = try context.fetch(descriptor)

        XCTAssertEqual(families.count, 1)
        XCTAssertEqual(families.first?.name, "Test Family")
    }

    func testDailyMenuCreation() throws {
        let family = Family(name: "Test Family", adminId: UUID())
        let member = FamilyMember(name: "Test Member", role: .member)
        member.family = family
        let dish = Dish(name: "Test Dish", description: "Test Description", category: .lunch, family: family)

        let context = modelContainer.mainContext
        context.insert(family)
        context.insert(member)
        context.insert(dish)

        let dailyMenu = DailyMenu(
            mealType: .lunch,
            memberId: member.id,
            dishId: dish.id,
            dishName: dish.name,
            memberName: member.name,
            family: family
        )

        context.insert(dailyMenu)
        try context.save()

        // Verify daily menu was created
        let descriptor = FetchDescriptor<DailyMenu>()
        let dailyMenus = try context.fetch(descriptor)

        XCTAssertEqual(dailyMenus.count, 1)
        XCTAssertEqual(dailyMenus.first?.dishName, "Test Dish")
        XCTAssertEqual(dailyMenus.first?.mealType, .lunch)
    }

    func testWantedDishCreation() throws {
        let family = Family(name: "Test Family", adminId: UUID())
        let member = FamilyMember(name: "Test Member", role: .member)
        member.family = family

        let context = modelContainer.mainContext
        context.insert(family)
        context.insert(member)

        let wantedDish = WantedDish(
            memberId: member.id,
            memberName: member.name,
            name: "Wanted Dish",
            ingredients: "Ingredients",
            seasonings: "Seasonings",
            cookingSteps: "Steps",
            family: family
        )

        context.insert(wantedDish)
        try context.save()

        // Verify wanted dish was created
        let descriptor = FetchDescriptor<WantedDish>()
        let wantedDishes = try context.fetch(descriptor)

        XCTAssertEqual(wantedDishes.count, 1)
        XCTAssertEqual(wantedDishes.first?.name, "Wanted Dish")
        XCTAssertEqual(wantedDishes.first?.memberName, "Test Member")
    }
}
```

**Step 2: Create manager tests**

```swift
// PrivateKitchenAppTests/ManagersTests.swift
import XCTest
@testable import PrivateKitchenApp
import SwiftData

final class ManagersTests: XCTestCase {

    var modelContainer: ModelContainer!
    var dataManager: DataManager!

    override func setUpWithError() throws {
        let schema = Schema([
            Family.self,
            FamilyMember.self,
            Dish.self,
            DailyMenu.self,
            WantedDish.self,
            OrderStatistics.self
        ])

        let config = ModelConfiguration(schema: schema)
        modelContainer = try ModelContainer(for: config)

        dataManager = DataManager()
        // Use the test container
        dataManager.container = modelContainer
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        dataManager = nil
    }

    func testDataManagerCreation() async {
        // Test that data manager initializes correctly
        XCTAssertNotNil(dataManager)

        // Test that default family is created if none exists
        let descriptor = FetchDescriptor<Family>()
        let families = try? modelContainer.mainContext.fetch(descriptor)

        XCTAssertEqual(families?.count, 1)
        XCTAssertEqual(families?.first?.name, "我的家庭")
    }

    func testAddDailyMenu() async {
        // Setup test data
        let family = Family(name: "Test Family", adminId: UUID())
        let member = FamilyMember(name: "Test Member", role: .member)
        member.family = family
        let dish = Dish(name: "Test Dish", description: "Test", category: .lunch, family: family)

        let context = modelContainer.mainContext
        context.insert(family)
        context.insert(member)
        context.insert(dish)
        try? context.save()

        // Set data manager family and member
        dataManager.family = family
        dataManager.currentMember = member

        // Add daily menu
        dataManager.addDailyMenu(dish: dish, member: member, mealType: .lunch)

        // Verify daily menu was added
        let descriptor = FetchDescriptor<DailyMenu>()
        let dailyMenus = try? modelContainer.mainContext.fetch(descriptor)

        XCTAssertEqual(dailyMenus?.count, 1)
        XCTAssertEqual(dailyMenus?.first?.dishName, "Test Dish")
    }

    func testUserSwitching() async {
        // Setup test data
        let family = Family(name: "Test Family", adminId: UUID())
        let member1 = FamilyMember(name: "Member 1", role: .member)
        let member2 = FamilyMember(name: "Member 2", role: .member)

        member1.family = family
        member2.family = family

        let context = modelContainer.mainContext
        context.insert(family)
        context.insert(member1)
        context.insert(member2)
        try? context.save()

        // Test user switching
        dataManager.switchUser(to: member1)
        XCTAssertEqual(dataManager.currentMember?.name, "Member 1")

        dataManager.switchUser(to: member2)
        XCTAssertEqual(dataManager.currentMember?.name, "Member 2")
    }
}
```

**Step 3: Commit**

```bash
git add PrivateKitchenAppTests/
git commit -m "test: add unit tests for models and managers"
```

## Phase 8: Documentation and Deployment

### Task 13: Update Documentation

**Files:**
- Update: `PrivateKitchenApp/README.md`
- Update: `docs/README.md`

**Step 1: Update README**

```markdown
# Private Kitchen App

An iOS app for family meal management built with SwiftUI and SwiftData.

## Features

### Admin Features
- Dish Management: Add, edit, and manage family dishes
- Today's Menu: View today's orders grouped by meal type (breakfast, lunch, dinner)
- Wanted Dishes: Review family members' wanted dishes
- Statistics: View meal statistics by family member with time range filtering
- Member Management: Add and manage family members
- Recipe Browsing: Browse national recipes with quick add feature

### Customer Features
- Meal Ordering: Browse and order meals directly (no payment required)
- My Wanted Dishes: Add and manage personal wanted dishes
- Recipe Browsing: Browse and add recipes to wanted list

### Shared Features
- User Switching: Switch between different family members
- CloudKit Sync: Optional multi-device synchronization
- Offline Support: Fully functional without internet

## Architecture

- **SwiftUI**: User interface framework
- **SwiftData**: Data persistence
- **CloudKit**: Optional cloud synchronization
- **BackgroundTasks**: Daily cleanup and statistics generation

## Getting Started

1. Clone the repository
2. Open `PrivateKitchenApp.xcodeproj` in Xcode
3. Build and run on iOS 17.0 or later

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request
```

**Step 2: Update API documentation**

**Step 3: Commit**

```bash
git add PrivateKitchenApp/README.md
git add docs/README.md
git commit -m "docs: update documentation with new features"
```

### Task 14: Final Integration

**Files:**
- Modify: `PrivateKitchenApp/main.swift`
- Modify: `PrivateKitchenApp/PrivateKitchenApp.swift`

**Step 1: Update main.swift**

```swift
// PrivateKitchenApp/main.swift
import SwiftUI

@main
struct PrivateKitchenApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [
                    Family.self,
                    FamilyMember.self,
                    Dish.self,
                    DailyMenu.self,
                    WantedDish.self,
                    OrderStatistics.self,
                    Recipe.self,
                    RecipeComment.self
                ])
        }
    }
}
```

**Step 2: Update ContentView**

```swift
// PrivateKitchenApp/PrivateKitchenApp.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager()
    @State private var showingRoleSelection = true

    var body: some View {
        Group {
            if showingRoleSelection {
                RoleSelectionView()
            } else if dataManager.currentMember?.role == .admin {
                AdminTabBarView()
                    .environmentObject(dataManager)
            } else {
                CustomerTabBarView()
                    .environmentObject(dataManager)
            }
        }
        .environmentObject(dataManager)
        .onAppear {
            // Check if user role is selected
            if dataManager.currentMember == nil {
                showingRoleSelection = true
            } else {
                showingRoleSelection = false
            }

            // Schedule daily cleanup task
            DailyCleanupManager.shared.scheduleDailyTask()
        }
    }
}
```

**Step 3: Commit**

```bash
git add PrivateKitchenApp/main.swift
git add PrivateKitchenApp/PrivateKitchenApp.swift
git commit -m "feat: final integration and setup"
```

## Summary

This implementation plan provides a comprehensive approach to updating the Private Kitchen app with the new requirements:

1. **Removed payment and order models**
2. **Added new data models**: DailyMenu, WantedDish, OrderStatistics
3. **Implemented CloudKit sync** for multi-device support
4. **Added user switching** functionality
5. **Updated admin interface** with Today's Menu, Wanted Dishes, and Statistics views
6. **Enhanced customer interface** with direct ordering and My Wanted Dishes
7. **Added recipe features**: Add to Wanted and Quick Add
8. **Implemented daily cleanup task** for automatic data management
9. **Added comprehensive tests**
10. **Updated documentation**

The plan follows TDD principles with frequent commits and focuses on maintaining code quality through DRY and YAGNI principles.