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
            .sheet(isPresented: Binding(
                get: { viewModel.state.showAddCategorySheet },
                set: { viewModel.send(.setShowAddCategorySheet($0)) }
            )) {
                categorySheet
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.send(.setShowAddCategorySheet(true))
                    } label: {
                        Image(systemName: "plus")
                    }
                }

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

    private var categorySheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        "카테고리명",
                        text: Binding(
                            get: { viewModel.state.categoryName },
                            set: { viewModel.send(.setCategoryName($0)) }
                        )
                    )
                    .frame(height: UIFont.preferredFont(forTextStyle: .body).lineHeight)
                }
                
                Section {
                    ColorPicker(
                        "색상",
                        selection: Binding(
                            get: { viewModel.state.categoryColor },
                            set: { viewModel.send(.setCategoryColor($0)) }
                        ),
                        supportsOpacity: false
                    )
                    .pickerStyle(.palette)
                }
            }
            .navigationTitle("카테고리 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        viewModel.send(.setShowAddCategorySheet(false))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("추가") {
                        viewModel.send(.addUserCategory)
                    }
                    .disabled(!viewModel.canAddUserCategory)
                }
            }
        }
    }
}
