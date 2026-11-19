import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: WordStore
    var onStart: (StudyMode) -> Void
    var onOpenWord: (Word) -> Void
    var onSettings: () -> Void

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 6 { return "夜深了" }
        if hour < 11 { return "早上好" }
        if hour < 14 { return "中午好" }
        if hour < 18 { return "下午好" }
        return "晚上好"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BrandHeader(
                    title: "词屿",
                    subtitle: "WORD ISLE",
                    trailing: AnyView(
                        HStack(spacing: 8) {
                            StreakPill(days: store.streak)
                            IconCircleButton(systemName: "gearshape", action: onSettings)
                        }
                    )
                )
                .padding(.bottom, 28)

                hello
                    .padding(.bottom, 22)

                hero
                    .padding(.bottom, 12)

                modeGrid
                    .padding(.bottom, 4)

                SectionHeader(title: "这一周", trailing: "连续 \(store.streak) 天")
                    .padding(.top, 25)
                    .padding(.bottom, 12)
                weekCard

                SectionHeader(title: "最需要再见", trailing: "\(store.wrongCount) 个错词")
                    .padding(.top, 25)
                    .padding(.bottom, 10)
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
                RadialGradient(colors: [Color.isleLime.opacity(0.18), .clear], center: .topTrailing, startRadius: 10, endRadius: 300)
                RadialGradient(colors: [Color.isleGreenSoft.opacity(0.08), .clear], center: .bottomLeading, startRadius: 10, endRadius: 260)
            }
            .ignoresSafeArea()
        )
    }

    private var hello: some View {
        let remaining = max(1, store.settings.goal - store.today().seen)
        return VStack(alignment: .leading, spacing: 9) {
            Text("\(greeting)，")
                .font(.system(size: 34, weight: .regular, design: .serif))
                .foregroundColor(Color.isleInk)
                .tracking(-0.6)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("和 ")
                Text("\(remaining)")
                    .background(alignment: .bottom) {
                        Capsule()
                            .fill(Color.isleLime.opacity(0.8))
                            .frame(height: 7)
                            .offset(y: 2)
                    }
                Text(" 个词见个面。")
            }
            .font(.system(size: 34, weight: .regular, design: .serif))
            .foregroundColor(Color.isleInk)
            .tracking(-0.6)
            .minimumScaleFactor(0.8)
            .lineLimit(1)

            Text("释义先藏起来。轻点卡片揭晓，再记录这次有没有想起来。")
                .font(.system(size: 12.5))
                .lineSpacing(4)
                .foregroundColor(Color.isleMuted)
        }
    }

    private var hero: some View {
        let today = store.today()
        let goal = max(5, store.settings.goal)
        let progress = min(1, Double(today.seen) / Double(goal))
        return ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.isleGreenSoft, Color.isleGreenDeep],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .stroke(Color.isleLime.opacity(0.18), lineWidth: 1)
                .frame(width: 210, height: 210)
                .offset(x: 66, y: -96)
            Circle()
                .fill(RadialGradient(colors: [Color.isleLime.opacity(0.16), .clear], center: .center, startRadius: 2, endRadius: 100))
                .frame(width: 180, height: 180)
                .offset(x: 50, y: 90)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TODAY · 今日进度")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(2)
                            .foregroundColor(Color.isleCream.opacity(0.55))
                        Text("已复习 \(today.seen) 个词")
                            .font(.system(size: 25, weight: .regular, design: .serif))
                            .foregroundColor(Color.isleCream)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                        Text("目标 \(goal) 个 · 正确率 \(today.seen == 0 ? 0 : today.accuracy)%")
                            .font(.system(size: 11))
                            .foregroundColor(Color.isleCream.opacity(0.62))
                    }
                    Spacer()
                    ProgressRing(progress: progress, size: 82, tint: .isleLime, track: Color.white.opacity(0.13), textColor: .isleCream, label: "今日")
                }

                HStack(alignment: .bottom) {
                    HStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(store.overallAccuracy)%")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Color.isleCream)
                            Text("总正确率")
                                .font(.system(size: 9))
                                .foregroundColor(Color.isleCream.opacity(0.45))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(store.uniqueSeen)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Color.isleCream)
                            Text("已遇见")
                                .font(.system(size: 9))
                                .foregroundColor(Color.isleCream.opacity(0.45))
                        }
                    }
                    Spacer()
                    Button {
                        onStart(.mixed)
                    } label: {
                        HStack(spacing: 5) {
                            Text("开始学习")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.isleGreen)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Capsule().fill(Color.isleLime))
                        .shadow(color: .black.opacity(0.16), radius: 8, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 20)
            }
            .padding(22)
        }
        .shadow(color: Color.isleGreen.opacity(0.25), radius: 22, x: 0, y: 14)
    }

    private var modeGrid: some View {
        HStack(spacing: 9) {
            modeCard(.new, icon: "sparkles", count: store.newCount, bg: Color.isleLime.opacity(0.45), fg: Color.isleGreen)
            modeCard(.review, icon: "arrow.triangle.2.circlepath", count: max(0, store.uniqueSeen - store.masteredCount), bg: Color.isleCoral.opacity(0.10), fg: Color.isleCoral)
            modeCard(.wrong, icon: "flame", count: store.wrongCount, bg: Color.isleGold.opacity(0.12), fg: Color.isleGold)
        }
    }

    private func modeCard(_ mode: StudyMode, icon: String, count: Int, bg: Color, fg: Color) -> some View {
        Button {
            onStart(mode)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(fg)
                    .frame(width: 32, height: 32)
                    .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(bg))
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode == .new ? "新词" : mode == .review ? "复习" : "错词")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(Color.isleInk)
                    Text(mode == .new ? "还没见过" : mode == .review ? "再见面一次" : "重点攻克")
                        .font(.system(size: 9.5))
                        .foregroundColor(Color.isleMuted)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.islePaper)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.isleLine, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                Text("\(count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Color.isleMutedLight)
                    .padding(.top, 13)
                    .padding(.trailing, 12)
            }
            .shadow(color: Color.isleInk.opacity(0.04), radius: 6, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var weekCard: some View {
        let days = store.week()
        let maxSeen = max(1, days.map(\.seen).max() ?? 1)
        return VStack(spacing: 14) {
            HStack {
                Text("每天一点点")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.isleInk)
                Spacer()
                Text("共 \(days.reduce(0) { $0 + $1.seen }) 次复习")
                    .font(.system(size: 10))
                    .foregroundColor(Color.isleMuted)
            }
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(days) { day in
                    VStack(spacing: 6) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(day.isToday ? Color.isleLime : (day.seen > 0 ? Color.isleGreenSoft : Color.isleInk.opacity(0.09)))
                            .frame(height: max(4, CGFloat(day.seen) / CGFloat(maxSeen) * 62))
                        Text(day.label.replacingOccurrences(of: "周", with: ""))
                            .font(.system(size: 8, weight: day.isToday ? .bold : .regular))
                            .foregroundColor(day.isToday ? Color.isleGreen : Color.isleMutedLight)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 82)
        }
        .isleCard()
    }

    private var weakList: some View {
        let weak = store.weakWords(limit: 4)
        return VStack(spacing: 8) {
            if weak.isEmpty {
                Text("还没有错词。开始第一组，答案会慢慢长出来。")
                    .font(.system(size: 11))
                    .lineSpacing(4)
                    .foregroundColor(Color.isleMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(weak) { word in
                    Button {
                        onOpenWord(word)
                    } label: {
                        HStack(spacing: 11) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(word.word)
                                    .font(.system(size: 17, weight: .semibold, design: .serif))
                                    .foregroundColor(Color.isleInk)
                                Text(word.primary)
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.isleMuted)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text("\(store.accuracy(word.id) ?? 0)%")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor((store.accuracy(word.id) ?? 0) >= 60 ? Color.isleGreenSoft : Color.isleCoral)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill((store.accuracy(word.id) ?? 0) >= 60 ? Color.isleGreen.opacity(0.08) : Color.isleCoralSoft)
                                )
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.isleMutedLight)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .fill(Color.islePaper)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .stroke(Color.isleLine, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
