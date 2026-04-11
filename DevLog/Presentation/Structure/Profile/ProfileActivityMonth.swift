//
//  ProfileActivityMonth.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import Foundation

struct ProfileActivityMonth: Identifiable, Hashable {
    var id: Date { monthStart }
    let monthStart: Date
    let weeks: [[ProfileActivityDay]]
}
