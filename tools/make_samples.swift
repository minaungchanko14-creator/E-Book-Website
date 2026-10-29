// Makes free-sample PDFs (cover + chapter 1) in samples/, each with a
// "free sample" label on every page and a closing "buy the full book" page.
// Run from the project folder:  swift tools/make_samples.swift
import PDFKit
import AppKit

let home = FileManager.default.homeDirectoryForCurrentUser.path
let downloads = "\(home)/Downloads"
let site = "minaungchanko14-creator.github.io/E-Book-Website"

struct Book { let file: String; let pages: ClosedRange<Int>; let title: String; let price: String; let inBundle: Bool; let out: String }
let books = [
    Book(file: "E-book/မင်းပြောင်းလဲနိုင်ပါတယ်.pdf", pages: 1...7, title: "မင်းပြောင်းလဲနိုင်ပါတယ်", price: "RM 19.90", inBundle: true, out: "Sample-You-Can-Change.pdf"),
    Book(file: "E-book/မင်း_လုပ်နိုင်ပါတယ်_ebook.pdf", pages: 1...6, title: "မင်းလုပ်နိုင်ပါတယ်", price: "RM 29.99", inBundle: true, out: "Sample-You-Can-Do-It.pdf"),
    Book(file: "E-book/bitcoin_the_new_money.pdf", pages: 1...6, title: "Bitcoin: The New Money", price: "RM 24.99", inBundle: true, out: "Sample-Bitcoin-The-New-Money.pdf"),
    Book(file: "The_Rich_Dont_Work_for_Money_MM_Expanded.pdf", pages: 1...5, title: "The Rich Don't Work for Money", price: "RM 39.99", inBundle: true, out: "Sample-The-Rich-Dont-Work-for-Money.pdf"),
    Book(file: "Digital Product/Digital_Product_Guide_2026.pdf", pages: 1...2, title: "Digital Product Business Guide 2026", price: "RM 14.90", inBundle: false, out: "Sample-Digital-Product-Guide-2026.pdf"),
]

let mm = { (size: CGFloat) in NSFont(name: "Myanmar Sangam MN", size: size) ?? NSFont.systemFont(ofSize: size) }

/// Closing page drawn as an image the same size as the book's pages.
func closingPage(_ b: Book, size: CGSize) -> PDFPage {
    let img = NSImage(size: size)
    img.lockFocus()
    NSColor(red: 0.027, green: 0.039, blue: 0.071, alpha: 1).setFill()
    NSRect(origin: .zero, size: size).fill()
    let para = NSMutableParagraphStyle(); para.alignment = .center; para.lineSpacing = 6
    var lines: [(String, NSFont, NSColor)] = [
        ("အခမဲ့ နမူနာ ဒီမှာ ပြီးပါပြီ", mm(16), NSColor(white: 1, alpha: 0.6)),
        (b.title, NSFont.systemFont(ofSize: 26, weight: .bold), .white),
        ("ကျန်တဲ့ အခန်းတွေကို ဆက်ဖတ်ချင်ရင် ဝယ်ယူနိုင်ပါပြီ", mm(17), NSColor(white: 1, alpha: 0.85)),
        (b.price, NSFont.systemFont(ofSize: 40, weight: .heavy), NSColor(red: 0.376, green: 0.647, blue: 0.980, alpha: 1)),
    ]
    if b.inBundle {
        lines.append(("🎁 E-book ၄ အုပ် Bundle — RM 79 (RM 35.87 သက်သာ)", mm(15), NSColor(red: 0.98, green: 0.80, blue: 0.30, alpha: 1)))
    }
    lines += [
        ("🌐 \(site)", NSFont.systemFont(ofSize: 14), NSColor(white: 1, alpha: 0.85)),
        ("💬 WhatsApp: +60 011-2838 1539", NSFont.systemFont(ofSize: 14), NSColor(white: 1, alpha: 0.85)),
        ("Ong Sike Books", NSFont.systemFont(ofSize: 13, weight: .semibold), NSColor(white: 1, alpha: 0.5)),
    ]
    let text = NSMutableAttributedString()
    for (i, (s, f, c)) in lines.enumerated() {
        text.append(NSAttributedString(string: s + (i < lines.count - 1 ? "\n\n" : ""),
                                       attributes: [.font: f, .foregroundColor: c, .paragraphStyle: para]))
    }
    let box = NSRect(x: 40, y: 0, width: size.width - 80, height: size.height)
    let h = text.boundingRect(with: box.size, options: [.usesLineFragmentOrigin]).height
    text.draw(with: NSRect(x: 40, y: (size.height - h) / 2, width: size.width - 80, height: h), options: [.usesLineFragmentOrigin])
    img.unlockFocus()
    return PDFPage(image: img)!
}

let outDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("samples")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

for b in books {
    guard let src = PDFDocument(url: URL(fileURLWithPath: "\(downloads)/\(b.file)")) else {
        print("missing: \(b.file)"); continue
    }
    let doc = PDFDocument()
    for n in b.pages where n <= src.pageCount {
        let page = src.page(at: n - 1)!.copy() as! PDFPage
        let r = page.bounds(for: .mediaBox)
        let label = PDFAnnotation(bounds: CGRect(x: r.minX, y: r.minY + 6, width: r.width, height: 18), forType: .freeText, withProperties: nil)
        label.contents = "အခမဲ့ နမူနာ · Ong Sike Books · \(site)"
        label.font = mm(8)
        label.fontColor = NSColor(white: 0.45, alpha: 1)
        label.color = .clear
        label.alignment = .center
        label.border = PDFBorder(); label.border?.lineWidth = 0
        page.addAnnotation(label)
        doc.insert(page, at: doc.pageCount)
    }
    let size = src.page(at: 0)!.bounds(for: .mediaBox).size
    doc.insert(closingPage(b, size: size), at: doc.pageCount)
    doc.documentAttributes = [PDFDocumentAttribute.titleAttribute: "\(b.title) — အခမဲ့ နမူနာ",
                              PDFDocumentAttribute.authorAttribute: "Ong Sike"]
    doc.write(to: outDir.appendingPathComponent(b.out))
    print("\(b.out): \(doc.pageCount) pages")
}
