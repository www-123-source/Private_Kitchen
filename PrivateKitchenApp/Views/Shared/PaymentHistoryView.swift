import SwiftUI

struct PaymentHistoryView: View {
    @EnvironmentObject private var paymentManager: PaymentManager

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                HStack {
                    Text("支付历史")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    Spacer()

                    // 筛选按钮
                    Menu {
                        Button("全部") { }
                        Button("成功") { }
                        Button("失败") { }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // 支付记录列表
                if paymentManager.paymentHistory.isEmpty {
                    EmptyPaymentHistoryView()
                } else {
                    List {
                        ForEach(paymentManager.paymentHistory) { record in
                            PaymentRecordRow(record: record)
                        }
                    }
                    .listStyle(PlainListStyle())
                }

                Spacer()
            }
            .navigationTitle("支付历史")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PaymentHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentHistoryView()
            .environmentObject(PaymentManager())
    }
}

// 空支付历史视图
struct EmptyPaymentHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)

            Text("暂无支付记录")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("完成订单后将显示在这里")
                .font(.subheadline)
                .foregroundColor(.gray)

            Button(action: {
                // 返回点餐页面
            }) {
                Text("去点餐")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            }
        }
        .padding()
    }
}

// 支付记录行组件
struct PaymentRecordRow: View {
    let record: PaymentRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // 支付方式图标
                Image(systemName: record.method.icon)
                    .foregroundColor(.orange)

                // 支付方式
                Text(record.method.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                // 支付状态
                Text(record.status.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(record.status == .success ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(record.status == .success ? .green : .red)
                    .cornerRadius(6)
            }

            // 支付金额和时间
            HStack {
                Text("$\(record.amount, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)

                Spacer()

                Text(record.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}