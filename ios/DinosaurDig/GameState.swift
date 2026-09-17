import Foundation
import Combine

struct DigPoint: Codable, Equatable {
    var x: Double
    var y: Double
    func distance(to other: DigPoint) -> Double { hypot(x - other.x, y - other.y) }
}

enum BoneKind: Int, Codable, CaseIterable, Identifiable {
    case skull, jaw, spine, ribs, pelvis, arms, legs, tail
    var id: Int { rawValue }
    var title: String { ["頭骨", "下あご", "背骨", "肋骨", "骨盤", "前脚", "後脚", "尾"][rawValue] }
    var reading: String { ["あたま", "あご", "せぼね", "ろっこつ", "こつばん", "まえあし", "うしろあし", "しっぽ"][rawValue] }
}

enum DigTool: String, CaseIterable { case brush, hammer }

struct BoneProgress: Codable, Equatable {
    var rockHits: Int
    var soil: Set<Int> = []
    var polished: Set<Int> = []
    var collected = false
    var exposed: Bool { soil.count >= 20 }
}

struct Expedition: Codable, Equatable {
    static let version = 1
    var version = Self.version
    var bones = BoneKind.allCases.map { BoneProgress(rockHits: $0.rawValue.isMultiple(of: 2) ? 4 : 0) }
    var activeBone: Int?
    var isValid: Bool {
        version == Self.version && bones.count == 8 &&
        (activeBone == nil || (0..<8).contains(activeBone!)) &&
        bones.allSatisfy { (0...4).contains($0.rockHits) && $0.soil.allSatisfy { (0..<25).contains($0) } && $0.polished.allSatisfy { (0..<10000).contains($0) } } &&
        (activeBone == nil || (!bones[activeBone!].collected && bones[activeBone!].exposed && bones[activeBone!].rockHits == 0))
    }
}

/// Coordinates and state transitions are independent of SpriteKit's frame rate.
@MainActor final class GameStore: ObservableObject {
    @Published private(set) var expedition: Expedition
    @Published var tool: DigTool = .brush
    @Published var message = "ブラシで砂をはらって、ほねをみつけよう"
    @Published var hintBone: Int?
    @Published var haptics = true
    private let defaults: UserDefaults
    private let saveKey = "dinosaur.native.expedition.v1"
    private var pendingSave: DispatchWorkItem?
    static let soilPoints: [DigPoint] = (0..<25).map {
        DigPoint(x: Double($0 % 5 - 2) * 19, y: Double($0 / 5 - 2) * 15)
    }
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: saveKey), let saved = try? JSONDecoder().decode(Expedition.self, from: data), saved.isValid {
            expedition = saved
        } else { expedition = Expedition() }
    }
    var count: Int { expedition.bones.filter(\.collected).count }
    var complete: Bool { count == 8 }
    var active: BoneKind? { expedition.activeBone.flatMap(BoneKind.init(rawValue:)) }
    var cleanFraction: Double {
        guard let bone = active else { return 0 }
        let samples = BoneArt.dirtPoints(for: bone)
        let cleared = expedition.bones[bone.rawValue].polished
        return Double(samples.indices.filter { cleared.contains($0) }.count) / Double(max(1, samples.count))
    }
    func select(_ tool: DigTool) {
        self.tool = tool
        message = tool == .brush ? "砂をはらおう。見えたほねをタップ！" : "岩を4回たたいて、ひびを入れよう"
    }
    @discardableResult func dig(bone: BoneKind, at point: DigPoint, isTap: Bool) -> Bool {
        guard active == nil, !complete, !expedition.bones[bone.rawValue].collected else { return false }
        let index = bone.rawValue
        if expedition.bones[index].rockHits > 0 {
            guard tool == .hammer else { message = "かたい岩は、ハンマーでたたこう"; return false }
            guard isTap else { return false }
            expedition.bones[index].rockHits -= 1
            message = expedition.bones[index].rockHits == 0 ? "岩がわれた！ ブラシで砂をはらおう" : "いいぞ！ 岩にひびが入ったよ"
        } else {
            guard tool == .brush else { message = "ほねはブラシで、やさしくね"; return false }
            if expedition.bones[index].exposed {
                expedition.activeBone = index
                message = "茶色いよごれを、ゆっくりなぞろう"
                hintBone = nil
            } else {
                let old = expedition.bones[index].soil.count
                for (id, sample) in Self.soilPoints.enumerated() where point.distance(to: sample) < 27 {
                    expedition.bones[index].soil.insert(id)
                }
                guard old != expedition.bones[index].soil.count else { return false }
                message = expedition.bones[index].exposed ? "ほねが見えた！ さわって大きくしよう" : "その調子！ まわりの砂もはらおう"
            }
        }
        scheduleSave()
        return true
    }
    @discardableResult func polish(at point: DigPoint) -> Bool {
        guard let bone = active, cleanFraction < 1 else { return false }
        let index = bone.rawValue
        let old = expedition.bones[index].polished.count
        for (id, sample) in BoneArt.dirtPoints(for: bone).enumerated() where point.distance(to: sample) < 13 {
            expedition.bones[index].polished.insert(id)
        }
        guard expedition.bones[index].polished.count != old else { return false }
        message = cleanFraction == 1 ? "ぴかぴか！ ほねをコレクションにしまおう" : "茶色いところを、ブラシでなぞろう"
        scheduleSave()
        return true
    }
    func collect() {
        guard let bone = active, cleanFraction == 1, !expedition.bones[bone.rawValue].collected else { return }
        expedition.bones[bone.rawValue].collected = true
        expedition.activeBone = nil
        hintBone = nil
        message = "\(bone.reading)をはっけん！ つぎのほねをさがそう"
        save()
    }
    func backToField() { expedition.activeBone = nil; message = "つづきは、ほねをさわると再開できるよ"; save() }
    func hint() {
        if active != nil { message = "のこっている茶色い点をなぞろう"; return }
        guard let id = expedition.bones.firstIndex(where: { !$0.collected }) else { return }
        hintBone = id
        tool = expedition.bones[id].rockHits > 0 ? .hammer : .brush
        message = "光っている場所を\(tool == .hammer ? "ハンマー" : "ブラシ")で調べよう"
    }
    func restart() {
        pendingSave?.cancel()
        expedition = Expedition(); tool = .brush; hintBone = nil
        message = "新しい調査だ！ 8このほねをみつけよう"
        save()
    }
    private func scheduleSave() {
        pendingSave?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.save() }
        pendingSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }
    func save() {
        pendingSave?.cancel()
        if let data = try? JSONEncoder().encode(expedition) { defaults.set(data, forKey: saveKey) }
    }
}
