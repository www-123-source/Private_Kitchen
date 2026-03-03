import SwiftUI

struct PaymentView: View {
    @EnvironmentObject private var paymentManager: PaymentManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 支付标题
                HStack {
                    Text("确认支付")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)

                // 支付金额
                VStack(alignment: .leading, spacing: 8) {
                    Text("支付金额")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("$\(paymentManager.amount, specifier: "%.2f")")
                        .font(.system(size: 48))
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal)

                // 支付方式选择
                VStack(alignment: .leading, spacing: 16) {
                    Text("选择支付方式")
                        .font(.headline)
                        .foregroundColor(.primary)

                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                        PaymentMethodButton(
                            method: method,
                            isSelected: paymentManager.selectedMethod == method,
                            action: {
                                paymentManager.selectedMethod = method
                            }
                        )
                    }
                }
                .padding(.horizontal)

                // 支付按钮
                VStack(spacing: 12) {
                    Button(action: {
                        paymentManager.processPayment()
                    }) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.white)
                            Text("确认支付")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }
                    .disabled(paymentManager.isProcessing)

                    Button(action: {
                        paymentManager.cancelPayment()
                        dismiss()
                    }) {
                        Text("取消")
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
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("确认支付")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("取消") {
                    paymentManager.cancelPayment()
                    dismiss()
                }
            }
            .alert("支付结果", isPresented: .constant(paymentManager.paymentStatus != .pending && paymentManager.paymentStatus != .processing)) {
                Button("确定") {
                    if paymentManager.paymentStatus == .success {
                        dismiss()
                    }
                }
            } message: {
                Text(paymentManager.paymentStatus == .success ? "支付成功！" : "支付失败，请重试")
            }
            .sheet(isPresented: $paymentManager.showPaymentView) {
                PaymentProcessingView()
            }
        }
    }
}

struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentView()
            .environmentObject(PaymentManager())
    }
}

// 支付方式按钮组件
struct PaymentMethodButton: View {
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: method.icon)
                    .foregroundColor(isSelected ? .orange : .gray)

                Text(method.rawValue)
                    .foregroundColor(isSelected ? .orange : .primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
    }
}