import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: WordStore
    @Environment(\.dismiss) private var dismiss
    @State private var showReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("学习") {
                    Picker("每组单词数", selection: Binding(
                        get: { store.settings.size },
                        set: { store.settings.size = $0; store.save() }
                    )) {
                        Text("10").tag(10)
                        Text("20").tag(20)
                        Text("30").tag(30)
                    }
                    .pickerStyle(.segmented)

                    Picker("每日目标", selection: Binding(
                        get: { store.settings.goal },
                        set: { store.settings.goal = $0; store.save() }
                    )) {
                        Text("10").tag(10)
                        Text("20").tag(20)
                        Text("30").tag(30)
                        Text("50").tag(50)
                    }
                    .pickerStyle(.segmented)

                    Toggle("揭晓时自动朗读", isOn: Binding(
                        get: { store.settings.autoSpeak },
                        set: { store.settings.autoSpeak = $0; store.save() }
                    ))
                    .tint(Color.isleGreen)
                }

                Section("学习进度") {
                    LabeledContent("已遇见", value: "\(store.uniqueSeen) / \(store.words.count)")
                    LabeledContent("连续学习", value: "\(store.streak) 天")
                    LabeledContent("总正确率", value: "\(store.overallAccuracy)%")
                    Button(role: .destructive) {
                        showReset = true
                    } label: {
                        Label("清空学习记录", systemImage: "trash")
                    }
                }

                Section("关于") {
                    HStack(spacing: 12) {
                        BrandMark(size: 44)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("词屿 · WORD ISLE")
                                .font(.system(size: 13, weight: .semibold))
                                .tracking(0.6)
                            Text("把答案藏起来，诚实记录每一次。")
                                .font(.system(size: 10))
                                .foregroundColor(Color.isleMuted)
                        }
                    }
                    .padding(.vertical, 3)

                    Text("词条整理自《5500 词》讲义，共 \(store.words.count) 个词条。在 iPhone 上安装后，学习记录保存在本机。")
                        .font(.system(size: 11))
                        .lineSpacing(4)
                        .foregroundColor(Color.isleMuted)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.isleBackground)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(Color.isleGreen)
                }
            }
            .alert("清空学习记录？", isPresented: $showReset) {
                Button("取消", role: .cancel) {}
                Button("清空", role: .destructive) {
                    store.resetAll()
                    dismiss()
                }
            } message: {
                Text("所有正确率、星标和打卡记录都会被删除，这个操作无法撤销。")
            }
        }
        .tint(Color.isleGreen)
    }
}
