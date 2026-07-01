//
//  Calendar.swift
//  Core
//
//  Created by opfic on 4/30/26.
//

import Foundation

public extension Calendar {
    func startOfQuarter(for date: Date) -> Date {
        let month = component(.month, from: date)
        let startMonth = ((month - 1) / 3) * 3 + 1
        var components = dateComponents([.year], from: date)
        components.month = startMonth
        components.day = 1
        return self.date(from: components) ?? startOfDay(for: date)
    }
}
