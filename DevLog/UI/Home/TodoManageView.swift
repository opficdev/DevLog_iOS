//
//  TodoManageView.swift
//  DevLog
//
//  Created by opfic on 6/16/25.
//

import SwiftUI

struct TodoManageView: View {
    @StateObject var viewModel: TodoManageViewModel
    var onDismiss: (([TodoKindPreference]) -> Void)?

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.state.todoKindPreferences, id: \.id) { preference in
                    let kind = preference.kind
                    HStack(spacing: 0) {
                        CheckBox(isChecked: preference.isVisible, font: .title3)
                            .padding(.horizontal)
                            .onTapGesture {
                                viewModel.send(.tapItem(kind))
                            }
                        Text(kind.localizedName)
                    }
                }
                .onMove { (source: IndexSet, destination: Int) in
                    viewModel.send(.moveItem(from: source, target: destination))
                }
                .listRowInsets(EdgeInsets())
            }
            //  편집 모드 활성화
            //  row 우측에 line.3.horizontal 추가됨
            .environment(\.editMode, .constant(EditMode.active))
            .navigationTitle("TODO 편집")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onDismiss?(viewModel.state.todoKindPreferences)
                    }) {
                        Text("완료")
                    }
                }
            }
        }
    }
}
