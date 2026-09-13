//
//  DevelopmentRecordPresentation.swift
//  Development
//
//  Created by opfic on 9/13/26.
//

import Foundation
import PresentationShared

enum DevelopmentRecordPresentation {
    static func text(_ key: String.LocalizationValue) -> String {
        String(localized: key, bundle: PresentationResources.bundle)
    }

    static func versionLabel(_ number: Int) -> String {
        "v1.\(max(0, number - 1))"
    }
}
