import SwiftUI

enum TourTarget: Hashable { case repository, modes, files, code, dpad, actions, review, ai, links }
struct TourAnchors: PreferenceKey {
    static var defaultValue: [TourTarget: Anchor<CGRect>] = [:]
    static func reduce(value: inout [TourTarget: Anchor<CGRect>], nextValue: () -> [TourTarget: Anchor<CGRect>]) { value.merge(nextValue(), uniquingKeysWith: { _, new in new }) }
}
extension View {
    func tourTarget(_ target: TourTarget) -> some View { transformAnchorPreference(key: TourAnchors.self, value: .bounds) { values, anchor in values[target] = anchor } }
}

struct SpotlightTour: View {
    @EnvironmentObject var s: Store
    let anchors: [TourTarget: Anchor<CGRect>]
    @State private var page = 0
    private let steps: [(TourTarget, String, String)] = [
        (.repository, "1. Open your repository", "Choose REPOSITORY to open a Git folder or return to a recent one. You can finish this tour before opening anything."),
        (.modes, "2. Choose what to inspect", "Review shows file changes. History shows commits; Branches shows branches. Compare with a branch or commit to review committed work. Working changes returns to uncommitted edits."),
        (.files, "3. Choose a changed file", "Green + means added, pink − means deleted, blue ~ means modified, and amber ! means conflict. Click a filename to read it. A checkmark means you already marked it reviewed."),
        (.code, "4. Read the code", "Green + lines are additions; pink − lines are removals. Working file and Staged for commit show different sets of edits. Highlight a section before asking AI. For conflicts, compare both versions, edit the resolution, save, then stage."),
        (.dpad, "5. Move through your review", "Up and down select the previous or next file. Left opens History; right returns to Review. Clicking files and tabs works too."),
        (.actions, "6. Git actions and refresh", "GIT ACTIONS opens staging, commits, fetch, pull, and push. REFRESH reloads the repository. Reading files and marking them reviewed does not change your code."),
        (.review, "7. A marks your reading progress", "After reading a file, press A / REVIEW to mark it reviewed. Press again to mark it unread. This saves your place; committing and releasing are separate actions."),
        (.ai, "8. B prepares your AI question", "ASK AI opens a preview of the exact prompt and code. Add your question, copy it, then paste into Codex or ChatGPT. Highlighted code is included. Nothing is sent automatically."),
        (.links, "9. Return here when you need to", "HELP restarts this walkthrough. REVIEW LINK copies a link to this repository, comparison, and file on this Mac. It does not upload code or share your checkout with other computers.")
    ]
    var body: some View {
        GeometryReader { proxy in
            let fullTarget = anchors[steps[page].0].map { proxy[$0].insetBy(dx: -7, dy: -7) } ?? CGRect(x: 40, y: 40, width: proxy.size.width-80, height: 70)
            let target = steps[page].0 == .code ? CGRect(x:fullTarget.minX,y:fullTarget.minY,width:fullTarget.width,height:min(fullTarget.height,max(120,proxy.size.height-fullTarget.minY-390))) : fullTarget
            let cardWidth = min(CGFloat(430), proxy.size.width-48)
            let cardHeight: CGFloat = 330
            let below = target.maxY + 20 + cardHeight < proxy.size.height-16
            let above = target.minY - 20 - cardHeight > 16
            let beside = !below && !above
            let cardX = beside ? (target.midX < proxy.size.width/2 ? proxy.size.width-cardWidth/2-24 : cardWidth/2+24) : min(max(target.midX,cardWidth/2+24),proxy.size.width-cardWidth/2-24)
            let cardY = below ? target.maxY+20+cardHeight/2 : above ? target.minY-20-cardHeight/2 : proxy.size.height/2
            ZStack(alignment: .topLeading) {
                Path { path in
                    path.addRect(CGRect(origin:.zero,size:proxy.size))
                    path.addRoundedRect(in:target,cornerSize:CGSize(width:12,height:12))
                }.fill(Color.black.opacity(0.72),style:FillStyle(eoFill:true)).allowsHitTesting(false)
                // Capture clicks even inside the clear spotlight; the tour never triggers Git operations.
                Color.clear.contentShape(Rectangle()).onTapGesture {}.accessibilityHidden(true)
                RoundedRectangle(cornerRadius:12).stroke(Color(red:0.96,green:0.77,blue:0.36),lineWidth:3)
                    .frame(width:target.width,height:target.height).position(x:target.midX,y:target.midY).allowsHitTesting(false)
                VStack(alignment:.leading,spacing:14) {
                    HStack { Text("GIT BOY · QUICK TOUR").font(.caption.bold()).tracking(1);Spacer();Text("\(page+1) / \(steps.count)").font(.caption.monospacedDigit()) }
                    Text(steps[page].1).font(.title2.bold()).fixedSize(horizontal:false,vertical:true)
                    Text(steps[page].2).font(.system(size:15)).lineSpacing(4).fixedSize(horizontal:false,vertical:true)
                    if page == steps.count-1 { Button("Open safe conflict practice…") {s.openConflictDemo();UserDefaults.standard.set(true,forKey:"hasSeenGuideV2")} .font(.callout) }
                    Spacer(minLength:0)
                    HStack {
                        Button("Close") { finish() }.keyboardShortcut(.cancelAction)
                        Spacer()
                        if page > 0 {Button("Back") {page -= 1}}
                        Button(page == steps.count-1 ? "Done" : "Next") {if page == steps.count-1 {finish()} else {page += 1}}.buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                    }
                    Text("Controls are paused during the tour. Open HELP to return.").font(.caption).foregroundStyle(.secondary)
                }.padding(22).frame(width:cardWidth,height:cardHeight).background(Color(red:0.91,green:0.91,blue:0.86),in:RoundedRectangle(cornerRadius:16))
                    .foregroundStyle(Handheld.ink).tint(Handheld.ink).shadow(color:.black.opacity(0.4),radius:18,y:8).position(x:cardX,y:cardY)
            }.frame(width:proxy.size.width,height:proxy.size.height)
        }.onAppear { s.tab="Review"; DispatchQueue.main.async { NSApp.keyWindow?.makeFirstResponder(nil) } }.accessibilityElement(children:.contain)
    }
    private func finish() {UserDefaults.standard.set(true,forKey:"hasSeenGuideV2");s.showGuide=false}
}

struct AIPromptPanel: View {
    @EnvironmentObject var s: Store
    @State private var intent = "Review these changes"
    @State private var question = ""
    @State private var copied = false
    var body: some View {
        VStack(alignment:.leading,spacing:12) {
            HStack { Text("Ask AI about this code").font(.title3.bold());Spacer();Button("Done") {s.showAI=false} }
            Text("Prepare a prompt for Codex or ChatGPT. No AI runs here and no code is sent automatically.").font(.callout).foregroundStyle(.secondary)
            Label(s.selectedCode.isEmpty ? "Includes the displayed diff or conflict versions" : "Includes the lines you highlighted",systemImage:s.selectedCode.isEmpty ? "doc.text" : "text.cursor").font(.callout)
            Picker("Help me",selection:$intent) { ForEach(["Review these changes","Explain this code","Help resolve this conflict"],id:\.self) {Text($0).tag($0)} }.onChange(of:intent) {_,_ in regenerate()}
            TextField("Optional: what do you want to understand?",text:$question).textFieldStyle(.roundedBorder).onChange(of:question) {_,_ in regenerate()}
            Text("THIS IS WHAT WILL BE COPIED").font(.caption.bold()).foregroundStyle(.secondary)
            ScrollView { Text(s.aiPrompt).font(.system(size:12,design:.monospaced)).textSelection(.enabled).frame(maxWidth:.infinity,alignment:.leading).padding(12) }.frame(height:210).background(Color(nsColor:.textBackgroundColor),in:RoundedRectangle(cornerRadius:8))
            HStack {
                Button("Copy prompt for Codex / ChatGPT") {s.copyPreparedPrompt();copied=true}.buttonStyle(.borderedProminent)
                Spacer()
                if copied {Label("Copied",systemImage:"checkmark.circle.fill").foregroundStyle(.green)}
            }
            Text(copied ? "Next: paste into your Codex or ChatGPT conversation and send it there." : "You can review all of the text above before copying anything.").font(.callout).foregroundStyle(copied ? .primary : .secondary)
        }.padding(22).frame(width:590).onAppear {intent = s.change?.conflict == true ? "Help resolve this conflict" : s.selectedCode.isEmpty ? "Review these changes" : "Explain this code";regenerate()}
    }
    private func regenerate() { copied=false;s.prepareAIPrompt(intent:intent,question:question) }
}
