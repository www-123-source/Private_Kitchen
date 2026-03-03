import SwiftUI

struct OrderTimelineView: View {
    let order: Order
    let timeline: [OrderTimeline]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 订单状态卡片
                    OrderStatusCard(order: order)

                    // 时间线
                    VStack(alignment: .leading, spacing: 16) {
                        Text("订单进度")
                            .font(.headline)
                            .foregroundColor(.primary)

                        LazyVStack(spacing: 12) {
                            ForEach(timeline) { event in
                                TimelineRow(event: event)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("订单进度")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 订单状态卡片
struct OrderStatusCard: View {
    let order: Order

    var body: some View {
        VStack(spacing: 16) {
            // 订单号
            HStack {
                Text("订单号")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("#\(order.orderNumber)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }

            // 当前状态
            HStack {
                Text("当前状态")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                StatusBadge(status: order.status)
            }

            // 总金额
            HStack {
                Text("总金额")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text("$\(order.totalAmount, specifier: "%.2f")")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }

            // 下单时间
            HStack {
                Text("下单时间")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(formattedDate(order.createdAt))
            }

            // 完成时间
            if let completedAt = order.completedAt {
                HStack {
                    Text("完成时间")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(formattedDate(completedAt))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 时间线行
struct TimelineRow: View {
    let event: OrderTimeline

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 时间点
            VStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 16, height: 16)

                // 连接线
                if !isLastEvent {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
            }

            // 内容
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(statusIcon)
                        .foregroundColor(statusColor)
                        .font(.title2)

                    Text(event.status.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Text(event.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(formattedTime)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var statusColor: Color {
        switch event.status {
        case .pending: return .orange
        case .confirmed: return .blue
        case .cooking: return .yellow
        case .ready: return .green
        case .delivered: return .purple
        case .cancelled: return .red
        }
    }

    private var statusIcon: String {
        switch event.status {
        case .pending: return "clock"
        case .confirmed: return "checkmark"
        case .cooking: return "flame"
        case .ready: return "checkmark.circle"
        case .delivered: return "truck"
        case .cancelled: return "xmark"
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: event.timestamp)
    }

    private var isLastEvent: Bool {
        // 这里应该判断是否是最后一个事件
        // 简化实现
        return false
    }
}

// MARK: - 状态徽章
struct StatusBadge: View {
    let status: OrderStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(20)
    }

    private var statusColor: Color {
        switch status {
        case .pending: return .orange
        case .confirmed: return .blue
        case .cooking: return .yellow
        case .ready: return .green
        case .delivered: return .purple
        case .cancelled: return .red
        }
    }
}

struct OrderTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        OrderTimelineView(
            order: Order(
                orderNumber: "PK-20240302-0001",
                status: .cooking,
                totalAmount: 85.50
            ),
            timeline: [
                OrderTimeline(
                    orderID: UUID(),
                    status: .pending,
                    message: "订单已创建",
                    timestamp: Date().addingTimeInterval(-3600)
                ),
                OrderTimeline(
                    orderID: UUID(),
                    status: .confirmed,
                    message: "订单已确认，开始制作",
                    timestamp: Date().addingTimeInterval(-1800)
                ),
                OrderTimeline(
                    orderID: UUID(),
                    status: .cooking,
                    message: "正在制作您的订单",
                    timestamp: Date()
                )
            ]
        )
    }
}