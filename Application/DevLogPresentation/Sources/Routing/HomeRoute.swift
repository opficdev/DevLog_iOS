//
//  HomeRoute.swift
//  DevLogPresentation
//
//  Created by opfic on 6/2/26.
//

import Foundation

public enum HomeRoute: Hashable {
    case category(TodoCategoryItem)
    case todo(TodoIdItem)
    case webPage(WebPageItem)
}
