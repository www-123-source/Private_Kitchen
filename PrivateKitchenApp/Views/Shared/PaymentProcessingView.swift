import SwiftUI

struct PaymentProcessingView: View {
    @EnvironmentObject private var paymentManager: PaymentManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // 支付处理标题
            Text("支付处理中")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .padding(.top)

            // 支付进度
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())

                Text("正在处理您的支付...")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("请勿关闭应用")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("支付处理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("取消") {
                paymentManager.cancelPayment()
                dismiss()
            }
        }
        .onAppear(perform: {
            // 自动开始支付处理
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                paymentManager.processPayment()
            }
        })
    }
}

struct PaymentProcessingView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentProcessingView()
            .environmentObject(PaymentManager())
    }
}