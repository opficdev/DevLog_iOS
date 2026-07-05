//
//  ThemeView.swift
//  ProfileTab
//
//  Created by opfic on 5/6/25.
//

import SwiftUI
import Core

struct ThemeView: View {
    @Binding var theme: SystemTheme

    var body: some View {
        List {
            Button(action: {
                theme = .automatic
            }) {
                HStack {
                    Text(SystemTheme.automatic.localizedName)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    if theme == .automatic {
                        Image(systemName: "checkmark")
                    }
                }
            }
            Button(action: {
                theme = .light
            }) {
                HStack {
                    Text(SystemTheme.light.localizedName)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    if theme == .light {
                        Image(systemName: "checkmark")
                    }
                }
            }
            Button(action: {
                theme = .dark
            }) {
                HStack {
                    Text(SystemTheme.dark.localizedName)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    if theme == .dark {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(String(localized: "nav_theme"))
                    .bold()
            }
        }
    }
}
