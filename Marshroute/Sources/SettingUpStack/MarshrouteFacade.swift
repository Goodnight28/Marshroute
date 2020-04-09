public struct MarshrouteModule<V: UIViewController> {
    public let viewController: V
    public let routerSeed: RouterSeed
}

public typealias MarshrouteNavigationModule = MarshrouteModule<UINavigationController>

public final class MarshrouteFacade {
    // MARK: - Private properties
    let marshrouteStack: MarshrouteStack
    
    // MARK: - Init
    public init(marshrouteSetupService: MarshrouteSetupService = MarshrouteSetupServiceImpl()) {
        self.marshrouteStack = marshrouteSetupService.marshrouteStack()
    }
    
    public init(marshrouteStack: MarshrouteStack) {
        self.marshrouteStack = marshrouteStack
    }
    
    public func navigationModule(
        _ navigationController: UINavigationController? = nil,
        withRootViewControllerDerivedFrom deriveViewController: (RouterSeed) -> (UIViewController))
        -> MarshrouteNavigationModule
    {
        let transitionId = marshrouteStack.transitionIdGenerator.generateNewTransitionId()
        
        let navigationController = navigationController ?? marshrouteStack.routerControllersProvider.navigationController()
        
        let navigationTransitionsHandler = marshrouteStack.transitionsHandlersProvider.navigationTransitionsHandler(
            navigationController: navigationController
        )
        
        let routerSeed = RouterSeed(
            transitionsHandlerBox: .init(animatingTransitionsHandler: navigationTransitionsHandler),
            transitionId: transitionId,
            presentingTransitionsHandler: nil,
            transitionsHandlersProvider: marshrouteStack.transitionsHandlersProvider,
            transitionIdGenerator: marshrouteStack.transitionIdGenerator,
            controllersProvider: marshrouteStack.routerControllersProvider
        )
        
        let viewController = deriveViewController(routerSeed)
        
        let resetContext = ResettingTransitionContext(
            settingRootViewController: viewController,
            forNavigationController: navigationController,
            animatingTransitionsHandler: navigationTransitionsHandler,
            animator: SetNavigationTransitionsAnimator(),
            transitionId: transitionId
        )
        
        navigationTransitionsHandler.resetWithTransition(
            context: resetContext
        )
        
        return MarshrouteNavigationModule(
            viewController: navigationController,
            routerSeed: routerSeed
        )
    }
    
    public func tabBarController(
        _ tabBarController: UITabBarController? = nil,
        tabControllerDeriviationFunctionTypes: [TabControllerDeriviationFunctionType])
        -> UITabBarController
    {
        // MARK: - Preimplementation
        let transitionId = marshrouteStack.transitionIdGenerator.generateNewTransitionId()
        
        // MARK: - Helpers
        func makeRouterSeed(transitionsHandlerBox: TransitionsHandlerBox)
            -> RouterSeed
        {
            return RouterSeed(
                transitionsHandlerBox: transitionsHandlerBox,
                transitionId: transitionId,
                presentingTransitionsHandler: nil,
                transitionsHandlersProvider: marshrouteStack.transitionsHandlersProvider,
                transitionIdGenerator: marshrouteStack.transitionIdGenerator,
                controllersProvider: marshrouteStack.routerControllersProvider
            )
        }
        
        func deriveDetailController(
            tabIndex: Int,
            detailControllerDeriviationFunctionType: DetailControllerDeriviationFunctionType)
            -> (UIViewController, AnimatingTransitionsHandler)
        {
            switch detailControllerDeriviationFunctionType {
            case .controller(let detailControllerDeriviationFuction):
                return deriveDetailController(
                    tabIndex: tabIndex,
                    detailControllerDeriviationFuction: detailControllerDeriviationFuction
                )
                
            case .controllerInNavigationController(let detailControllerDeriviationFuction):
                return deriveDetailControllerInNavigationController(
                    tabIndex: tabIndex,
                    detailControllerDeriviationFuction: detailControllerDeriviationFuction
                )
            }
        }
        
        func deriveDetailController(
            tabIndex: Int,
            detailControllerDeriviationFuction: DetailControllerDeriviationFuction)
            -> (UIViewController, AnimatingTransitionsHandler)
        {
            let animatingTransitionsHandler = marshrouteStack.transitionsHandlersProvider.animatingTransitionsHandler()
            
            let routerSeed = makeRouterSeed(
                transitionsHandlerBox: .init(animatingTransitionsHandler: animatingTransitionsHandler)
            )
            
            let controllerDeriviationParams = DetailControllerDeriviationParams(
                tabIndex: tabIndex,
                routerSeed: routerSeed
            )
            
            let viewController = detailControllerDeriviationFuction.deriveController(controllerDeriviationParams)
            
            let resetContext = ResettingTransitionContext(
                registeringViewController: viewController,
                animatingTransitionsHandler: animatingTransitionsHandler,
                transitionId: transitionId
            )
            
            animatingTransitionsHandler.resetWithTransition(context: resetContext)
            
            return (viewController, animatingTransitionsHandler)
        }
        
        func deriveDetailControllerInNavigationController(
            tabIndex: Int,
            detailControllerDeriviationFuction: DetailControllerDeriviationFuction)
            -> (UIViewController, AnimatingTransitionsHandler)
        {
            let navigationController = marshrouteStack.routerControllersProvider.navigationController()
            
            let navigationTransitionsHandler = marshrouteStack.transitionsHandlersProvider.navigationTransitionsHandler(
                navigationController: navigationController
            )
            
            let routerSeed = makeRouterSeed(
                transitionsHandlerBox: .init(animatingTransitionsHandler: navigationTransitionsHandler)
            )
            
            let controllerDeriviationParams = DetailControllerDeriviationParams(
                tabIndex: tabIndex,
                routerSeed: routerSeed
            )
            
            let viewController = detailControllerDeriviationFuction.deriveController(controllerDeriviationParams)
            
            let resetContext = ResettingTransitionContext(
                settingRootViewController: viewController,
                forNavigationController: navigationController,
                animatingTransitionsHandler: navigationTransitionsHandler,
                animator: SetNavigationTransitionsAnimator(),
                transitionId: transitionId
            )
            
            navigationTransitionsHandler.resetWithTransition(
                context: resetContext
            )
            
            return (viewController, navigationTransitionsHandler)
        }
        
        // MARK: - MasterDetail helpers
    
        func makeMasterDetailRouterSeed(
            masterTransitionsHandlerBox: TransitionsHandlerBox,
            detailTransitionsHandlerBox: TransitionsHandlerBox)
            -> MasterDetailRouterSeed
        {
            return MasterDetailRouterSeed(
                masterTransitionsHandlerBox: masterTransitionsHandlerBox,
                detailTransitionsHandlerBox: detailTransitionsHandlerBox,
                transitionId: transitionId,
                presentingTransitionsHandler: nil,
                transitionsHandlersProvider: marshrouteStack.transitionsHandlersProvider,
                transitionIdGenerator: marshrouteStack.transitionIdGenerator,
                controllersProvider: marshrouteStack.routerControllersProvider
            )
        }
        
        func deriveMasterController(
            tabIndex: Int,
            detailTransitionsHandlerBox: TransitionsHandlerBox,
            masterControllerDeriviationFunctionType: MasterControllerDeriviationFunctionType)
            -> (UIViewController, AnimatingTransitionsHandler)
        {
            switch masterControllerDeriviationFunctionType {
            case .controller(let masterControllerDeriviationFuction):
                return deriveMasterController(
                    tabIndex: tabIndex,
                    detailTransitionsHandlerBox: detailTransitionsHandlerBox,
                    masterControllerDeriviationFuction: masterControllerDeriviationFuction
                )
                
            case .controllerInNavigationController(let masterControllerDeriviationFuction):
                return deriveMasterControllerInNavigationController(
                    tabIndex: tabIndex,
                    detailTransitionsHandlerBox: detailTransitionsHandlerBox,
                    masterControllerDeriviationFuction: masterControllerDeriviationFuction
                )
            }
        }
        
        func deriveMasterController(
            tabIndex: Int,
            detailTransitionsHandlerBox: TransitionsHandlerBox,
            masterControllerDeriviationFuction: MasterControllerDeriviationFunction)
            -> (UIViewController, AnimatingTransitionsHandler)
        {
            let animatingTransitionsHandler = marshrouteStack.transitionsHandlersProvider.animatingTransitionsHandler()
            
            let routerSeed = makeMasterDetailRouterSeed(
                masterTransitionsHandlerBox: .init(animatingTransitionsHandler: animatingTransitionsHandler),
                detailTransitionsHandlerBox: detailTransitionsHandlerBox
            )
            
            let controllerDeriviationParams = MasterControllerDeriviationParams(
                tabIndex: tabIndex,
                routerSeed: routerSeed
            )
            
            let viewController = masterControllerDeriviationFuction.deriveController(controllerDeriviationParams)
            
            let resetContext = ResettingTransitionContext(
                registeringViewController: viewController,
                animatingTransitionsHandler: animatingTransitionsHandler,
                transitionId: transitionId
            )
            
            animatingTransitionsHandler.resetWithTransition(context: resetContext)
            
            return (viewController, animatingTransitionsHandler)
        }
        
        func deriveMasterControllerInNavigationController(
            tabIndex: Int,
            detailTransitionsHandlerBox: TransitionsHandlerBox,
            masterControllerDeriviationFuction: MasterControllerDeriviationFunction)
            -> (UIViewController, AnimatingTransitionsHandler)
        {
            let navigationController = marshrouteStack.routerControllersProvider.navigationController()
            
            let navigationTransitionsHandler = marshrouteStack.transitionsHandlersProvider.navigationTransitionsHandler(
                navigationController: navigationController
            )
            
            let routerSeed = makeMasterDetailRouterSeed(
                masterTransitionsHandlerBox: .init(animatingTransitionsHandler: navigationTransitionsHandler),
                detailTransitionsHandlerBox: detailTransitionsHandlerBox
            )
            
            let controllerDeriviationParams = MasterControllerDeriviationParams(
                tabIndex: tabIndex,
                routerSeed: routerSeed
            )
            
            let viewController = masterControllerDeriviationFuction.deriveController(controllerDeriviationParams)
            
            let resetContext = ResettingTransitionContext(
                settingRootViewController: viewController,
                forNavigationController: navigationController,
                animatingTransitionsHandler: navigationTransitionsHandler,
                animator: SetNavigationTransitionsAnimator(),
                transitionId: transitionId
            )
            
            navigationTransitionsHandler.resetWithTransition(
                context: resetContext
            )
            
            return (viewController, navigationTransitionsHandler)
        }

        func deriveMasterDetailController(
            tabIndex: Int,
            masterDetailControllerDeriviationFuctionTypes: MasterDetailControllerDeriviationFuctionTypes)
            -> (UIViewController, SplitViewTransitionsHandlerImpl)
        {
            let (detailController, detaillTransitionHandler) = deriveDetailController(
                tabIndex: tabIndex,
                detailControllerDeriviationFunctionType: masterDetailControllerDeriviationFuctionTypes.detailFunctionType
            )
            
            let (masterController, masterTransitionsHandler) = deriveMasterController(
                tabIndex: tabIndex,
                detailTransitionsHandlerBox: .init(animatingTransitionsHandler: detaillTransitionHandler),
                masterControllerDeriviationFunctionType: masterDetailControllerDeriviationFuctionTypes.masterFunctionType
            )
            
            let splitViewController = marshrouteStack.routerControllersProvider.splitViewController()
            
            splitViewController.viewControllers = [masterController, detailController]
            
            let splitTransitionsHandler = marshrouteStack.transitionsHandlersProvider.splitViewTransitionsHandler(
                splitViewController: splitViewController
            )
            
            splitTransitionsHandler.masterTransitionsHandler = masterTransitionsHandler
            splitTransitionsHandler.detailTransitionsHandler = detaillTransitionHandler
            
            return (splitViewController, splitTransitionsHandler)
        }

        // MARK: - Implementation
        let tabBarController = tabBarController ?? UITabBarController()
        
        let tabTransitionsHandler = marshrouteStack.transitionsHandlersProvider.tabBarTransitionsHandler(
            tabBarController: tabBarController
        )
        
        var animatingTransitionsHandlers = [Int: AnimatingTransitionsHandler]()
        var containingTransitionsHandlers = [Int: ContainingTransitionsHandler]()
        var tabControllers = [UIViewController]()
        
        for (tabIndex, deriviationFunctionType) in tabControllerDeriviationFunctionTypes.enumerated() {
            switch deriviationFunctionType {
            case .controller(let detailControllerDeriviationFunctionType):
                let (viewController, animatingTransitionsHandler) = deriveDetailController(
                    tabIndex: tabIndex,
                    detailControllerDeriviationFunctionType: detailControllerDeriviationFunctionType
                )
                tabControllers.append(viewController)
                animatingTransitionsHandlers[tabIndex] = animatingTransitionsHandler
                
            case .masterDetailController(let masterDetailControllerDeriviationFuctionTypes):
                let (viewController, containingTransitionsHandler) = deriveMasterDetailController(
                    tabIndex: tabIndex,
                    masterDetailControllerDeriviationFuctionTypes: masterDetailControllerDeriviationFuctionTypes
                )
                tabControllers.append(viewController)
                containingTransitionsHandlers[tabIndex] = containingTransitionsHandler
            }
        }
        
        tabTransitionsHandler.animatingTransitionsHandlers = animatingTransitionsHandlers
        tabTransitionsHandler.containingTransitionsHandlers = containingTransitionsHandlers
        
        return tabBarController
    }
}

struct DetailControllerDeriviationParams {
    let tabIndex: Int
    let routerSeed: RouterSeed
}

public struct DetailControllerDeriviationFuction {
    let deriveController: ((DetailControllerDeriviationParams) -> (UIViewController))
}

public enum DetailControllerDeriviationFunctionType {
    case controller(DetailControllerDeriviationFuction)
    case controllerInNavigationController(DetailControllerDeriviationFuction)
}

struct MasterControllerDeriviationParams {
    let tabIndex: Int
    let routerSeed: MasterDetailRouterSeed
}

public struct MasterControllerDeriviationFunction {
    let deriveController: ((MasterControllerDeriviationParams) -> (UIViewController))
}

public enum MasterControllerDeriviationFunctionType {
    case controller(MasterControllerDeriviationFunction)
    case controllerInNavigationController(MasterControllerDeriviationFunction)
}

public struct MasterDetailControllerDeriviationFuctionTypes {
    let masterFunctionType: MasterControllerDeriviationFunctionType
    let detailFunctionType: DetailControllerDeriviationFunctionType
}

public enum TabControllerDeriviationFunctionType {
    case controller(DetailControllerDeriviationFunctionType)
    case masterDetailController(MasterDetailControllerDeriviationFuctionTypes)
}
