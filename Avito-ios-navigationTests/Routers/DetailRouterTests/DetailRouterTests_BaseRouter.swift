import XCTest

final class DetailRouterTests_BaseRouter: XCTestCase
{
    var detailAnimatingTransitionsHandlerSpy: AnimatingTransitionsHandlerSpy!
    var targetViewController: UIViewController!
    var nextModuleRouterSeed: RouterSeed!
    
    var router: DetailRouter!
    
    override func setUp() {
        super.setUp()
        
        let transitionIdGenerator = TransitionIdGeneratorImpl()
        
        let transitionsCoordinator = TransitionsCoordinatorImpl(
            stackClientProvider: TransitionContextsStackClientProviderImpl()
        )
        
        detailAnimatingTransitionsHandlerSpy = AnimatingTransitionsHandlerSpy(
            transitionsCoordinator: transitionsCoordinator
        )
        
        targetViewController = UIViewController()
        
        router = BaseRouter(
            routerSeed: RouterSeed(
                transitionsHandlerBox: .init(
                    animatingTransitionsHandler: detailAnimatingTransitionsHandlerSpy
                ),
                transitionId: transitionIdGenerator.generateNewTransitionId(),
                presentingTransitionsHandler: nil,
                transitionsCoordinator: transitionsCoordinator,
                transitionIdGenerator: transitionIdGenerator,
                controllersProvider: RouterControllersProviderImpl()
            )
        )
    }
    
    func testThatRouterCallsItsTransitionsHandlerOn_SetViewControllerDerivedFrom_WithCorrectResettingContext() {
        // When
        router.setViewControllerDerivedFrom { (routerSeed) -> UIViewController in
            nextModuleRouterSeed = routerSeed
            return targetViewController
        }
        
        // Then
        XCTAssert(detailAnimatingTransitionsHandlerSpy.resetWithTransitionCalled)
        
        let resettingContext = detailAnimatingTransitionsHandlerSpy.resetWithTransitionContextParameter
        XCTAssertEqual(resettingContext.transitionId, nextModuleRouterSeed.transitionId)
        XCTAssert(resettingContext.targetViewController === targetViewController)
        XCTAssert(resettingContext.targetTransitionsHandlerBox.unbox() === detailAnimatingTransitionsHandlerSpy)
        XCTAssertNil(resettingContext.storableParameters)
        if case .ResettingNavigationRoot(let launchingContext) = resettingContext.resettingAnimationLaunchingContextBox {
            XCTAssert(launchingContext.rootViewController! == targetViewController)
        } else { XCTFail() }
    }
    
    func testThatRouterCallsItsTransitionsHandlerOn_SetViewControllerDerivedFrom_WithCorrectResettingContext_IfCustomAnimator() {
        // Given
        let resetNavigationTransitionsAnimator = ResetNavigationTransitionsAnimator()
        
        // When
        router.setViewControllerDerivedFrom( { (routerSeed) -> UIViewController in
            nextModuleRouterSeed = routerSeed
            return targetViewController
            }, animator: resetNavigationTransitionsAnimator
        )
        
        // Then
        XCTAssert(detailAnimatingTransitionsHandlerSpy.resetWithTransitionCalled)
        
        let resettingContext = detailAnimatingTransitionsHandlerSpy.resetWithTransitionContextParameter
        XCTAssertEqual(resettingContext.transitionId, nextModuleRouterSeed.transitionId)
        XCTAssert(resettingContext.targetViewController === targetViewController)
        XCTAssert(resettingContext.targetTransitionsHandlerBox.unbox() === detailAnimatingTransitionsHandlerSpy)
        XCTAssertNil(resettingContext.storableParameters)
        if case .ResettingNavigationRoot(let launchingContext) = resettingContext.resettingAnimationLaunchingContextBox {
            XCTAssert(launchingContext.animator === resetNavigationTransitionsAnimator)
            XCTAssert(launchingContext.rootViewController! === targetViewController)
        } else { XCTFail() }
    }
    
    func testThatRouterCallsItsTransitionsHandlerOn_PushViewControllerDerivedFrom_WithCorrectPresentationContext() {
        // When
        router.pushViewControllerDerivedFrom { (routerSeed) -> UIViewController in
            nextModuleRouterSeed = routerSeed
            return targetViewController
        }
        
        // Then
        XCTAssert(detailAnimatingTransitionsHandlerSpy.performTransitionCalled)
        
        let presentationContext = detailAnimatingTransitionsHandlerSpy.perFormTransitionContextParameter
        XCTAssertEqual(presentationContext.transitionId, nextModuleRouterSeed.transitionId)
        XCTAssert(presentationContext.targetViewController === targetViewController)
        if case .PendingAnimating = presentationContext.targetTransitionsHandlerBox {} else { XCTFail() }
        XCTAssertNil(presentationContext.storableParameters)
        if case .Push(let launchingContext) = presentationContext.presentationAnimationLaunchingContextBox {
            XCTAssert(launchingContext.targetViewController! == targetViewController)
        } else { XCTFail() }
    }
    
    func testThatRouterCallsItsTransitionsHandlerOn_PushViewControllerDerivedFrom_WithCorrectPresentationContext_IfCustomAnimator() {
        // Given
        let navigationTransitionsAnimator = NavigationTransitionsAnimator()
        
        // When
        router.pushViewControllerDerivedFrom( { (routerSeed) -> UIViewController in
            nextModuleRouterSeed = routerSeed
            return targetViewController
            }, animator: navigationTransitionsAnimator
        )
        
        // Then
        XCTAssert(detailAnimatingTransitionsHandlerSpy.performTransitionCalled)
        
        let presentationContext = detailAnimatingTransitionsHandlerSpy.perFormTransitionContextParameter
        XCTAssertEqual(presentationContext.transitionId, nextModuleRouterSeed.transitionId)
        XCTAssert(presentationContext.targetViewController === targetViewController)
        if case .PendingAnimating = presentationContext.targetTransitionsHandlerBox {} else { XCTFail() }
        XCTAssertNil(presentationContext.storableParameters)
        if case .Push(let launchingContext) = presentationContext.presentationAnimationLaunchingContextBox {
            XCTAssert(launchingContext.animator === navigationTransitionsAnimator)
            XCTAssert(launchingContext.targetViewController! === targetViewController)
        } else { XCTFail() }
    }
}
