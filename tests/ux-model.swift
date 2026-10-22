import Foundation

@main struct UXTests {
    @MainActor static func main() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("git-boy-ux-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        func check(_ result: Bool, _ label: String) { if !result { fatalError(label) } }
        let repo = try LearningDemo.create(in: root.appendingPathComponent("practice"))
        var snapshot = try Git.snapshot(repo, base: nil)
        check(snapshot.mergeInProgress, "Practice must be an active merge")
        check(snapshot.changes.contains(where: \.conflict), "Practice must have an unresolved conflict")
        let draftStore = Store(); draftStore.repo=repo; draftStore.refresh()
        for _ in 0..<600 { if !draftStore.busy && !draftStore.diffLoading && !draftStore.conflictOriginal.isEmpty {break};try await Task.sleep(nanoseconds:10_000_000) }
        draftStore.conflictResult += "\nAn unsaved draft note"
        let draft = draftStore.conflictResult
        draftStore.refresh()
        for _ in 0..<600 { if !draftStore.busy && !draftStore.diffLoading {break};try await Task.sleep(nanoseconds:10_000_000) }
        check(draftStore.conflictResult == draft, "Refreshing must preserve an unsaved conflict draft")
        try "Home\nExplore Careers & Join Our Team\nContact\n".write(to: URL(fileURLWithPath: repo).appendingPathComponent("navigation.txt"), atomically: true, encoding: .utf8)
        _ = try Git.run(repo, ["add", "--", "navigation.txt"])
        snapshot = try Git.snapshot(repo, base: nil)
        check(snapshot.mergeInProgress && !snapshot.changes.contains(where: \.conflict), "Saved/staged merge must remain distinguishable from an unresolved conflict")
        let store = Store(); store.repo = repo; store.refresh()
        for _ in 0..<600 {
            if !store.busy && !store.diffLoading { break }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        check(!store.busy && !store.diffLoading, "Repository load timed out")
        check(store.staged, "Staged-only file must automatically show the staged side")
        check(store.diff.contains("+Explore Careers & Join Our Team"), "Staged-only changes must be visible instead of blank")
        check(store.message.contains("Merge conflicts resolved"), "Explain that a staged resolution is already resolved")
        store.selectedCode = "+Explore Careers & Join Our Team"
        store.prepareAIPrompt(intent: "Explain this code", question: "Why this label?")
        check(store.aiPrompt.contains("SELECTED DIFF EXCERPT"), "Selection must be identified")
        check(store.aiPrompt.contains("Why this label?"), "Question must be included")
        check(store.aiPrompt.contains("staged changes for the next commit"), "AI must receive the correct comparison side")
        check(!store.aiPrompt.contains("@@"), "Selection-only prompt must not silently include the full diff")
        store.staged = false; store.loadDiff(autoSelectSide: false)
        for _ in 0..<600 { if !store.diffLoading { break }; try await Task.sleep(nanoseconds: 10_000_000) }
        check(!store.staged && store.diff.isEmpty, "An explicit empty-side choice must remain available for the explanatory empty state")
        let other = try LearningDemo.create(in: root.appendingPathComponent("other-practice"))
        let otherSnapshot = try Git.snapshot(other, base:nil)
        check(other != repo && otherSnapshot.changes.contains(where: \.conflict), "A fresh practice must not overwrite the already-resolved example")
        print("PASS: fresh practice isolation, real merge-state detection, staged-only auto-selection, selected-code AI prompt, user question, explicit empty-side choice, conflict draft preservation")
    }
}
