import Foundation
import UIKit

/// `AllChatsActionProvider` provides the menu for managing the `AllChatsLayoutSettingsManager`
@available(iOS 13.0, *)
class AllChatsActionProvider {
    
    // MARK: - Properties
    
    private let allChatsSettingsManager = AllChatsLayoutSettingsManager.shared
   
    private var hasStarted: Bool {
            get {
                UserDefaults.standard.bool(forKey: "AllChatsActionProviderHasStarted")
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "AllChatsActionProviderHasStarted")
            }
        }
    
    // MARK: - RoomActionProviderProtocol
    
    init() {
        start()
       }
    
    
    var menu: UIMenu {
        
        
        var menu: UIMenu {
            return UIMenu(title: "", children: [
                self.recentsAction,
                self.filtersAction,
                UIMenu(title: "", options: .displayInline, children: [
                    activityOrderAction,
                    alphabeticalOrderAction
                ])
            ])
        }
        
        
        
        
        return UIMenu(title: "", children: [
            self.recentsAction,
            self.filtersAction,
            UIMenu(title: "", options: .displayInline, children: [
                activityOrderAction,
                alphabeticalOrderAction
            ])
        ])
    }
    
    // MARK: - Private
    
    private var recentsAction: UIAction {
        return UIAction(title: VectorL10n.allChatsEditLayoutShowRecents,
                        image: UIImage(systemName: "clock.arrow.circlepath")?.withRenderingMode(.alwaysTemplate),
                        discoverabilityTitle: VectorL10n.allChatsEditLayoutShowRecents,
                        state: AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.sections.contains(.recents) ? .on : .off) { action in
                            let settings = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings
                            let newSettings = AllChatsLayoutSettings(sections: action.state == .on ? [] : .recents,
                                                                     filters: settings.filters,
                                                                     sorting: settings.sorting)
                            AllChatsLayoutSettingsManager.shared.allChatLayoutSettings = newSettings
                            Analytics.shared.trackInteraction(action.state == .on ? .allChatsRecentsDisabled : .allChatsRecentsEnabled)
                        }
    }
    
    private var filtersAction: UIAction {
        return UIAction(title: VectorL10n.allChatsEditLayoutShowFilters,
                        image: UIImage(systemName: "bubble.right")?.withRenderingMode(.alwaysTemplate),
                        state: AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.filters == [] ? .off : .on) { action in
                            let settings = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings
                            let newSettings = AllChatsLayoutSettings(sections: settings.sections,
                                                                     filters: action.state == .on ? [] : [.unreads, .favourites, .people],
                                                                     sorting: settings.sorting)
                            AllChatsLayoutSettingsManager.shared.allChatLayoutSettings = newSettings
                            Analytics.shared.trackInteraction(action.state == .on ? .allChatsFiltersDisabled : .allChatsFiltersEnabled)
                        }
    }
    
    private var activityOrderAction: UIAction {
        return UIAction(title: VectorL10n.allChatsEditLayoutActivityOrder,
                        state: AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.sorting == .activity ? .on : .off) { action in
                            let settings = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings
                            let newSettings = AllChatsLayoutSettings(sections: settings.sections,
                                                                     filters: settings.filters,
                                                                     sorting: .activity)
                            AllChatsLayoutSettingsManager.shared.allChatLayoutSettings = newSettings
                        }
    }
    
    private var alphabeticalOrderAction: UIAction {
        return UIAction(title: VectorL10n.allChatsEditLayoutAlphabeticalOrder,
                        state: AllChatsLayoutSettingsManager.shared.allChatLayoutSettings.sorting == .alphabetical ? .on : .off) { action in
                            let settings = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings
                            let newSettings = AllChatsLayoutSettings(sections: settings.sections,
                                                                     filters: settings.filters,
                                                                     sorting: .alphabetical)
                            AllChatsLayoutSettingsManager.shared.allChatLayoutSettings = newSettings
                        }
    }
    
    
    //xxxobi2
    private func start() {
           guard !hasStarted else { return }
           hasStarted = true
        MXLog.debug("Modified Region started")
        
        let settings = AllChatsLayoutSettingsManager.shared.allChatLayoutSettings
        let newSettings = AllChatsLayoutSettings(sections: settings.sections,
                                                 filters: [.unreads, .favourites, .people],
                                                 sorting: settings.sorting)
        
        AllChatsLayoutSettingsManager.shared.allChatLayoutSettings = newSettings
        
        Analytics.shared.trackInteraction(.allChatsFiltersEnabled)
        MXLog.debug("Modified Region Ended")
       }
}












