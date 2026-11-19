import SwiftUI

extension Color {
    static let isleBackground = Color(red: 0.965, green: 0.953, blue: 0.918)
    static let islePaper      = Color(red: 1.000, green: 0.992, blue: 0.973)
    static let isleInk        = Color(red: 0.106, green: 0.165, blue: 0.129)
    static let isleInkSoft    = Color(red: 0.200, green: 0.275, blue: 0.235)
    static let isleMuted      = Color(red: 0.459, green: 0.502, blue: 0.467)
    static let isleMutedLight = Color(red: 0.604, green: 0.639, blue: 0.608)
    static let isleGreen      = Color(red: 0.129, green: 0.298, blue: 0.216)
    static let isleGreenDeep  = Color(red: 0.090, green: 0.227, blue: 0.161)
    static let isleGreenSoft  = Color(red: 0.216, green: 0.416, blue: 0.314)
    static let isleLime       = Color(red: 0.847, green: 0.941, blue: 0.416)
    static let isleLimeSoft   = Color(red: 0.910, green: 0.976, blue: 0.604)
    static let isleCoral      = Color(red: 0.788, green: 0.376, blue: 0.290)
    static let isleCoralSoft  = Color(red: 0.980, green: 0.914, blue: 0.886)
    static let isleGold       = Color(red: 0.780, green: 0.604, blue: 0.231)
    static let isleCream      = Color(red: 0.973, green: 0.957, blue: 0.914)
    static let isleLine       = Color.black.opacity(0.075)
    static let isleLineStrong = Color.black.opacity(0.13)
}

struct IsleCard: ViewModifier {
    var padding: CGFloat = 18
    var radius: CGFloat = 26

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.islePaper)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.isleLine, lineWidth: 1)
            )
            .shadow(color: Color.isleInk.opacity(0.055), radius: 16, x: 0, y: 8)
    }
}

extension View {
    func isleCard(padding: CGFloat = 18, radius: CGFloat = 26) -> some View {
        modifier(IsleCard(padding: padding, radius: radius))
    }
}

struct BrandMark: View {
    var size: CGFloat = 35
    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.31, style: .continuous)
            .fill(Color.isleGreen)
            .frame(width: size, height: size)
            .overlay(
                Text("词")
                    .font(.system(size: size * 0.52, weight: .regular, design: .serif))
                    .foregroundColor(Color.isleCream)
            )
            .shadow(color: Color.isleGreen.opacity(0.2), radius: 7, x: 0, y: 3)
    }
}

struct BrandHeader: View {
    let title: String
    let subtitle: String
    var trailing: AnyView? = nil

    init(title: String, subtitle: String, trailing: AnyView? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 10) {
            BrandMark()
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(1.0)
                Text(subtitle)
                    .font(.system(size: 8, weight: .medium))
                    .tracking(2.2)
                    .foregroundColor(Color.isleMutedLight)
            }
            Spacer()
            if let trailing { trailing }
        }
    }
}

struct StreakPill: View {
    let days: Int
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.isleCoral)
            Text("\(days)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Color.isleInkSoft)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.islePaper.opacity(0.7)))
        .overlay(Capsule().stroke(Color.isleLine, lineWidth: 1))
    }
}

struct IconCircleButton: View {
    let systemName: String
    var tint: Color = .isleInkSoft
    var background: Color = .islePaper.opacity(0.7)
    var size: CGFloat = 38
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundColor(tint)
                .frame(width: size, height: size)
                .background(Circle().fill(background))
                .overlay(Circle().stroke(Color.isleLine, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct ProgressRing: View {
    var progress: Double
    var size: CGFloat = 82
    var lineWidth: CGFloat = 6
    var tint: Color = .isleLime
    var track: Color = .white.opacity(0.13)
    var textColor: Color = .isleCream
    var label: String = "今日"

    var body: some View {
        ZStack {
            Circle()
                .stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.004, min(progress, 1)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.system(size: size * 0.235, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .minimumScaleFactor(0.7)
                Text(label)
                    .font(.system(size: max(CGFloat(7), size * 0.09), weight: .medium))
                    .foregroundColor(textColor.opacity(0.55))
            }
        }
        .frame(width: size, height: size)
        .animation(.easeOut(duration: 0.55), value: progress)
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var action: (() -> Void)? = nil

    init(title: String, trailing: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.trailing = trailing
        self.action = action
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.isleInk)
            Spacer()
            if let trailing {
                if let action {
                    Button(action: action) {
                        HStack(spacing: 2) {
                            Text(trailing)
                            Image(systemName: "chevron.right").font(.system(size: 9, weight: .bold))
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.isleGreenSoft)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(trailing)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.isleMuted)
                }
            }
        }
        .padding(.horizontal, 2)
    }
}

struct AccuracyBadge: View {
    let id: String
    @EnvironmentObject private var store: WordStore

    var body: some View {
        let stat = store.stat(id)
        let acc = stat.accuracy
        Text(stat.seen == 0 ? "新" : "\(acc ?? 0)%")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(background)
            )
    }

    private var color: Color {
        let acc = store.accuracy(id)
        if acc == nil { return Color.isleMuted }
        if acc! >= 80 { return Color.isleGreenSoft }
        if acc! >= 60 { return Color.isleGold }
        return Color.isleCoral
    }

    private var background: Color {
        let acc = store.accuracy(id)
        if acc == nil { return Color.isleInk.opacity(0.05) }
        if acc! >= 80 { return Color.isleGreen.opacity(0.08) }
        if acc! >= 60 { return Color.isleGold.opacity(0.12) }
        return Color.isleCoralSoft
    }
}

struct PosChip: View {
    let pos: String
    var body: some View {
        Text(pos.hasSuffix(".") ? pos : pos + ".")
            .font(.system(size: 11, weight: .medium, design: .serif))
            .italic()
            .foregroundColor(Color.isleGreenSoft)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.isleGreen.opacity(0.07)))
    }
}

struct IslePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(Color.isleCream)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(Color.isleGreen)
            )
            .shadow(color: Color.isleGreen.opacity(0.22), radius: 10, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct IsleSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color.isleGreenSoft)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.islePaper.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.isleLineStrong, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct IsleWrongButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(Color.isleCoral)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .fill(Color.isleCoralSoft)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(Color.isleCoral.opacity(0.13), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
