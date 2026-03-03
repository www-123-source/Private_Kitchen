import SwiftUI

struct OrderListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var orders: [Order]
    @State private var selectedStatus: OrderStatus? = nil

    private var filteredOrders: [Order] {
        if let status = selectedStatus {
            return orders.filter { $0.status == status }
        }
        return orders
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 顶部横向状态筛选
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            StatusChip(title: "全部", isSelected: selectedStatus == nil) {
                                selectedStatus = nil
                            }
                            ForEach(OrderStatus.allCases, id: \.self) { status in
                                StatusChip(title: status.displayName, isSelected: selectedStatus == status) {
                                    selectedStatus = status
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    .background(Color.white.opacity(0.6))

                    // 订单列表（横板信息层级）
                    if filteredOrders.isEmpty {
                        EmptyOrderState()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredOrders) { order in
                                    NavigationLink(destination: OrderDetailView(order: order)) {
                                        OrderRow(order: order)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationTitle("订单管理")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - 单条订单横板卡片
struct OrderRow: View {
    let order: Order

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 左侧：订单号 + 下单人 + 时间
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("订单 #\(order.orderNumber)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.charcoal)

                    if let member = order.member {
                        Text("· \(member.name)")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.sage)
                    }
                }

                Text("下单时间 \(formattedDate(order.createdAt))")
                    .font(.caption)
                    .foregroundStyle(AppTheme.sage)

                // 横向预览前两项菜品
                if !order.items.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(order.items.prefix(2)) { item in
                            HStack(spacing: 4) {
                                Text(item.dishName)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.charcoal)
                                Text("x\(item.quantity)")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.sage)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AppTheme.terracottaMuted)
                            .clipShape(Capsule())
                        }
                        if order.items.count > 2 {
                            Text("+\(order.items.count - 2)")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.sage)
                        }
                    }
                }

                if let note = order.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.sage)
                        .lineLimit(1)
                }
            }

            Spacer()

            // 右侧：金额 + 状态
            VStack(alignment: .trailing, spacing: 8) {
                Text("¥\(order.totalAmount, specifier: "%.0f")")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.terracotta)

                StatusBadge(status: order.status)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

// MARK: - 顶部状态筛选 Chip
private struct StatusChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.terracotta : AppTheme.terracottaMuted)
                .foregroundStyle(isSelected ? .white : AppTheme.terracotta)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 状态徽章
private struct StatusBadge: View {
    let status: OrderStatus

    private var background: Color {
        switch status {
        case .pending: return AppTheme.terracotta
        case .confirmed: return AppTheme.sage
        case .cooking: return .yellow.opacity(0.8)
        case .ready: return .green.opacity(0.85)
        case .delivered: return .blue.opacity(0.8)
        case .cancelled: return .red.opacity(0.8)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: 6, height: 6)
            Text(status.displayName)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(background)
        .foregroundStyle(Color.white)
        .clipShape(Capsule())
    }
}

// MARK: - 空状态
private struct EmptyOrderState: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "list.clipboard")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.terracotta.opacity(0.5))
            Text("暂无订单")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(AppTheme.charcoal)
                .padding(.top, 8)
            Text("等待家庭成员下单后，这里会显示最新订单")
                .font(.subheadline)
                .foregroundStyle(AppTheme.sage)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 4)
            Spacer()
        }
    }
}

struct OrderListView_Previews: PreviewProvider {
    static var previews: some View {
        OrderListView()
            .modelContainer(for: [Order.self, OrderItem.self])
    }
}