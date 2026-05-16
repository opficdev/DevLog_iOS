//
//  TodoCursorDTO.swift
//  DevLogData
//
//  Created by opfic on 2/21/26.
//

import Foundation
import DevLogDomain

public struct TodoCursorDTO {
    public let primarySortDate: Date?
    public let secondarySortDate: Date?
    public let documentID: String

    public init(
        primarySortDate: Date?,
        secondarySortDate: Date?,
        documentID: String
    ) {
        self.primarySortDate = primarySortDate
        self.secondarySortDate = secondarySortDate
        self.documentID = documentID
    }
}
