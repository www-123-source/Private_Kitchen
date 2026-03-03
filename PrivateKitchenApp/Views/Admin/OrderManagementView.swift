import SwiftUI

struct OrderManagementView: View {
    var body: some View {
        OrderListView()
    }
}

struct OrderManagementView_Previews: PreviewProvider {
    static var previews: some View {
        OrderManagementView()
            .modelContainer(for: [Order.self, OrderItem.self])
    }
}