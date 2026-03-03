import SwiftUI

struct QuickActionsView: View {
    @Binding var showOrderManagement: Bool
    @Binding var showDishManagement: Bool
    @Binding var showMemberManagement: Bool
    @Binding var showSettings: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("快速操作")
                .font(.headline)
                .foregroundColor(.primary)

            // 操作按钮网格
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ActionButton(
                    title: "订单管理",
                    icon: "cart.fill",
                    color: .blue,
                    action: { showOrderManagement = true }
                )

                ActionButton(
                    title: "菜品管理",
                    icon: "list.bullet",
                    color: .green,
                    action: { showDishManagement = true }
                )

                ActionButton(
                    title: "成员管理",
                    icon: "person.2.fill",
                    color: .purple,
                    action: { showMemberManagement = true }
                )

                ActionButton(
                    title: "系统设置",
                    icon: "gearshape.fill",
                    color: .orange,
                    action: { showSettings = true }
                )

                ActionButton(
                    title: "数据同步",
                    icon: "arrow.clockwise",
                    color: .orange,
                    action: { showSyncSettings = true }
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct QuickActionsView_Previews: PreviewProvider {
    static var previews: some View {
        QuickActionsView(
            showOrderManagement: .constant(false),
            showDishManagement: .constant(false),
            showMemberManagement: .constant(false),
            showSettings: .constant(false)
        )
    }
}

// 操作按钮组件
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(color)
                    .cornerRadius(12)

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}