

import Foundation

enum MDMSettings {
    private static let appleManagedConfigurationKey = "com.apple.configuration.managed"
    
    private enum Key: String {
        case serverConfigDefaultHomeserverUrlString = "com.p2pchatter.bitchat.serverConfigDefaultHomeserverUrlString"
        case serverConfigSygnalAPIUrlString = "com.p2pchatter.bitchat.serverConfigSygnalAPIUrlString"
        case clientPermalinkBaseUrl = "com.p2pchatter.bitchat.clientPermalinkBaseUrl"
    }
    
    static var serverConfigDefaultHomeserverUrlString: String? {
        valueForKey(.serverConfigDefaultHomeserverUrlString) as? String
    }
    
    static var serverConfigSygnalAPIUrlString: String? {
        valueForKey(.serverConfigSygnalAPIUrlString) as? String
    }
    
    static var clientPermalinkBaseUrl: String? {
        valueForKey(.clientPermalinkBaseUrl) as? String
    }
    
    // MARK: - Private
    
    static private func valueForKey(_ key: Key) -> Any? {
        guard let managedConfiguration = UserDefaults.standard.dictionary(forKey: appleManagedConfigurationKey) else {
            print("MDM configuration missing")
            return nil
        }
        
        print("Retrieved MDM configuration: \(managedConfiguration)")
        
        return managedConfiguration[key.rawValue]
    }
}
