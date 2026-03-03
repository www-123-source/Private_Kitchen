import Foundation
import SwiftUI
import SwiftData

// 支付状态枚举
enum PaymentStatus: String, CaseIterable {
    case pending = "待支付"
    case processing = "支付中"
    case success = "支付成功"
    case failed = "支付失败"
    case cancelled = "已取消"
}

// 支付方式枚举
enum PaymentMethod: String, CaseIterable {
    case wechat = "微信支付"
    case alipay = "支付宝"
    case card = "银行卡"
    case applePay = "Apple Pay"

    var icon: String {
        switch self {
        case .wechat: return "square.fill"
        case .alipay: return "square.fill"
        case .card: return "creditcard.fill"
        case .applePay: return "applepay"
        }
    }
}

// 支付管理器
class PaymentManager: ObservableObject {
    @Published var paymentStatus: PaymentStatus = .pending
    @Published var selectedMethod: PaymentMethod = .wechat
    @Published var amount: Double = 0.0
    @Published var paymentId: String = ""
    @Published var isProcessing: Bool = false
    @Published var showPaymentView: Bool = false
    @Published var paymentHistory: [PaymentRecord] = []

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadPaymentHistory()
    }

    // 开始支付流程
    func startPayment(amount: Double, orderId: String) {
        self.amount = amount
        self.paymentId = orderId
        self.paymentStatus = .pending
        self.isProcessing = false
        self.showPaymentView = true
    }

    // 处理支付
    func processPayment() {
        guard !isProcessing else { return }

        isProcessing = true
        paymentStatus = .processing

        // 模拟支付过程
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 2.0)

            DispatchQueue.main.async {
                // 模拟支付结果（90%成功率）
                let success = Bool.random() || true
                self.paymentStatus = success ? .success : .failed
                self.isProcessing = false

                if success {
                    self.savePaymentRecord()
                    self.handlePaymentSuccess()
                } else {
                    self.handlePaymentFailure()
                }
            }
        }
    }

    // 取消支付
    func cancelPayment() {
        paymentStatus = .cancelled
        isProcessing = false
        showPaymentView = false
    }

    // 保存支付记录
    private func savePaymentRecord() {
        let record = PaymentRecord(
            amount: amount,
            method: selectedMethod,
            status: paymentStatus,
            timestamp: Date(),
            orderId: paymentId
        )

        // 保存到 SwiftData
        modelContext.insert(record)

        // 添加到内存列表
        paymentHistory.insert(record, at: 0)

        // 保存到持久化存储
        do {
            try modelContext.save()
        } catch {
            print("Error saving payment record: \(error)")
        }
    }

    // 支付成功后处理
    func handlePaymentSuccess() {
        // 发送支付成功通知
        NotificationCenter.default.post(
            name: .paymentSuccess,
            object: nil,
            userInfo: [
                "orderID": paymentId,
                "paymentMethod": selectedMethod.rawValue,
                "amount": amount
            ]
        )

        // 重置支付状态
        resetPaymentState()
    }

    // 支付失败处理
    func handlePaymentFailure() {
        paymentStatus = .failed
        isProcessing = false

        // 保存失败的支付记录
        savePaymentRecord()
    }

    // 重置支付状态
    private func resetPaymentState() {
        paymentStatus = .pending
        isProcessing = false
        showPaymentView = false
    }

    // 加载支付历史
    private func loadPaymentHistory() {
        do {
            let descriptor = FetchDescriptor<PaymentRecord>(predicate: #Predicate { _ in true },
                                                              sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
            paymentHistory = try modelContext.fetch(descriptor).prefix(50).map { record in
                // 确保使用 SwiftData 模型
                return record
            }
        } catch {
            print("Error loading payment history: \(error)")
        }
    }
}

// 支付记录模型
@Model
class PaymentRecord: Identifiable {
    var id = UUID()
    var amount: Double
    var method: PaymentMethod
    var status: PaymentStatus
    var timestamp: Date
    var orderId: String?

    init(amount: Double, method: PaymentMethod, status: PaymentStatus, timestamp: Date, orderId: String? = nil) {
        self.amount = amount
        self.method = method
        self.status = status
        self.timestamp = timestamp
        self.orderId = orderId
    }
}