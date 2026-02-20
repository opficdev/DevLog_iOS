//
//  SearchView.swift
//  DevLog
//
//  Created by 최윤진 on 2/12/26.
//

import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sceneWidth) private var sceneWidth
    @StateObject private var router = NavigationRouter()
    @StateObject var viewModel: SearchViewModel

    var body: some View {
        NavigationStack(path: $router.path) {
            searchableContent
                .navigationDestination(for: Path.self) { path in
                    switch path {
                    case .webView(let url):
                        WebView(url: url)
                            .toolbar {
                                ToolbarItem(placement: .principal) {
                                    Text(viewModel.state.selectedWebPage?.title ?? "")
                                        .bold()
                                }
                            }
                    }
                }
                .onAppear {
                    viewModel.send(.setSearching(true))
                }
                .onChange(of: viewModel.state.isSearching) { isSearching in
                    if !isSearching {
                        dismiss()
                    }
                }
                .alert(viewModel.state.alertTitle, isPresented: Binding(
                    get: { viewModel.state.showAlert },
                    set: { viewModel.send(.setAlert($0)) }
                )) {
                    Button("확인", role: .cancel) { }
                } message: {
                    Text(viewModel.state.alertMessage)
                }
                // TODO: iOS 16에서 introspect 모듈을 사용하여 .searchable의 isPresented를 관리한다
                // .introspect(.searchField, on: iOS(.v16)) { searchBar in }

        }
    }

    @ViewBuilder
    private var searchableContent: some View {
        let searchQueryBinding = Binding(
            get: { viewModel.state.searchQuery },
            set: { viewModel.send(.setSearchQuery($0)) }
        )
        let searchingBinding = Binding(
            get: { viewModel.state.isSearching },
            set: { viewModel.send(.setSearching($0)) }
        )

        let scrollContent = ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if viewModel.state.isLoading {
                    LoadingView()
                } else if viewModel.state.searchQuery.isEmpty {
                    if viewModel.state.recentQueries.isEmpty {
                        searchInstruction
                    } else {
                        recentQueries
                    }
                } else if viewModel.state.webPages.isEmpty {
                    emptySearchResult
                } else {
                    webPages
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        Group {
            if #available(iOS 17.0, *) {
                scrollContent.searchable(
                    text: searchQueryBinding,
                    isPresented: searchingBinding,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "검색"
                )
            } else {
                scrollContent
                    .searchable(
                        text: searchQueryBinding,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "검색"
                    )
            }
        }
        .onSubmit(of: .search) {
            viewModel.send(.addRecentQuery(viewModel.state.searchQuery))
        }
    }

    private var searchInstruction: some View {
        VStack {
            Spacer()
            Text("검색어를 입력해 저장한 앱 컨텐츠를 찾아보세요.")
                .foregroundStyle(Color.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptySearchResult: some View {
        VStack {
            Spacer()
            Text("검색 결과가 없습니다.")
                .foregroundStyle(Color.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var webPages: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Web Pages")
                .font(.headline)
                .foregroundStyle(Color(.label))
            ForEach(viewModel.state.webPages, id: \.id) { page in
                searchResultRow(page)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func searchResultRow(_ item: WebPageItem) -> some View {
        Button {
            viewModel.send(.selectWebPage(item))
            router.push(Path.webView(item.url))
        } label: {
            HStack {
                CacheableImage(url: item.imageURL) {
                    Image(systemName: "globe")
                        .resizable()
                        .scaledToFit()
                }
                .frame(width: sceneWidth / 10, height: sceneWidth / 10)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading) {
                    Text(item.title)
                        .foregroundStyle(Color.primary)
                        .bold()
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Text(item.displayURL)
                        .foregroundStyle(Color.accentColor)
                        .underline()
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private var recentQueries: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("최근 검색")
                    .font(.headline)
                    .foregroundStyle(Color(.label))
                Spacer()
                Button("전체 삭제") {
                    viewModel.send(.clearRecentQueries)
                }
                .font(.subheadline)
                .foregroundStyle(Color.gray)
            }

            ForEach(viewModel.state.recentQueries, id: \.self) { query in
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(Color.gray)
                    Text(query)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Button {
                        viewModel.send(.removeRecentQuery(query))
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.gray)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.send(.setSearchQuery(query))
                    viewModel.send(.setSearching(true))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private enum Path: Hashable {
        case webView(URL)
    }
}
