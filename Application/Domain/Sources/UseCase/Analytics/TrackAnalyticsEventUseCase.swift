//
//  TrackAnalyticsEventUseCase.swift
//  Domain
//
//  Created by opfic on 5/27/26.
//

public protocol TrackAnalyticsEventUseCase {
    func execute(_ event: AnalyticsEvent)
}
