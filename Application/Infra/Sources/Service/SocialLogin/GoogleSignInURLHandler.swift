//
//  GoogleSignInURLHandler.swift
//  Infra
//
//  Created by opfic on 7/26/26.
//

import Foundation
import GoogleSignIn

public enum GoogleSignInURLHandler {
    public static func handle(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}
