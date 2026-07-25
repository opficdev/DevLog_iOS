//
//  PackageExports.swift
//  PresentationShared
//
//  Created by opfic on 7/3/26.
//

// Presentation 계열 target이 같은 static package를 각각 링크하면 duplicate symbol이 발생합니다.
// 외부 package 접근은 PresentationShared로 모아 한 번만 링크되도록 유지합니다.
@_exported import ComposableArchitecture
@_exported import OrderedCollections
