import AppKit
let output = CommandLine.arguments[1]
let image = NSImage(size: NSSize(width:1024,height:1024));image.lockFocus()
func shape(_ x:CGFloat,_ y:CGFloat,_ w:CGFloat,_ h:CGFloat,_ radius:CGFloat=0)->NSBezierPath { NSBezierPath(roundedRect:NSRect(x:x,y:y,width:w,height:h),xRadius:radius,yRadius:radius) }
func fill(_ p:NSBezierPath,_ c:NSColor) { c.setFill();p.fill() }
func gradient(_ p:NSBezierPath,_ a:NSColor,_ b:NSColor) { NSGradient(starting:a,ending:b)!.draw(in:p,angle:-65) }
func shadow(_ blur:CGFloat,_ x:CGFloat,_ y:CGFloat,_ alpha:CGFloat) { let s=NSShadow();s.shadowBlurRadius=blur;s.shadowOffset=NSSize(width:x,height:y);s.shadowColor=NSColor.black.withAlphaComponent(alpha);s.set() }
func text(_ t:String,_ x:CGFloat,_ y:CGFloat,_ size:CGFloat,_ italic:Bool=false) { NSAttributedString(string:t,attributes:[.font:NSFont(name:italic ? "HelveticaNeue-Italic":"HelveticaNeue-Bold",size:size)!, .foregroundColor:NSColor(red:0.13,green:0.17,blue:0.40,alpha:1)]).draw(at:NSPoint(x:x,y:y)) }
let cream=NSColor(red:0.84,green:0.84,blue:0.79,alpha:1), gray=NSColor(red:0.66,green:0.66,blue:0.62,alpha:1)
let ink=NSColor(white:0.15,alpha:1), berry=NSColor(red:0.57,green:0.06,blue:0.26,alpha:1)
let body=shape(150,45,730,930,80)
NSGraphicsContext.saveGraphicsState();shadow(12,8,-10,0.35);fill(body,gray);NSGraphicsContext.restoreGraphicsState()
gradient(body,NSColor(red:0.94,green:0.94,blue:0.90,alpha:1),gray)
body.lineWidth=3;NSColor.white.withAlphaComponent(0.7).setStroke();body.stroke()
// Molded upper seam and attachment grooves.
fill(shape(160,915,708,2),NSColor.black.withAlphaComponent(0.15));fill(shape(160,912,708,2),NSColor.white.withAlphaComponent(0.8))
for x in [178,190,202,820,832,844] { gradient(shape(CGFloat(x),910,5,42,2),gray,NSColor.white.withAlphaComponent(0.8)) }
let bezel=shape(200,475,630,405,28);gradient(bezel,NSColor(red:0.48,green:0.49,blue:0.54,alpha:1),NSColor(red:0.34,green:0.35,blue:0.4,alpha:1))
fill(shape(225,843,240,3),berry);fill(shape(225,836,240,3),NSColor(red:0.12,green:0.18,blue:0.4,alpha:1));fill(shape(640,843,165,3),berry)
NSAttributedString(string:"DOT MATRIX",attributes:[.font:NSFont.systemFont(ofSize:14),.foregroundColor:NSColor.white]).draw(at:NSPoint(x:486,y:834))
gradient(shape(281,518,497,288,3),NSColor(red:0.58,green:0.65,blue:0.27,alpha:1),NSColor(red:0.72,green:0.78,blue:0.4,alpha:1))
fill(shape(281,794,497,12),NSColor.black.withAlphaComponent(0.24));fill(shape(281,518,10,288),NSColor.black.withAlphaComponent(0.20))
NSGraphicsContext.saveGraphicsState();shadow(7,0,0,0.7);fill(NSBezierPath(ovalIn:NSRect(x:229,y:661,width:15,height:15)),.red);NSGraphicsContext.restoreGraphicsState()
// Pixel code marks on LCD.
let green=NSColor(red:0.18,green:0.27,blue:0.10,alpha:1)
for (x,y,w,h) in [(350,696,16,16),(366,680,16,16),(382,664,16,16),(366,648,16,16),(350,632,16,16),(445,629,95,12),(445,695,220,10),(445,668,160,10)] {fill(shape(CGFloat(x),CGFloat(y),CGFloat(w),CGFloat(h)),green)}
text("Git",205,422,33);text("BOY",254,416,49,true)
// Use the same original rendered controls as the app so the icon shares its materials.
func asset(_ name:String,_ rect:NSRect) { NSImage(contentsOfFile:"assets/"+name+".png")?.draw(in:rect) }
asset("control-dpad",NSRect(x:195,y:192,width:246,height:246))
for (x,y,label) in [(574.0,264.0,"B"),(709.0,320.0,"A")] {
 asset("control-action",NSRect(x:x-18,y:y-18,width:124,height:124));text(label,CGFloat(x+33),CGFloat(y-45),22)
}
for (x,label) in [(400.0,"SELECT"),(510.0,"START")] { asset("control-pill",NSRect(x:x-7,y:151,width:94,height:31));text(label,CGFloat(x-1),125,15) }
for i in 0..<6 { gradient(shape(CGFloat(614+i*31),75+CGFloat(i*5),9,76,4),NSColor(white:0.31,alpha:1),NSColor(white:0.60,alpha:1)) }
image.unlockFocus();let bitmap=NSBitmapImageRep(data:image.tiffRepresentation!)!;try bitmap.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:output))
