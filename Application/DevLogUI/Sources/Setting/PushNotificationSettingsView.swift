//
//  PushNotificationSettingsView.swift
//  DevLogUI
//
//  Created by opfic on 5/14/25.
//

import SwiftUI
import DevLogPresentation

struct PushNotificationSettingsView: View {
    @State var viewModel: PushNotificationSettingsViewModel

    var body: some View {
        List {
            Section(content: {
                Toggle(isOn:
                        Binding(
                            get: { viewModel.state.pushNotificationEnable },
                            set: { viewModel.send(.setPushNotificationEnable($0)) }
                        )) {
                            Text(String(localized: "push_settings_enable"))
                        }
                        .tint(.blue)
            }, footer: {
                Text(String(localized: "push_settings_footer"))
            })
            Section {
                ForEach([9, 15, 18, 21], id: \.self) { hour in
                    if let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) {
                        HStack {
                            Text(formattedTimeString(date))
                            Spacer()
                            if viewModel.state.pushNotificationHour == hour &&
                                viewModel.state.pushNotificationMinute == 0 {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.send(.selectPresetTime(date))
                        }
                    }
                }
                HStack {
                    Text(String(localized: "push_settings_custom"))
                    Spacer()
                    Text(formattedTimeString(viewModel.state.viewPushNotificationTime))
                        .foregroundStyle(.secondary)
                    if viewModel.state.pushNotificationMinute != 0 {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.send(.setShowTimePicker(true))
                }
            }
            .disabled(!viewModel.state.pushNotificationEnable)
            .opacity(viewModel.state.pushNotificationEnable ? 1.0 : 0.2)
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "nav_push_settings"))
        .overlay {
            if viewModel.state.isLoading {
                LoadingView()
            }
        }
        .onAppear {
            viewModel.send(.fetchSettings)
        }
        .sheet(isPresented: Binding(
            get: { viewModel.state.showTimePicker },
            set: { viewModel.send(.setShowTimePicker($0))  }
        )) {
            NavigationStack {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { viewModel.state.sheetPushNotificationTime },
                        set: { viewModel.send(.setPushNotificationTime(sheet: $0)) }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .onAppear { UIDatePicker.appearance().minuteInterval = 5 }
                .onDisappear { UIDatePicker.appearance().minuteInterval = 1 /* 기본값으로 복원 */ }
                .toolbar {
                    ToolbarLeadingButton {
                        viewModel.send(.rollbackUpdate)
                    }
                    ToolbarTrailingButton {
                        viewModel.send(.confirmUpdate)
                    }
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear.onAppear {
                            viewModel.send(.setSheetHeight(geometry.size.height))
                        }
                    }
                )
            }
            .presentationDragIndicator(.hidden)
            .presentationDetents([.height(viewModel.state.sheetHeight)])
        }
    }

    private func formattedTimeString(_ date: Date) -> String {
        date.formatted(.dateTime.hour().minute())
    }
}
