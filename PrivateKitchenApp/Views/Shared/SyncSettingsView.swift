import SwiftUI

struct SyncSettingsView: View {
    @ObservedObject var syncManager: SyncManager
    @State private var showSyncNow = false

    var body: some View {
        NavigationView {
            Form {
                // 同步类型
                Section(header: Text("同步类型").font(.headline).foregroundColor(.primary)) {
                    Picker("同步类型", selection: $syncManager.syncSettings.syncType) {
                        ForEach(SyncType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                // 自动同步设置
                if syncManager.syncSettings.syncType == .scheduled {
                    Section(header: Text("定时同步设置").font(.headline).foregroundColor(.primary)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("同步间隔")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Picker("同步间隔", selection: $syncManager.syncSettings.syncInterval) {
                                Text("15分钟").tag(900.0)
                                Text("30分钟").tag(1800.0)
                                Text("1小时").tag(3600.0)
                                Text("3小时").tag(10800.0)
                                Text("6小时").tag(21600.0)
                                Text("12小时").tag(43200.0)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                }

                // 网络设置
                Section(header: Text("网络设置").font(.headline).foregroundColor(.primary)) {
                    Toggle("仅在WiFi下同步", isOn: $syncManager.syncSettings.syncOnWiFiOnly)
                    Toggle("自动同步", isOn: $syncManager.syncSettings.autoSync)
                }

                // 网络状态
                Section(header: Text("网络状态").font(.headline).foregroundColor(.primary)) {
                    HStack {
                        Image(systemName: syncManager.isOnline ? "wifi" : "wifi.slash")
                            .foregroundColor(syncManager.isOnline ? .green : .red)

                        Text(syncManager.isOnline ? "在线" : "离线")
                            .foregroundColor(syncManager.isOnline ? .green : .red)
                    }
                }
            }
            .navigationTitle("同步设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("保存") {
                    syncManager.updateSettings(syncManager.syncSettings)
                }
            }
            .sheet(isPresented: $showSyncNow) {
                SyncNowView(syncManager: syncManager)
            }
        }
    }
}

struct SyncSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SyncSettingsView(syncManager: SyncManager())
    }
}

// 手动同步视图
struct SyncNowView: View {
    @ObservedObject var syncManager: SyncManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("手动同步")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .padding(.top)

            // 同步状态
            VStack(spacing: 16) {
                if syncManager.status == .syncing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())

                        Text("同步中...")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("\(Int(syncManager.syncProgress))%")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: syncManager.status == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(syncManager.status == .success ? .green : .red)
                            .font(.system(size: 60))

                        Text(syncManager.status.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
            }

            Spacer()

            // 按钮
            VStack(spacing: 12) {
                if syncManager.status == .syncing {
                    Button(action: {
                        // 取消同步
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
                } else {
                    Button(action: {
                        syncManager.manualSync()
                    }) {
                        Text("重新同步")
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

                Button(action: {
                    dismiss()
                }) {
                    Text("关闭")
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
        }
        .padding()
        .navigationTitle("手动同步")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("取消") {
                dismiss()
            }
        }
    }
}