//
//  PushNotificationSettingsView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct PushNotificationSettingsView: View {
    @StateObject var viewModel: PushNotificationSettingsViewModel

    var body: some View {
        List {
            Section(content: {
                Toggle(isOn:
                        Binding(
                            get: { viewModel.state.pushNotificationEnable },
                            set: { viewModel.send(.setPushNotificationEnable($0)) }
                        )) {
                            Text("푸시 알람 활성화")
                        }
            }, footer: {
                Text("설정에서의 푸시 알람 설정과 별개입니다.")
            })
            Section {
                ForEach([9, 15, 18, 21], id: \.self) { hour in
                    HStack {
                        Text((hour < 12 ? "오전 \(hour)시" : "오후 \(hour - 12)시"))
                        Spacer()
                        if viewModel.state.pushNotificationHour == hour {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.send(.setPushNotificationHour(hour))
                    }
                }
                HStack {
                    Text("사용자 설정")
                    Spacer()
                    Text(formattedTimeString(viewModel.state.pushNotificationTime))
                        .foregroundStyle(.secondary)
                    if ![9, 15, 18, 21].contains(viewModel.state.pushNotificationHour) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.accentColor)
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
        .navigationTitle("알람")
        .onAppear {
            viewModel.send(.onAppear)
        }
        .sheet(isPresented: Binding(
            get: { viewModel.state.showTimePicker },
            set: { _ in viewModel.send(.setShowTimePicker(false)) }
        )) {
            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel.state.pushNotificationTime },
                    set: { viewModel.send(.setPushNotificationTime($0)) }
                ),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .presentationDragIndicator(.hidden)
            .presentationDetents([.height(viewModel.state.sheetHeight)])
            .onAppear {
                UIDatePicker.appearance().minuteInterval = 5
            }
            .onDisappear {
                UIDatePicker.appearance().minuteInterval = 1 // 기본값으로 복원
            }
            .background(
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        viewModel.send(.setSheetHeight(geometry.size.height))
                    }
                }
            )
        }
    }

    private func formattedTimeString(_ date: Date) -> String {
        let minuteValue = Calendar.current.component(.minute, from: date)
        let formatStyle: Date.FormatStyle = .dateTime.hour(.twoDigits(amPM: .wide))

        if minuteValue == 0 {
            return "\(date.formatted(formatStyle))"
        }

        let hourText = date.formatted(formatStyle)
        let minuteText = date.formatted(.dateTime.minute(.twoDigits))
        return "\(hourText) \(minuteText)분"
    }
}
