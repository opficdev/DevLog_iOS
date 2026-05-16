//
//  SystemTheme.swift
//  DevLogDomain
//
//  Created by opfic on 5/6/25.
//

import SwiftUI

public enum SystemTheme: String, Identifiable {
    case automatic
    case light
    case dark
    
    public var id: String {
        rawValue
    }
    
    public var localizedName: String {
        switch self {
        case .automatic:
            return NSLocalizedString("system_theme_automatic", comment: "System theme: automatic")
        case .light:
            return NSLocalizedString("system_theme_light", comment: "System theme: light")
        case .dark:
            return NSLocalizedString("system_theme_dark", comment: "System theme: dark")
        }
    }
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .automatic:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
