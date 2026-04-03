//
//  FirestorePath.swift
//  DevLog
//
//  Created by opfic on 3/26/26.
//

enum FirestorePath {
    private enum Collection: String {
        case users
        case userData
        case counters
        case todoLists
        case activity
        case activityEvents
        case notifications
        case webPages
    }

    enum UserData: String {
        case info
        case tokens
        case settings
        case categories
    }

    enum Counter: String {
        case todo
    }

    static func user(_ uid: String) -> String {
        "\(Collection.users.rawValue)/\(uid)"
    }

    static func userData(_ uid: String, document: UserData? = nil) -> String {
        let path = "\(user(uid))/\(Collection.userData.rawValue)"
        guard let document else { return path }
        return "\(path)/\(document.rawValue)"
    }

    static func counter(_ uid: String, document: Counter) -> String {
        "\(user(uid))/\(Collection.counters.rawValue)/\(document.rawValue)"
    }

    static func todos(_ uid: String) -> String {
        "\(user(uid))/\(Collection.todoLists.rawValue)"
    }

    static func todo(_ uid: String, todoId: String) -> String {
        "\(todos(uid))/\(todoId)"
    }

    static func activity(_ uid: String) -> String {
        "\(user(uid))/\(Collection.activity.rawValue)"
    }

    static func activityDaily(_ uid: String, dayKey: String) -> String {
        "\(activity(uid))/\(dayKey)"
    }

    static func activityEvents(_ uid: String) -> String {
        "\(user(uid))/\(Collection.activityEvents.rawValue)"
    }

    static func activityEvent(_ uid: String, documentId: String) -> String {
        "\(activityEvents(uid))/\(documentId)"
    }

    static func notifications(_ uid: String) -> String {
        "\(user(uid))/\(Collection.notifications.rawValue)"
    }

    static func webPages(_ uid: String) -> String {
        "\(user(uid))/\(Collection.webPages.rawValue)"
    }

    static func webPage(_ uid: String, documentId: String) -> String {
        "\(webPages(uid))/\(documentId)"
    }
}
