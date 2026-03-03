import SwiftUI

struct QuantityPickerView: View {
    let currentQuantity: Int
    let maxQuantity: Int
    let onChange: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedQuantity: Int

    init(currentQuantity: Int, maxQuantity: Int = 99, onChange: @escaping (Int) -> Void) {
        self.currentQuantity = currentQuantity
        self.maxQuantity = maxQuantity
        self.onChange = onChange
        _selectedQuantity = State(initialValue: currentQuantity)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 数量显示
                VStack(spacing: 8) {
                    Text("选择数量")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("×\(selectedQuantity)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.orange)
                }

                // 数量选择器
                Picker("数量", selection: $selectedQuantity) {
                    ForEach(1...maxQuantity, id: \.self) { quantity in
                        Text("\(quantity)")
                            .tag(quantity)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)

                // 预览
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                    Text("最大可购买数量: \(maxQuantity)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                // 按钮
                VStack(spacing: 16) {
                    Button(action: {
                        onChange(selectedQuantity)
                        dismiss()
                    }) {
                        Text("确定")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button("取消", role: .cancel) {
                        dismiss()
                    }
                    .disabled(selectedQuantity != currentQuantity)
                }
                .padding(.horizontal)
            }
            .navigationTitle("调整数量")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct QuantityPickerView_Previews: PreviewProvider {
    static var previews: some View {
        QuantityPickerView(currentQuantity: 2, maxQuantity: 10) { _ in }
    }
}