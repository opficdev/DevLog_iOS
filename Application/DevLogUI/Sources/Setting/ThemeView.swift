//
//  ThemeView.swift
//  DevLogUI
//
//  Created by opfic on 5/6/25.
//

import SwiftUI
import DevLogPresentation

struct ThemeView: View {
    @Binding var theme: SettingViewModel.Theme

    var body: some View {
        List {
            Button(action: {
                theme = .automatic
            }) {
                HStack {
                    Text(SettingViewModel.Theme.automatic.localizedName)
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
                    Text(SettingViewModel.Theme.light.localizedName)
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
                    Text(SettingViewModel.Theme.dark.localizedName)
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
