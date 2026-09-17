import SpriteKit
import UIKit

@MainActor final class ExcavationScene: SKScene {
    weak var store: GameStore?
    private let content = SKNode()
    private let effects = SKNode()
    private var previous: CGPoint?
    private var strokeBone: Int?
    private var strokeChangedMode = false
    private var lastFeedback: TimeInterval = 0
    private var activeTouch: UITouch?
    private let softFeedback = UIImpactFeedbackGenerator(style: .soft)
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = UIColor(red: 0.70, green: 0.49, blue: 0.29, alpha: 1)
        addChild(content); addChild(effects)
        effects.zPosition = 100
    }
    required init?(coder: NSCoder) { fatalError("Use init(size:)") }
    override func didMove(to view: SKView) { view.isMultipleTouchEnabled = false; render() }
    override func didChangeSize(_ oldSize: CGSize) { render() }
    private var fieldScale: CGFloat { min((size.width - 42) / 220, (size.height - 32) / 344) }
    private var polishScale: CGFloat { min((size.width - 40) / 110, (size.height - 60) / 100) }
    func center(for bone: BoneKind) -> CGPoint {
        CGPoint(x: size.width * (bone.rawValue % 2 == 0 ? 0.26 : 0.74), y: size.height * (0.865 - CGFloat(bone.rawValue / 2) * 0.245))
    }
    func render() {
        guard let store, size.width > 0, size.height > 0 else { return }
        content.removeAllChildren()
        // Stable, deterministic sediment texture; resizing never resets game state.
        for i in 0..<95 {
            let dot = SKShapeNode(ellipseOf: CGSize(width: 2 + i % 4, height: 2))
            dot.position = CGPoint(x: CGFloat((i*71+17)%997)/997*size.width, y: CGFloat((i*137+31)%991)/991*size.height)
            dot.fillColor = i.isMultiple(of: 2) ? UIColor.white.withAlphaComponent(0.13) : UIColor.brown.withAlphaComponent(0.22)
            dot.strokeColor = .clear; content.addChild(dot)
        }
        if let bone = store.active {
            let halo = SKShapeNode(ellipseOf: CGSize(width: size.width-22,height: min(size.height-16,size.width-22)))
            halo.position = CGPoint(x:size.width/2,y:size.height/2)
            halo.fillColor = UIColor(red:0.86,green:0.68,blue:0.43,alpha:1)
            halo.strokeColor = UIColor.white.withAlphaComponent(0.18); halo.lineWidth = 2
            content.addChild(halo)
            let group = specimen(bone, scale: polishScale)
            group.position = CGPoint(x: size.width/2,y: size.height/2)
            content.addChild(group)
            for (id, point) in BoneArt.dirtPoints(for: bone).enumerated() where !store.expedition.bones[bone.rawValue].polished.contains(id) {
                let dirt = SKShapeNode(circleOfRadius: 4.8)
                dirt.position = CGPoint(x:point.x,y:point.y)
                dirt.fillColor = UIColor(red:0.48,green:0.29,blue:0.15,alpha:0.90)
                dirt.strokeColor = .clear; dirt.zPosition = 2; group.addChild(dirt)
            }
        } else {
            for bone in BoneKind.allCases {
                let state = store.expedition.bones[bone.rawValue]
                let spot = center(for: bone)
                let bed = SKShapeNode(ellipseOf: CGSize(width: 101*fieldScale,height: 74*fieldScale))
                bed.position = spot; bed.fillColor = UIColor(red:0.48,green:0.31,blue:0.18,alpha:0.30)
                bed.strokeColor = store.hintBone == bone.rawValue ? UIColor(red:1,green:0.89,blue:0.4,alpha:1) : UIColor.white.withAlphaComponent(0.1)
                bed.lineWidth = store.hintBone == bone.rawValue ? 4 : 1
                content.addChild(bed)
                if state.collected {
                    let check = SKLabelNode(fontNamed:"AvenirNext-Bold")
                    check.text = "✓"; check.fontSize = 24; check.fontColor = UIColor.white.withAlphaComponent(0.55)
                    check.verticalAlignmentMode = .center; check.position = spot; content.addChild(check)
                    continue
                }
                let group = specimen(bone, scale: fieldScale*0.78)
                group.position = spot; content.addChild(group)
                if !state.exposed {
                    for (id, point) in GameStore.soilPoints.enumerated() where !state.soil.contains(id) {
                        let dirt = SKShapeNode(ellipseOf: CGSize(width:29,height:24))
                        dirt.position = CGPoint(x:point.x,y:point.y)
                        dirt.fillColor = id.isMultiple(of:2) ? UIColor(red:0.66,green:0.43,blue:0.23,alpha:1) : UIColor(red:0.72,green:0.49,blue:0.27,alpha:1)
                        dirt.strokeColor = .clear; dirt.zPosition = 2; group.addChild(dirt)
                    }
                }
                if state.rockHits > 0 {
                    let rockPath = CGMutablePath()
                    rockPath.addLines(between: [CGPoint(x:-47,y:-12),CGPoint(x:-27,y:-34),CGPoint(x:18,y:-32),CGPoint(x:47,y:-7),CGPoint(x:36,y:26),CGPoint(x:-17,y:33),CGPoint(x:-46,y:14)])
                    rockPath.closeSubpath()
                    let rock = SKShapeNode(path:rockPath); rock.fillColor = UIColor(red:0.46,green:0.45,blue:0.41,alpha:1)
                    rock.strokeColor = UIColor(red:0.32,green:0.31,blue:0.28,alpha:1); rock.lineWidth = 3; rock.zPosition = 3; group.addChild(rock)
                    if state.rockHits < 4 {
                        let crack = CGMutablePath(); crack.addLines(between:[CGPoint(x:-19,y:-27),CGPoint(x:3,y:-7),CGPoint(x:-9,y:5),CGPoint(x:13,y:26)])
                        if state.rockHits < 3 { crack.move(to:CGPoint(x:-9,y:5)); crack.addLine(to:CGPoint(x:-35,y:16)) }
                        if state.rockHits < 2 { crack.move(to:CGPoint(x:3,y:-7)); crack.addLine(to:CGPoint(x:35,y:-16)) }
                        let cracks = SKShapeNode(path:crack); cracks.strokeColor = BoneArt.cream; cracks.lineWidth = 3; cracks.zPosition = 4; group.addChild(cracks)
                    }
                }
            }
        }
    }
    private func specimen(_ bone: BoneKind, scale: CGFloat) -> SKNode {
        let group = SKNode(); group.xScale = scale; group.yScale = -scale
        let shape = SKShapeNode(path:BoneArt.path(for:bone)); shape.fillColor = BoneArt.cream
        shape.strokeColor = BoneArt.ink; shape.lineWidth = 2; shape.lineJoin = .round
        group.addChild(shape)
        if bone == .skull {
            let eye = SKShapeNode(ellipseOf:CGSize(width:13,height:11)); eye.position = CGPoint(x:-14,y:-7)
            eye.fillColor = BoneArt.ink; eye.strokeColor = .clear; eye.zPosition = 1; group.addChild(eye)
        }
        return group
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }
        activeTouch = touch; previous = touch.location(in:self)
        strokeBone = store?.active?.rawValue; strokeChangedMode = false
        softFeedback.prepare(); impactFeedback.prepare()
        act(at:previous!, isTap:true)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch), store?.tool == .brush, !strokeChangedMode else { return }
        let next = touch.location(in:self)
        let from = previous ?? next
        let steps = max(1,Int(hypot(next.x-from.x,next.y-from.y)/5))
        for step in 1...steps {
            let t = CGFloat(step)/CGFloat(steps)
            act(at:CGPoint(x:from.x+(next.x-from.x)*t,y:from.y+(next.y-from.y)*t),isTap:false)
            if strokeChangedMode { break }
        }
        previous = next
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { endStroke() }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { endStroke() }
    private func endStroke() { previous = nil; activeTouch = nil; effects.childNode(withName:"cursor")?.removeFromParent() }
    private func act(at point: CGPoint, isTap: Bool) {
        guard let store, !strokeChangedMode else { return }
        var changed = false
        if store.active != nil {
            changed = store.polish(at:DigPoint(x:Double((point.x-size.width/2)/polishScale),y:Double(-(point.y-size.height/2)/polishScale)))
        } else if let nearest = BoneKind.allCases.filter({ !store.expedition.bones[$0.rawValue].collected }).min(by: { distance(point,center(for:$0)) < distance(point,center(for:$1)) }) {
            let p = center(for:nearest)
            if abs(point.x-p.x) < 54*fieldScale && abs(point.y-p.y) < 39*fieldScale {
                changed = store.dig(bone:nearest,at:DigPoint(x:Double((point.x-p.x)/(fieldScale*0.78)),y:Double(-(point.y-p.y)/(fieldScale*0.78))),isTap:isTap)
            }
        }
        strokeChangedMode = store.active?.rawValue != strokeBone
        if changed {
            render()
            if Date.timeIntervalSinceReferenceDate-lastFeedback > 0.08 {
                lastFeedback = Date.timeIntervalSinceReferenceDate
                if store.haptics { (store.tool == .hammer ? impactFeedback : softFeedback).impactOccurred(intensity:store.tool == .hammer ? 0.85 : 0.35) }
                puff(at:point)
            }
        }
        effects.childNode(withName:"cursor")?.removeFromParent()
        if !strokeChangedMode {
            let cursor = SKShapeNode(circleOfRadius:store.active == nil ? 22 : 13*polishScale)
            cursor.name = "cursor"; cursor.position = point; cursor.strokeColor = UIColor.white.withAlphaComponent(0.8); cursor.lineWidth = 2
            effects.addChild(cursor)
        }
    }
    private func distance(_ a: CGPoint,_ b: CGPoint) -> CGFloat { hypot(a.x-b.x,a.y-b.y) }
    private func puff(at point: CGPoint) {
        for i in 0..<5 {
            let particle = SKShapeNode(circleOfRadius:2); particle.position = point
            particle.fillColor = BoneArt.cream; particle.strokeColor = .clear; effects.addChild(particle)
            let angle = CGFloat(i)*1.25
            particle.run(.sequence([.group([.moveBy(x:cos(angle)*24,y:sin(angle)*24,duration:0.28),.fadeOut(withDuration:0.28)]),.removeFromParent()]))
        }
    }
}
