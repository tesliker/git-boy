import Foundation

enum LearningDemo {
    static func create(in directory: URL? = nil) throws -> String {
        let folder = directory ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/GitBoy/Learning/Conflict practice " + UUID().uuidString.prefix(8))
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let root = folder.path
        func git(_ args: [String]) throws { _ = try Git.run(root, args) }
        func write(_ text: String) throws { try text.write(to: folder.appendingPathComponent("navigation.txt"), atomically: true, encoding: .utf8) }
        try git(["init", "-b", "master"])
        try git(["config", "commit.gpgsign", "false"]); try git(["config", "user.name", "Git Boy Practice"]); try git(["config", "user.email", "practice@example.invalid"])
        try write("Home\nCareers\nContact\n"); try git(["add", "--", "navigation.txt"]); try git(["-c", "core.hooksPath=/dev/null", "commit", "-m", "Original navigation"])
        try git(["switch", "-c", "incoming-label"]); try write("Home\nJoin Our Team\nContact\n"); try git(["-c", "core.hooksPath=/dev/null", "commit", "-am", "Incoming careers label"])
        try git(["switch", "master"]); try write("Home\nExplore Careers\nContact\n"); try git(["-c", "core.hooksPath=/dev/null", "commit", "-am", "Current careers label"])
        _ = try? Git.run(root, ["-c", "core.hooksPath=/dev/null", "merge", "incoming-label"])
        let state = try Git.snapshot(root, base: nil)
        guard state.changes.contains(where: \.conflict) else { throw GitError(message: "The practice conflict could not be prepared.") }
        return root
    }
}
