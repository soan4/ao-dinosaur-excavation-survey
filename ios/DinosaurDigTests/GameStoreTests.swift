import XCTest
@testable import DinosaurDig

@MainActor final class GameStoreTests: XCTestCase {
    var defaults: UserDefaults!
    var store: GameStore!
    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName:"DinosaurDig.Tests.\(UUID().uuidString)")!
        store = GameStore(defaults:defaults)
    }
    func expose(_ bone: BoneKind) {
        store.select(.hammer)
        for _ in 0..<4 { store.dig(bone:bone,at:DigPoint(x:0,y:0),isTap:true) }
        store.select(.brush)
        for point in GameStore.soilPoints { store.dig(bone:bone,at:point,isTap:true) }
        store.dig(bone:bone,at:DigPoint(x:0,y:0),isTap:true)
    }
    func testRockRequiresFourDiscreteHammerTaps() {
        XCTAssertFalse(store.dig(bone:.skull,at:.init(x:0,y:0),isTap:true))
        XCTAssertEqual(store.expedition.bones[0].rockHits,4)
        store.select(.hammer)
        XCTAssertFalse(store.dig(bone:.skull,at:.init(x:0,y:0),isTap:false))
        for remaining in (0...3).reversed() {
            XCTAssertTrue(store.dig(bone:.skull,at:.init(x:0,y:0),isTap:true))
            XCTAssertEqual(store.expedition.bones[0].rockHits,remaining)
        }
        XCTAssertNil(store.active)
        XCTAssertFalse(store.dig(bone:.skull,at:.init(x:0,y:0),isTap:true))
    }
    func testPolishCountsOnlyBoneSurfaceAndCannotCollectEarly() {
        expose(.jaw)
        XCTAssertEqual(store.active,.jaw)
        store.collect(); XCTAssertEqual(store.count,0)
        XCTAssertFalse(store.polish(at:.init(x:500,y:500)))
        XCTAssertEqual(store.cleanFraction,0)
        for point in BoneArt.dirtPoints(for:.jaw) { store.polish(at:point) }
        XCTAssertEqual(store.cleanFraction,1)
        store.collect(); store.collect()
        XCTAssertEqual(store.count,1)
    }
    func testAllEightPartsCompleteAndRestart() {
        for bone in BoneKind.allCases {
            expose(bone)
            XCTAssertEqual(store.active,bone)
            XCTAssertFalse(BoneArt.dirtPoints(for:bone).isEmpty)
            for point in BoneArt.dirtPoints(for:bone) { store.polish(at:point) }
            store.collect()
            XCTAssertEqual(store.count,bone.rawValue+1)
        }
        XCTAssertTrue(store.complete)
        store.restart()
        XCTAssertFalse(store.complete); XCTAssertEqual(store.count,0)
        XCTAssertEqual(store.expedition,Expedition())
    }
    func testPartialPolishPersistsAndResumeDoesNotDuplicate() {
        expose(.ribs)
        store.polish(at:BoneArt.dirtPoints(for:.ribs)[0]); store.save()
        let reloaded = GameStore(defaults:defaults)
        XCTAssertEqual(reloaded.expedition,store.expedition)
        XCTAssertGreaterThan(reloaded.cleanFraction,0)
        reloaded.backToField()
        XCTAssertNil(reloaded.active)
        reloaded.dig(bone:.ribs,at:.init(x:0,y:0),isTap:true)
        XCTAssertEqual(reloaded.active,.ribs)
        XCTAssertEqual(reloaded.cleanFraction,store.cleanFraction)
    }
    func testInvalidSaveRecoversSafely() throws {
        var bad = Expedition(); bad.activeBone = 99
        defaults.set(try JSONEncoder().encode(bad),forKey:"dinosaur.native.expedition.v1")
        XCTAssertEqual(GameStore(defaults:defaults).expedition,Expedition())
        bad = Expedition(); bad.bones = []
        defaults.set(try JSONEncoder().encode(bad),forKey:"dinosaur.native.expedition.v1")
        XCTAssertEqual(GameStore(defaults:defaults).expedition,Expedition())
    }
    func testHintSelectsRequiredToolAndResizePreservesProgress() {
        store.hint(); XCTAssertEqual(store.tool,.hammer); XCTAssertEqual(store.hintBone,0)
        expose(.skull)
        let before = store.expedition
        let scene = ExcavationScene(size:.init(width:320,height:400)); scene.store = store
        scene.size = .init(width:393,height:510)
        XCTAssertEqual(before,store.expedition)
    }
}
