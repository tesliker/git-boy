import SwiftUI
import AppKit

@MainActor final class Store: ObservableObject {
    @Published var repos: [String] = UserDefaults.standard.stringArray(forKey: "repos") ?? []
    @Published var repo = ""; @Published var base = ""; @Published var snapshot = Snapshot()
    @Published var selected: String?; @Published var diff = ""; @Published var busy = false
    @Published var message = "Open a repository or a review link to begin."
    @Published var staged = false; @Published var commitMessage = ""; @Published var branchName = ""
    @Published var reviewed: Set<String> = []; @Published var expectedHead: String?; @Published var project: String?
    @Published var conflictSide = "Result"; @Published var conflictResult = ""; @Published var conflictOriginal = ""; @Published var conflictVersions: [String: String] = [:]
    @Published var targetPath: String?; @Published var targetLine: Int?; @Published var tab = "Review"; @Published var confirmation: String?
    @Published var showGuide = false; @Published var showAI = false
    @Published var selectedCode = ""; @Published var aiPrompt = ""; @Published var lastReviewLink = ""
    @Published var diffLoading = false
    private struct ConflictDraft { let original: String; let result: String }
    private var conflictOwner: String?
    private var conflictDrafts: [String: ConflictDraft] = [:]
    var diffRequest = 0
    var generation = 0
    var change: Change? { snapshot.changes.first { $0.path == selected } }
    var reviewMode: Bool { !base.isEmpty }
    func add(_ path: String) {
        if !repos.contains(path) { repos.append(path); UserDefaults.standard.set(repos, forKey: "repos") }
        repo = path; base = ""; expectedHead = nil; project = nil; reviewed = []; selected = nil; refresh()
    }
    func choose() { let p = NSOpenPanel(); p.canChooseDirectories = true; p.canChooseFiles = false; if p.runModal() == .OK, let url = p.url { add(url.path) } }
    func refresh() {
        guard !repo.isEmpty, !busy else { return }; busy = true; generation += 1
        let token = generation; let root = repo; let ref = base.isEmpty ? nil : base
        Task {
            let result = await Task.detached { Result { try Git.snapshot(root, base: ref) } }.value
            guard token == generation else { return }; busy = false
            switch result {
            case .success(let s):
                reviewed = Set(UserDefaults.standard.stringArray(forKey: "reviewed." + s.fingerprint) ?? [])
                snapshot = s; repo = s.root
                if selected == nil || !s.changes.contains(where: { $0.path == selected }) { selected = s.changes.first?.path }
                message = expectedHead != nil && expectedHead != s.head ? "This link targets another commit. Current HEAD differs; review is not the original snapshot." : (s.mergeInProgress && !s.changes.contains(where: \.conflict) ? "Merge conflicts resolved. Review the staged resolution, then commit when ready." : "\(s.changes.count) changed files · \(s.changes.filter(\.conflict).count) conflicts")
                loadDiff()
            case .failure(let e): snapshot = Snapshot(); diff = ""; message = e.localizedDescription
            }
        }
    }
    func loadDiff(autoSelectSide: Bool = true) {
        if let owner=conflictOwner, conflictResult != conflictOriginal {conflictDrafts[owner]=ConflictDraft(original:conflictOriginal,result:conflictResult)}
        diffRequest += 1; let request = diffRequest
        selectedCode = ""
        guard let change else { diff = ""; diffLoading = false; return }
        if autoSelectSide && !reviewMode {
            if change.staged && change.work == " " { staged = true }
            else if !change.staged { staged = false }
        }
        diff = ""; diffLoading = true
        if change.conflict { loadConflict(change) }
        let root = repo, ref = base.isEmpty ? nil : base, isStaged = staged, path = change.path
        Task {
            let result = await Task.detached { Result { try Git.diff(root, change: change, base: ref, staged: isStaged) } }.value
            guard request == diffRequest, root == repo, ref == (base.isEmpty ? nil : base), path == selected, isStaged == staged else { return }
            diffLoading = false
            switch result { case .success(let text): diff=text; case .failure(let error): diff="Unable to load diff: " + error.localizedDescription }
        }
    }
    func loadConflict(_ c: Change) {
        let root = repo, path = c.path
        Task {
            let versions = await Task.detached { () -> [String: String] in
                var v: [String: String] = [:]
                for (name, stage) in [("Base", 1), ("Ours", 2), ("Theirs", 3)] { v[name] = (try? Git.run(root, ["show", ":\(stage):\(path)"])) ?? "No file in this stage" }
                v["Result"] = (try? String(contentsOf: URL(fileURLWithPath: root).appendingPathComponent(path), encoding: .utf8)) ?? ""
                return v
            }.value
            guard repo == root, selected == path else { return }
            let owner=root + "\0" + path
            if let current=conflictOwner, conflictResult != conflictOriginal {conflictDrafts[current]=ConflictDraft(original:conflictOriginal,result:conflictResult)}
            conflictVersions = versions; conflictOwner=owner
            if let draft=conflictDrafts[owner] {conflictOriginal=draft.original;conflictResult=draft.result}
            else {conflictOriginal=versions["Result"] ?? "";conflictResult=conflictOriginal}
        }
    }
    @discardableResult func saveResolution() -> Bool {
        guard let c = change, c.conflict else { return false }
        do {
            let url = URL(fileURLWithPath: repo).appendingPathComponent(c.path)
            let resolved = url.resolvingSymlinksInPath().path
            let safeRoot = URL(fileURLWithPath: repo).resolvingSymlinksInPath().path + "/"
            guard resolved.hasPrefix(safeRoot), (try FileManager.default.attributesOfItem(atPath: url.path)[.type] as? FileAttributeType) == .typeRegular else { throw GitError(message: "Only regular files inside this repository can be edited.") }
            guard try String(contentsOf: url, encoding: .utf8) == conflictOriginal else { throw GitError(message: "File changed outside Git Boy. Refresh before saving.") }
            guard !conflictResult.components(separatedBy: "\n").contains(where: { $0.hasPrefix("<<<<<<< ") || $0.hasPrefix("=======") || $0.hasPrefix(">>>>>>> ") }) else { throw GitError(message: "Remove conflict markers before saving the resolution.") }
            let backup = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/GitBoy/ConflictBackups")
            try FileManager.default.createDirectory(at: backup, withIntermediateDirectories: true)
            try Data(conflictOriginal.utf8).write(to: backup.appendingPathComponent(UUID().uuidString + ".txt"), options: .atomic)
            try conflictResult.write(to: url, atomically: true, encoding: .utf8)
            conflictOriginal=conflictResult
            if let owner=conflictOwner {conflictDrafts.removeValue(forKey:owner)}
            reviewed.remove(c.path); message = "Resolution saved; original backed up. Inspect, then stage to mark resolved."; refresh(); return true
        } catch { message = error.localizedDescription; return false }
    }
    func action(_ args: [String], label: String) {
        guard !busy else { return }
        if args.first == "add", let c = change, c.conflict {
            let text = (try? String(contentsOf: URL(fileURLWithPath: repo).appendingPathComponent(c.path), encoding: .utf8)) ?? ""
            if text.components(separatedBy: "\n").contains(where: { $0.hasPrefix("<<<<<<< ") || $0.hasPrefix("=======") || $0.hasPrefix(">>>>>>> ") }) { message = "Resolve conflict markers before staging."; return }
        }
        busy = true; let root = repo
        Task {
            let result = await Task.detached { Result { try Git.run(root, args) } }.value
            busy = false
            switch result { case .success(let out): message = "\(label) completed. \(out)"; refresh(); case .failure(let e): message = e.localizedDescription }
        }
    }
    func receive(_ url: URL) {
        guard !busy else { message = "Wait for the current Git operation, then open the link again."; return }
        do {
            let link = try ReviewLink(url); repo = link.repo; base = link.base ?? ""; selected = link.file
            expectedHead = link.head; project = link.project; targetLine = link.line; targetPath = link.file; reviewed = []; tab = "Review"
            if !repos.contains(repo) { repos.append(repo); UserDefaults.standard.set(repos, forKey: "repos") }
            refresh()
        } catch { message = error.localizedDescription }
    }
    func toggleReviewed() {
        guard let path = selected else { return }
        if reviewed.contains(path) { reviewed.remove(path) } else { reviewed.insert(path) }
        UserDefaults.standard.set(Array(reviewed), forKey: "reviewed." + snapshot.fingerprint)
    }
    func copyLink() {
        let url = ReviewLink.make(repo: repo, base: base.isEmpty ? nil : base, file: selected, head: snapshot.head, project: project, line: selected == targetPath ? targetLine : nil)
        NSPasteboard.general.clearContents(); var browser = URLComponents(url: url, resolvingAgainstBaseURL: false)!; browser.scheme = "http"; browser.host = "127.0.0.1"; browser.port = 47831; browser.path = "/review"
        lastReviewLink = browser.url!.absoluteString
        NSPasteboard.general.setString(lastReviewLink, forType: .string); message = "Local review link copied — opens on this Mac."
    }
    func prepareAIPrompt(intent: String = "Review these changes", question: String = "") {
        let context: String
        if !selectedCode.isEmpty { context = "SELECTED DIFF EXCERPT\n" + selectedCode }
        else if change?.conflict == true {
            context = ["Base", "Ours", "Theirs"].map { "\($0.uppercased())\n" + (conflictVersions[$0] ?? "Not available") }.joined(separator: "\n\n") + "\n\nDRAFT RESOLUTION\n" + conflictResult
        } else { context = diff }
        let limited = String(context.prefix(60000))
        aiPrompt = "\(intent) in \(repo).\nBranch: \(snapshot.branch)\nHEAD: \(snapshot.head)\nComparison: \(base.isEmpty ? (staged ? "staged changes for the next commit" : "unstaged working-file changes") : base + "...HEAD")\nFile: \(selected ?? "No file selected")\n\n" + (question.isEmpty ? "" : "My question: " + question + "\n\n") + "Explain in plain language. Describe what the code does, why it changed, and any correctness, security, regression, or testing concerns. For a conflict, explain both sides before proposing a minimal resolution. Do not edit files, mark a review approved, commit, push, or deploy unless I ask. Return file and line references where possible.\n\n" + limited + (context.count > 60000 ? "\n\n[Excerpt limited to 60,000 characters; inspect the full file if needed.]" : "")
    }
    func copyPreparedPrompt() {
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(aiPrompt, forType: .string)
        message = "Prompt copied. Paste it into your Codex chat."
    }
    func openConflictDemo() {
        guard !busy else { return }; showGuide = false; busy = true
        Task {
            let result = await Task.detached { Result { try LearningDemo.create() } }.value
            busy = false
            switch result { case .success(let path): add(path); case .failure(let error): message = error.localizedDescription }
        }
    }
}
