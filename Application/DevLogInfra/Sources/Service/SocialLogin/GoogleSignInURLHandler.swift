//
//  GoogleSignInURLHandler.swift
//  DevLogInfra
//
//  Created by opfic on 5/23/26.
//

import Foundation
import GoogleSignIn

public enum GoogleSignInURLHandler {
    public static func handle(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}
