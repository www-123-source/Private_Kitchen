import SwiftUI
import SwiftData

struct KitchenDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncManager: SyncManager
    @State private var family: Family? = nil
    @State private var showOrderManagement = false
    @State private var showDishManagement = false
    @State private var showMemberManagement = false
    @State private var showSettings = false
    @State private var showSyncSettings = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                HStack {
                    Text("家庭厨房管理")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)

                // 同步状态
                SyncStatusView(syncManager: syncManager)
                    .padding(.horizontal)

                // 家庭信息
                if let family = family {
                    FamilyInfoCard(family: family)
                        .padding(.horizontal)
                }

                // 统计卡片
                KitchenStatsView()
                    .padding(.horizontal)

                // 快速操作
                QuickActionsView(
                    showOrderManagement: $showOrderManagement,
                    showDishManagement: $showDishManagement,
                    showMemberManagement: $showMemberManagement,
                    showSettings: $showSettings
                )
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("厨房管理")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showOrderManagement) {
                OrderManagementView()
            }
            .sheet(isPresented: $showDishManagement) {
                DishManagementView()
            }
            .sheet(isPresented: $showMemberManagement) {
                MemberManagementView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showSyncSettings) {
                SyncSettingsView(syncManager: syncManager)
            }
            .onAppear(perform: loadFamilyData)
        }
    }

    // 加载家庭数据
    private func loadFamilyData() {
        // 模拟加载家庭数据
        family = Family(name: "张氏家庭", adminId: UUID())
    }
}

struct KitchenDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        KitchenDashboardView()
            .environmentObject(SyncManager())
            .modelContainer(for: [Family.self, FamilyMember.self, Dish.self, Order.self])
    }
}

// 家庭信息卡片
struct FamilyInfoCard: View {
    let family: Family

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("家庭信息")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("家庭名称")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text(family.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("创建时间")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text(family.createdAt, style: .date)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("成员数量")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("\(family.members.count) 人")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("菜品数量")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("\(family.dishes.count) 道")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("订单数量")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("\(family.orders.count) 笔")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}