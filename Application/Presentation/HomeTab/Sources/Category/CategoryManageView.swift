//
//  CategoryManageView.swift
//  HomeTab
//
//  Created by opfic on 6/16/25.
//

import SwiftUI
import PresentationShared

struct CategoryManageView: View {
    @Environment(\.isTabContentActive) private var isTabContentActive
    @Bindable var store: StoreOf<CategoryManageFeature>

    var body: some View {
        CardCollectionView<TodoCategoryItem>
            .composable { view in
                view.updateContent(
                    items: store.preferences,
                    header: UIHostingConfiguration {
                        Text(String(localized: "todo_manage_description", bundle: PresentationResources.bundle))
                            .font(.footnote)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .margins(.horizontal, 16)
                    .margins(.vertical, 8),
                    footer: UIHostingConfiguration {
                        Button {
                            store.send(.tapAddUserCategory)
                        } label: {
                            Label(
                                String(localized: "todo_manage_add_category_title", bundle: PresentationResources.bundle),
                                systemImage: "plus.circle.fill"
                            )
                            .font(.headline)
                            .foregroundStyle(Color.onPrimaryContainer)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .adaptiveButtonStyle(shape: RoundedRectangle(cornerRadius: 16), color: .primaryContainer)
                    }
                    .margins(.horizontal, 16)
                    .margins(.vertical, 24),
                    row: { item in
                        UIHostingConfiguration {
                            CategoryManageRow(
                                item: item,
                                onToggle: { store.send(.tapItem(item)) },
                                onEdit: { store.send(.tapEditUserCategory(item)) },
                                onDelete: { store.send(.tapDeleteUserCategory(item)) }
                            )
                        }
                        .margins(.horizontal, 0)
                        .margins(.vertical, 8)
                    },
                    onMove: { source, destination in
                        store.send(.moveItem(from: source, target: destination))
                    }
                )
            }
            .ignoresSafeArea(edges: .bottom)
            .safeAreaInset(edge: .top, spacing: 0) { toolBar }
            .background(Color.appBackground.ignoresSafeArea())
            .sheet(
                item: $store.scope(state: \.categorySheet, action: \.categorySheet)
                    .activePresentation(when: isTabContentActive)
            ) { sheetStore in
                CategoryManageSheet(store: sheetStore)
            }
            .prominentAlert(store, state: \.alert, action: \.alert)
            .presentationDragIndicator(.visible)
    }

    private var toolBar: some View {
        ZStack {
            Text(String(localized: "todo_category_manage", bundle: PresentationResources.bundle))
                .font(.headline)
            HStack {
                Spacer()
                if #available(iOS 26.0, *) {
                    Button {
                        store.send(.tapDoneButton, animation: .default)
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .topBarButtonStyle()
                } else {
                    Button {
                        store.send(.tapDoneButton, animation: .default)
                    } label: {
                        Text(String(localized: "profile_done", bundle: PresentationResources.bundle))
                    }
                    .topBarButtonStyle(tint: Color.accent)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appBackground, ignoresSafeAreaEdges: .top)
    }
}

private struct CategoryManageRow: View {
    let item: TodoCategoryItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        if item.isUserCategory {
            content
                .background(Color.surface)
                .itemActions {
                    ItemActionButton(
                        color: Color.accent,
                        image: Image(systemName: "pencil"),
                        action: onEdit
                    )

                    ItemActionButton(
                        color: Color.red,
                        image: Image(systemName: "trash"),
                        action: onDelete
                    )
                }
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            Image(systemName: item.symbolName)
                .font(.headline)
                .frame(width: 36, height: 36)
                .iconStyle(color: item.color, in: Circle())

            Text(item.localizedName)
                .lineLimit(1)

            Spacer(minLength: 8)

            Toggle(
                item.localizedName,
                isOn: Binding(get: { item.isVisible }, set: { _ in onToggle() })
            )
            .labelsHidden()
            .tint(Color.accent)
        }
        .padding(.trailing, 12)
        .frame(minHeight: 44)
    }
}

private struct CategoryManageSheet: View {
    @Bindable var store: Store<CategoryManageFeature.CategorySheetState, CategoryManageFeature.Action.CategorySheet>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 8) {
                        TextField(
                            "",
                            text: $store.category.name,
                            prompt: Text(store.placeholder).foregroundStyle(.secondary)
                        )
                        .frame(height: UIFont.preferredFont(forTextStyle: .body).lineHeight)

                        Text(store.categoryNameCountText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                Section {
                    ColorPicker(selection: $store.category.colorHex.colorValue, supportsOpacity: false) {
                        Text(store.category.colorHex.isEmpty ? "#" : store.category.colorHex)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .frame(height: 1)
                                    .offset(y: 1)
                            }
                            .foregroundStyle(store.category.colorHex.colorValue)
                            .onTapGesture {
                                store.send(.tapRandomColorButton)
                            }
                    }
                    .pickerStyle(.palette)
                }
            }
            .navigationTitle(store.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "common_close", bundle: PresentationResources.bundle)) {
                        store.send(.tapCloseButton)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(store.submitTitle) {
                        store.send(.tapSaveButton)
                    }
                    .disabled(!store.canSubmitUserCategory)
                }
            }
        }
    }
}

private extension String {
    var colorValue: Color {
        get { Color(hexString: self) ?? .randomValue }
        set {
            if let hexValue = newValue.hexValue {
                self = hexValue
            }
        }
    }
}
