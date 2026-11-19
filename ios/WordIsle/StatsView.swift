import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: WordStore
    var onOpenWord: (Word) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BrandHeader(title: "统计", subtitle: "YOUR ISLAND")
                    .padding(.bottom, 18)

                VStack(alignment: .leading, spacing: 5) {
                    Text("学习足迹")
                        .font(.system(size: 28, weight: .bold))
                        .tracking(-0.5)
                        .foregroundColor(Color.isleInk)
                    Text("每一次“想起来”都算数")
                        .font(.system(size: 11))
                        .foregroundColor(Color.isleMuted)
                }
                .padding(.bottom, 15)

                hero
                    .padding(.bottom, 10)

                metricGrid
                    .padding(.bottom, 4)

                SectionHeader(title: "最近 7 天", trailing: "每天 \(store.settings.goal) 词")
                    .padding(.top, 24)
                    .padding(.bottom, 11)
                weekChart

                SectionHeader(title: "掌握程度", trailing: "\(store.words.count) 个词")
                    .padding(.top, 24)
                    .padding(.bottom, 11)
                distribution

                SectionHeader(title: "正确率最低", trailing: "再见面一次")
                    .padding(.top, 24)
                    .padding(.bottom, 11)
                weakList
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background(
            ZStack {
                Color.isleBackground
                RadialGradient(colors: [Color.isleLime.opacity(0.14), .clear], center: .topTrailing, startRadius: 10, endRadius: 280)
            }
            .ignoresSafeArea()
        )
    }

    private var hero: some View {
        HStack(spacing: 17) {
            ProgressRing(
                progress: Double(store.overallAccuracy) / 100,
                size: 96,
                lineWidth: 7,
                tint: Color.isleLime,
                track: Color.white.opacity(0.13),
                textColor: Color.isleCream,
                label: "正确率"
            )
            VStack(alignment: .leading, spacing: 5) {
                Text("OVERALL ACCURACY")
                    .font(.system(size: 8.5, weight: .bold))
                    .tracking(1.8)
                    .foregroundColor(Color.isleCream.opacity(0.5))
                Text("\(store.overallAccuracy)% 的总正确率")
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .foregroundColor(Color.isleCream)
                    .minimumScaleFactor(0.75)
                    .lineLimit(2)
                Text("共作答 \(store.totalSeen) 次 · 正确 \(store.totalCorrect) 次\n遇见过 \(store.uniqueSeen) / \(store.words.count) 个词")
                    .font(.system(size: 10))
                    .lineSpacing(3)
                    .foregroundColor(Color.isleCream.opacity(0.58))
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.isleGreenSoft, Color.isleGreenDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .stroke(Color.isleLime.opacity(0.17), lineWidth: 1)
                .frame(width: 160, height: 160)
                .offset(x: 54, y: 74)
        }
        .shadow(color: Color.isleGreen.opacity(0.22), radius: 20, x: 0, y: 12)
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 9), GridItem(.flexible(), spacing: 9)], spacing: 9) {
            metric("连续学习", "\(store.streak)", "天")
            metric("学习天数", "\(store.studiedDays)", "天")
            metric("作答次数", "\(store.totalSeen)", "次")
            metric("已掌握", "\(store.masteredCount)", "词")
        }
    }

    private func metric(_ label: String, _ value: String, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 9.5))
                .foregroundColor(Color.isleMuted)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundColor(Color.isleInk)
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundColor(Color.isleMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .fill(Color.islePaper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke(Color.isleLine, lineWidth: 1)
        )
    }

    private var weekChart: some View {
        let days = store.week()
        let maxSeen = max(1, days.map(\.seen).max() ?? 1)
        return VStack(spacing: 14) {
            HStack {
                Text("复习次数")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.isleInk)
                Spacer()
                Text("共 \(days.reduce(0) { $0 + $1.seen }) 次")
                    .font(.system(size: 10))
                    .foregroundColor(Color.isleMuted)
            }
            HStack(alignment: .bottom, spacing: 9) {
                ForEach(days) { day in
                    VStack(spacing: 5) {
                        Text(day.seen == 0 ? "" : "\(day.seen)")
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundColor(Color.isleMutedLight)
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(day.isToday ? Color.isleLime : (day.seen > 0 ? Color.isleGreenSoft : Color.isleInk.opacity(0.09)))
                            .frame(height: max(4, CGFloat(day.seen) / CGFloat(maxSeen) * 100))
                        Text(day.isToday ? "今天" : day.label.replacingOccurrences(of: "周", with: ""))
                            .font(.system(size: 8, weight: day.isToday ? .bold : .regular))
                            .foregroundColor(day.isToday ? Color.isleGreen : Color.isleMutedLight)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 128)
        }
        .isleCard()
    }

    private var distribution: some View {
        let total = max(1, store.words.count)
        let pMastered = Double(store.masteredCount) / Double(total)
        let pLearning = Double(store.learningCount) / Double(total)
        let pNew = max(0, 1 - pMastered - pLearning)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("词库分布")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.isleInk)
                Spacer()
                Text("已掌握 \(store.masteredCount) 个")
                    .font(.system(size: 10))
                    .foregroundColor(Color.isleMuted)
            }
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle().fill(Color.isleGreen).frame(width: geo.size.width * pMastered)
                    Rectangle().fill(Color.isleLime).frame(width: geo.size.width * pLearning)
                    Rectangle().fill(Color.isleInk.opacity(0.12)).frame(width: geo.size.width * pNew)
                }
            }
            .frame(height: 10)
            .clipShape(Capsule())

            HStack(spacing: 14) {
                legend("已掌握 \(store.masteredCount)", Color.isleGreen)
                legend("学习中 \(store.learningCount)", Color.isleLime)
                legend("未学习 \(store.newCount)", Color.isleInk.opacity(0.12))
            }
        }
        .isleCard()
    }

    private func legend(_ text: String, _ color: Color) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 7, height: 7)
            Text(text)
                .font(.system(size: 9))
                .foregroundColor(Color.isleMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private var weakList: some View {
        let weak = store.weakWords(limit: 5)
        return VStack(spacing: 0) {
            if weak.isEmpty {
                Text("还没有足够的数据。先完成一组学习吧。")
                    .font(.system(size: 11))
                    .foregroundColor(Color.isleMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
            } else {
                ForEach(Array(weak.indices), id: \.self) { idx in
                    let word = weak[idx]
                    HStack(spacing: 10) {
                        Button {
                            onOpenWord(word)
                        } label: {
                            Text(word.word)
                                .font(.system(size: 16, weight: .semibold, design: .serif))
                                .foregroundColor(Color.isleInk)
                                .lineLimit(1)
                                .frame(width: 92, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.isleCoral.opacity(0.12))
                                Capsule()
                                    .fill(Color.isleCoral)
                                    .frame(width: max(3, geo.size.width * CGFloat(store.accuracy(word.id) ?? 0) / 100))
                            }
                        }
                        .frame(height: 6)
                        Text("\(store.accuracy(word.id) ?? 0)%")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(Color.isleCoral)
                            .frame(width: 32, alignment: .trailing)
                    }
                    .padding(.vertical, 11)
                    if idx < weak.count - 1 {
                        Divider().overlay(Color.isleLine)
                    }
                }
            }
        }
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.islePaper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.isleLine, lineWidth: 1)
        )
    }
}
