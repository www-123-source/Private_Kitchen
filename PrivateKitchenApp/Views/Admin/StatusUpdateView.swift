import SwiftUI

struct StatusUpdateView: View {
    @Environment(\.dismiss) private var dismiss
    let order: Order
    @Binding var selectedStatus: OrderStatus?

    var body: some View {
        NavigationView {
            List {
                ForEach(OrderStatus.allCases, id: \.self) { status in
                    Button(action: {
                        updateOrderStatus(to: status)
                    }) {
                        HStack {
                            Text(status.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if order.status == status {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("更新状态")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func updateOrderStatus(to newStatus: OrderStatus) {
        order.status = newStatus
        if newStatus == .ready {
            order.completedAt = Date()
        }
        dismiss()
    }
}

struct StatusUpdateView_Previews: PreviewProvider {
    static var previews: some View {
        StatusUpdateView(order: Order(orderNumber: "ORD001", status: .pending, totalAmount: 99.99), selectedStatus: .constant(.pending))
            .modelContainer(for: [Order.self])
    }
}