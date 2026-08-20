//
//  CollectionRenderingSnapshot.swift
//  CollectionUI
//
//  Created by opfic on 8/20/26.
//

import Foundation

// Collection 화면에 적용할 section과 item 식별자 상태를 보관한다.
public struct CollectionRenderingSnapshot<SectionIdentifier, ItemIdentifier>: Equatable, Sendable
where SectionIdentifier: Hashable & Sendable, ItemIdentifier: Hashable & Sendable {
    // 하나의 section과 그 안의 item 식별자 순서를 보관한다.
    public struct Section: Equatable, Sendable {
        // section을 구분하는 고유 식별자다.
        public let identifier: SectionIdentifier
        // section 안에 표시할 item의 순서가 있는 식별자 목록이다.
        public let itemIdentifiers: [ItemIdentifier]

        // section 식별자와 표시 순서를 지정해 section 값을 생성한다.
        public init(
            identifier: SectionIdentifier,
            itemIdentifiers: [ItemIdentifier]
        ) {
            self.identifier = identifier
            self.itemIdentifiers = itemIdentifiers
        }
    }

    // 표시할 section과 item 식별자의 전체 순서다.
    public let sections: [Section]
    // 같은 식별자를 유지한 채 다시 구성할 item 식별자 집합이다.
    public let reconfiguredItemIdentifiers: Set<ItemIdentifier>

    // section 순서와 다시 구성할 item 식별자를 지정해 rendering snapshot을 생성한다.
    public init(
        sections: [Section],
        reconfiguredItemIdentifiers: Set<ItemIdentifier> = []
    ) {
        self.sections = sections
        self.reconfiguredItemIdentifiers = reconfiguredItemIdentifiers
    }
}
