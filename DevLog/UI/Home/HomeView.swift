//
//  HomeView.swift
//  DevLog
//
//  Created by opfic on 5/7/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                VStack {
                    Searchable(isSearching: Binding(
                        get: { viewModel.state.isSearching },
                        set: { viewModel.send(.updateSearching($0)) }
                    ))
                        .searchable(text: Binding(
                            get: { viewModel.state.searchText },
                            set: { viewModel.send(.updateSearchText($0)) }
                            ), prompt: "DevLog 검색"
                        )
                    List {
                        Section(content: {
                            ForEach(viewModel.state.selectedTodoKinds, id: \.self) { kind in
                                NavigationLink(value: kind) {
                                    HStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(kind.color)
                                            .frame(width: screenWidth * 0.08, height: screenWidth * 0.08)
                                            .overlay {
                                                Image(systemName: kind.symbolName)
                                                    .foregroundStyle(Color.white)
                                                    .font(.title3)
                                            }
                                        Text(kind.localizedName)
                                            .foregroundStyle(Color.primary)
                                    }
                                    .frame(height: screenWidth)
                                }
                            }
                        }, header: {
                            HStack {
                                Text("TODO")
                                    .foregroundStyle(Color.primary)
                                    .font(.title2)
                                    .bold()
                                Spacer()
                                Button(action: {
                                    viewModel.send(.didTapEllipsisButton)
                                }) {
                                    Image(systemName: "ellipsis")
                                        .font(.title2)
                                        .foregroundStyle(Color.gray)
                                }
                            }
                            .listRowInsets(EdgeInsets())    //  헤더의 padding 제거
                        })
                        
                        Section(content: {
                            if viewModel.state.pinnedTodos.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("최근에 중요 표시를 한 Todo가 여기 표시됩니다.")
                                        .font(.callout)
                                    Spacer()
                                }
                            } else {
                                ForEach(viewModel.state.pinnedTodos, id: \.id) { todo in
                                    NavigationLink(value: todo.kind) {
                                        HStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(todo.kind.color)
                                                .frame(width: screenWidth * 0.08, height: screenWidth * 0.08)
                                                .overlay {
                                                    Image(systemName: todo.kind.symbolName)
                                                        .foregroundStyle(Color.white)
                                                        .font(.title3)
                                                }
                                            VStack(alignment: .leading) {
                                                Text(todo.title)
                                                    .bold()
                                                Text(todo.dueDate?
                                                    .formatted(date: .abbreviated, time: .omitted) ?? "마감일 없음"
                                                )
                                                .font(.caption2)
                                                .foregroundStyle(Color.gray)
                                            }
                                        }
                                        .frame(height: screenWidth)
                                    }
                                }
                            }
                        }, header: {
                            HStack {
                                Text("중요 표시")
                                    .foregroundStyle(Color.primary)
                                    .font(.title2)
                                    .bold()
                                Spacer()
                                
                            }
                            .listRowInsets(EdgeInsets())
                        })
                    }
                }
            }
            .navigationTitle("홈")
            .navigationDestination(for: TodoKind.self) { kind in
                TodoView(viewModel: TodoViewModel(kind: kind))
            }
            .navigationDestination(for: Todo.self) { todo in
                TodoDetailView(
                    todo: todo,
                    onSubmit: { viewModel.send(.upsertTodo($0)) }
                )
            }
            .sheet(isPresented: Binding(
                get: { viewModel.state.reorderTodo },
                set: { _,_ in viewModel.send(.closeToast) })) {
//                TodoManageView().environmentObject(container.viewModel)
            }
            .alert("", isPresented: Binding(
                get: { viewModel.state.showToast }, set: { _, _ in })
            ) {
                Button(action: {
                    viewModel.send(.closeToast)
                }) {
                    Text("확인")
                }
            } message: {
                Text(viewModel.state.toastMessage)
            }
            .onAppear {
                viewModel.send(.onAppear)
            }
            .overlay {
                if viewModel.state.isLoading {
                    LoadingView()
                }
            }
        }
    }
}
