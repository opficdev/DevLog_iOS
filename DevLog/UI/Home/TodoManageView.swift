//
//  TodoManageView.swift
//  DevLog
//
//  Created by opfic on 6/16/25.
//

import SwiftUI

struct TodoManageView: View {
    @State var viewModel: TodoManageViewModel
    @State private var tmpText: String = ""
    var onDismiss: (([TodoCategoryPreference]) -> Void)?

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.state.preferences, id: \.id) { preference in
                    let category = preference.category
                    HStack(spacing: 0) {
                        CheckBox(isChecked: preference.isVisible, font: .title3)
                            .padding(.horizontal)
                            .onTapGesture {
                                viewModel.send(.tapItem(category))
                            }
                        Text(category.localizedName)
                            .lineLimit(1)
                        Spacer()
                        if case .user = category {
                            Button {
                                viewModel.send(.tapEditUserCategory(preference))
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                            }
                            .buttonStyle(.borderless)
                            .padding(.trailing, 8)

                            Button(role: .destructive) {
                                viewModel.send(.tapDeleteUserCategory(preference))
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .padding(.trailing)
                        }
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
                get: { viewModel.state.showSheet },
                set: { viewModel.send(.setShowSheet($0)) }
            )) {
                categorySheet
            }
            .alert(
                "카테고리 삭제",
                isPresented: Binding(
                    get: { viewModel.state.showAlert },
                    set: { viewModel.send(.setShowAlert($0)) }
                )
            ) {
                Button("취소", role: .cancel) {
                    viewModel.send(.setShowAlert(false))
                }
                Button("삭제", role: .destructive) {
                    viewModel.send(.confirmDeleteUserCategory)
                }
            } message: {
                Text("이 카테고리를 삭제하면 해당하던 TODO는 기타 카테고리로 처리됩니다.\n정말 삭제하시겠습니까?")
                    .multilineTextAlignment(.leading)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.send(.tapAddUserCategory)
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onDismiss?(viewModel.state.preferences)
                    }) {
                        Text("완료")
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var categorySheet: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 8) {
                        TextField(
                            "",
                            text: $tmpText,
                            prompt: Text(viewModel.placerholder).foregroundStyle(.secondary)
                        )
                        .frame(height: UIFont.preferredFont(forTextStyle: .body).lineHeight)
                        .onAppear {
                            tmpText = viewModel.state.category?.name ?? ""
                        }
                        .onChange(of: tmpText) { _, value in
                            viewModel.send(.setCategoryName(value))
                            tmpText = viewModel.state.category?.name ?? ""
                        }

                        Text(viewModel.categoryNameCountText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                
                Section {
                    let color = Color(hexString: viewModel.state.category?.colorHex ?? "#0A84FF") ?? .blue
                    ColorPicker(selection: Binding(
                        get: { color },
                        set: { viewModel.send(.setCategoryColor($0)) }
                    ), supportsOpacity: false) {
                        Text(viewModel.state.category?.colorHex ?? "#")
                            .foregroundStyle(color)
                    }
                    .pickerStyle(.palette)
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        viewModel.send(.setShowSheet(false))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(viewModel.submitTitle) {
                        viewModel.send(.saveUserCategory)
                    }
                    .disabled(!viewModel.canSubmitUserCategory)
                }
            }
        }
    }
}
