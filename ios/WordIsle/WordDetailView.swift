import SwiftUI

struct WordDetailView: View {
    @EnvironmentObject private var store: WordStore
    @Environment(\.dismiss) private var dismiss

    let word: Word
    var onStudy: (Word) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    IconCircleButton(systemName: "chevron.left", size: 38) { dismiss() }
                    Spacer()
                    HStack(spacing: 8) {
                        Button {
                            store.toggleStar(word.id)
                        } label: {
                            Image(systemName: store.starred.contains(word.id) ? "star.fill" : "star")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(store.starred.contains(word.id) ? Color.isleGold : Color.isleInkSoft)
                                .frame(width: 38, height: 38)
                                .background(Circle().fill(Color.islePaper.opacity(0.8)))
                                .overlay(Circle().stroke(Color.isleLine, lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        IconCircleButton(systemName: "speaker.wave.2.fill", size: 38) {
                            SpeechService.shared.speak(word.word)
                        }
                    }
                }
                .padding(.bottom, 10)

                VStack(spacing: 0) {
                    Text(word.word)
                        .font(.system(size: 60, weight: .regular, design: .serif))
                        .tracking(-1.6)
                        .foregroundColor(Color.isleInk)
                        .minimumScaleFactor(0.42)
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                    Text(word.phoneticDisplay)
                        .font(.system(size: 13.5, design: .serif))
                        .foregroundColor(Color.isleMuted)
                        .padding(.top, 8)

                    Button {
                        SpeechService.shared.speak(word.word)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.isleCream)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(Color.isleGreen))
                            .shadow(color: Color.isleGreen.opacity(0.22), radius: 10, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 15)

                    HStack(spacing: 6) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 10, weight: .medium))
                        Text("\(word.lesson) · \(word.lessonTitle)")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(Color.isleMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.islePaper.opacity(0.75)))
                    .overlay(Capsule().stroke(Color.isleLine, lineWidth: 1))
                    .padding(.top, 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 24)

                meaningBlock
                    .padding(.bottom, 10)
                metricStrip
                    .padding(.bottom, 10)
                if !word.examples.isEmpty {
                    examplesBlock
                        .padding(.bottom, 10)
                }
                if !word.note.isEmpty {
                    noteBlock
                        .padding(.bottom, 10)
                }

                HStack(spacing: 9) {
                    Button {
                        SpeechService.shared.speak(word.word)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("朗读")
                        }
                    }
                    .buttonStyle(IsleSecondaryButtonStyle())

                    Button {
                        onStudy(word)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.clockwise")
                            Text("复习这个词")
                        }
                    }
                    .buttonStyle(IslePrimaryButtonStyle())
                }
                .padding(.top, 4)

                Text("收藏这个词，之后可以在「星标」里找到它。")
                    .font(.system(size: 9))
                    .foregroundColor(Color.isleMutedLight)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(Color.isleBackground.ignoresSafeArea())
    }

    private var meaningBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            blockTitle("MEANING · 释义")
            ForEach(Array(word.senses.indices), id: \.self) { idx in
                let sense = word.senses[idx]
                HStack(alignment: .top, spacing: 8) {
                    if !sense.pos.isEmpty {
                        PosChip(pos: sense.pos)
                            .padding(.top, 1)
                    }
                    Text(sense.def)
                        .font(.system(size: 15))
                        .lineSpacing(4)
                        .foregroundColor(Color.isleInkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 7)
                if idx < word.senses.count - 1 {
                    Divider().overlay(Color.isleLine.opacity(0.7))
                }
            }
        }
        .isleCard(padding: 17, radius: 22)
    }

    private var metricStrip: some View {
        HStack(spacing: 1) {
            metricCell("\(store.stat(word.id).seen)", "作答次数")
            metricCell(store.accuracy(word.id).map { "\($0)%" } ?? "—", "正确率")
            metricCell(store.lastSeenText(word.id), "上次学习")
        }
        .background(Color.isleLine)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.isleLine, lineWidth: 1)
        )
    }

    private func metricCell(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: value.count > 5 ? CGFloat(12) : CGFloat(19), weight: .bold, design: .rounded))
                .foregroundColor(Color.isleInk)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 8.5))
                .foregroundColor(Color.isleMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(Color.islePaper)
    }

    private var examplesBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            blockTitle("EXAMPLES · 例句")
            ForEach(Array(word.examples.prefix(4).indices), id: \.self) { idx in
                let example = word.examples[idx]
                VStack(alignment: .leading, spacing: 4) {
                    Text(example.en)
                        .font(.system(size: 13, design: .serif))
                        .lineSpacing(4)
                        .foregroundColor(Color.isleInkSoft)
                    if !example.zh.isEmpty {
                        Text(example.zh)
                            .font(.system(size: 11))
                            .lineSpacing(4)
                            .foregroundColor(Color.isleMuted)
                    }
                }
                .padding(.vertical, 8)
                if idx < min(4, word.examples.count) - 1 {
                    Divider().overlay(Color.isleLine.opacity(0.7))
                }
            }
        }
        .isleCard(padding: 17, radius: 22)
    }

    private var noteBlock: some View {
        VStack(alignment: .leading, spacing: 9) {
            blockTitle("ROOTS · 词源助记")
            Text(word.note)
                .font(.system(size: 11.5))
                .lineSpacing(4)
                .foregroundColor(Color.isleGreenSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .isleCard(padding: 17, radius: 22)
    }

    private func blockTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .tracking(1.8)
            .foregroundColor(Color.isleMutedLight)
            .padding(.bottom, 9)
    }
}
