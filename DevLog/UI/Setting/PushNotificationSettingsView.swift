//
//  PushNotificationSettingsView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct PushNotificationSettingsView: View {
    @StateObject var viewModel: PushNotificationSettingsViewModel
    @State private var sheetHeight: CGFloat = 0 // 시트 높이 조정용

    var body: some View {
        List {
            Section(content: {
                Toggle(isOn:
                        Binding(
                            get: { viewModel.state.pushNotificationEnable },
                            set: { newValue in
                                viewModel.send(.setPushNotificationEnable(newValue))
                            }
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
                    Text("\(viewModel.state.pushNotificationHour)시")
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
        .sheet(isPresented: Binding(
            get: { viewModel.state.showTimePicker },
            set: { _ in viewModel.send(.setShowTimePicker(false)) }
        )) {
            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel.state.pushNotificationTime },
                    set: { newValue in
                        viewModel.send(.setPushNotificationTime(newValue))
                    }),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .presentationDragIndicator(.hidden)
            .presentationDetents([.height(sheetHeight)])
            .onAppear {
                UIDatePicker.appearance().minuteInterval = 5
            }
            .onDisappear {
                UIDatePicker.appearance().minuteInterval = 1 // 기본값으로 복원
            }
            .background(
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        if sheetHeight == 0 {
                            sheetHeight = geometry.size.height
                        }
                    }
                }
            )
        }
    }
}
