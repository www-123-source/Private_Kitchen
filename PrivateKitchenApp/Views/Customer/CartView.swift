import SwiftUI
import SwiftData

struct CartView: View {
    @EnvironmentObject private var dataManager: DataManager

    @State private var showClearConfirm = false
    @State private var selectedCartItem: CartItem?
    @State private var showQuantityPicker = false

    // 模拟购物车数据
    @State private var cartItems: [CartItem] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 购物车标题
                HStack {
                    Text("购物车")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(.horizontal)

                // 购物车为空提示
                if cartItems.isEmpty {
                    EmptyCartView()
                } else {
                    // 购物车列表
                    List {
                        ForEach(cartItems) { item in
                            CartItemRow(item: item)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(PlainListStyle())

                    // 总计和操作
                    VStack(spacing: 16) {
                        // 清空购物车
                        Button(action: {
                            showClearConfirm = true
                        }) {
                            HStack {
                                Image(systemName: "trash.circle")
                                    .foregroundColor(.red)
                                Text("清空购物车")
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .border(Color.red, width: 2)
                            .cornerRadius(12)
                            .shadow(radius: 5)
                        }
                        .disabled(cartItems.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("购物车")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                EditButton()
            }
            .alert("确认清空", isPresented: $showClearConfirm) {
                Button("确认", role: .destructive) {
                    cartItems.removeAll()
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("确定要清空购物车吗？此操作不可恢复。")
            }
            .onAppear(perform: loadCartItems)
        }
    }

    // 加载购物车商品
    private func loadCartItems() {
        // 模拟加载购物车数据
        // 在实际应用中，这里会从持久化存储加载数据
    }

    // 删除商品
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            cartItems.remove(at: index)
        }
    }
}

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartView()
            .modelContainer(for: [Dish.self])
    }
}

// 购物车商品模型
@Model
class CartItem: Identifiable {
    var id = UUID()
    var dish: Dish
    var quantity: Int
    var addedAt: Date

    init(dish: Dish, quantity: Int = 1) {
        self.dish = dish
        self.quantity = quantity
        self.addedAt = Date()
    }
}

// 购物车商品行组件
struct CartItemRow: View {
    let item: CartItem

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // 菜品图片
                if let imageData = item.dish.image, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(12)
                        .clipped()
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    // 菜品名称
                    HStack {
                        Text(item.dish.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Spacer()

                        // 数量
                        Text("数量: \(item.quantity)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    // 菜品描述
                    Text(item.dish.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // 可用性状态
                    if !item.dish.isAvailable {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("暂不可用")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }

                Spacer()

                // 删除按钮
                Button(action: {
                    // 在实际应用中，需要传递回调来删除商品
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

// 空购物车视图
struct EmptyCartView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 30) {
            // 动画图标
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 150, height: 150)

                    Image(systemName: "cart")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.orange)
                        .rotationEffect(.degrees(-10))
                }
            }

            // 文字说明
            VStack(spacing: 12) {
                Text("购物车是空的")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("还没有添加任何商品")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            // 操作按钮
            VStack(spacing: 16) {
                Button(action: {
                    // 返回点餐页面
                }) {
                    HStack {
                        Image(systemName: "utensils")
                        Text("去点餐")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }

                Button(action: {
                    dismiss()
                }) {
                    Text("继续购物")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.gray)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
            }
        }
        .padding()
    }
}