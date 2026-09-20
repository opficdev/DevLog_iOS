//
//  GoalDescriptionCard.swift
//  Development
//
//  Created by opfic on 9/20/26.
//

import SwiftUI
import PresentationShared

struct GoalDescriptionCard: View {
    let description: String
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(RecordPresentation.text("development_goal_description_title"))
                .font(.title3.bold())

            if isLoading {
                ProgressView()
                    .tint(Color.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else if description.isEmpty {
                Text(RecordPresentation.text("development_goal_description_empty_message"))
                    .font(.body)
                    .foregroundStyle(Color.textSecondary)
            } else {
                MarkdownContentView(content: description)
                    .frame(minHeight: 120)
            }
        }
        .padding(20)
        .background(Color.surface, in: .rect(cornerRadius: 24))
    }
}

#Preview("목표 설명") {
    GoalDescriptionCard(
        description: """
        개발 기록을 여러 버전으로 안전하게 관리하고,
        확정된 기록의 이력을 보존합니다.

        - 초안과 확정 분리
        - 정정은 새 버전으로 저장
        - 이전 버전으로 되돌리기
        """,
        isLoading: false
    )
    .padding()
    .background(Color.appBackground)
}
