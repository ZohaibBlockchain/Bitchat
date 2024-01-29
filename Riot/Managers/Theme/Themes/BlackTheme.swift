import UIKit

class BlackTheme: DarkTheme {

    override init() {
        super.init()
        self.identifier = ThemeIdentifier.black.rawValue
        self.backgroundColor = UIColor(rgb: 0xffffff)
        self.headerBorderColor = UIColor(rgb: 0xffffff)
    }
    
    override var baseColor: UIColor {
        UIColor(rgb: 0xffffff)
    }
    
    override var headerBackgroundColor: UIColor {
        UIColor(rgb: 0xffffff)
    }
}
