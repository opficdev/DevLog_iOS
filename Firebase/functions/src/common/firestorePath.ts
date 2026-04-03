export namespace FirestorePath {
    enum Collection {
        users = "users",
        userData = "userData",
        todoLists = "todoLists",
        activity = "activity",
        activityEvents = "activityEvents",
        notifications = "notifications",
        notificationDispatches = "notificationDispatches",
        webPages = "webPages"
    }

    export enum UserDataDocument {
        info = "info",
        tokens = "tokens",
        settings = "settings",
        categories = "categories"
    }

    export function user(userId: string): string {
        return `${Collection.users}/${userId}`;
    }

    export function userData(userId: string, document?: UserDataDocument): string {
        const path = `${user(userId)}/${Collection.userData}`;
        if (!document) { return path; }
        return `${path}/${document}`;
    }

    export function todos(userId: string): string {
        return `${user(userId)}/${Collection.todoLists}`;
    }

    export function todo(userId: string, todoId: string): string {
        return `${todos(userId)}/${todoId}`;
    }

    export function activity(userId: string): string {
        return `${user(userId)}/${Collection.activity}`;
    }

    export function activityDaily(userId: string, dayKey: string): string {
        return `${activity(userId)}/${dayKey}`;
    }

    export function activityEvents(userId: string): string {
        return `${user(userId)}/${Collection.activityEvents}`;
    }

    export function activityEvent(userId: string, eventId: string): string {
        return `${activityEvents(userId)}/${eventId}`;
    }

    export function notifications(userId: string): string {
        return `${user(userId)}/${Collection.notifications}`;
    }

    export function notification(userId: string, notificationId: string): string {
        return `${notifications(userId)}/${notificationId}`;
    }

    export function notificationDispatches(userId: string): string {
        return `${user(userId)}/${Collection.notificationDispatches}`;
    }

    export function notificationDispatch(userId: string, dispatchId: string): string {
        return `${notificationDispatches(userId)}/${dispatchId}`;
    }

    export function webPages(userId: string): string {
        return `${user(userId)}/${Collection.webPages}`;
    }

    export function webPage(userId: string, documentId: string): string {
        return `${webPages(userId)}/${documentId}`;
    }
}
