import SwiftUI

struct SyncStatusView: View {
    @ObservedObject var syncManager: SyncManager

    var body: some View {
        VStack(spacing: 16) {
            // 同步状态标题
            HStack {
                Text("数据同步")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                // 同步状态指示器
                HStack(spacing: 8) {
                    Circle()
                        .fill(syncManager.status == .syncing ? .orange :
                              syncManager.status == .success ? .green :
                              syncManager.status == .failed ? .red :
                              syncManager.status == .offline ? .gray : .green)
                        .frame(width: 8, height: 8)

                    Text(syncManager.status.rawValue)
                        .font(.caption)
                        .foregroundColor(syncManager.status == .offline ? .gray : .primary)
                }
            }

            // 同步进度条（仅同步中显示）
            if syncManager.status == .syncing {
                VStack(spacing: 8) {
                    ProgressView(value: syncManager.syncProgress, total: 100)
                        .progressViewStyle(LinearProgressViewStyle())

                    Text("\(Int(syncManager.syncProgress))%")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // 最后同步时间
            if let lastSyncTime = syncManager.lastSyncTime {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)

                    Text("最后同步: \(lastSyncTime, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            // 同步按钮
            Button(action: {
                syncManager.manualSync()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.white)
                    Text("手动同步")
                        .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
                .shadow(radius: 5)
            }
            .disabled(syncManager.status == .syncing)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct SyncStatusView_Previews: PreviewProvider {
    static var previews: some View {
        SyncStatusView(syncManager: SyncManager())
    }
}