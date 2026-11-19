import SwiftUI

enum LibraryFilter: String, CaseIterable, Identifiable {
    case all, new, review, wrong, mastered, starred

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "全部"
        case .new: return "未学习"
        case .review: return "需复习"
        case .wrong: return "错词"
        case .mastered: return "已掌握"
        case .starred: return "星标"
        }
    }
}

struct LibraryView: View {
    @EnvironmentObject private var store: WordStore
    var onOpenWord: (Word) -> Void

    @State private var query = ""
    @State private var filter: LibraryFilter = .all
    @State private var limit = 80

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BrandHeader(title: "词库", subtitle: "\(store.words.count) WORDS")
                    .padding(.bottom, 18)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("所有单词")
                            .font(.system(size: 28, weight: .bold))
                            .tracking(-0.5)
                            .foregroundColor(Color.isleInk)
                        Text("点击单词查看详细信息与正确率")
                            .font(.system(size: 11))
                            .foregroundColor(Color.isleMuted)
                    }
                    Spacer()
                    Text("\(filtered.count) 个")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color.isleMuted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color.islePaper.opacity(0.75)))
                        .overlay(Capsule().stroke(Color.isleLine, lineWidth: 1))
                }
                .padding(.bottom, 15)

                searchField
                    .padding(.bottom, 12)

                filterChips
                    .padding(.bottom, 13)

                LazyVStack(spacing: 0) {
                    ForEach(Array(filtered.prefix(limit).indices), id: \.self) { idx in
                        let word = filtered[idx]
                        WordRow(word: word, onOpen: { onOpenWord(word) })
                        if idx < min(limit, filtered.count) - 1 {
                            Divider().overlay(Color.isleLine)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.islePaper)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.isleLine, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                if filtered.isEmpty {
                    VStack(spacing: 7) {
                        Text("没有找到")
                            .font(.system(size: 21, design: .serif))
                            .foregroundColor(Color.isleInkSoft)
                        Text("试试更短的关键词，或换一个筛选条件。")
                            .font(.system(size: 11))
                            .foregroundColor(Color.isleMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 42)
                } else if filtered.count > limit {
                    Button {
                        limit += 80
                    } label: {
                        Text("再看一些")
                    }
                    .buttonStyle(IsleSecondaryButtonStyle())
                    .padding(.top, 16)
                }
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
        .onChange(of: query) { _ in limit = 80 }
        .onChange(of: filter) { _ in limit = 80 }
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.isleMutedLight)
            TextField("搜索单词或中文释义", text: $query)
                .font(.system(size: 15))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundColor(Color.isleInk)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color.isleMuted)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.isleInk.opacity(0.07)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.islePaper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.isleLine, lineWidth: 1)
        )
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(LibraryFilter.allCases) { item in
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) {
                            filter = item
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(item.title)
                            Text("\(count(for: item))")
                                .font(.system(size: 9, weight: .medium))
                                .opacity(0.65)
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(filter == item ? Color.isleCream : Color.isleMuted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(filter == item ? Color.isleGreen : Color.islePaper.opacity(0.65)))
                        .overlay(Capsule().stroke(filter == item ? Color.clear : Color.isleLine, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
            .padding(.vertical, 1)
        }
    }

    private var filtered: [Word] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return store.words.filter { word in
            guard match(word) else { return false }
            guard !q.isEmpty else { return true }
            return word.searchBlob.contains(q)
        }
    }

    private func match(_ word: Word) -> Bool {
        let stat = store.stat(word.id)
        switch filter {
        case .all: return true
        case .new: return stat.seen == 0
        case .review: return stat.seen > 0 && !store.isMastered(word.id)
        case .wrong:
            guard stat.seen > 0 else { return false }
            return stat.lastResult == false || (stat.accuracy ?? 100) < 60
        case .mastered: return store.isMastered(word.id)
        case .starred: return store.starred.contains(word.id)
        }
    }

    private func count(for item: LibraryFilter) -> Int {
        switch item {
        case .all: return store.words.count
        case .new: return store.newCount
        case .review: return max(0, store.uniqueSeen - store.masteredCount)
        case .wrong: return store.wrongCount
        case .mastered: return store.masteredCount
        case .starred: return store.starred.count
        }
    }
}

private struct WordRow: View {
    @EnvironmentObject private var store: WordStore
    let word: Word
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text(word.word)
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundColor(Color.isleInk)
                        .lineLimit(1)
                    Text(word.phoneticDisplay)
                        .font(.system(size: 9, design: .serif))
                        .foregroundColor(Color.isleMutedLight)
                        .lineLimit(1)
                }
                Text(word.primary)
                    .font(.system(size: 10.5))
                    .foregroundColor(Color.isleMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpen)

            AccuracyBadge(id: word.id)

            Button {
                store.toggleStar(word.id)
            } label: {
                Image(systemName: store.starred.contains(word.id) ? "star.fill" : "star")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(store.starred.contains(word.id) ? Color.isleGold : Color.isleMutedLight.opacity(0.7))
                    .frame(width: 29, height: 29)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(Color.islePaper)
    }
}
