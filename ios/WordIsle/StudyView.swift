import SwiftUI
import UIKit
import Foundation

struct StudySessionView: View {
    @EnvironmentObject private var store: WordStore
    @Environment(\.dismiss) private var dismiss

    let launch: StudyLaunch

    @State private var queue: [Word]
    @State private var index = 0
    @State private var revealed = false
    @State private var results: [StudyResult] = []
    @State private var showSummary = false
    @State private var startedAt = Date()

    init(launch: StudyLaunch) {
        self.launch = launch
        _queue = State(initialValue: launch.words)
    }

    private var current: Word? {
        guard queue.indices.contains(index) else { return nil }
        return queue[index]
    }

    var body: some View {
        ZStack {
            Color.isleBackground.ignoresSafeArea()
            if showSummary {
                SummaryView(
                    mode: launch.mode,
                    results: results,
                    startedAt: startedAt,
                    onRestart: restart,
                    onClose: { dismiss() }
                )
            } else if let word = current {
                session(word)
            }
        }
        .interactiveDismissDisabled()
    }

    private func session(_ word: Word) -> some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 14)

            Spacer(minLength: 12)

            card(word)
                .padding(.horizontal, 20)

            Spacer(minLength: 12)

            actions(word)
                .padding(.horizontal, 20)

            Text("诚实比正确率重要")
                .font(.system(size: 9))
                .foregroundColor(Color.isleMutedLight)
                .padding(.top, 10)
                .padding(.bottom, 10)
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.isleInkSoft)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.islePaper.opacity(0.8)))
                    .overlay(Circle().stroke(Color.isleLine, lineWidth: 1))
            }
            .buttonStyle(.plain)

            VStack(spacing: 6) {
                HStack {
                    Text("\(index + 1) / \(queue.count)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.isleMuted)
                    Spacer()
                    Text("\(Int(Double(index) / Double(max(1, queue.count)) * 100))% 完成")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.isleInkSoft)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.isleInk.opacity(0.09))
                        Capsule()
                            .fill(Color.isleGreen)
                            .frame(width: max(3, geo.size.width * CGFloat(index) / CGFloat(max(1, queue.count))))
                    }
                }
                .frame(height: 4)
            }

            Text(launch.mode.title)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color.isleGreenSoft)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.isleGreen.opacity(0.07)))
        }
    }

    private func card(_ word: Word) -> some View {
        VStack(spacing: 0) {
            Text(word.word)
                .font(.system(size: 52, weight: .regular, design: .serif))
                .tracking(-1.4)
                .foregroundColor(Color.isleInk)
                .minimumScaleFactor(0.45)
                .lineLimit(1)
                .padding(.top, 8)
                .padding(.horizontal, 4)

            Text(word.phoneticDisplay)
                .font(.system(size: 13, design: .serif))
                .foregroundColor(Color.isleMuted)
                .padding(.top, 10)

            Button {
                SpeechService.shared.speak(word.word)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color.isleGreen)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.isleGreen.opacity(0.07)))
                    .overlay(Circle().stroke(Color.isleGreen.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, 14)

            if revealed {
                revealContent(word)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.isleLime)
                        .frame(width: 5, height: 5)
                        .shadow(color: Color.isleLime.opacity(0.6), radius: 3)
                    Text("轻点卡片，揭晓释义")
                        .font(.system(size: 9.5))
                        .foregroundColor(Color.isleMutedLight)
                }
                .padding(.top, 24)
                .padding(.bottom, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 22)
        .padding(.vertical, 26)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.islePaper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.isleLine, lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .stroke(Color.isleGreen.opacity(0.06), lineWidth: 1)
                .frame(width: 180, height: 180)
                .offset(x: 82, y: -94)
        }
        .shadow(color: Color.isleInk.opacity(0.12), radius: 26, x: 0, y: 14)
        .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .onTapGesture {
            reveal(word)
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: revealed)
    }

    private func revealContent(_ word: Word) -> some View {
        let accuracyText = store.accuracy(word.id).map { "\($0)%" } ?? "新词"
        return VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.isleLine)
                .frame(height: 1)
                .padding(.top, 22)

            Text("MEANING · 释义")
                .font(.system(size: 9, weight: .bold))
                .tracking(1.8)
                .foregroundColor(Color.isleMutedLight)
                .padding(.top, 18)
                .padding(.bottom, 11)

            VStack(alignment: .leading, spacing: 11) {
                ForEach(word.senses.prefix(4)) { sense in
                    HStack(alignment: .top, spacing: 8) {
                        if !sense.pos.isEmpty {
                            PosChip(pos: sense.pos)
                                .padding(.top, 1)
                        }
                        Text(sense.def)
                            .font(.system(size: 16))
                            .lineSpacing(4)
                            .foregroundColor(Color.isleInkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if !word.note.isEmpty {
                Text(word.note)
                    .font(.system(size: 10.5))
                    .lineSpacing(3)
                    .foregroundColor(Color.isleGreenSoft)
                    .lineLimit(3)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.isleGreen.opacity(0.045))
                    )
                    .padding(.top, 14)
            }

            if let example = word.examples.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(example.en)
                        .font(.system(size: 12, design: .serif))
                        .lineSpacing(3)
                        .foregroundColor(Color.isleInkSoft)
                        .lineLimit(3)
                    if !example.zh.isEmpty {
                        Text(example.zh)
                            .font(.system(size: 10))
                            .lineSpacing(3)
                            .foregroundColor(Color.isleMuted)
                            .lineLimit(2)
                    }
                }
                .padding(11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.isleInk.opacity(0.035))
                )
                .padding(.top, 12)
            }

            HStack(spacing: 5) {
                Text("正确率 \(accuracyText)")
                Text("·")
                Text("已作答 \(store.stat(word.id).seen) 次")
            }
            .font(.system(size: 9))
            .foregroundColor(Color.isleMutedLight)
            .frame(maxWidth: .infinity)
            .padding(.top, 18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reveal(_ word: Word) {
        guard !revealed else { return }
        withAnimation {
            revealed = true
        }
        if store.settings.autoSpeak {
            SpeechService.shared.speak(word.word)
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    @ViewBuilder
    private func actions(_ word: Word) -> some View {
        if revealed {
            HStack(spacing: 10) {
                Button {
                    answer(word, correct: false)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                        Text("没想起来")
                    }
                }
                .buttonStyle(IsleWrongButtonStyle())

                Button {
                    answer(word, correct: true)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark").font(.system(size: 13, weight: .bold))
                        Text("想起来了")
                    }
                }
                .buttonStyle(IslePrimaryButtonStyle())
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        } else {
            Button {
                reveal(word)
            } label: {
                Text("查看释义")
            }
            .buttonStyle(IslePrimaryButtonStyle())
        }
    }

    private func answer(_ word: Word, correct: Bool) {
        store.record(word, correct: correct)
        results.append(StudyResult(word: word, correct: correct))
        UIImpactFeedbackGenerator(style: correct ? .light : .medium).impactOccurred()

        if index + 1 >= queue.count {
            withAnimation(.easeInOut(duration: 0.3)) {
                showSummary = true
            }
        } else {
            withAnimation(.easeInOut(duration: 0.22)) {
                index += 1
                revealed = false
            }
        }
    }

    private func restart() {
        queue = store.makeQueue(mode: launch.mode)
        index = 0
        revealed = false
        results = []
        showSummary = false
        startedAt = Date()
    }
}

private struct SummaryView: View {
    @EnvironmentObject private var store: WordStore
    let mode: StudyMode
    let results: [StudyResult]
    let startedAt: Date
    let onRestart: () -> Void
    let onClose: () -> Void

    private var right: Int { results.filter { $0.correct }.count }
    private var total: Int { results.count }
    private var acc: Double { total == 0 ? 0 : Double(right) / Double(total) }
    private var wrong: [Word] { results.filter { !$0.correct }.map(\.word) }
    private var seconds: Int { max(1, Int(Date().timeIntervalSince(startedAt))) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("SESSION COMPLETE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2.2)
                        .foregroundColor(Color.isleGreenSoft)
                    Spacer()
                    Text(mode.title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.isleMuted)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.islePaper))
                }

                Text(title)
                    .font(.system(size: 35, weight: .regular, design: .serif))
                    .tracking(-0.8)
                    .foregroundColor(Color.isleInk)
                    .padding(.top, 16)
                Text(subtitle)
                    .font(.system(size: 12))
                    .lineSpacing(5)
                    .foregroundColor(Color.isleMuted)
                    .padding(.top, 8)

                ProgressRing(
                    progress: acc,
                    size: 160,
                    lineWidth: 8,
                    tint: Color.isleGreen,
                    track: Color.isleGreen.opacity(0.1),
                    textColor: Color.isleInk,
                    label: "本组正确率"
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 22)
                .padding(.bottom, 20)

                HStack(spacing: 8) {
                    summaryMetric("\(right)", "想起来了")
                    summaryMetric("\(total - right)", "没想起来")
                    summaryMetric(String(format: "%d:%02d", seconds / 60, seconds % 60), "用时")
                }

                if !wrong.isEmpty {
                    SectionHeader(title: "再见一次", trailing: "\(wrong.count) 个")
                        .padding(.top, 24)
                        .padding(.bottom, 9)
                    VStack(spacing: 0) {
                        ForEach(Array(wrong.prefix(8).indices), id: \.self) { idx in
                            let word = wrong[idx]
                            HStack(spacing: 10) {
                                Text(word.word)
                                    .font(.system(size: 16, weight: .semibold, design: .serif))
                                    .foregroundColor(Color.isleInk)
                                Text(word.primary)
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.isleMuted)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(store.accuracy(word.id) ?? 0)%")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.isleCoral)
                            }
                            .padding(.vertical, 11)
                            if idx < min(8, wrong.count) - 1 {
                                Divider().overlay(Color.isleLine)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.islePaper)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.isleLine, lineWidth: 1)
                    )
                }

                Spacer(minLength: 24)

                Button(action: onRestart) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("再来一组")
                    }
                }
                .buttonStyle(IslePrimaryButtonStyle())
                .padding(.top, 16)

                Button(action: onClose) {
                    Text("回到首页")
                }
                .buttonStyle(IsleSecondaryButtonStyle())
                .padding(.top, 9)
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .background(Color.isleBackground.ignoresSafeArea())
    }

    private var title: String {
        if total > 0 && right == total { return "这一组，全记得。" }
        if acc >= 0.7 { return "感觉正在长出来。" }
        return "没关系，再见一次。"
    }

    private var subtitle: String {
        if total > 0 && right == total { return "漂亮的完成。要不要再来一组，趁热打铁？" }
        return "答错的词已经记在词库里了，下一次会更容易。"
    }

    private func summaryMetric(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundColor(Color.isleInk)
            Text(label)
                .font(.system(size: 8.5))
                .foregroundColor(Color.isleMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.islePaper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color.isleLine, lineWidth: 1)
        )
    }
}
