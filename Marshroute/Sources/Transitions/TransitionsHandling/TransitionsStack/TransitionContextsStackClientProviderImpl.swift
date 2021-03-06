public final class TransitionContextsStackClientProviderImpl {
    private var historyItems = [TransitionsHistoryItem]()
    
    public init() {}
}

// MARK: - TransitionContextsStackClientProvider
extension TransitionContextsStackClientProviderImpl: TransitionContextsStackClientProvider {
    public func stackClient(forTransitionsHandler transitionsHandler: TransitionsHandler)
        -> TransitionContextsStackClient?
    {
        updateHistoryItems()
        
        let matchingHistoryItems = historyItems.filter { $0.transitionsHandler === transitionsHandler }
        
        marshrouteAssert(matchingHistoryItems.count <= 1)
        
        return matchingHistoryItems.first?.stackClient
    }
    
    public func createStackClient(forTransitionsHandler transitionsHandler: TransitionsHandler)
        -> TransitionContextsStackClient
    {
        updateHistoryItems()
        
        let stackClient = TransitionContextsStackClientImpl()

        let newHistoryItem = TransitionsHistoryItem(
            stackClient: stackClient,
            transitionsHandler: transitionsHandler
        )
        
        historyItems.append(newHistoryItem)
        
        return stackClient
    }
}

// MARK: - helpers
private extension TransitionContextsStackClientProviderImpl {
    func updateHistoryItems()
    {
        historyItems = historyItems.filter { $0.transitionsHandler != nil }
    }
}
