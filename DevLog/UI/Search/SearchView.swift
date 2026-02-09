//
//  SearchView.swift
//  DevLog
//
//  Created by opfic on 5/14/25.
//

import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sceneWidth) private var sceneWidth
    @Environment(\.sceneHeight) private var sceneHeight
    @StateObject private var router = NavigationRouter()
    @StateObject var viewModel: SearchViewModel

    var body: some View {
        NavigationStack(path: $router.path) {
            VStack {
                searchable
                if viewModel.state.isLoading {
                    LoadingView()
                } else if viewModel.state.isSearching {
                    if viewModel.state.searchQuery.isEmpty {
                        searchInstruction
                    } else {
                        ScrollView {
                            LazyVStack {
                                ForEach(viewModel.state.filteredWebPages, id: \.id) { page in
                                    webInfoCard(page)
                                }
                            }
                        }
                    }
                } else {
                    if viewModel.state.webPages.isEmpty {
                        webInstruction
                    } else {
                        List(viewModel.state.webPages, id: \.id) { page in
                            webInfoRaw(page)
                                .listRowSeparator(.hidden)  //  섹션 내 요소의 구분선 숨김
                                .listSectionSeparator(.hidden)  //  섹션의 구분선 숨김
                                .listRowBackground(Color.clear)
                                .swipeActions {
                                    Button(role: .destructive, action: {
                                        viewModel.send(.deleteWebPage(item: page))
                                    }) {
                                        Image(systemName: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("검색")
            .navigationDestination(for: Path.self) { path in
                switch path {
                case .webView(let url):
                    WebView(url: url)
                        .navigationBarTitleDisplayMode(.inline) //  명시하지 않으면 iOS 18 미만에서는 Large 크기만큼의 상단의 영역을 차지
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text(viewModel.state.selectedWebPage?.title ?? "")
                                    .bold()
                            }
                        }
                }
            }
            .task { viewModel.send(.fetchWebPage()) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.send(.setAlert(isPresented: true, type: .addWebPage))
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert(
                viewModel.state.alertTitle,
                isPresented: Binding(
                    get: { viewModel.state.showAlert },
                    set: { viewModel.send(.setAlert(isPresented: $0)) }
            )) {
                if let type = viewModel.state.alertType {
                    alertView(type)
                }
            } message: {
                Text(viewModel.state.alertMessage)
            }
        }
    }

    @ViewBuilder
    private func alertView(_ type: SearchViewModel.AlertType) -> some View {
        switch type {
        case .addWebPage:
            TextField("URL", text: Binding(
                get: { viewModel.state.newURL },
                set: { viewModel.send(.setNewURL($0)) }
            ))
            HStack {
                Button {
                    viewModel.send(.setNewURL())
                    dismiss()
                } label: {
                    Text("취소")
                }
                Button {
                    viewModel.send(.addWebPage())
                    dismiss()
                } label: {
                    Text("추가")
                }
            }
        case .error:
            Button("확인", role: .cancel) {}
        }
    }

    private var searchable: some View {
        Searchable(isSearching: Binding(
            get: { viewModel.state.isSearching },
            set: { viewModel.send(.setSearching($0)) }
        ))
        .searchable(
            text: Binding(
                get: { viewModel.state.searchQuery },
                set: { viewModel.send(.setSearchQuery($0)) }
            ),
            prompt: "DevLog 검색")
    }

    private var searchInstruction: some View {
        VStack {
            Spacer()
            Text("앱 내 컨텐츠를 검색할 수 있어요.")
                .foregroundStyle(Color.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var webInstruction: some View {
        Text("저장된 웹페이지가 없습니다.\n우측 '+' 버튼을 눌러 웹페이지를 추가해보세요.")
            .foregroundStyle(Color.gray)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .multilineTextAlignment(.center)
    }

    private func webInfoCard(_ item: WebPageItem) -> some View {
        ZStack(alignment: .bottom) {
            Color.white
            GeometryReader { geometry in
                AsyncImage(url: item.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    default:
                        Image(systemName: "globe")
                            .resizable()
                            .scaledToFit()
                            .frame(height: UIScreen.main.bounds.height / 5)
                            .foregroundStyle(Color.gray)
                            .padding()
                    }
                }
            }
            HStack {
                VStack(alignment: .leading) {
                    Text(item.title)
                        .foregroundStyle(Color.black)
                        .multilineTextAlignment(.leading)
                    Text(item.displayURL)
                        .foregroundStyle(Color.accentColor)
                        .underline()
                }
                .padding()
                Spacer()
            }
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .frame(height: sceneHeight / 4)
    }

    private func webInfoRaw(_ item: WebPageItem) -> some View {
        Button {
            router.push(Path.webView(item.url))
        } label: {
            HStack {
                AsyncImage(url: item.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image(systemName: "globe")
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(
                    width: sceneWidth / 5,
                    height: sceneWidth / 5
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading) {
                    Text(item.title)
                        .foregroundStyle(Color.primary)
                        .bold()
                    Text(item.displayURL)
                        .foregroundStyle(Color.accentColor)
                        .underline()
                }
            }
        }
    }

    private enum Path: Hashable {
        case webView(URL)
    }
}
