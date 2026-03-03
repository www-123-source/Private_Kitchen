import SwiftUI

struct MemberStatsView: View {
    let member: FamilyMember

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 成员信息头部
                HStack {
                    // 头像
                    if let avatar = member.avatar, let uiImage = UIImage(data: avatar) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.orange)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(member.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("角色: \(member.role.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Text("加入时间: \(formattedDate(member.joinedAt))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    // 角色标签
                    if member.role == .admin {
                        Text("管理员")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                .padding(.horizontal)

                // 统计卡片
                VStack(spacing: 16) {
                    StatCard(title: "总订单数", value: "\(member.orders.count)", color: .orange)
                    StatCard(title: "总消费", value: "¥\(totalSpent, specifier: "%.2f")", color: .orange)
                    StatCard(title: "平均订单金额", value: "¥\(averageOrderAmount, specifier: "%.2f")", color: .orange)
                }
                .padding(.horizontal)

                // 订单历史
                VStack {
                    Text("订单历史")
                        .font(.headline)
                        .padding(.horizontal)

                    List {
                        ForEach(member.orders.sorted(by: { $0.createdAt > $1.createdAt })) { order in
                            OrderHistoryRow(order: order)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                .frame(height: 300)

                Spacer()
            }
            .navigationTitle("成员统计")
        }
    }

    private var totalSpent: Double {
        return member.orders.reduce(0) { $0 + $1.totalAmount }
    }

    private var averageOrderAmount: Double {
        guard !member.orders.isEmpty else { return 0 }
        return totalSpent / Double(member.orders.count)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct OrderHistoryRow: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("订单 #\(order.orderNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(order.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor(for: order.status))
                    .cornerRadius(4)
                    .foregroundColor(.white)
            }

            Text("金额: ¥\(order.totalAmount, specifier: "%.2f")")
                .font(.caption)
                .foregroundColor(.gray)

            Text("时间: \(formattedDate(order.createdAt))")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }

    private func statusColor(for status: OrderStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .confirmed: return .blue
        case .cooking: return .yellow
        case .ready: return .green
        case .delivered: return .purple
        case .cancelled: return .red
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

struct MemberStatsView_Previews: PreviewProvider {
    static var previews: some View {
        MemberStatsView(member: FamilyMember(name: "测试成员", role: .member))
            .modelContainer(for: [FamilyMember.self, Order.self])
    }
}