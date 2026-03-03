import SwiftUI
import SwiftData

struct DishDetailView: View {
    let dish: Dish
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dataManager: DataManager
    @EnvironmentObject private var cartManager: CartManager
    @State private var quantity = 1
    @State private var showCart = false
    @State private var addToCartSuccess = false
    @State private var showQuantityPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 菜品图片
                if let imageData = dish.image, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                        .cornerRadius(12)
                }

                // 菜品名称和价格
                VStack(alignment: .leading, spacing: 8) {
                    Text(dish.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("$\(dish.price, specifier: "%.2f")")
                        .font(.title)
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)

                    Text(dish.category.displayName)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                }

                // 菜品描述
                VStack(alignment: .leading, spacing: 12) {
                    Text("菜品描述")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(dish.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }

                // 数量选择
                VStack(alignment: .leading, spacing: 8) {
                    // 数量选择
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("数量")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()

                            Text("小计: $\(dish.price * Double(quantity), specifier: "%.2f")")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }

                        HStack {
                            Button(action: {
                                if quantity > 1 {
                                    quantity -= 1
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.orange)
                                    .font(.title2)
                            }
                            .disabled(quantity <= 1)

                            Text("\(quantity)")
                                .font(.title)
                                .fontWeight(.bold)
                                .frame(minWidth: 40)

                            Button(action: {
                                showQuantityPicker = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.orange)
                                    Text("更多")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                .fontWeight(.semibold)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }

                // 添加到购物车按钮
                Button(action: {
                    addToCart()
                }) {
                    HStack {
                        Image(systemName: "cart.badge.plus")
                            .foregroundColor(.white)
                        Text("添加到购物车")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }
                .padding(.top, 20)

                Spacer()
            }
            .padding()
        }
        .navigationTitle(dish.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(action: {
                showCart = true
            }) {
                Image(systemName: "cart.fill")
                    .foregroundColor(.orange)
            }
        }
        .sheet(isPresented: $showCart) {
            CartView()
        }
        .alert("成功", isPresented: $addToCartSuccess) {
            Button("确定") { }
        } message: {
            Text("\(dish.name) x\(quantity) 已添加到购物车")
        }
        .sheet(isPresented: $showQuantityPicker) {
            QuantityPickerView(
                currentQuantity: quantity,
                maxQuantity: 99,
                onChange: { newQuantity in
                    quantity = newQuantity
                }
            )
        }
    }

    private func addToCart() {
        // 检查菜品是否可用
        guard dish.isAvailable else {
            // 显示不可用提示
            return
        }

        // 使用购物车管理器添加商品
        if cartManager.addItem(dish, quantity: quantity) {
            addToCartSuccess = true

            // 重置数量
            quantity = 1
        }
    }
}

struct DishDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DishDetailView(dish: Dish(
            name: "番茄炒蛋",
            description: "经典家常菜，酸甜可口，营养丰富",
            price: 25.00,
            category: .lunch
        ))
        .modelContainer(for: [Dish.self])
    }
}