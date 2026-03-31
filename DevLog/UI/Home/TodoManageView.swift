//
//  TodoManageView.swift
//  DevLog
//
//  Created by opfic on 6/16/25.
//

import SwiftUI

struct TodoManageView: View {
    @State var viewModel: TodoManageViewModel
    @State private var tmpText = ""
    var onDismiss: (([TodoCategoryItem]) -> Void)?

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.state.preferences, id: \.id) { item in
                    HStack(spacing: 0) {
                        CheckBox(isChecked: item.isVisible, font: .title3)
                            .padding(.horizontal)
                            .onTapGesture {
                                viewModel.send(.tapItem(item))
                            }
                        Text(item.localizedName)
                            .lineLimit(1)
                        Spacer()
                        if item.isUserCategory {
                            Button {
                                viewModel.send(.tapEditUserCategory(item))
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                            }
                            .buttonStyle(.borderless)
                            .padding(.trailing, 8)

                            Button(role: .destructive) {
                                viewModel.send(.tapDeleteUserCategory(item))
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .padding(.trailing)
                        }
                    }
                }
                .onMove { source, destination in
                    viewModel.send(.moveItem(from: source, target: destination))
                }
                .listRowInsets(EdgeInsets())
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle(String(localized: "todo_manage_title"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .sheet(isPresented: Binding(
                get: { viewModel.state.showSheet },
                set: { viewModel.send(.setShowSheet($0)) }
            )) {
                categorySheet
            }
            .alert(
                String(localized: "todo_manage_delete_category_title"),
                isPresented: Binding(
                    get: { viewModel.state.showAlert },
                    set: { viewModel.send(.setShowAlert($0)) }
                )
            ) {
                Button(String(localized: "common_cancel"), role: .cancel) {
                    viewModel.send(.setShowAlert(false))
                }
                Button(String(localized: "common_delete"), role: .destructive) {
                    viewModel.send(.confirmDeleteUserCategory)
                }
            } message: {
                Text(String(localized: "todo_manage_delete_category_message"))
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
                    Button {
                        onDismiss?(viewModel.state.preferences)
                    } label: {
                        Text(String(localized: "profile_done"))
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
                            prompt: Text(viewModel.placeholder).foregroundStyle(.secondary)
                        )
                        .frame(height: UIFont.preferredFont(forTextStyle: .body).lineHeight)
                        .onAppear {
                            tmpText = currentCategoryName
                        }
                        .onChange(of: tmpText) { _, value in
                            viewModel.send(.setCategoryName(value))
                            tmpText = currentCategoryName
                        }

                        Text(viewModel.categoryNameCountText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                Section {
                    let color = Color(hexString: currentCategoryColorHex) ?? .randomValue
                    ColorPicker(selection: Binding(
                        get: { color },
                        set: { viewModel.send(.setCategoryColor($0)) }
                    ), supportsOpacity: false) {
                        Text(currentCategoryColorHex.isEmpty ? "#" : currentCategoryColorHex)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .frame(height: 1)
                                    .offset(y: 1)
                            }
                            .foregroundStyle(color)
                            .onTapGesture {
                                viewModel.send(.setRandomCategoryColor)
                            }
                    }
                    .pickerStyle(.palette)
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "common_close")) {
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

    private var currentCategoryName: String {
        guard
            let categoryItem = viewModel.state.category,
            case .user(let userTodoCategory) = categoryItem.category
        else {
            return ""
        }

        return userTodoCategory.name
    }

    private var currentCategoryColorHex: String {
        guard
            let categoryItem = viewModel.state.category,
            case .user(let userTodoCategory) = categoryItem.category
        else {
            return ""
        }

        return userTodoCategory.colorHex
    }
}
