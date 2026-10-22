import SwiftUI
import AppKit

enum Handheld {
    static let shell = Color(red: 0.79, green: 0.79, blue: 0.75)
    static let plastic = Color(red: 0.65, green: 0.65, blue: 0.62)
    static let ink = Color(red: 0.13, green: 0.17, blue: 0.40)
    static let berry = Color(red: 0.55, green: 0.06, blue: 0.24)
    static let lcd = NSColor(red: 0.68, green: 0.74, blue: 0.37, alpha: 1)
    static let dark = NSColor(red: 0.16, green: 0.23, blue: 0.08, alpha: 1)
    static let green = Color(nsColor: dark)
    static let bezel = Color(red: 0.40, green: 0.41, blue: 0.46)
    static func asset(_ name: String) -> NSImage? { Bundle.main.url(forResource:name,withExtension:"png").flatMap { NSImage(contentsOf:$0) } }
    static let grain = asset("console-plastic")
    static let dpad = asset("control-dpad")
    static let actionButton = asset("control-action")
    static let pill = asset("control-pill")
    static func label(_ size: CGFloat = 11) -> Font { .custom("HelveticaNeue-Bold", size: size) }
}

struct PlasticGrain: View {
    private var texture: NSImage? { Handheld.grain }
    var body: some View {
        Group {
            if let texture { Image(nsImage: texture).resizable(resizingMode: .tile).opacity(0.17).blendMode(.multiply) }
            else {
                Canvas { context, size in
                    for i in 0..<3800 {
                        let x = CGFloat((i * 7919) % 10007) / 10007 * size.width
                        let y = CGFloat((i * 3571) % 9973) / 9973 * size.height
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 0.65, height: 0.65)), with: .color(.black.opacity(0.06)))
                    }
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct DPadShape: Shape {
    func path(in rect: CGRect) -> Path {
        let points: [(CGFloat, CGFloat)] = [(0.34,0),(0.66,0),(0.66,0.34),(1,0.34),(1,0.66),(0.66,0.66),(0.66,1),(0.34,1),(0.34,0.66),(0,0.66),(0,0.34),(0.34,0.34)]
        var p = Path(); p.move(to: CGPoint(x: rect.minX + points[0].0 * rect.width, y: rect.minY + points[0].1 * rect.height))
        for (x,y) in points.dropFirst() { p.addLine(to: CGPoint(x: rect.minX+x*rect.width,y:rect.minY+y*rect.height)) }; p.closeSubpath(); return p
    }
}
struct DPadFace: View {
    var body: some View {
        Group {
            if let image=Handheld.dpad { Image(nsImage:image).resizable().interpolation(.high).scaledToFit().scaleEffect(1.10) }
            else { drawnFace }
        }.accessibilityHidden(true)
    }
    private var drawnFace: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: [.black.opacity(0.22), .white.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle().fill(Color(red:0.65,green:0.65,blue:0.62)).padding(3)
            DPadShape().fill(.black.opacity(0.6)).padding(11).offset(y: 3).blur(radius: 1)
            DPadShape().fill(LinearGradient(colors: [Color(white: 0.26), Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)).padding(11)
                .overlay(DPadShape().stroke(.white.opacity(0.16), lineWidth: 1).padding(12))
            Circle().fill(LinearGradient(colors: [.black.opacity(0.75), .white.opacity(0.13)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 22, height: 22)
            Circle().fill(Color(white: 0.12)).frame(width: 18, height: 18).offset(x: 1, y: 1)
        }.accessibilityHidden(true)
    }
}
struct HardwareButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    let pill: Bool
    init(pill: Bool = false) { self.pill = pill }
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .offset(y: configuration.isPressed ? 3 : 0)
            .opacity(enabled ? 1 : 0.40)
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
    }
}
struct RoundControl: View {
    let letter: String; let label: String; var disabled = false; let action: () -> Void
    var body: some View {
        VStack(spacing: 9) {
            Button(action: action) {
                Group {
                    if let image=Handheld.actionButton { Image(nsImage:image).resizable().interpolation(.high).scaledToFit().frame(width:68,height:68).scaleEffect(1.10) }
                    else { buttonFace }
                }.frame(width:68,height:68).contentShape(Circle())
            }.buttonStyle(HardwareButtonStyle()).disabled(disabled).accessibilityLabel(label).help(label)
            Text(letter).font(Handheld.label(13)).foregroundStyle(Handheld.ink)
            Text(label.uppercased()).font(Handheld.label(9)).foregroundStyle(Handheld.ink.opacity(0.8)).lineLimit(1)
        }.frame(width: 84)
    }
    private var buttonFace: some View {
                ZStack {
                    Circle().fill(LinearGradient(colors: [.black.opacity(0.34), .white.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 68, height: 68)
                    Circle().fill(Color(red: 0.64, green: 0.64, blue: 0.61)).frame(width: 61, height: 61)
                    Circle().fill(Color(red: 0.24, green: 0.02, blue: 0.10)).frame(width: 51, height: 51).offset(y: 3).shadow(color: .black.opacity(0.4), radius: 3, x: 2, y: 4)
                    Circle().fill(LinearGradient(colors: [Color(red:0.68,green:0.12,blue:0.34),Handheld.berry,Color(red:0.39,green:0.02,blue:0.16)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 51, height: 51)
                        .overlay(Circle().stroke(.white.opacity(0.24), lineWidth: 1).padding(1))
                }
    }
}
struct PillControl: View {
    let title: String; let detail: String; var disabled = false; let action: () -> Void
    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                Group {
                    if let image=Handheld.pill { Image(nsImage:image).resizable().interpolation(.high).scaledToFit().frame(width:65,height:27).scaleEffect(1.08) }
                    else {
                        Capsule().fill(LinearGradient(colors: [.black.opacity(0.3), .white.opacity(0.65)], startPoint: .top, endPoint: .bottom)).frame(width:65,height:27)
                            .overlay(Capsule().fill(Color(white:0.34)).frame(width:51,height:13).shadow(color:.black.opacity(0.5),radius:1,x:1,y:2).offset(y:-1))
                    }
                }.frame(width:65,height:27).contentShape(Capsule())
            }.buttonStyle(HardwareButtonStyle(pill: true)).disabled(disabled).accessibilityLabel(title).help(detail)
            Text(title).font(Handheld.label(11)).tracking(1).foregroundStyle(Handheld.ink)
            Text(detail.uppercased()).font(Handheld.label(8)).foregroundStyle(Handheld.ink.opacity(0.65))
        }
    }
}
struct SpeakerGrille: View {
    var body: some View {
        HStack(spacing: 9) {
            ForEach(0..<6) { _ in
                Capsule().fill(.white.opacity(0.65)).frame(width: 7, height: 58).offset(x: 1, y: 1)
                    .overlay(Capsule().fill(LinearGradient(colors:[Color(white:0.30),Color(white:0.43)],startPoint:.leading,endPoint:.trailing)).frame(width:5,height:56).shadow(color:.black.opacity(0.5),radius:1,x:1,y:0))
            }
        }.rotationEffect(.degrees(-19)).accessibilityHidden(true)
    }
}
struct BatteryLight: View {
    let busy: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glow = false
    var body: some View {
        VStack(spacing: 8) {
            Circle().fill(Color.black.opacity(0.35)).frame(width: 13, height: 13)
                .overlay(Circle().fill(RadialGradient(colors:[Color(red:1,green:0.48,blue:0.42),.red,Color(red:0.40,green:0,blue:0.06)],center:.topLeading,startRadius:0,endRadius:10)).padding(2))
                .shadow(color: .red.opacity(glow && busy ? 0.9 : 0.38), radius: glow && busy ? 9 : 4)
            Text("BATTERY").font(Handheld.label(8)).foregroundStyle(.white.opacity(0.83))
        }.onAppear { if !reduceMotion { withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { glow = true } } }
            .accessibilityLabel(busy ? "Power on, Git operation running" : "Power on")
    }
}
struct ScreenGlass: View {
    var body: some View {
        ZStack {
            LinearGradient(stops: [.init(color:.white.opacity(0.13),location:0),.init(color:.white.opacity(0.02),location:0.42),.init(color:.clear,location:0.43),.init(color:.white.opacity(0.035),location:1)],startPoint:.topLeading,endPoint:.bottomTrailing)
            VStack(spacing: 0) { LinearGradient(colors:[.black.opacity(0.26),.clear],startPoint:.top,endPoint:.bottom).frame(height:12); Spacer(); LinearGradient(colors:[.clear,.white.opacity(0.12)],startPoint:.top,endPoint:.bottom).frame(height:3) }
            HStack(spacing: 0) { LinearGradient(colors:[.black.opacity(0.20),.clear],startPoint:.leading,endPoint:.trailing).frame(width:9); Spacer() }
            Canvas { context, size in
                for y in stride(from: 0.0, to: size.height, by: 3) { context.fill(Path(CGRect(x:0,y:y,width:size.width,height:0.5)),with:.color(.black.opacity(0.035))) }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct ContentView: View {
    @EnvironmentObject var s: Store
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var actionsOpen = false
    @State private var powered = false
    @State private var baseInput = ""
    @State private var dpadPressed = false
    @State private var reviewNotice = false
    @State private var linkOpen = false
    @State private var resolutionSaved = false
    private let casing = UnevenRoundedRectangle(topLeadingRadius: 25, bottomLeadingRadius: 28, bottomTrailingRadius: 85, topTrailingRadius: 25)
    var body: some View {
        ZStack {
            Color(red: 0.20, green: 0.21, blue: 0.22)
            casing.fill(Color(red:0.47,green:0.47,blue:0.44)).offset(x: 4, y: 6).padding(12)
            casing.fill(LinearGradient(colors:[Color(red:0.88,green:0.88,blue:0.84),Handheld.shell,Color(red:0.73,green:0.73,blue:0.69)],startPoint:.topLeading,endPoint:.bottomTrailing))
                .overlay(PlasticGrain().clipShape(casing))
                .overlay(casing.stroke(.white.opacity(0.7),lineWidth:2).padding(2))
                .overlay(casing.stroke(.black.opacity(0.17),lineWidth:1).padding(7))
                .shadow(color:.black.opacity(0.32),radius:5,x:4,y:6).padding(12)
            VStack(spacing: 0) {
                topMolding
                display.frame(maxHeight: .infinity).padding(.horizontal, 34)
                brand.padding(.horizontal, 48).padding(.top, 12)
                hardwareControls.padding(.horizontal, 53).padding(.top, 6).padding(.bottom, 13)
                status.padding(.horizontal, 48).padding(.bottom, 25)
            }.padding(12).accessibilityHidden(s.showGuide).allowsHitTesting(!s.showGuide)
        }
        .overlayPreferenceValue(TourAnchors.self) { anchors in if s.showGuide { SpotlightTour(anchors:anchors).environmentObject(s) } }
        .ignoresSafeArea()
        .frame(minWidth: 1020, minHeight: 790)
        .preferredColorScheme(.light).tint(Handheld.green)
        .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
        .onOpenURL { s.receive($0) }
        .onChange(of: s.base) { _, value in baseInput = value }
        .onChange(of: scenePhase) { _, phase in if phase == .active { s.refresh() } }
        .onAppear { if !UserDefaults.standard.bool(forKey:"hasSeenGuideV2") {s.showGuide=true}; baseInput=s.base; withAnimation(reduceMotion ? nil : .easeOut(duration: 0.55)) { powered = true }; DispatchQueue.main.async { NSApp.keyWindow?.makeFirstResponder(nil) } }
        .alert("Confirm Git operation", isPresented: Binding(get: { s.confirmation != nil }, set: { if !$0 { s.confirmation = nil } })) {
            Button("Cancel", role: .cancel) { s.confirmation = nil }
            Button("Continue") { let op = s.confirmation; s.confirmation = nil; if op == "push" { s.action(["push"], label: "Push") } else if op == "pull" { s.action(["pull", "--ff-only"], label: "Pull") } }
        } message: { Text(s.confirmation == "push" ? "Push the current branch to its configured upstream? This publishes committed changes." : "Fetch and fast-forward the current branch? Git will stop if branches have diverged.") }
    }
    private var topMolding: some View {
        VStack(spacing: 10) {
            HStack { Spacer(); Text("LOCAL CODE • HUMAN REVIEW").font(Handheld.label(8)).foregroundStyle(.black.opacity(0.33)); Spacer() }.padding(.top, 20)
            HStack(spacing: 5) {
                ForEach(0..<3) { _ in Capsule().fill(.black.opacity(0.14)).frame(width:4,height:13).overlay(Capsule().stroke(.white.opacity(0.7),lineWidth:0.7).offset(x:1)) }
                Rectangle().fill(.black.opacity(0.13)).frame(height:1).overlay(Rectangle().fill(.white.opacity(0.7)).offset(y:1))
                ForEach(0..<3) { _ in Capsule().fill(.black.opacity(0.14)).frame(width:4,height:13).overlay(Capsule().stroke(.white.opacity(0.7),lineWidth:0.7).offset(x:1)) }
            }.padding(.horizontal, 18)
        }.padding(.bottom, 16).accessibilityHidden(true)
    }
    private var display: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                VStack(spacing: 3) { Rectangle().fill(Handheld.berry).frame(height:2); Rectangle().fill(Handheld.ink).frame(height:2) }
                Text("DOT MATRIX WITH CODE REVIEW").font(.custom("HelveticaNeue-Medium",size:10)).tracking(1.0).foregroundStyle(.white.opacity(0.92)).fixedSize()
                VStack(spacing: 3) { Rectangle().fill(Handheld.berry).frame(height:2); Rectangle().fill(Handheld.ink).frame(height:2) }
            }.padding(.horizontal, 9)
            HStack(alignment: .center, spacing: 13) {
                BatteryLight(busy: s.busy).frame(width: 43)
                VStack(spacing: 0) {
                    lcdHeader
                    Rectangle().fill(Handheld.green.opacity(0.25)).frame(height: 1)
                    Group {
                        if s.tab == "History" { ScrollView { Text(s.snapshot.history.isEmpty ? "OPEN A REPOSITORY TO BEGIN" : s.snapshot.history).font(.system(size:12,design:.monospaced)).textSelection(.enabled).frame(maxWidth:.infinity,alignment:.leading).padding(16) } }
                        else if s.tab == "Branches" { branchScreen }
                        else { reviewScreen }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                }.foregroundStyle(Handheld.green).background(Color(nsColor:Handheld.lcd))
                    .overlay(ScreenGlass()).clipShape(RoundedRectangle(cornerRadius:3))
                    .overlay(RoundedRectangle(cornerRadius:3).stroke(.black.opacity(0.65),lineWidth:2))
                    .opacity(powered ? 1 : 0.1)
                Spacer().frame(width: 3)
            }
        }.padding(.top, 15).padding(.bottom, 20).padding(.horizontal, 16)
            .background(UnevenRoundedRectangle(topLeadingRadius:12,bottomLeadingRadius:12,bottomTrailingRadius:48,topTrailingRadius:12).fill(LinearGradient(colors:[Color(red:0.48,green:0.49,blue:0.54),Handheld.bezel,Color(red:0.36,green:0.37,blue:0.42)],startPoint:.topLeading,endPoint:.bottomTrailing)))
            .overlay(UnevenRoundedRectangle(topLeadingRadius:12,bottomLeadingRadius:12,bottomTrailingRadius:48,topTrailingRadius:12).stroke(.black.opacity(0.25),lineWidth:1))

    }
    private var lcdHeader: some View {
        VStack(spacing: 7) {
            HStack {
                Text(s.repo.isEmpty ? "INSERT A REPOSITORY" : URL(fileURLWithPath:s.repo).lastPathComponent.uppercased()).font(.system(size:12,weight:.bold,design:.monospaced)).lineLimit(1)
                Spacer()
                Text(s.snapshot.branch).font(.system(size:10,design:.monospaced)).lineLimit(1)
                Text("\(s.reviewed.count)/\(s.snapshot.changes.count)").font(.system(size:10,weight:.bold,design:.monospaced))
            }
            HStack(spacing: 16) {
                ForEach(["Review","History","Branches"], id:\.self) { tab in Button { s.tab = tab } label: { Text((s.tab == tab ? "▶ " : "  ")+tab.uppercased()).font(.system(size:10,weight:.bold,design:.monospaced)) }.buttonStyle(.plain) }
                Spacer()
                TextField("Compare with branch / commit",text:$baseInput).font(.system(size:10,design:.monospaced)).textFieldStyle(.plain).frame(width:170).onSubmit { s.base=baseInput;s.refresh() }.accessibilityLabel("Base revision")
                Button("COMPARE") { s.base=baseInput;s.refresh() }.buttonStyle(.plain).font(.system(size:10,weight:.bold,design:.monospaced)).disabled(s.busy)
                if s.reviewMode { Button("WORKING CHANGES") { s.base="";s.expectedHead=nil;s.refresh() }.buttonStyle(.plain).font(.system(size:10,weight:.bold,design:.monospaced)) }
            }
            HStack {
                Text(s.reviewMode ? "Comparing committed changes on \(s.snapshot.branch) with \(s.base.prefix(12))" : (s.snapshot.changes.contains(where: \.conflict) ? "Merge conflict — compare both sides, edit the resolution, then save and stage" : s.snapshot.mergeInProgress ? "Merge resolved — review the staged result, then commit when ready" : "Working changes — edits that have not been committed yet"))
                    .font(.system(size:11,weight:.medium,design:.monospaced)).lineLimit(2)
                Spacer()
                Button {s.showGuide=true} label: {Image(systemName:"questionmark.circle")}.buttonStyle(.plain).help("How code review works")
            }
        }.padding(.horizontal,14).padding(.vertical,10).tourTarget(.modes)
    }
    private var reviewScreen: some View {
        HSplitView {
            VStack(alignment:.leading,spacing:0) {
                VStack(alignment:.leading,spacing:5) {
                    Text("FILES  \(s.snapshot.changes.count)").font(.system(size:9,weight:.bold,design:.monospaced))
                    HStack(spacing:6) {
                        Text("+ Added").foregroundStyle(Color(red:0.13,green:0.30,blue:0.10))
                        Text("− Deleted").foregroundStyle(Handheld.berry)
                        Text("~ Modified").foregroundStyle(Handheld.ink)
                    }.font(.system(size:8,weight:.bold,design:.monospaced))
                }.padding(10)
                ScrollView {
                    LazyVStack(spacing:2) {
                        ForEach(s.snapshot.changes) { change in
                            fileRow(change)
                        }
                        if s.snapshot.changes.isEmpty { Text(s.repo.isEmpty ? "OPEN A REPOSITORY\nTO BEGIN" : "NO CHANGED FILES\nIN THIS VIEW").font(.system(size:10,design:.monospaced)).lineSpacing(5).padding(16) }
                    }
                }
            }.frame(minWidth:175,idealWidth:210,maxWidth:270).background(Handheld.green.opacity(0.035)).tourTarget(.files)
            VStack(alignment:.leading,spacing:0) {
                HStack {
                    Text(s.selected ?? "CODE DISPLAY").font(.system(size:10,weight:.bold,design:.monospaced)).lineLimit(1)
                    Spacer()
                    if !s.reviewMode && s.change?.conflict != true {
                        Picker("Show changes",selection:$s.staged) {Text("Working file").tag(false);Text("Staged for commit").tag(true)}.pickerStyle(.segmented).labelsHidden().frame(width:265).onChange(of:s.staged) { _,_ in s.loadDiff(autoSelectSide:false) }
                    }
                }.padding(10)
                if !s.selectedCode.isEmpty {Text("Highlighted code · press ASK AI to explain it").font(.system(size:11,design:.monospaced)).padding(.horizontal,10).padding(.bottom,6)}
                if s.change?.conflict == true { conflictScreen }
                else if s.diffLoading {ProgressView("Loading changes…").frame(maxWidth:.infinity,maxHeight:.infinity)}
                else if s.diff.isEmpty {emptyDiff}
                else { DiffView(text:s.diff,target:s.selected == s.targetPath ? s.targetLine : nil,selection:$s.selectedCode) }
            }.frame(minWidth:400).tourTarget(.code)
        }
    }
    private func fileRow(_ change: Change) -> some View {
        Button { s.selected=change.path;s.loadDiff() } label: {
            HStack(spacing:6) {
                Text(statusSymbol(change)).font(.system(size:12,weight:.bold,design:.monospaced))
                Text(change.path).font(.system(size:11,design:.monospaced)).lineLimit(2).frame(maxWidth:.infinity,alignment:.leading)
                Text(change.kind).font(.system(size:9,weight:.bold,design:.monospaced))
                    .padding(.horizontal,4).padding(.vertical,3)
                    .background(statusColor(change).opacity(0.12),in:RoundedRectangle(cornerRadius:3))
            }.padding(.horizontal,8).padding(.vertical,7)
                .frame(maxWidth:.infinity,minHeight:36,alignment:.leading)
                .background(Handheld.green.opacity(s.selected == change.path ? 0.18 : 0))
                .contentShape(Rectangle())
        }.buttonStyle(.plain).foregroundStyle(statusColor(change))
            .help(change.kind + " · " + (s.reviewMode ? "Committed comparison" : change.statusLabel))
            .accessibilityLabel(change.path + ", " + change.kind + ", " + (s.reviewMode ? "Committed comparison" : change.statusLabel))
    }
    private func statusSymbol(_ change: Change) -> String {
        if s.reviewed.contains(change.path) { return "✓" }
        switch change.kind {case "Added": return "+";case "Deleted": return "−";case "Conflict": return "!";default:return "~"}
    }
    private func statusColor(_ change: Change) -> Color {
        switch change.kind {
        case "Added": return Color(red:0.13,green:0.30,blue:0.10)
        case "Deleted": return Handheld.berry
        case "Conflict": return Color(red:0.40,green:0.23,blue:0.02)
        default: return Handheld.ink
        }
    }
    private var emptyDiff: some View {
        VStack(alignment:.leading,spacing:14) {
            Text(s.repo.isEmpty ? "Open a repository to begin" : s.snapshot.mergeInProgress && s.snapshot.changes.isEmpty ? "Conflicts resolved; no file changes remain" : s.snapshot.changes.isEmpty ? "No changes in this view" : s.selected == nil ? "Choose a changed file to read its diff" : s.reviewMode ? "No text changes to show for this file" : s.staged ? "No staged changes for this file" : "No unstaged edits for this file").font(.system(size:15,weight:.bold,design:.monospaced))
            if s.repo.isEmpty {Button("Open repository…",action:s.choose)}
            else if s.snapshot.mergeInProgress && s.snapshot.changes.isEmpty {Text("Your resolution matches the current branch. Git is ready to record the merge. Use Git Actions to commit when ready.").font(.system(size:13,design:.monospaced))}
            else if s.snapshot.changes.isEmpty {Text(s.reviewMode ? "These revisions have no changes to show. Choose another comparison or Working changes." : "The working tree is clean. Use History to see commits, or compare with another branch.").font(.system(size:13,design:.monospaced))}
            if let c=s.change,!s.reviewMode {
                if c.staged && !s.staged {
                    Text("The changes are staged for your next commit. Switch views to read them.").font(.system(size:13,design:.monospaced))
                    Button("Show staged changes") {s.staged=true;s.loadDiff(autoSelectSide:false)}
                } else if s.staged && c.work != " " {
                    Text("The edits are still in the working file. They have not been staged yet.").font(.system(size:13,design:.monospaced))
                    Button("Show working-file changes") {s.staged=false;s.loadDiff(autoSelectSide:false)}
                }
            }
            Text("Green + lines are additions. Red − lines are removals. Highlight a section and choose ASK AI if you want an explanation.").font(.system(size:12,design:.monospaced)).lineSpacing(4)
            Spacer()
        }.padding(22).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topLeading)
    }
    private var conflictScreen: some View {
        VStack(alignment:.leading,spacing:10) {
            Text("Two branches changed the same part of this file.").font(.system(size:13,weight:.bold,design:.monospaced))
            Text("1 Compare the versions   2 Edit resolution   3 Save   4 Stage").font(.system(size:11,design:.monospaced))
            Picker("Conflict side",selection:$s.conflictSide) {
                Text("Original").tag("Base");Text("Current side").tag("Ours");Text("Incoming side").tag("Theirs");Text("Edit resolution").tag("Result")
            }.pickerStyle(.segmented)
            if s.conflictSide == "Result" {
                TextEditor(text:$s.conflictResult).font(.system(size:13,design:.monospaced)).scrollContentBackground(.hidden).background(Color(nsColor:Handheld.lcd))
                HStack {
                    Button("Save resolution") {resolutionSaved=s.saveResolution()}.disabled(s.busy || s.conflictResult == s.conflictOriginal)
                    Button("Stage resolved file") {if let c=s.change {s.action(["add","--",c.path],label:"Stage resolution")}}.disabled(s.busy || s.conflictResult != s.conflictOriginal || s.conflictResult.contains("<<<<<<< "))
                }
                Text(resolutionSaved ? "Saved to the working file. Inspect it, then stage the resolution." : "Edit the text to keep the right content and remove the conflict marker lines. Saving keeps a backup.").font(.system(size:11,design:.monospaced))
            } else {
                ScrollView {Text(s.conflictVersions[s.conflictSide] ?? "Loading…").font(.system(size:13,design:.monospaced)).textSelection(.enabled).frame(maxWidth:.infinity,alignment:.leading).padding(10)}
                if s.conflictSide != "Base" {Button("Use this version as the draft resolution") {s.conflictResult=s.conflictVersions[s.conflictSide] ?? "";s.conflictSide="Result";resolutionSaved=false}}
                Text("Current and Incoming are Git’s two merge sides. Their meaning can differ during a rebase. ASK AI can help compare them.").font(.system(size:11,design:.monospaced))
            }
        }.padding(12)
    }
    private var branchScreen: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:12) {
                ForEach(s.snapshot.branches,id:\.self) { b in HStack { Text(b).font(.system(size:12,design:.monospaced));Spacer();Button("Switch") { s.action(["switch","--",b],label:"Switch branch") }.disabled(s.busy || b == s.snapshot.branch || !s.snapshot.changes.isEmpty || s.reviewMode) } }
                HStack { TextField("New branch name",text:$s.branchName);Button("Create") { s.action(["switch","-c",s.branchName],label:"Create branch") }.disabled(s.busy || s.branchName.isEmpty || s.branchName.hasPrefix("-") || !s.snapshot.changes.isEmpty || s.reviewMode) }
            }.padding(16)
        }
    }
    private var brand: some View {
        HStack(alignment:.firstTextBaseline,spacing:4) {
            DPadFace().frame(width:107,height:107).scaleEffect(0.27).frame(width:29,height:29).padding(.trailing,6).offset(y:5)
            Text("Git").font(.custom("HelveticaNeue-Bold",size:19))
            Text("BOY").font(.custom("HelveticaNeue-Italic",size:27)).tracking(-1)
            Text("™").font(.custom("HelveticaNeue",size:9)).offset(y:-9)
            Spacer()
            Text("HUMAN REVIEW SYSTEM").font(Handheld.label(8)).tracking(1.7).opacity(0.65)
        }.foregroundStyle(Handheld.ink)
    }
    private var hardwareControls: some View {
        HStack(alignment:.center,spacing:28) {
            VStack(spacing:5) {
                ZStack {
                    DPadFace().frame(width:107,height:107).offset(y:dpadPressed ? 2 : 0).animation(.easeOut(duration:0.08),value:dpadPressed)
                    VStack(spacing:0) {
                        Button { navigate(-1) } label: { Color.clear.frame(width:36,height:33).contentShape(Rectangle()) }.accessibilityLabel("Previous file")
                        HStack(spacing:33) {
                            Button { s.tab = "History" } label: { Color.clear.frame(width:34,height:34).contentShape(Rectangle()) }.accessibilityLabel("View history")
                            Button { s.tab = "Review" } label: { Color.clear.frame(width:34,height:34).contentShape(Rectangle()) }.accessibilityLabel("View code review")
                        }
                        Button { navigate(1) } label: { Color.clear.frame(width:36,height:33).contentShape(Rectangle()) }.accessibilityLabel("Next file")
                    }.buttonStyle(HardwareButtonStyle()).disabled(s.busy)
                }.simultaneousGesture(DragGesture(minimumDistance:0).onChanged { _ in dpadPressed=true }.onEnded { _ in dpadPressed=false })
                Text("↑↓ FILES · ←→ VIEWS").font(Handheld.label(8)).tracking(0.8).foregroundStyle(Handheld.ink.opacity(0.75))
            }.tourTarget(.dpad)
            VStack(alignment:.leading,spacing:12) {
                HStack { Menu {
                    Button("Open Repository…",action:s.choose)
                    Divider()
                    ForEach(s.repos,id:\.self) { path in Button(URL(fileURLWithPath:path).lastPathComponent) { s.add(path) } }
                } label: { Text("REPOSITORY ▾").font(Handheld.label(10)).foregroundStyle(Handheld.ink) }.menuStyle(.borderlessButton).frame(width:145).disabled(s.busy) }.tourTarget(.repository)
                HStack(spacing:22) {
                    PillControl(title:"GIT ACTIONS",detail:"Stage · commit · sync",disabled:s.busy) { actionsOpen=true }.popover(isPresented:$actionsOpen) { actionsPanel }
                    PillControl(title:"REFRESH",detail:"Reload changes",disabled:s.busy || s.repo.isEmpty) { s.refresh() }
                }.rotationEffect(.degrees(-10))
            }.padding(.leading,5).tourTarget(.actions)
            Spacer(minLength:10)
            HStack(alignment:.center,spacing:5) {
                RoundControl(letter:"B",label:"Ask AI",disabled:s.selected == nil || s.busy) {s.prepareAIPrompt();s.showAI=true}.offset(y:13)
                    .popover(isPresented:$s.showAI,arrowEdge:.top) {AIPromptPanel().environmentObject(s)}.tourTarget(.ai)
                RoundControl(letter:"A",label:s.selected.map { s.reviewed.contains($0) } == true ? "Reviewed" : "Review",disabled:s.selected == nil || s.busy) {s.toggleReviewed();reviewNotice=true}.offset(y:-12).tourTarget(.review)
                    .overlay(alignment:.top) {if reviewNotice {Text(s.selected.map {s.reviewed.contains($0)} == true ? "Marked reviewed ✓\nYour reading progress is saved." : "Marked unread").font(.system(size:12,weight:.medium)).multilineTextAlignment(.center).padding(12).background(.regularMaterial,in:RoundedRectangle(cornerRadius:10)).fixedSize().offset(y:-75).allowsHitTesting(false)}}
                    .task(id:reviewNotice) {if reviewNotice {do {try await Task.sleep(nanoseconds:3_000_000_000);reviewNotice=false} catch {}}}
            }
            SpeakerGrille().frame(width:110,height:100).padding(.leading,12).padding(.top,32)
        }.frame(height:155)
    }
    private var status: some View {
        HStack(alignment:.top,spacing:12) {
            Text(s.message).font(.custom("HelveticaNeue",size:12)).foregroundStyle(Handheld.ink.opacity(0.85)).lineLimit(2).textSelection(.enabled)
            Spacer()
            Button {s.showGuide=true} label: {Label("HELP",systemImage:"questionmark.circle").font(Handheld.label(11))}.buttonStyle(.plain).foregroundStyle(Handheld.ink)
            Button { s.copyLink();linkOpen=true } label: { Label("REVIEW LINK · THIS MAC",systemImage:"link").font(Handheld.label(11)) }.buttonStyle(.plain).foregroundStyle(Handheld.ink).disabled(s.repo.isEmpty)
                .popover(isPresented:$linkOpen,arrowEdge:.top) {
                    VStack(alignment:.leading,spacing:14) {
                        Text("Local review link copied").font(.headline)
                        Text("This reopens the repository, comparison, and file in Git Boy on this Mac. It is not a public share link, does not upload code, and will not open this checkout on another device.").font(.callout)
                        Text(s.lastReviewLink).font(.system(size:11,design:.monospaced)).textSelection(.enabled)
                        HStack {Button("Copy again") {s.copyLink()};Spacer();Button("Done") {linkOpen=false}}
                    }.padding(22).frame(width:440)
                }
            if let project=s.project,let url=URL(string:project),url.scheme=="https",url.host=="agfirst.wf.lytho.us" { Link("LYTHO",destination:url).font(Handheld.label(9)) }
        }.frame(minHeight:25).tourTarget(.links)
    }
    private var actionsPanel: some View {
        VStack(alignment:.leading,spacing:16) {
            Text("GIT OPERATIONS").font(.headline)
            HStack {
                Button("Fetch") { s.action(["fetch","--all","--prune"],label:"Fetch") }
                Button("Pull") { actionsOpen=false;s.confirmation="pull" }
                Button("Push") { actionsOpen=false;s.confirmation="push" }
            }
            if !s.reviewMode {
                HStack {
                    Button("Stage File") { if let c=s.change { s.action(["add","--",c.path]+(c.original.map { [$0] } ?? []),label:"Stage") } }.disabled(s.change == nil)
                    Button("Unstage File") { if let c=s.change { s.action(["reset","--",c.path]+(c.original.map { [$0] } ?? []),label:"Unstage") } }.disabled(s.change == nil)
                }
                TextField("Commit message",text:$s.commitMessage).textFieldStyle(.roundedBorder)
                Button("Commit Staged Changes") { s.action(["commit","-m",s.commitMessage],label:"Commit") }.disabled(s.commitMessage.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
            }
            Text("Existing Git credentials and hooks apply. Push requires confirmation.").font(.caption).foregroundStyle(.secondary)
        }.padding(22).frame(width:365).disabled(s.busy || s.repo.isEmpty)
    }
    private func navigate(_ direction:Int) {
        guard !s.snapshot.changes.isEmpty else { return }
        let index=s.snapshot.changes.firstIndex { $0.path == s.selected } ?? 0
        let next=max(0,min(s.snapshot.changes.count-1,index+direction));s.selected=s.snapshot.changes[next].path;s.loadDiff()
    }
}
