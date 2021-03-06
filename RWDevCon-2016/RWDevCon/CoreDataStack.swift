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

import Foundation
import CoreData

public class CoreDataStack {

  // MARK: - Properties
  public static let modelName = "RWDevCon"

  public let context: NSManagedObjectContext
  let psc: NSPersistentStoreCoordinator
  let model: NSManagedObjectModel
  let store: NSPersistentStore?

  // MARK: - Initializers
  init(type: String) {
    let bundle = Bundle.main
    let modelURL = bundle.url(forResource: type(of:self).modelName, withExtension:"momd")!
    model = NSManagedObjectModel(contentsOf: modelURL)!
    psc = NSPersistentStoreCoordinator(managedObjectModel: model)

    context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    context.persistentStoreCoordinator = psc

    let documentsURL = Config.applicationDocumentsDirectory()
    let storeURL = documentsURL.appendingPathComponent("\(type(of:self).modelName).sqlite")

    print("Store is at \(storeURL)")

    let options = [NSInferMappingModelAutomaticallyOption: true,
                   NSMigratePersistentStoresAutomaticallyOption: true]

    do {
      store = try psc.addPersistentStore(ofType: type, configurationName: nil, at: storeURL, options: options)
    } catch {
      do {
        try FileManager.default.removeItem(at: storeURL!)
        print("Model has changed, removing.")
      } catch {
        print("Error removing persistent store: \(error)")
        abort()
      }
      do {
        store = try psc.addPersistentStore(ofType: type, configurationName: nil, at: storeURL, options: options)
      } catch {
        print("Error adding persistent store: \(error)")
        abort()
      }
    }
  }

  convenience init() {
    self.init(type: NSSQLiteStoreType)
  }

  // MARK: - Internal
  func saveContext() {
    guard context.hasChanges else { return }

    do {
      try context.save()
    } catch {
      print("Could not save: \(error)")
      abort()
    }
  }
}
