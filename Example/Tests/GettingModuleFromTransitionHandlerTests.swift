//
// Created by Cheslau Bachko on 12/24/19.
// Copyright (c) 2019 Cheslau Bachko. All rights reserved.
//

import XCTest
import UIKit
import ViperMcFlurrySwift

private protocol ViewOutput {}
private class ViperModule: ViperModuleInput, ViewOutput {}
private class TraditionalViperView: UIViewController {
    var output: ViewOutput!
}

/// Access to (module)presenter via UIViewController
class GettingModuleFromTransitionHandlerTests: XCTestCase {
    // via object association
    func testRetrieveModuleFromViewControllerAfterSetIt() {
        let viewController = UIViewController()
        let module = ViperModule()
        viewController.moduleInput = module

        XCTAssertNotNil(viewController.moduleInput)
        XCTAssert(viewController.moduleInput === module)
    }

    // via reflection (mirror)
    func testRetrieveModuleFromViewControllerViaViewOutput() {
        let viewController = TraditionalViperView()
        let module = ViperModule()
        viewController.output = module

        XCTAssertNotNil(viewController.moduleInput)
        XCTAssert(viewController.moduleInput === module)
    }
}
