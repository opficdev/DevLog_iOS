//
//  WidgetRepository.swift
//  DevLog
//
//  Created by opfic on 4/29/26.
//

protocol WidgetRepository {
    func saveTodaySnapshot(_ snapshot: TodayWidgetSnapshot) throws
    func saveHeatmapSnapshot(_ snapshot: HeatmapWidgetSnapshot) throws
    func reloadTodayWidget()
    func reloadHeatmapWidget()
}
