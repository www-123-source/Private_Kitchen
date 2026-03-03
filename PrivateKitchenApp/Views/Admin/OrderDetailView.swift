import SwiftUI

struct OrderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let order: Order

    @State private var showingStatusUpdate = false
    @State private var selectedStatus: OrderStatus?

    var body: some View {
        NavigationView {
            Form {
                // 订单信息
                Section(header: Text("订单信息")) {
                    HStack {
                        Text("订单号:")
                        Spacer()
                        Text(order.orderNumber)
                            .foregroundColor(.orange)
                    }

                    HStack {
                        Text("下单时间:")
                        Spacer()
                        Text(formattedDate(order.createdAt))
                    }

                    if let completedAt = order.completedAt {
                        HStack {
                            Text("完成时间:")
                            Spacer()
                            Text(formattedDate(completedAt))
                        }
                    }

                    HStack {
                        Text("状态:")
                        Spacer()
                        Text(order.status.rawValue)
                            .foregroundColor(statusColor(for: order.status))
                    }

                    HStack {
                        Text("总金额:")
                        Spacer()
                        Text("¥\(order.totalAmount, specifier: "%.2f")")
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }

                    if let member = order.member {
                        HStack {
                            Text("下单人:")
                            Spacer()
                            Text(member.name)
                        }
                    }

                    if let note = order.note, !note.isEmpty {
                        HStack {
                            Text("备注:")
                            Spacer()
                            Text(note)
                                .foregroundColor(.gray)
                                .italic()
                        }
                    }
                }

                // 菜品列表
                Section(header: Text("菜品列表")) {
                    ForEach(order.items) { item in
                        HStack {
                            Text(item.dishName)
                            Spacer()
                            Text("x\(item.quantity)")
                            Spacer()
                            Text("¥\(item.price * Double(item.quantity), specifier: "%.2f")")
                                .fontWeight(.semibold)
                        }
                    }
                }

                // 操作按钮
                Section {
                    Button(action: {
                        showingStatusUpdate = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.circle")
                            Text("更新状态")
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("订单详情")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("收银") {
                        completePayment()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingStatusUpdate) {
                StatusUpdateView(order: order, selectedStatus: $selectedStatus)
            }
        }
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

    private func completePayment() {
        order.status = .delivered
        order.completedAt = Date()
        dismiss()
    }
}

struct OrderDetailView_Previews: PreviewProvider {
    static var previews: some View {
        OrderDetailView(order: Order(orderNumber: "ORD001", status: .pending, totalAmount: 99.99))
            .modelContainer(for: [Order.self, OrderItem.self])
    }
}