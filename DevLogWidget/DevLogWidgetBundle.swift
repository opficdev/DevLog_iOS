//
//  DevLogWidgetBundle.swift
//  DevLogWidget
//
//  Created by 최윤진 on 4/14/26.
//

import WidgetKit
import SwiftUI

@main
struct DevLogWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayTodoWidget()
        ProfileHeatmapWidget()
    }
}
