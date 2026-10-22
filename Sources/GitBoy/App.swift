import SwiftUI
import AppKit

// AppKit can paint a system-colored square where the two scrollers meet.
// Cover only that unused intersection; keep both scrollbars and their hit targets.
final class LCDCorner: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override var wantsDefaultClipping: Bool { true }
    override func draw(_ dirtyRect: NSRect) { Handheld.lcd.setFill(); bounds.fill() }
}
final class LCDScrollView: NSScrollView {
    private let lcdCorner = LCDCorner()
    override func tile() {
        super.tile()
        contentView.drawsBackground = true
        contentView.backgroundColor = Handheld.lcd
        guard let horizontal = horizontalScroller, let vertical = verticalScroller else { return }
        if lcdCorner.superview == nil { lcdCorner.clipsToBounds = true; addSubview(lcdCorner, positioned: .above, relativeTo: nil) }
        let side = NSScroller.scrollerWidth(for: .regular, scrollerStyle: .overlay)
        lcdCorner.frame = NSRect(x: bounds.maxX - side, y: isFlipped ? bounds.maxY - side : bounds.minY, width: side, height: side)
        lcdCorner.isHidden = horizontal.isHidden || vertical.isHidden
        lcdCorner.needsDisplay = true
    }
}
struct DiffView: NSViewRepresentable {
    let text: String; let target: Int?
    @Binding var selection: String
    final class Coordinator: NSObject, NSTextViewDelegate {
        var selection: Binding<String>; var updating = false
        init(_ selection: Binding<String>) { self.selection = selection }
        func textViewDidChangeSelection(_ notification: Notification) {
            guard !updating, let view = notification.object as? NSTextView else { return }
            let range = view.selectedRange(), text = view.string as NSString
            let excerpt = range.length > 0 && NSMaxRange(range) <= text.length ? text.substring(with: range) : ""
            if selection.wrappedValue != excerpt { selection.wrappedValue = excerpt }
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator($selection) }
    func makeNSView(context: Context) -> NSScrollView {
        let scroll = LCDScrollView(); scroll.hasVerticalScroller = true; scroll.hasHorizontalScroller = true; scroll.autohidesScrollers = true; scroll.scrollerStyle = .overlay; scroll.drawsBackground = true; scroll.backgroundColor = Handheld.lcd; scroll.horizontalScroller?.knobStyle = .dark; scroll.verticalScroller?.knobStyle = .dark
        let view = NSTextView(); view.delegate = context.coordinator; view.selectedTextAttributes = [.backgroundColor: Handheld.dark.withAlphaComponent(0.3), .foregroundColor: Handheld.dark]; view.isEditable = false; view.isSelectable = true
        view.isRichText = false; view.backgroundColor = Handheld.lcd; view.insertionPointColor = Handheld.dark; view.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        view.textContainerInset = NSSize(width: 14, height: 14)
        view.isVerticallyResizable = true; view.isHorizontallyResizable = true
        view.autoresizingMask = [.width]; view.minSize = NSSize(width: 0, height: 0)
        view.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        view.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        view.textContainer?.widthTracksTextView = false
        scroll.documentView = view; return scroll
    }
    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.selection = $selection
        guard let view = scroll.documentView as? NSTextView, view.string != text else { return }
        context.coordinator.updating = true
        defer { context.coordinator.updating = false }
        let output = NSMutableAttributedString()
        var currentLine = 0; var targetRange = NSRange(location: 0, length: 0)
        for row in text.components(separatedBy: "\n") {
            if row.hasPrefix("@@"), let plus = row.split(separator: " ").first(where: { $0.hasPrefix("+") }) { currentLine = Int(plus.dropFirst().split(separator: ",")[0]) ?? 0 }
            else if !row.hasPrefix("-") && !row.hasPrefix("\\") {
                if currentLine == target { targetRange = NSRange(location: output.length, length: (row as NSString).length) }
                currentLine += 1
            }
            let color: NSColor = row.hasPrefix("+") ? NSColor(red: 0.11, green: 0.30, blue: 0.09, alpha: 1) : row.hasPrefix("-") ? NSColor(red: 0.48, green: 0.14, blue: 0.22, alpha: 1) : row.hasPrefix("@@") ? NSColor(red: 0.27, green: 0.34, blue: 0.12, alpha: 1) : Handheld.dark
            output.append(NSAttributedString(string: row + "\n", attributes: [.font: NSFont.monospacedSystemFont(ofSize: 13, weight: .medium), .foregroundColor: color]))
        }
        view.textStorage?.setAttributedString(output)
        view.scrollRangeToVisible(target == nil ? NSRange(location: 0, length: 0) : targetRange)
    }
}
@main struct GitBoyApp: App {
    @StateObject var store = Store()
    var body: some Scene {
        WindowGroup { ContentView().environmentObject(store) }
            .defaultSize(width:1160,height:850).windowStyle(.hiddenTitleBar)
            .commands {
                CommandGroup(after:.newItem) {
                    Button("Open Repository…") {store.choose()}.keyboardShortcut("o")
                    Button("Refresh") {store.refresh()}.keyboardShortcut("r")
                }
                CommandGroup(replacing:.help) {
                    Button("Git Boy Guide") {store.showGuide=true}.keyboardShortcut("?",modifiers:[.command])
                }
            }
    }
}
