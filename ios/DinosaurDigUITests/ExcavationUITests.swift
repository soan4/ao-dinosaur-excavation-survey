import XCTest

final class ExcavationUITests: XCTestCase {
    func testPortraitFieldAndCollection() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing"]; app.launch()
        XCTAssertTrue(app.buttons["brush"].waitForExistence(timeout:10))
        XCTAssertTrue(app.buttons["hammer"].isHittable)
        XCTAssertTrue(app.buttons["collection"].isHittable)
        attach("01-field")
        app.buttons["collection"].tap()
        XCTAssertTrue(app.staticTexts["collectionTitle"].waitForExistence(timeout:3))
        attach("02-collection")
    }
    func testEightBoneJourney() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing"]; app.launch()
        let field = app.descendants(matching:.any)["digField"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout:10))
        for bone in 0..<8 {
            let x = bone % 2 == 0 ? 0.26 : 0.74
            let y = 0.135 + Double(bone/2)*0.245
            if bone.isMultiple(of:2) {
                app.buttons["hammer"].tap()
                for _ in 0..<4 { field.coordinate(withNormalizedOffset:CGVector(dx:x,dy:y)).tap() }
            }
            app.buttons["brush"].tap()
            for offset in [-0.06,0.0,0.06] {
                if app.buttons["collectBone"].exists { break }
                field.coordinate(withNormalizedOffset:CGVector(dx:x-0.14,dy:y+offset)).press(forDuration:0.05,thenDragTo:field.coordinate(withNormalizedOffset:CGVector(dx:x+0.14,dy:y+offset)),withVelocity:.slow,thenHoldForDuration:0)
            }
            if !app.buttons["collectBone"].exists { field.coordinate(withNormalizedOffset:CGVector(dx:x,dy:y)).tap() }
            XCTAssertTrue(app.buttons["collectBone"].waitForExistence(timeout:3),"Bone \(bone) did not open")
            if bone == 0 { attach("03-polishing") }
            let polishScale = min((field.frame.width - 40) / 110, (field.frame.height - 60) / 100)
            for localY in stride(from: -36.0, through: 54.0, by: 18.0) {
                let row = 0.5 + localY * polishScale / field.frame.height
                if app.buttons["collectBone"].isEnabled { break }
                field.coordinate(withNormalizedOffset:CGVector(dx:0.04,dy:row)).press(forDuration:0.01,thenDragTo:field.coordinate(withNormalizedOffset:CGVector(dx:0.96,dy:row)),withVelocity:.fast,thenHoldForDuration:0)
            }
            XCTAssertTrue(app.buttons["collectBone"].isEnabled,"Bone \(bone) still dirty")
            app.buttons["collectBone"].tap()
        }
        XCTAssertTrue(app.staticTexts["completionTitle"].waitForExistence(timeout:5))
        let assembled = NSPredicate(format: "label == %@", "ぜんしんこっかく かんせい！")
        expectation(for: assembled, evaluatedWith: app.staticTexts["assemblyState"])
        waitForExpectations(timeout: 5)
        attach("04-complete")
        app.swipeUp()
        app.buttons["restartExpedition"].tap()
        XCTAssertTrue(app.buttons["brush"].waitForExistence(timeout:3))
        XCTAssertEqual(app.staticTexts["boneCount"].label,"0 / 8")
    }
    private func attach(_ name: String) {
        let attachment = XCTAttachment(screenshot:XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
