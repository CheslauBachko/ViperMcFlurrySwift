import UIKit

public protocol ViperModuleFactory {
    func instantiateModuleTransitionHandler() -> ViperModuleTransitionHandler
}
