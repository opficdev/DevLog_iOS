//
//  AnalyticsRepository.swift
//  Domain
//
//  Created by opfic on 5/27/26.
//

public protocol AnalyticsRepository {
    func track(_ event: AnalyticsEvent)
}
