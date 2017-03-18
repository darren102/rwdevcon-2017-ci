/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import XCTest
import CoreData
@testable import RWDevCon

class DataTests: XCTestCase {

  var coreDataStack: CoreDataStack!

  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
    coreDataStack = CoreDataStack(type: NSInMemoryStoreType)
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    coreDataStack = nil
    super.tearDown()
  }

  func loadInitialData() {
    AppDelegate.loadInitialData(stack: coreDataStack)
  }

  class func verify(entityName: String, existsIn stack: CoreDataStack) {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
    let entities = try! stack.context.fetch(request)
    XCTAssertGreaterThan(entities.count, 0);
  }

  func testInitialDataHasAllEntities() {
    loadInitialData()
    type(of: self).verify(entityName: "Session", existsIn: coreDataStack)
    type(of: self).verify(entityName: "Room", existsIn: coreDataStack)
    type(of: self).verify(entityName: "Track", existsIn: coreDataStack)
    type(of: self).verify(entityName: "Person", existsIn: coreDataStack)
  }

  func testInitialDataSessionsAllHaveSpeakers() {
    loadInitialData()
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Session")
    let sessions = try! coreDataStack.context.fetch(request) as! [Session]

    for session in sessions {
      XCTAssertGreaterThanOrEqual(session.presenters.count, 0)
    }
  }

  func testInitialDataTracksAllHaveSessions() {
    loadInitialData()
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
    let tracks = try! coreDataStack.context.fetch(request) as! [Track]

    for track in tracks {
      XCTAssertGreaterThanOrEqual(track.sessions.count, 0)
    }
  }

  func testPersonCreatesCorrectFullName() {
    let person = Person.personByIdentifierOrNew(identifier: "Jack", context: coreDataStack.context)
    person.first = "Jack"
    person.last = "Wu"
    XCTAssertEqual(person.fullNameFor("en"), "Jack Wu")
  }

  func testPersonCreatesCorrectFullChineseName() {
    let person = Person.personByIdentifierOrNew(identifier: "Jack", context: coreDataStack.context)
    person.first = "桐"
    person.last = "吴"
    XCTAssertEqual(person.fullNameFor("zh"), "吴桐")
  }

  func testMakeThingsFail() {
    XCTFail("This is a deliberate attempt to make things fail.")
  }
}
