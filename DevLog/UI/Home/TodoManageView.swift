//
//  TodoManageView.swift
//  DevLog
//
//  Created by opfic on 6/16/25.
//

import SwiftUI

struct TodoManageView: View {
    @State var viewModel: TodoManageViewModel
    var onDismiss: (([TodoCategoryPreference]) -> Void)?

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.state.todoCategoryPreferences, id: \.id) { preference in
                    let category = preference.category
                    HStack(spacing: 0) {
                        CheckBox(isChecked: preference.isVisible, font: .title3)
                            .padding(.horizontal)
                            .onTapGesture {
                                viewModel.send(.tapItem(category))
                            }
                        Text(category.localizedName)
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
                        onDismiss?(viewModel.state.todoCategoryPreferences)
                    }) {
                        Text("완료")
                    }
                }
            }
        }
    }
}
