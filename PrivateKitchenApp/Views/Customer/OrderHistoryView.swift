import SwiftUI
import SwiftData

struct OrderHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var orders: [Order]

    init() {
        // 初始化查询，获取所有订单并按时间排序
        _orders = Query(sort: [SortDescriptor(\.createdAt, order: .reverse)])
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 订单统计
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("我的订单")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)

                        Text("共 \(orders.count) 笔订单")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // 订单列表
                List {
                    ForEach(orders) { order in
                        NavigationLink(destination: OrderDetailView(order: order)) {
                            OrderRow(order: order)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("我的订单")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct OrderHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        OrderHistoryView()
            .modelContainer(for: [Order.self])
    }
}

// 订单行组件
struct OrderRow: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("订单号: \(order.orderNumber)")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text(order.status.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(order.statusColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            HStack {
                Text("总金额: $\(order.totalAmount, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()

                Text(order.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

// 订单详情视图
struct OrderDetailView: View {
    let order: Order

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 订单信息
                VStack(alignment: .leading, spacing: 12) {
                    Text("订单详情")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    HStack {
                        Text("订单号: \(order.orderNumber)")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        Text(order.status.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(order.statusColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    HStack {
                        Text("总金额: $\(order.totalAmount, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)

                        Spacer()

                        Text(order.createdAt, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    if let note = order.note, !note.isEmpty {
                        Text("备注: \(note)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                // 订单项列表
                VStack(alignment: .leading, spacing: 8) {
                    Text("订单内容")
                        .font(.headline)
                        .foregroundColor(.primary)

                    ForEach(order.items) { item in
                        OrderItemRow(item: item)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("订单详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OrderDetailView_Previews: PreviewProvider {
    static var previews: some View {
        OrderDetailView(order: Order(
            orderNumber: "ORD202403010001",
            status: .confirmed,
            totalAmount: 63.00,
            note: "不要辣"
        ))
        .modelContainer(for: [Order.self, OrderItem.self])
    }
}

// 订单项行组件
struct OrderItemRow: View {
    let item: OrderItem

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.dishName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("数量: \(item.quantity)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let note = item.note, !note.isEmpty {
                    Text("备注: \(note)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Text("$\(item.price * Double(item.quantity), specifier: "%.2f")")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.orange)
        }
        .padding(.vertical, 8)
    }
}

// 扩展OrderStatus以添加颜色属性
extension OrderStatus {
    var statusColor: Color {
        switch self {
        case .pending:
            return Color.orange
        case .confirmed:
            return Color.blue
        case .cooking:
            return Color.yellow
        case .ready:
            return Color.green
        case .delivered:
            return Color.teal
        case .cancelled:
            return Color.red
        }
    }
}