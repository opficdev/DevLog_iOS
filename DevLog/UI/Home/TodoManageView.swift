//
//  TodoManageView.swift
//  DevLog
//
//  Created by opfic on 6/16/25.
//

import SwiftUI

struct TodoManageView: View {
    @StateObject var viewModel: TodoManageViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.state.todoKinds) { kind in
                    HStack(spacing: 0) {
                        CheckBox(isChecked: viewModel.contains(kind), font: .title3)
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
            .environment(\.editMode, .constant(EditMode.active))
            .navigationTitle("TODO 편집")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("완료")
                    }
                }
            }
        }
        //  편집 모드 활성화
        //  row 우측에 line.3.horizontal 추가됨
        .environment(\.editMode, .constant(EditMode.active))
    }
}
