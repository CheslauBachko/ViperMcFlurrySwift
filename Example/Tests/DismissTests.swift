//
// Created by Cheslau Bachko on 12/24/19.
// Copyright (c) 2019 Cheslau Bachko. All rights reserved.
//

import XCTest
import ViperMcFlurrySwift

private class Presenter: NSObject, ViperModuleInput {
    var moduleDidSkipOnDismissCalledCounter = 0
    func moduleDidSkipOnDismiss() {
        moduleDidSkipOnDismissCalledCounter += 1
    }
}

private class TestController: UIViewController {

    let output = Presenter()

    private static func rnd() -> CGFloat {
        return CGFloat(arc4random() % 256)/255
    }

    private static var i = 0
    private static let colors: [UIColor] = stride(from: 0, to: 10, by: 1).map({ _ -> UIColor in UIColor(red: rnd(),
            green: rnd(),
            blue: rnd(),
            alpha: 1) })

    override func viewDidLoad() {
        super.viewDidLoad()
        let cl = type(of: self)
        view.backgroundColor = cl.colors[cl.i % cl.colors.count]
        cl.i += 1
    }


}

extension UIViewController {
    var isInProgress: Bool {
        return isBeingDismissed || isBeingPresented || isMovingToParentViewController || isMovingFromParentViewController
    }
}

class DismissTests: XCTestCase {
    override func setUp() {
        self.continueAfterFailure = false
    }

    func testCompliation() {
        let handler: ViperModuleTransitionHandler! = UIViewController()
        handler!.skipOnDismiss = true
    }

    func testSimpleDismiss() {

        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }

        setupCustomRootController()

        let closedExpectation = XCTestExpectation(description: "closedExpectation")

        let controller = TestController()

        UIApplication.shared.keyWindow!.rootViewController!.present(controller, animated: true, completion: {
            controller.closeCurrentModule(true) {
                closedExpectation.fulfill()
            }
        })

        wait(for: [closedExpectation], timeout: 10)
        XCTAssertFalse(controller.isInProgress)
    }

    func testDeepDismiss() {

        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }

        func test(animated: Bool) {
            let depth = 5

            for i in stride(from: depth - 1, through: 0, by: -1) {

                setupCustomRootController()

                let controllers = stride(from: 0, to: depth, by: 1).map({ _ -> TestController in TestController() })

                let presentExpectation = XCTestExpectation(description: "presentExpectation")

                var controllersToPresent = controllers

                func present() {

                    if controllersToPresent.isEmpty {
                        presentExpectation.fulfill()
                        return
                    }

                    var top = UIApplication.shared.keyWindow!.rootViewController!

                    while top.presentedViewController != nil {
                        top = top.presentedViewController!
                    }

                    top.present(controllersToPresent.removeFirst(), animated: false, completion: {
                        present()
                    })
                }

                present()

                wait(for: [presentExpectation], timeout: 10)

                let closedExpectation = XCTestExpectation(description: "closedExpectation")

                controllers[i].closeCurrentModule(animated) {
                    closedExpectation.fulfill()
                }

                wait(for: [closedExpectation], timeout: 10)

                XCTAssertFalse(controllers.reduce(false) { $0 || $1.isInProgress })
                XCTAssertEqual(controllers.filter({ $0.presentingViewController != nil && controllers.firstIndex(of: $0)! < i }).count, i)
            }
        }

        test(animated: false)
        test(animated: true)
    }

    func testSimpleNavigationControllerDismiss() {

        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }

        func test(animated: Bool) {
            let depth = 5

            for i in stride(from: depth - 1, through: 0, by: -1) {

                setupCustomRootController()

                let controllers = stride(from: 0, to: depth, by: 1).map({ _ -> TestController in TestController() })

                let presentExpectation = XCTestExpectation(description: "presentExpectation")

                let nc = UINavigationController()
                nc.viewControllers = controllers

                UIApplication.shared.keyWindow!.rootViewController!.present(nc, animated: false) {
                    presentExpectation.fulfill()
                }

                wait(for: [presentExpectation], timeout: 10)

                let closedExpectation = XCTestExpectation(description: "closedExpectation")

                controllers[i].closeCurrentModule(animated) {
                    closedExpectation.fulfill()
                }

                wait(for: [closedExpectation], timeout: 10)

                XCTAssertFalse(controllers.reduce(false) { $0 || $1.isInProgress })
                XCTAssertTrue(
                        (i > 0 && UIApplication.shared.keyWindow!.rootViewController!.presentedViewController!.isKind(of: UINavigationController.self) && nc.viewControllers.count == i)
                                || (i == 0 && UIApplication.shared.keyWindow!.rootViewController!.presentedViewController == nil)
                )
                XCTAssertEqual(controllers.filter({ $0.presentingViewController != nil && controllers.firstIndex(of: $0)! < i }).count, i)
            }
        }

        test(animated: false)
        test(animated: true)
    }

    func testComplexNavigationControllerDismiss() {

        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }

        setupCustomRootController()

        let controller = TestController()

        let nc = UINavigationController(rootViewController: UIViewController())
        nc.pushViewController(controller, animated: false)

        waitForAnimationCompletion(nc)

        let closedExpectation = XCTestExpectation(description: "closedExpectation")

        UIApplication.shared.keyWindow!.rootViewController!.present(nc, animated: true, completion: {
            controller.closeCurrentModule(true) {
                closedExpectation.fulfill()
            }
        })

        wait(for: [closedExpectation], timeout: 10)

        XCTAssert(UIApplication.shared.keyWindow!.rootViewController!.childViewControllers.count == 0)
        XCTAssert(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController == nc)
        XCTAssert(nc.childViewControllers.count == 1)
    }

    func testPassthroughSimple() {

        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }

        setupCustomRootController()

        let controller1 = TestController()
        let controller2 = TestController()

        controller1.skipOnDismiss = true

        let closedExpectation = XCTestExpectation(description: "closedExpectation")

        UIApplication.shared.keyWindow!.rootViewController!.present(controller1, animated: true, completion: {
            controller1.present(controller2, animated: true, completion: {
                controller2.closeCurrentModule(true) {
                    closedExpectation.fulfill()
                }
            })
        })

        wait(for: [closedExpectation], timeout: 10)

        XCTAssertNil(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController)
        XCTAssertEqual(controller1.output.moduleDidSkipOnDismissCalledCounter, 0)
        XCTAssertEqual(controller2.output.moduleDidSkipOnDismissCalledCounter, 1)
    }

    func testPassthroughTriplexHalf() {

        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }

        setupCustomRootController()

        let controller1 = TestController()
        let controller2 = TestController()
        let controller3 = TestController()

        controller2.skipOnDismiss = true

        let closedExpectation = XCTestExpectation(description: "closedExpectation")

        UIApplication.shared.keyWindow!.rootViewController!.present(controller1, animated: true, completion: {
            controller1.present(controller2, animated: true, completion: {
                controller2.present(controller3, animated: true, completion: {
                    controller3.closeCurrentModule(true) {
                        closedExpectation.fulfill()
                    }
                })
            })
        })

        wait(for: [closedExpectation], timeout: 10)

        XCTAssert(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController === controller1)
        XCTAssertNil(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController!.presentedViewController)
        XCTAssertEqual(controller1.output.moduleDidSkipOnDismissCalledCounter, 0)
        XCTAssertEqual(controller2.output.moduleDidSkipOnDismissCalledCounter, 0)
        XCTAssertEqual(controller3.output.moduleDidSkipOnDismissCalledCounter, 1)
    }

    func testPassthroughSimpleTriplex() {

        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }

        setupCustomRootController()

        let controller1 = TestController()
        let controller2 = TestController()
        let controller3 = TestController()

        controller1.skipOnDismiss = true
        controller2.skipOnDismiss = true

        let closedExpectation = XCTestExpectation(description: "closedExpectation")

        UIApplication.shared.keyWindow!.rootViewController!.present(controller1, animated: true, completion: {
            controller1.present(controller2, animated: true, completion: {
                controller2.present(controller3, animated: true, completion: {
                    controller3.closeCurrentModule(true) {
                        closedExpectation.fulfill()
                    }
                })
            })
        })

        wait(for: [closedExpectation], timeout: 10)

        XCTAssertNil(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController)
        XCTAssertEqual(controller1.output.moduleDidSkipOnDismissCalledCounter, 0)
        XCTAssertEqual(controller2.output.moduleDidSkipOnDismissCalledCounter, 1)
        XCTAssertEqual(controller3.output.moduleDidSkipOnDismissCalledCounter, 1)
    }

    func testPassthroughNavigation() {

        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }

        setupCustomRootController()

        let controller1 = TestController()

        let nc = UINavigationController(rootViewController: UIViewController())
        nc.skipOnDismiss = true
        nc.pushViewController(controller1, animated: false)

        waitForAnimationCompletion(nc)

        let closedExpectation = XCTestExpectation(description: "closedExpectation")

        UIApplication.shared.keyWindow!.rootViewController!.present(nc, animated: true, completion: {
            controller1.closeCurrentModule(true) {
                closedExpectation.fulfill()
            }
        })

        wait(for: [closedExpectation], timeout: 10)

        XCTAssertNil(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController)
        XCTAssertEqual(controller1.output.moduleDidSkipOnDismissCalledCounter, 1)
    }

    func testPassthroughChild() {

        let oldRootViewController = UIApplication.shared.keyWindow!.rootViewController!
        defer {
            UIApplication.shared.keyWindow!.rootViewController = oldRootViewController
        }

        setupCustomRootController()

        let controller1 = TestController()
        let controller2 = TestController()

        controller2.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        controller2.view.frame = controller2.view.bounds

        controller1.addChildViewController(controller2)
        controller1.view.addSubview(controller2.view)
        controller2.didMove(toParentViewController: controller1)

        controller1.skipOnDismiss = true

        let closedExpectation = XCTestExpectation(description: "closedExpectation")

        UIApplication.shared.keyWindow!.rootViewController!.present(controller1, animated: true, completion: {
            controller2.closeCurrentModule(true) {
                closedExpectation.fulfill()
            }
        })

        wait(for: [closedExpectation], timeout: 10)

        XCTAssertNil(UIApplication.shared.keyWindow!.rootViewController!.presentedViewController)
        XCTAssertEqual(controller1.output.moduleDidSkipOnDismissCalledCounter, 0)
        XCTAssertEqual(controller2.output.moduleDidSkipOnDismissCalledCounter, 1)
    }
}
