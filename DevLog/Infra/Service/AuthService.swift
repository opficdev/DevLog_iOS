//
//  AuthService.swift
//  DevLog
//
//  Created by 최윤진 on 11/29/25.
//

import FirebaseAuth

final class AuthService {
    var uid: String? {
        Auth.auth().currentUser?.uid
    }
}

