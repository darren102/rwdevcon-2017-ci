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
import UIKit
import CoreData

typealias TableCellConfigurationBlock = (_: ScheduleTableViewCell, _: NSIndexPath, _: Session) -> ()

class ScheduleDataSource: NSObject {

  // MARK: - Properties
  var coreDataStack: CoreDataStack!

  var startDate: NSDate?
  var endDate: NSDate?
  var favoritesOnly = false

  let hourHeaderHeight: CGFloat = 40
  let numberOfTracksInSchedule = 3
  let numberOfHoursInSchedule = 11
  let trackHeaderWidth: CGFloat = 120
  let widthPerHour: CGFloat = 180
  let firstHour = 8
  
  var tableCellConfigurationBlock: TableCellConfigurationBlock?

  var allSessions: [Session] {
    let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Session")

    if self.startDate != nil && self.endDate != nil {
      fetch.predicate = NSPredicate(format: "(active = %@) AND (date >= %@) AND (date <= %@)", argumentArray: [true, self.startDate!, self.endDate!])
    } else if favoritesOnly {
      fetch.predicate = NSPredicate(format: "active = %@ AND identifier IN %@", argumentArray: [true, Array(Config.favoriteSessions().values)])
    } else {
      fetch.predicate = NSPredicate(format: "active = %@", argumentArray: [true])
    }
    fetch.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true), NSSortDescriptor(key: "track.trackId", ascending: true), NSSortDescriptor(key: "column", ascending: true)]
    
    do {
      guard let results = try coreDataStack.context.fetch(fetch) as? [Session] else { return [] }
      return results
    } catch {
      return []
    }
  }

  var distinctTimes: [String] {
    return type(of:self).distinctTimes(for: allSessions, favoritesOnly: favoritesOnly)
  }

  class func distinctTimes(for sessions: [SessionDateFormattable], favoritesOnly: Bool) -> [String] {
    var times = [String]()

    if favoritesOnly {
      for session in sessions {
        let last = times.last
        let thisDayOfWeek = session.startDateDayOfWeek

        if (last == nil) || (last != nil && last! != thisDayOfWeek) {
          times.append(thisDayOfWeek)
        }
      }
    } else {
      for session in sessions {
        let last = times.last
        if (last == nil) || (last != nil && last! != session.startDateTimeString) {
          times.append(session.startDateTimeString)
        }
      }
    }

    return times
  }


  internal func sessionForIndexPath(indexPath: NSIndexPath) -> Session {
    let sessions = arrayOfSessionsForSection(section: indexPath.section)
    return sessions[indexPath.row]
  }
  
  // MARK: Private Utilities

  fileprivate func arrayOfSessionsForSection(section: Int) -> [Session] {
    if favoritesOnly {
      let weekday = distinctTimes[section]
      return allSessions.filter({ (session) -> Bool in
        return session.startDateTimeString.hasPrefix(weekday)
      })
    } else {
      let startTimeString = distinctTimes[section]
      return allSessions.filter({ (session) -> Bool in
        return session.startDateTimeString == startTimeString
      })
    }
  }
  
  private func groupDictionaryForSection(section: Int) -> NSDictionary {
    return ["Header": distinctTimes[section]]
  }
  
}

extension ScheduleDataSource: UITableViewDataSource {

  func numberOfSections(in tableView: UITableView) -> Int {
    return distinctTimes.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return arrayOfSessionsForSection(section: section).count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleTableViewCell") as! ScheduleTableViewCell
    let session = sessionForIndexPath(indexPath: indexPath as NSIndexPath)
    if let configureBlock = tableCellConfigurationBlock {
      configureBlock(cell, indexPath as NSIndexPath, session)
    }
    return cell
  }
}
