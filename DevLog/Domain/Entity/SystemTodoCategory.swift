//
//  SystemTodoCategory.swift
//  DevLog
//
//  Created by opfic on 3/29/26.
//

import Foundation

public enum SystemTodoCategory: String, CaseIterable, Hashable {
    case issue          // 이슈
    case feature        // 신규 기능
    case improvement    // 개선/리팩터링
    case review         // 코드/문서 리뷰
    case test           // 테스트/QA
    case doc            // 문서화
    case research       // 리서치/학습
    case etc            // 기타
}
