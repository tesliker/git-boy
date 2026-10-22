import Foundation
@main struct Test {
 static func main() throws {
    func check(_ expression: @autoclosure () throws -> Bool) throws { let value = try expression(); assert(value) }
    let fm = FileManager.default
    let dir = fm.temporaryDirectory.appendingPathComponent("harbor-test-" + UUID().uuidString)
    try fm.createDirectory(at: dir, withIntermediateDirectories: true); defer { try? fm.removeItem(at: dir) }
    let root = dir.path
    _ = try Git.run(root,["init","-b","master"])
    _ = try Git.run(root,["config","user.name","Harbor Test"]); _ = try Git.run(root,["config","user.email","test@example.invalid"])
    func write(_ name:String,_ text:String) throws { try text.write(to:dir.appendingPathComponent(name),atomically:true,encoding:.utf8) }
    try write("file.txt","base\n"); _ = try Git.run(root,["add","--","file.txt"]); _ = try Git.run(root,["commit","-m","base"])
    let base = try Git.run(root,["rev-parse","HEAD"]).trimmingCharacters(in:.whitespacesAndNewlines)
    try write("space file\nname.txt","new\n"); try write("file.txt","edited\n")
    var s = try Git.snapshot(root,base:nil)
    try check(s.changes.count == 2); try check(s.changes.contains { $0.path == "space file\nname.txt" })
    try check(s.changes.first { $0.path == "file.txt" }?.kind == "Modified")
    try check(s.changes.first { $0.path == "space file\nname.txt" }?.kind == "Added")
    try check(Change(path:"deleted",index:" ",work:"D",original:nil).kind == "Deleted")
    try check(Change(path:"deleted",index:"D",work:" ",original:nil).kind == "Deleted")
    try check(Change(path:"conflict",index:"D",work:"U",original:nil).kind == "Conflict")
    let fingerprint = s.fingerprint
    try write("file.txt","edited again\n"); s = try Git.snapshot(root,base:nil); try check(s.fingerprint != fingerprint)
    let change = s.changes.first { $0.path == "file.txt" }!
    try check(try Git.diff(root,change:change,base:nil,staged:false).contains("+edited again"))
    _ = try Git.run(root,["add","--","file.txt"])
    try check(try Git.diff(root,change:change,base:nil,staged:true).contains("+edited again"))
    _ = try Git.run(root,["commit","-m","edit"])
    try check(try Git.snapshot(root,base:base).changes.count == 1)
    _ = try Git.run(root,["mv","file.txt","renamed file.txt"])
    s = try Git.snapshot(root,base:nil); try check(s.changes.contains { $0.path == "renamed file.txt" && $0.original == "file.txt" })
    try check(s.changes.first { $0.original == "file.txt" }?.kind == "Renamed")
    _ = try Git.run(root,["commit","-m","rename"])
    _ = try Git.run(root,["switch","-c","other"]); try write("renamed file.txt","theirs\n"); _ = try Git.run(root,["commit","-am","theirs"])
    _ = try Git.run(root,["switch","master"]); try write("renamed file.txt","ours\n"); _ = try Git.run(root,["commit","-am","ours"])
    _ = try? Git.run(root,["merge","other"])
    s = try Git.snapshot(root,base:nil); try check(s.changes.contains { $0.conflict })
    try check(try Git.run(root,["show",":2:renamed file.txt"]) == "ours\n")
    try check(try Git.run(root,["show",":3:renamed file.txt"]) == "theirs\n")
    let url = ReviewLink.make(repo:root,base:base,file:"space & file.txt",head:s.head,project:"https://agfirst.wf.lytho.us/projects/123",line:12)
    let link = try ReviewLink(url); try check(link.file == "space & file.txt" && link.line == 12 && link.repo == root)
    do { _ = try ReviewLink(URL(string:"gitboy://push?repo=/tmp")!); fatalError("accepted write link") } catch {}
    do { try Git.validateRef(root,"--help"); fatalError("accepted option ref") } catch {}
    print("PASS: status, unusual paths, freshness, staged/unstaged diff, branch comparison, rename, real merge conflict, conflict sides, deep-link round trip, unsafe link/ref rejection")
 }
}
