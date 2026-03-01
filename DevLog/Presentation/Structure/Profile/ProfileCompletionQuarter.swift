//
//  ProfileCompletionQuarter.swift
//  DevLog
//
//  Created by opfic on 3/2/26.
//

import Foundation

struct ProfileCompletionQuarter: Identifiable, Hashable {
    let quarterStart: Date
    let months: [ProfileCompletionMonth]

    var id: Date { quarterStart }
}
