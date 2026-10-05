//
//  DevelopmentGoalListView.swift
//  DevelopmentTab
//
//  Created by opfic on 10/5/26.
//

import Development
import Domain
import PresentationShared
import SwiftUI

public struct DevelopmentGoalListView: View {
    @State private var store: StoreOf<DevelopmentGoalListFeature>
    private let isSelected: Bool

    public init(isSelected: Bool = true) {
        self._store = State(initialValue: Store(initialState: DevelopmentGoalListFeature.State()) {
            DevelopmentGoalListFeature()
        })
        self.isSelected = isSelected
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if store.hasLoadFailure {
                        loadFailure
                    }
                    if store.hasLoaded {
                        if store.filteredGoals.isEmpty {
                            emptyState
                        } else {
                            ForEach(store.filteredGoals, id: \.id) { goal in
                                Button {
                                    store.send(.showDetail(goal.id))
                                } label: {
                                    DevelopmentGoalCard(
                                        goal: goal,
                                        recentRecord: store.recentRecords[goal.id]
                                    )
                                }
                                .buttonStyle(.plain)
                                .onAppear {
                                    store.send(.cardAppeared(goal.id))
                                }
                                .onDisappear {
                                    store.send(.cardDisappeared(goal.id))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .refreshable {
                await store.send(.refresh).finish()
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("nav_development_goals", bundle: PresentationResources.bundle)
                            .font(.largeTitle.bold())
                        Spacer()
                        Button {
                            store.send(.showCreate)
                        } label: {
                            Image(systemName: "plus")
                        }
                        .topBarButtonStyle()
                    }
                    statusTabs
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .background(Color.appBackground)
                .toolbarBackground(Color.appBackground)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .toolbarVisibility(.hidden, for: .navigationBar)
            .sheet(
                item: $store.scope(state: \.sheet, action: \.sheet)
                    .activePresentation(when: isSelected)
            ) { sheetStore in
                switch sheetStore.state {
                case .create:
                    GoalCreateView { goal in
                        store.send(.goalCreated(goal))
                    }
                case .detail(let goalID):
                    GoalDetailView(goalId: goalID)
                }
            }
        }
        .onChange(of: isSelected, initial: true) { _, isSelected in
            guard isSelected else { return }
            store.send(.selected)
        }
        .overlay {
            if store.isLoading {
                LoadingView()
            }
        }
    }

    private var statusTabs: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(DevelopmentGoal.Status.tabs, id: \.self) { status in
                    let isSelected = store.selectedStatus == status
                    Button {
                        store.send(.selectStatus(status))
                    } label: {
                        HStack(spacing: 4) {
                            Text(status.title)
                            Text(store.state.count(for: status).formatted())
                                .opacity(0.6)
                        }
                        .font(.callout)
                        .foregroundStyle(isSelected ? Color.onPrimaryContainer : Color.onControlBackground)
                        .adaptiveButtonStyle(color: isSelected ? .primaryContainer : .controlBackground)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, -16)
        .contentMargins(.horizontal, 16, for: .scrollContent)
    }

    private var loadFailure: some View {
        ContentUnavailableView {
            Label(
                String(localized: "common_error_title", bundle: PresentationResources.bundle),
                systemImage: "exclamationmark.triangle"
            )
        } description: {
            Text(String(localized: "common_error_message", bundle: PresentationResources.bundle))
        } actions: {
            Button(String(localized: "development_record_timeline_retry", bundle: PresentationResources.bundle)) {
                store.send(.retry)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(store.selectedStatus.emptyTitle, systemImage: "flag.checkered")
        } actions: {
            if store.selectedStatus == .inProgress {
                Button {
                    store.send(.showCreate)
                } label: {
                    Text("development_goals_create", bundle: PresentationResources.bundle)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
