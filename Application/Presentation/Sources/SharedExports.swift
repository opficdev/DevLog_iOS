//
//  SharedExports.swift
//  Presentation
//
//  Created by opfic on 7/2/26.
//

// App의 window group에서 사용하는 shared presentation API를 노출하면서
// App은 PresentationShared가 아닌 Presentation에만 의존하도록 유지합니다.
@_exported import PresentationShared
