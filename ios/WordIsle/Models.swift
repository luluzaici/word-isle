import Foundation
import SwiftUI

// MARK: - Data model

struct Sense: Codable, Hashable, Identifiable {
    var id: String { "\(pos)|\(def)" }
    let pos: String
    let def: String

    var displayPos: String {
        let p = pos.trimmingCharacters(in: .whitespaces)
        return p.isEmpty ? "" : (p.hasSuffix(".") ? p : p + ".")
    }
}

struct Example: Codable, Hashable, Identifiable {
    var id: String { en }
    let en: String
    let zh: String
}

struct Word: Codable, Hashable, Identifiable {
    let id: String
    let word: String
    let phonetic: String
    let senses: [Sense]
    let note: String
    let examples: [Example]
    let lesson: String
    let lessonTitle: String
    let num: Int
    let page: Int
    let letter: String

    var primary: String {
        guard let s = senses.first else { return "" }
        return (s.pos.isEmpty ? "" : s.displayPos + " ") + s.def
    }

    var phoneticDisplay: String {
        phonetic.isEmpty ? "" : "/\(phonetic)/"
    }

    var searchBlob: String {
        (word + " " + phonetic + " " + senses.map { $0.def }.joined(separator: " ")).lowercased()
    }
}

struct Progress: Codable, Hashable {
    var seen: Int = 0
    var correct: Int = 0
    var lastResult: Bool? = nil
    var lastSeen: Double = 0

    var accuracy: Int? {
        guard seen > 0 else { return nil }
        return Int((Double(correct) / Double(seen) * 100).rounded())
    }
}

struct DayStat: Codable, Hashable {
    var seen: Int = 0
    var correct: Int = 0
    var accuracy: Int {
        seen == 0 ? 0 : Int((Double(correct) / Double(seen) * 100).rounded())
    }
}

struct AppSettings: Codable, Equatable {
    var size: Int = 20
    var goal: Int = 20
    var autoSpeak: Bool = false
}

enum StudyMode: String, CaseIterable, Identifiable {
    case mixed, new, review, wrong, single
    var id: String { rawValue }

    var title: String {
        switch self {
        case .mixed: return "混合学习"
        case .new: return "新词"
        case .review: return "复习"
        case .wrong: return "错词"
        case .single: return "单词复习"
        }
    }
}

struct StudyLaunch: Identifiable {
    let id = UUID()
    let mode: StudyMode
    let words: [Word]
}

struct StudyResult: Identifiable {
    let id = UUID()
    let word: Word
    let correct: Bool
}

struct WeekDay: Identifiable {
    var id: String { key }
    let key: String
    let label: String
    let date: Int
    let seen: Int
    let correct: Int
    let isToday: Bool
}

// MARK: - Store

final class WordStore: ObservableObject {
    @Published private(set) var words: [Word] = []
    @Published var progress: [String: Progress] = [:]
    @Published var starred: Set<String> = []
    @Published var history: [String: DayStat] = [:]
    @Published var settings = AppSettings()
    @Published private(set) var loaded = false

    private let storageKey = "wordisle.native.v1"

    init() {
        loadWords()
        loadProgress()
    }

    // MARK: Loading

    private func loadWords() {
        guard let url = Bundle.main.url(forResource: "vocabulary", withExtension: "json") else {
            words = []
            loaded = true
            return
        }
        do {
            let data = try Data(contentsOf: url)
            words = try JSONDecoder().decode([Word].self, from: data)
                .filter { !$0.senses.isEmpty }
                .sorted { $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending }
        } catch {
            print("WordIsle: failed to decode vocabulary — \(error)")
            words = []
        }
        loaded = true
    }

    private struct Saved: Codable {
        var progress: [String: Progress]
        var starred: [String]
        var history: [String: DayStat]
        var settings: AppSettings
    }

    private func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode(Saved.self, from: data) else { return }
        progress = saved.progress
        starred = Set(saved.starred)
        history = saved.history
        settings = saved.settings
    }

    func save() {
        let saved = Saved(progress: progress, starred: Array(starred), history: history, settings: settings)
        if let data = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    // MARK: Lookups

    func word(id: String) -> Word? { words.first { $0.id == id } }

    func stat(_ id: String) -> Progress { progress[id] ?? Progress() }

    func accuracy(_ id: String) -> Int? { stat(id).accuracy }

    func isMastered(_ id: String) -> Bool {
        let s = stat(id)
        return s.seen >= 3 && (s.accuracy ?? 0) >= 80
    }

    var uniqueSeen: Int { words.reduce(0) { $0 + (stat($1.id).seen > 0 ? 1 : 0) } }
    var masteredCount: Int { words.reduce(0) { $0 + (isMastered($1.id) ? 1 : 0) } }
    var learningCount: Int { max(0, uniqueSeen - masteredCount) }
    var newCount: Int { max(0, words.count - uniqueSeen) }
    var wrongCount: Int {
        words.reduce(0) { partial, w in
            let s = stat(w.id)
            guard s.seen > 0 else { return partial }
            return partial + ((s.lastResult == false || (s.accuracy ?? 100) < 60) ? 1 : 0)
        }
    }

    var totalSeen: Int { progress.values.reduce(0) { $0 + $1.seen } }
    var totalCorrect: Int { progress.values.reduce(0) { $0 + $1.correct } }
    var overallAccuracy: Int {
        totalSeen == 0 ? 0 : Int((Double(totalCorrect) / Double(totalSeen) * 100).rounded())
    }

    func today() -> DayStat { history[Date().dayKey] ?? DayStat() }
    var streak: Int { currentStreak() }
    var studiedDays: Int { history.values.filter { $0.seen > 0 }.count }

    func weakWords(limit: Int = 5) -> [Word] {
        words.filter { stat($0.id).seen > 0 }
            .sorted { a, b in
                let sa = stat(a.id), sb = stat(b.id)
                let aa = sa.accuracy ?? 0, ab = sb.accuracy ?? 0
                if aa == ab { return sa.lastSeen < sb.lastSeen }
                return aa < ab
            }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: Recording

    func record(_ word: Word, correct: Bool) {
        var p = progress[word.id] ?? Progress()
        p.seen += 1
        p.correct += correct ? 1 : 0
        p.lastResult = correct
        p.lastSeen = Date().timeIntervalSince1970
        progress[word.id] = p

        let key = Date().dayKey
        var day = history[key] ?? DayStat()
        day.seen += 1
        day.correct += correct ? 1 : 0
        history[key] = day
        save()
    }

    func toggleStar(_ id: String) {
        if starred.contains(id) { starred.remove(id) } else { starred.insert(id) }
        save()
    }

    func resetAll() {
        progress = [:]
        starred = []
        history = [:]
        save()
    }

    // MARK: Queue building

    func makeQueue(mode: StudyMode, fixed: [Word] = []) -> [Word] {
        if !fixed.isEmpty { return fixed }
        let size = max(5, min(settings.size, 50))
        let newWords = words.filter { stat($0.id).seen == 0 }
        let seenWords = words.filter { stat($0.id).seen > 0 }
        let review = seenWords.filter { !isMastered($0.id) }
        let wrong = seenWords.filter {
            let s = stat($0.id)
            return s.lastResult == false || (s.accuracy ?? 100) < 60
        }

        var queue: [Word] = []
        switch mode {
        case .mixed:
            let wantNew = max(1, Int((Double(size) * 0.6).rounded()))
            queue = Array(newWords.shuffled().prefix(wantNew))
            if queue.count < size {
                queue += Array(review.sorted { weakScore($0) > weakScore($1) }.shuffled().prefix(size - queue.count))
            }
            if queue.count < size {
                queue += Array(seenWords.filter { w in !queue.contains(w) }.shuffled().prefix(size - queue.count))
            }
        case .new:
            queue = Array(newWords.shuffled().prefix(size))
            if queue.count < size {
                queue += Array(seenWords.filter { w in !queue.contains(w) }.shuffled().prefix(size - queue.count))
            }
        case .review, .wrong:
            let pool = mode == .wrong ? wrong : review
            let sorted = pool.sorted { weakScore($0) > weakScore($1) }
            queue = Array(sorted.prefix(max(size * 3, size)).shuffled().prefix(size))
            if queue.count < size {
                queue += Array(newWords.filter { w in !queue.contains(w) }.shuffled().prefix(size - queue.count))
            }
        case .single:
            queue = Array(seenWords.shuffled().prefix(1))
        }
        if queue.isEmpty { queue = Array(words.shuffled().prefix(size)) }
        return Array(queue.prefix(size))
    }

    private func weakScore(_ w: Word) -> Double {
        let s = stat(w.id)
        let acc = Double(s.accuracy ?? 0) / 100.0
        let days = s.lastSeen > 0 ? (Date().timeIntervalSince1970 - s.lastSeen) / 86400 : 30
        return (1 - acc) * 100 + min(days, 30) * 1.3 + (s.lastResult == false ? 18 : 0)
    }

    // MARK: Dates & charts

    private func currentStreak() -> Int {
        let cal = Calendar.current
        var date = cal.startOfDay(for: Date())
        if (history[date.dayKey]?.seen ?? 0) == 0 {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = yesterday
        }
        var count = 0
        for _ in 0..<4000 {
            if (history[date.dayKey]?.seen ?? 0) > 0 {
                count += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: date) else { break }
                date = prev
            } else {
                break
            }
        }
        return count
    }

    func week(days: Int = 7) -> [WeekDay] {
        let cal = Calendar.current
        let names = ["日", "一", "二", "三", "四", "五", "六"]
        return (0..<days).reversed().map { offset in
            let date = cal.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let key = date.dayKey
            let stat = history[key] ?? DayStat()
            return WeekDay(
                key: key,
                label: "周" + names[cal.component(.weekday, from: date) - 1],
                date: cal.component(.day, from: date),
                seen: stat.seen,
                correct: stat.correct,
                isToday: offset == 0
            )
        }
    }

    func lastSeenText(_ id: String) -> String {
        let s = stat(id)
        guard s.lastSeen > 0 else { return "还没学" }
        let date = Date(timeIntervalSince1970: s.lastSeen)
        return "\(Calendar.current.component(.month, from: date))月\(Calendar.current.component(.day, from: date))日"
    }
}

extension Date {
    var dayKey: String {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }
}

extension Int {
    var percentText: String { "\(self)%" }
}
