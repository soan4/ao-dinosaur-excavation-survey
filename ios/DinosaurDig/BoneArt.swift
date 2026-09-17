import UIKit

/// Temporary vector specimens. No generated images or external assets.
enum BoneArt {
    static let cream = UIColor(red: 0.98, green: 0.90, blue: 0.70, alpha: 1)
    static let ink = UIColor(red: 0.28, green: 0.22, blue: 0.15, alpha: 1)
    static func path(for kind: BoneKind) -> CGPath {
        let p = UIBezierPath()
        func line(_ points: [CGPoint], width: CGFloat) {
            let l = UIBezierPath(); l.move(to: points[0]); points.dropFirst().forEach { l.addLine(to: $0) }
            p.append(UIBezierPath(cgPath: l.cgPath.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 1)))
        }
        func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) { p.append(UIBezierPath(ovalIn: CGRect(x: x, y: y, width: w, height: h))) }
        switch kind {
        case .skull:
            p.move(to: CGPoint(x: -44, y: -18)); p.addCurve(to: CGPoint(x: 35, y: -22), controlPoint1: CGPoint(x: -25, y: -40), controlPoint2: CGPoint(x: 16, y: -34))
            p.addLine(to: CGPoint(x: 47, y: 2)); p.addLine(to: CGPoint(x: 23, y: 20)); p.addLine(to: CGPoint(x: -35, y: 22)); p.close()
        case .jaw:
            line([CGPoint(x: -42,y: -12), CGPoint(x: -27,y: 13), CGPoint(x: 30,y: 18), CGPoint(x: 44,y: 3)], width: 11)
            for i in 0..<5 { line([CGPoint(x: -21 + i*11,y: 10), CGPoint(x: -19 + i*11,y: 0)], width: 4) }
        case .spine:
            line([CGPoint(x: -43,y: 0),CGPoint(x: 43,y: 0)], width: 9)
            for i in 0..<7 { oval(CGFloat(-42+i*12), -8, 12, 16); line([CGPoint(x: -36+i*12,y: -3),CGPoint(x: -36+i*12,y: -22)], width: 5) }
        case .ribs:
            line([CGPoint(x: 0,y: -30),CGPoint(x: 0,y: 29)], width: 8)
            for i in 0..<4 {
                let y = CGFloat(-25 + i*13)
                for side: CGFloat in [-1, 1] {
                    let rib = UIBezierPath(); rib.move(to: CGPoint(x: 0,y: y)); rib.addQuadCurve(to: CGPoint(x: side*29,y: y+23), controlPoint: CGPoint(x: side*40,y: y+1))
                    p.append(UIBezierPath(cgPath: rib.cgPath.copy(strokingWithWidth: 5, lineCap: .round, lineJoin: .round, miterLimit: 1)))
                }
            }
        case .pelvis:
            oval(-40,-25,34,49); oval(6,-25,34,49); line([CGPoint(x: -20,y: 3),CGPoint(x: 20,y: 3)],width: 14)
        case .arms, .legs:
            let thick: CGFloat = kind == .legs ? 13 : 9
            line([CGPoint(x: -31,y: -25),CGPoint(x: 1,y: -1),CGPoint(x: 23,y: 28),CGPoint(x: 42,y: 28)],width: thick)
            oval(-40,-34,20,20); oval(-6,-9,18,18)
            if kind == .arms { line([CGPoint(x: 23,y: 28),CGPoint(x: 37,y: 15)], width: 5) }
        case .tail:
            line([CGPoint(x: -44,y: -12),CGPoint(x: -9,y: 0),CGPoint(x: 42,y: 13)],width: 5)
            for i in 0..<8 { let size = CGFloat(16-i); oval(CGFloat(-45+i*12),CGFloat(-20+i*4),size,size) }
        }
        return p.cgPath
    }
    /// Connected museum pose in a shared 560 × 310 coordinate space.
    static func skeletonPath(for kind: BoneKind) -> CGPath {
        let p = UIBezierPath()
        func stroke(_ points: [CGPoint], width: CGFloat = 8) {
            let line = UIBezierPath(); line.move(to: points[0])
            points.dropFirst().forEach { line.addLine(to: $0) }
            p.append(UIBezierPath(cgPath: line.cgPath.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 1)))
        }
        func curve(_ start: CGPoint, _ end: CGPoint, _ c1: CGPoint, _ c2: CGPoint, width: CGFloat) {
            let line = UIBezierPath(); line.move(to: start)
            line.addCurve(to: end, controlPoint1: c1, controlPoint2: c2)
            p.append(UIBezierPath(cgPath: line.cgPath.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 1)))
        }
        switch kind {
        case .skull:
            p.move(to: CGPoint(x: 409,y: 63))
            p.addCurve(to: CGPoint(x: 526,y: 59), controlPoint1: CGPoint(x: 434,y: 32), controlPoint2: CGPoint(x: 491,y: 29))
            p.addLine(to: CGPoint(x: 543,y: 84)); p.addLine(to: CGPoint(x: 518,y: 103))
            p.addLine(to: CGPoint(x: 445,y: 104)); p.addLine(to: CGPoint(x: 413,y: 89)); p.close()
        case .jaw:
            stroke([CGPoint(x: 441,y: 106),CGPoint(x: 459,y: 119),CGPoint(x: 521,y: 117),CGPoint(x: 533,y: 107)],width: 7)
            for x in stride(from: 462, through: 512, by: 12) { stroke([CGPoint(x: x,y: 109),CGPoint(x: x+2,y: 115)],width: 3) }
        case .spine:
            curve(CGPoint(x: 423,y: 91),CGPoint(x: 277,y: 135),CGPoint(x: 373,y: 98),CGPoint(x: 321,y: 112),width: 10)
            for i in 0..<9 { let x = CGFloat(285+i*14), y = 132-CGFloat(i)*4; stroke([CGPoint(x:x,y:y),CGPoint(x:x-3,y:y-13)],width:4) }
        case .ribs:
            for i in 0..<5 {
                let x = CGFloat(310+i*16), y = CGFloat(127-i*5)
                curve(CGPoint(x:x,y:y),CGPoint(x:x-5,y:190-CGFloat(i)*4),CGPoint(x:x+22,y:y+25),CGPoint(x:x+16,y:180),width:5)
            }
        case .pelvis:
            p.move(to:CGPoint(x:250,y:134)); p.addLine(to:CGPoint(x:277,y:126)); p.addLine(to:CGPoint(x:311,y:142))
            p.addLine(to:CGPoint(x:315,y:172)); p.addLine(to:CGPoint(x:284,y:185)); p.addLine(to:CGPoint(x:259,y:169)); p.close()
        case .arms:
            stroke([CGPoint(x:372,y:143),CGPoint(x:398,y:177),CGPoint(x:427,y:174)],width:6)
            stroke([CGPoint(x:361,y:151),CGPoint(x:385,y:188),CGPoint(x:411,y:192)],width:5)
            stroke([CGPoint(x:423,y:174),CGPoint(x:430,y:165)],width:3)
        case .legs:
            stroke([CGPoint(x:276,y:174),CGPoint(x:246,y:232),CGPoint(x:258,y:278),CGPoint(x:224,y:283)],width:12)
            stroke([CGPoint(x:300,y:173),CGPoint(x:334,y:232),CGPoint(x:323,y:276),CGPoint(x:358,y:280)],width:10)
        case .tail:
            curve(CGPoint(x:277,y:135),CGPoint(x:28,y:176),CGPoint(x:186,y:174),CGPoint(x:103,y:192),width:8)
            for i in 0..<12 { let x = CGFloat(53+i*18), y = 178-pow(CGFloat(i)/11,2)*35; stroke([CGPoint(x:x,y:y-4),CGPoint(x:x-3,y:y+5)],width:4) }
        }
        return p.cgPath
    }
    private static let samples: [[DigPoint]] = BoneKind.allCases.map { bone in
        let shape = path(for: bone)
        var result: [DigPoint] = []
        for y in stride(from: -36, through: 42, by: 6) {
            for x in stride(from: -48, through: 48, by: 6) where shape.contains(CGPoint(x: x,y: y)) {
                result.append(DigPoint(x: Double(x),y: Double(y)))
            }
        }
        return result
    }
    static func dirtPoints(for kind: BoneKind) -> [DigPoint] { samples[kind.rawValue] }
}
