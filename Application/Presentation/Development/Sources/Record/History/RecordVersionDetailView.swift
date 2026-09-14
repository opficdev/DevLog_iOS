//
//  RecordVersionDetailView.swift
//  Development
//
//  Created by opfic on 9/14/26.
//

import SwiftUI
import Domain
import PresentationShared

struct RecordVersionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isConfirmationPresented = false

    let version: DevelopmentRecord.Version
    let currentVersionNumber: Int
    let hasDraft: Bool
    let isRestoring: Bool
    let restoredSourceVersionID: String?
    let onRestore: (DevelopmentRecord.Version) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                titleSection
                contentCard
                currentVersionCard
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .safeAreaInset(edge: .bottom, spacing: 0) { restoreBar }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbarVisibility(.hidden, for: .navigationBar)
        .confirmationAlert(
            isPresented: $isConfirmationPresented,
            configuration: ConfirmationAlertConfiguration(
                title: RecordPresentation.text("development_record_restore_alert_title"),
                message: String.localizedStringWithFormat(
                    RecordPresentation.text("development_record_restore_alert_message_format"),
                    RecordPresentation.versionLabel(version.number)
                ),
                cancelTitle: RecordPresentation.text("common_cancel"),
                confirmTitle: RecordPresentation.text("development_record_restore_alert_confirm")
            ),
            isConfirming: isRestoring,
            onConfirm: { onRestore(version) }
        )
        .overlay {
            if isRestoring {
                LoadingView()
            }
        }
        .onChange(of: restoredSourceVersionID) { _, sourceVersionID in
            guard sourceVersionID == version.id else { return }
            dismiss()
        }
    }

    private var topBar: some View {
        HStack {
            RecordBackButton(action: dismiss.callAsFunction)
                .disabled(isRestoring)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
        .background(Color.appBackground, ignoresSafeAreaEdges: .top)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(RecordPresentation.text("development_record_previous_version_title"))
                .font(.largeTitle.bold())

            Text(version.title)
                .font(.title3)
                .foregroundStyle(Color.textSecondary)
                .lineLimit(2)

            HStack(spacing: 8) {
                RecordVersionBadge(number: version.number, isCurrent: false)
                kindBadge
                Text(version.confirmedAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(RecordPresentation.text("development_record_result_title"))
                .font(.title3.bold())

            if version.markdownContent.isEmpty {
                ContentUnavailableView(
                    RecordPresentation.text("development_record_content_empty_title"),
                    systemImage: "doc.text"
                )
            } else {
                MarkdownContentView(content: version.markdownContent)
                    .frame(minHeight: 420)
            }
        }
        .padding(20)
        .background(Color.surface, in: .rect(cornerRadius: 24))
    }

    private var currentVersionCard: some View {
        Label {
            if hasDraft {
                Text(RecordPresentation.text("development_record_restore_draft_message"))
            } else {
                Text(String.localizedStringWithFormat(
                    RecordPresentation.text("development_record_restore_current_version_format"),
                    RecordPresentation.versionLabel(currentVersionNumber)
                ))
            }
        } icon: {
            Image(systemName: hasDraft ? "pencil" : "clock.arrow.circlepath")
                .foregroundStyle(hasDraft ? Color.warning : Color.accent)
        }
        .font(.subheadline)
        .foregroundStyle(Color.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.surfaceSecondary, in: .rect(cornerRadius: 18))
    }

    private var restoreBar: some View {
        Button {
            isConfirmationPresented = true
        } label: {
            Text(RecordPresentation.text("development_record_restore_button"))
                .font(.headline)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .adaptiveButtonStyle(shape: RoundedRectangle(cornerRadius: 16), color: .accent)
        .disabled(isRestoring || hasDraft)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.surface, ignoresSafeAreaEdges: .bottom)
    }

    @ViewBuilder
    private var kindBadge: some View {
        switch version.kind {
        case .initial:
            statusBadge(
                RecordPresentation.text("development_record_version_initial"),
                foreground: .textSecondary,
                background: .surfaceSecondary
            )
        case .correction:
            statusBadge(
                RecordPresentation.text("development_record_version_correction"),
                foreground: .accent,
                background: .primaryContainer
            )
        case .rollback:
            statusBadge(
                RecordPresentation.text("development_record_version_rollback"),
                foreground: .warning,
                background: .warning.opacity(0.12)
            )
        }
    }

    private func statusBadge(
        _ title: String,
        foreground: Color,
        background: Color
    ) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(background, in: .rect(cornerRadius: 8))
    }
}
