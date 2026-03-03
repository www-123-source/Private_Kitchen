import SwiftUI

/// 订单进度指示器
struct OrderProgressIndicator: View {
    let order: Order
    let timeline: [OrderTimeline]

    var body: some View {
        VStack(spacing: 16) {
            // 进度标题
            HStack {
                Text("订单进度")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text(progressText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // 进度条
            ProgressView(value: progressValue, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .animation(.easeInOut, value: progressValue)

            // 步骤指示器
            HStack(spacing: 4) {
                ForEach(OrderStatus.allCases, id: \.self) { status in
                    StepIndicator(
                        status: status,
                        isActive: status == order.status,
                        isCompleted: isCompleted(status)
                    )
                }
            }
            .padding(.horizontal, 8)

            // 当前状态描述
            VStack(alignment: .leading, spacing: 4) {
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                if let estimatedTime = estimatedTime {
                    Text(estimatedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - 计算属性

    private var progressValue: Double {
        let totalSteps = OrderStatus.allCases.count
        let currentIndex = OrderStatus.allCases.firstIndex(of: order.status) ?? 0
        return Double(currentIndex) / Double(totalSteps - 1)
    }

    private var progressColor: Color {
        switch order.status {
        case .pending: return .orange
        case .confirmed: return .blue
        case .cooking: return .yellow
        case .ready: return .green
        case .delivered: return .purple
        case .cancelled: return .red
        }
    }

    private var progressText: String {
        switch order.status {
        case .pending: return "等待确认"
        case .confirmed: return "已确认"
        case .cooking: return "制作中"
        case .ready: return "已完成"
        case .delivered: return "已送达"
        case .cancelled: return "已取消"
        }
    }

    private var statusMessage: String {
        switch order.status {
        case .pending: return "等待厨房接单"
        case .confirmed: return "订单已确认，正在准备食材"
        case .cooking: return "正在为您制作美食，预计需要约15-30分钟"
        case .ready: return "制作完成，可以上菜了"
        case .delivered: return "订单已完成"
        case .cancelled: return "订单已取消"
        }
    }

    private var estimatedTime: String? {
        switch order.status {
        case .cooking:
            let cookingDuration = 30 * 60 // 30分钟
            let elapsedTime = Date().timeIntervalSince(timeline.last { $0.status == .confirmed }?.timestamp ?? Date())
            let remainingTime = max(0, cookingDuration - elapsedTime)

            if remainingTime > 0 {
                let minutes = Int(remainingTime) / 60
                return "预计还需要 \(minutes) 分钟"
            }
            return nil
        default:
            return nil
        }
    }

    private func isCompleted(_ status: OrderStatus) -> Bool {
        guard let currentIndex = OrderStatus.allCases.firstIndex(of: order.status) else { return false }
        let statusIndex = OrderStatus.allCases.firstIndex(of: status) ?? 0
        return statusIndex < currentIndex
    }

    private func isCurrent(_ status: OrderStatus) -> Bool {
        return status == order.status
    }
}

// MARK: - 步骤指示器
struct StepIndicator: View {
    let status: OrderStatus
    let isActive: Bool
    let isCompleted: Bool

    var body: some View {
        VStack(spacing: 4) {
            // 状态图标
            ZStack {
                Circle()
                    .fill(
                        isCompleted ? Color.green :
                        isActive ? Color.orange :
                        Color.gray.opacity(0.3)
                    )
                    .frame(width: 32, height: 32)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.caption)
                } else if isActive {
                    Image(systemName: status.icon)
                        .foregroundColor(.white)
                        .font(.caption)
                } else {
                    Image(systemName: status.icon)
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }

            // 状态标签
            Text(status.displayName)
                .font(.caption)
                .foregroundColor(
                    isCompleted ? .green :
                    isActive ? .orange :
                    .gray
                )
        }
    }
}

// MARK: - OrderStatus 扩展
extension OrderStatus {
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .confirmed: return "checkmark"
        case .cooking: return "flame"
        case .ready: return "checkmark.circle"
        case .delivered: return "truck"
        case .cancelled: return "xmark"
        }
    }
}

struct OrderProgressIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 不同状态的预览
            ForEach([OrderStatus.pending, .confirmed, .cooking, .ready, .delivered], id: \.self) { status in
                OrderProgressIndicator(
                    order: Order(
                        orderNumber: "PK-20240302-0001",
                        status: status,
                        totalAmount: 85.50
                    ),
                    timeline: []
                )
                .padding()
            }
        }
    }
}