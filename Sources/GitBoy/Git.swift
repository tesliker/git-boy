import Foundation
import CryptoKit

struct GitError: LocalizedError { let message: String; var errorDescription: String? { message } }
struct Change: Identifiable, Hashable {
    let path: String; let index: String; let work: String; let original: String?
    var id: String { path }
    var conflict: Bool { ["DD", "AU", "UD", "UA", "DU", "AA", "UU"].contains(index + work) }
    var staged: Bool { index != " " && index != "?" }
    var kind: String {
        if conflict { return "Conflict" }
        if work == "D" || index == "D" { return "Deleted" }
        if index == "?" || index == "A" || work == "A" { return "Added" }
        if index == "R" || work == "R" { return "Renamed" }
        return "Modified"
    }
    var statusLabel: String {
        if conflict { return "Conflict" }; if index == "?" { return "New" }
        if staged && work != " " { return "Staged + edited" }
        return staged ? "Staged" : "Edited"
    }
}
struct Snapshot {
    var root = ""; var branch = ""; var changes: [Change] = []; var branches: [String] = []; var history = ""; var head = ""; var upstream = ""; var fingerprint = ""; var mergeInProgress = false
}
enum Git {
    static func run(_ root: String, _ args: [String]) throws -> String {
        let process = Process(); process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["--no-pager", "-C", root] + args
        var env = ProcessInfo.processInfo.environment
        env["GIT_TERMINAL_PROMPT"] = "0"; env["GIT_OPTIONAL_LOCKS"] = "0"; env["LC_ALL"] = "C"
        process.environment = env
        let output = Pipe(); process.standardOutput = output; process.standardError = output
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile(); process.waitUntilExit()
        let text = String(decoding: data, as: UTF8.self)
        guard process.terminationStatus == 0 else { throw GitError(message: text.isEmpty ? "Git exited with \(process.terminationStatus)" : text) }
        return text
    }
    static func parseStatus(_ text: String) -> [Change] {
        let parts = text.split(separator: "\0", omittingEmptySubsequences: true).map(String.init)
        var result: [Change] = []; var i = 0
        while i < parts.count {
            let row = parts[i]; i += 1
            guard row.count >= 4 else { continue }
            let codes = Array(row.prefix(2)); let path = String(row.dropFirst(3))
            var original: String? = nil
            if codes.contains("R") || codes.contains("C") { if i < parts.count { original = parts[i]; i += 1 } }
            result.append(Change(path: path, index: String(codes[0]), work: String(codes[1]), original: original))
        }
        return result
    }
    static func snapshot(_ root: String, base: String?) throws -> Snapshot {
        let realRoot = try run(root, ["rev-parse", "--show-toplevel"]).trimmingCharacters(in: .whitespacesAndNewlines)
        var s = Snapshot(); s.root = realRoot
        s.head = (try? run(realRoot, ["rev-parse", "HEAD"]).trimmingCharacters(in: .whitespacesAndNewlines)) ?? "Unborn"
        s.branch = (try? run(realRoot, ["symbolic-ref", "--short", "HEAD"]).trimmingCharacters(in: .whitespacesAndNewlines)) ?? "Detached HEAD"
        if let base, !base.isEmpty {
            try validateRef(realRoot, base)
            let names = try run(realRoot, ["diff", "--name-status", "-z", "--no-renames", "\(base)...HEAD", "--"]).split(separator: "\0").map(String.init)
            var i = 0
            while i + 1 < names.count { s.changes.append(Change(path: names[i+1], index: names[i], work: " ", original: nil)); i += 2 }
        } else { s.changes = parseStatus(try run(realRoot, ["status", "--porcelain=v1", "-z", "--untracked-files=all"])) }
        var digest = SHA256()
        digest.update(data: Data((s.head + (base ?? "working")).utf8))
        digest.update(data: Data((try run(realRoot, ["diff", "--no-ext-diff", "--no-textconv", "--binary", "--cached", "--"])).utf8))
        for c in s.changes {
            digest.update(data: Data((c.path + c.index + c.work).utf8))
            let url = URL(fileURLWithPath: realRoot).appendingPathComponent(c.path)
            if let handle = try? FileHandle(forReadingFrom: url) {
                while let data = try? handle.read(upToCount: 65536), !data.isEmpty { digest.update(data: data) }
                try? handle.close()
            }
        }
        s.fingerprint = digest.finalize().map { String(format: "%02x", $0) }.joined()
        s.branches = try run(realRoot, ["for-each-ref", "--format=%(refname:short)", "refs/heads"]).split(separator: "\n").map(String.init)
        s.history = (try? run(realRoot, ["log", "-40", "--date=short", "--pretty=format:%h  %ad  %s", "--decorate"])) ?? "No commits yet"
        s.mergeInProgress = (try? run(realRoot, ["rev-parse", "--verify", "MERGE_HEAD"])) != nil
        s.upstream = (try? run(realRoot, ["rev-list", "--left-right", "--count", "HEAD...@{upstream}"]).trimmingCharacters(in: .whitespacesAndNewlines)) ?? "No upstream"
        return s
    }
    static func validateRef(_ root: String, _ ref: String) throws {
        guard !ref.hasPrefix("-"), !ref.isEmpty else { throw GitError(message: "Invalid revision") }
        _ = try run(root, ["rev-parse", "--verify", "--end-of-options", "\(ref)^{commit}"])
    }
    static func diff(_ root: String, change: Change, base: String?, staged: Bool) throws -> String {
        if let base, !base.isEmpty { try validateRef(root, base); return try run(root, ["diff", "--no-ext-diff", "--no-textconv", "--no-color", "\(base)...HEAD", "--", change.path]) }
        if change.index == "?" {
            let url = URL(fileURLWithPath: root).appendingPathComponent(change.path)
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path), (attrs[.size] as? NSNumber)?.intValue ?? 0 <= 2_000_000 else { return "File too large for inline preview" }
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { return "Binary or unavailable file" }
            return "New file: \(change.path)\n" + text.split(separator: "\n", omittingEmptySubsequences: false).enumerated().map { "+ \($0.offset + 1)  \($0.element)" }.joined(separator: "\n")
        }
        return try run(root, ["diff", "--no-ext-diff", "--no-textconv", "--no-color"] + (staged ? ["--cached"] : []) + ["--", change.path])
    }
}
struct ReviewLink {
    let repo: String; let base: String?; let file: String?; let line: Int?; let head: String?; let project: String?
    init(_ url: URL) throws {
        guard ["gitboy", "githarbor"].contains(url.scheme ?? ""), url.host == "review", let c = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw GitError(message: "Unsupported review URL") }
        let items = c.queryItems ?? []
        func value(_ key: String) -> String? { items.first { $0.name == key }?.value }
        guard let repo = value("repo"), repo.hasPrefix("/") else { throw GitError(message: "Review link needs an absolute repository path") }
        self.repo = repo; self.base = value("base"); self.file = value("file"); self.line = value("line").flatMap(Int.init); self.head = value("head"); self.project = value("project")
    }
    static func make(repo: String, base: String?, file: String?, head: String?, project: String?, line: Int? = nil) -> URL {
        var c = URLComponents(); c.scheme = "gitboy"; c.host = "review"
        c.queryItems = [("repo", Optional(repo)), ("base", base), ("file", file), ("head", head), ("project", project), ("line", line.map(String.init))].compactMap { key, value in value.map { URLQueryItem(name: key, value: $0) } }
        return c.url!
    }
}
