import SwiftUI
import SwiftData

struct KitchenStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var todayOrders: Int = 0
    @State private var totalRevenue: Double = 0
    @State private var popularDish: String = "暂无"
    @State private var activeMembers: Int = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("厨房统计")
                .font(.headline)
                .foregroundColor(.primary)

            // 统计卡片网格
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(title: "今日订单", value: "\(todayOrders)", icon: "cart.fill", color: .blue)
                StatCard(title: "总收入", value: "$\(totalRevenue, specifier: "%.2f")", icon: "dollarsign.circle", color: .green)
                StatCard(title: "热门菜品", value: popularDish, icon: "star.fill", color: .orange)
                StatCard(title: "活跃成员", value: "\(activeMembers) 人", icon: "person.2.fill", color: .purple)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 1)
        .onAppear(perform: loadStatsData)
    }

    // 加载统计数据
    private func loadStatsData() {
        // 模拟加载统计数据
        todayOrders = 12
        totalRevenue = 856.50
        popularDish = "番茄炒蛋"
        activeMembers = 3
    }
}

struct KitchenStatsView_Previews: PreviewProvider {
    static var previews: some View {
        KitchenStatsView()
            .modelContainer(for: [Family.self, FamilyMember.self, Dish.self, Order.self])
    }
}

// 统计卡片组件
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}