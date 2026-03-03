import SwiftUI

struct AddEditDishView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var price: String = ""
    @State private var category: DishCategory = .lunch
    @State private var isAvailable: Bool = true
    @State private var showingImagePicker = false
    @State private var imageData: Data?

    var dish: Dish?

    init(dish: Dish? = nil) {
        self.dish = dish
        if let dish = dish {
            _name = State(initialValue: dish.name)
            _description = State(initialValue: dish.description)
            _price = State(initialValue: String(dish.price))
            _category = State(initialValue: dish.category)
            _isAvailable = State(initialValue: dish.isAvailable)
            _imageData = State(initialValue: dish.image)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.cream
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 菜品图片
                        imageSection

                        // 基本信息
                        formSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle(dish == nil ? "添加菜品" : "编辑菜品")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.cream, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.terracotta)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveDish()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.terracotta)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(imageData: $imageData)
            }
        }
    }

    // MARK: - 图片区域
    private var imageSection: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )

                if let image = imageData, let uiImage = UIImage(data: image) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 44))
                            .foregroundStyle(AppTheme.terracotta.opacity(0.5))
                        Text("添加菜品图片")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.sage)
                    }
                }
            }
            .onTapGesture {
                showingImagePicker = true
            }

            Button {
                showingImagePicker = true
            } label: {
                Text(imageData != nil ? "更换图片" : "选择图片")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.terracotta)
            }
        }
    }

    // MARK: - 表单区域
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("基本信息")
                .font(.subheadline)
                .fontWeight(.600)
                .foregroundStyle(AppTheme.charcoal)

            VStack(spacing: 0) {
                FormField(label: "菜名", text: $name, placeholder: "例如：番茄炒蛋")
                Divider().background(AppTheme.border).padding(.leading, 16)
                FormField(label: "描述", text: $description, placeholder: "简要描述菜品")
                Divider().background(AppTheme.border).padding(.leading, 16)
                FormField(label: "价格", text: $price, placeholder: "0", keyboardType: .decimalPad)
                Divider().background(AppTheme.border).padding(.leading, 16)
                categoryPicker
                Divider().background(AppTheme.border).padding(.leading, 16)
                availabilityToggle
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
        }
    }

    private var categoryPicker: some View {
        HStack {
            Text("分类")
                .font(.body)
                .foregroundStyle(AppTheme.charcoal)
            Spacer()
            Picker("", selection: $category) {
                ForEach(DishCategory.allCases, id: \.self) { cat in
                    Text(cat.displayName).tag(cat)
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.terracotta)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var availabilityToggle: some View {
        HStack {
            Text("上架")
                .font(.body)
                .foregroundStyle(AppTheme.charcoal)
            Spacer()
            Toggle("", isOn: $isAvailable)
                .tint(AppTheme.terracotta)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func saveDish() {
        if let dish = dish {
            dish.name = name
            dish.description = description
            dish.price = Double(price) ?? 0
            dish.category = category
            dish.isAvailable = isAvailable
            dish.image = imageData
            dish.updatedAt = Date()
        } else {
            let newDish = Dish(
                name: name,
                description: description,
                price: Double(price) ?? 0,
                category: category,
                image: imageData,
                isAvailable: isAvailable
            )
            modelContext.insert(newDish)
        }
        dismiss()
    }
}

// MARK: - 表单项
private struct FormField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.body)
                .foregroundStyle(AppTheme.charcoal)
                .frame(width: 60, alignment: .leading)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct AddEditDishView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditDishView()
            .modelContainer(for: [Dish.self])
    }
}
