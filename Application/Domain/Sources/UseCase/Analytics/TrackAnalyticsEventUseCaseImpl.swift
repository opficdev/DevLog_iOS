//
//  TrackAnalyticsEventUseCaseImpl.swift
//  Domain
//
//  Created by opfic on 5/27/26.
//

public final class TrackAnalyticsEventUseCaseImpl: TrackAnalyticsEventUseCase {
    private let repository: AnalyticsRepository

    init(_ repository: AnalyticsRepository) {
        self.repository = repository
    }

    public func execute(_ event: AnalyticsEvent) {
        repository.track(event)
    }
}
