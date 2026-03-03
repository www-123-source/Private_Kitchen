import SwiftUI
import SwiftData

struct CartView: View {
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var paymentManager: PaymentManager
    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var orderFlowManager: OrderFlowManager
    @State private var showPaymentView = false
    @State private var showClearConfirm = false
    @State private var selectedCartItem: CartItem?
    @State private var showQuantityPicker = false
    @State private var showOrderSuccess = false
    @State private var currentOrder: Order?

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

                    // 总计和结算
                    VStack(spacing: 16) {
                        // 总计
                        HStack {
                            Text("总计:")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()

                            Text("$\(totalAmount, specifier: "%.2f")")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal)

                        // 结算按钮
                        Button(action: {
                            if totalAmount > 0 {
                                // 创建订单
                                let orderItems = cartItems.map { cartItem -> OrderItem in
                                    OrderItem(
                                        dishId: cartItem.dish.id,
                                        dishName: cartItem.dish.name,
                                        price: cartItem.dish.price,
                                        quantity: cartItem.quantity
                                    )
                                }

                                if let order = dataManager.createOrder(items: orderItems, note: "请加快制作") {
                                    // 支付完成后关联订单
                                    paymentManager.paymentId = order.id.uuidString
                                    paymentManager.startPayment(amount: totalAmount, orderId: order.id.uuidString)
                                    showPaymentView = true
                                }
                            }
                        }) {
                            Text("去结算")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                        }
                        .disabled(cartItems.isEmpty)

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
            .sheet(isPresented: $showPaymentView) {
                PaymentView()
            }
            .alert("购物车为空", isPresented: $showEmptyCart) {
                Button("确定", role: .cancel) { }
            } message: {
                Text("您的购物车中没有商品")
            }
            .alert("确认清空", isPresented: $showClearConfirm) {
                Button("确认", role: .destructive) {
                    cartManager.clearCart()
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("确定要清空购物车吗？此操作不可恢复。")
            }
            .alert("订单创建成功", isPresented: $showOrderSuccess) {
                Button("查看订单") {
                    if let order = currentOrder {
                        // 导航到订单详情页
                    }
                }
                Button("继续购物", role: .cancel) { }
            } message: {
                Text("您的订单已成功创建并支付！")
            }
            .sheet(isPresented: $showQuantityPicker) {
                if let item = selectedCartItem {
                    QuantityPickerView(
                        currentQuantity: item.quantity,
                        maxQuantity: 99,
                        onChange: { newQuantity in
                            cartManager.updateQuantity(item, newQuantity: newQuantity)
                        }
                    )
                }
            }
            .onAppear(perform: loadCartItems)
            .onReceive(NotificationCenter.default.publisher(for: .cartUpdated)) { _ in
                loadCartItems()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("清空购物车") {
                            showClearConfirm = true
                        }
                        .disabled(cartItems.isEmpty)

                        Button("结算全部") {
                            if cartManager.canCheckout() {
                                checkout()
                            }
                        }
                        .disabled(cartItems.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    // 计算总价
    private var totalAmount: Double {
        cartManager.totalPrice
    }

    // 加载购物车商品
    private func loadCartItems() {
        cartItems = cartManager.cartItems
        showEmptyCart = cartItems.isEmpty

        // 检查是否有不可用的商品
        if cartItems.contains(where: { !$0.dish.isAvailable }) {
            cartManager.removeUnavailableItems()
        }
    }

    // 删除商品
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            cartManager.removeItem(cartItems[index])
        }
        loadCartItems()
    }

    // 结算
    private func checkout() {
        let summary = cartManager.getCartSummary()

        if summary.totalPrice > 0 && cartManager.canCheckout() {
            // 使用 OrderFlowManager 创建订单
            if let order = orderFlowManager.createOrderFromCart(cartItems: cartItems, note: "请尽快制作") {
                currentOrder = order
                paymentManager.paymentId = order.id.uuidString
                paymentManager.startPayment(amount: summary.totalPrice, orderId: order.id.uuidString)
                showPaymentView = true

                // 支付成功后显示成功提示
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if paymentManager.paymentStatus == .success {
                        showOrderSuccess = true
                        cartManager.clearCart()
                    }
                }
            }
        }
    }
}

struct CartView_Previews: PreviewProvider {
    static var previews: some View {
        CartView()
            .environmentObject(PaymentManager())
            .modelContainer(for: [Dish.self, CartItem.self])
    }
}

// 购物车商品模型
struct CartItem: Identifiable {
    let id = UUID()
    let dish: Dish
    var quantity: Int
}

// 购物车商品行组件
struct CartItemRow: View {
    @EnvironmentObject private var cartManager: CartManager
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

                        // 状态标记
                        if !item.dish.isAvailable {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Text("已下架")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    // 菜品描述
                    Text(item.dish.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // 单价
                    Text("单价: $\(item.dish.price, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.gray)

                    // 小计
                    HStack {
                        Spacer()
                        Text("小计: $\(item.dish.price * Double(item.quantity), specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                }

                Spacer()

                // 右侧按钮组
                VStack(spacing: 8) {
                    // 删除按钮
                    Button(action: {
                        cartManager.removeItem(item)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }

                    // 快速加减按钮
                    HStack(spacing: 4) {
                        Button(action: {
                            cartManager.updateQuantity(item, newQuantity: item.quantity - 1)
                        }) {
                            Image(systemName: "minus")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.gray)
                                .clipShape(Circle())
                        }
                        .disabled(item.quantity <= 1)

                        Text("\(item.quantity)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(minWidth: 24)

                        Button(action: {
                            cartManager.updateQuantity(item, newQuantity: item.quantity + 1)
                        }) {
                            Image(systemName: "plus")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.orange)
                                .clipShape(Circle())
                        }
                        .disabled(item.quantity >= 99)
                    }
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