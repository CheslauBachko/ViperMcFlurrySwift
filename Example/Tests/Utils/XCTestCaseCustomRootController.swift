//
// Created by Cheslau Bachko on 12/24/19.
// Copyright (c) 2019 Cheslau Bachko. All rights reserved.
//

import XCTest

extension XCTestCase {

    func setupCustomRootController() {
        // HACK :)
        // Wait a little to avoid: Unbalanced calls to begin/end appearance transitions for <UIViewController: 0x7ffe17e28000>
        // while changed rootViewController
        //
        let hackExpectation = XCTestExpectation(description: "")
        UIApplication.shared.keyWindow!.rootViewController = UIViewController()
        DispatchQueue.main.async {
            hackExpectation.fulfill()
        }
        wait(for: [hackExpectation], timeout: 1)
    }

    func waitForAnimationCompletion(_ viewController: UIViewController) {
        // TODO
    }
}

