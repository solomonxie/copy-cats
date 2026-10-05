import Foundation

enum AppGroup {
    static let id = Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as! String

    static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id)!
    }

    static let defaults = UserDefaults(suiteName: id)!
}
