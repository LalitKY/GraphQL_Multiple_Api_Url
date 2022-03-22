

import Foundation
import Apollo
import ApolloWebSocket
import Security
import CommonCrypto

enum GraphQLType: String {
    case filmList = "filmList"
    case subscription = "Subscription"
}

/// GraphQl network manager
final class GraphQLNetworkManager {
    /// set apollo and get apollo client instance
    /// - Parameter type: type of GraphLQ api
    /// - Returns: ApolloClient
    func getApollo(type: GraphQLType) -> ApolloClient {
        let sessionConfig = URLSessionConfiguration.default
        // MARK: PromiscuousURLSessionClient is for Certificate/SSL pinning
        let client = PromiscuousURLSessionClient(sessionConfiguration: sessionConfig )
        let cache = InMemoryNormalizedCache()
        let store = ApolloStore(cache: cache)
        let provider = NetworkInterceptorProvider(store: store, client: client)
        let url = URL(string: getGraphQLURL(type: type))!
        let transport = RequestChainNetworkTransport(interceptorProvider: provider, endpointURL: url)
        let splitNetworkTransport = SplitNetworkTransport(
            uploadingNetworkTransport: transport,
            webSocketNetworkTransport: self.webSocketTransport
          )
        return ApolloClient(networkTransport: splitNetworkTransport, store: store)
    }
    
    /// getGraphQL URL for specific
    /// - Parameter type: type of graphLQ api
    /// - Returns: api url
    private func getGraphQLURL(type: GraphQLType) -> String {
        switch type {
        case .filmList:
            return "http://localhost:58800"
        case .subscription:
            return "http://localhost:subscription"
        }
    }
    
    /// A web socket transport to use for subscriptions
      // This web socket will have to provide the connecting payload which
      // initializes the connection as an authorized channel.
    private lazy var webSocketTransport: WebSocketTransport = {
        let url = URL(string: self.getGraphQLURL(type: .subscription))!
        let request = URLRequest(url: url)
        let authPayload = authPayloadData
        return WebSocketTransport(websocket: WebSocket(request: request, protocol: .graphql_transport_ws),
                                  clientName: WebSocketTransport.defaultClientName,
                                  clientVersion: WebSocketTransport.defaultClientVersion,
                                  sendOperationIdentifiers: false,
                                  reconnect: true,
                                  reconnectionInterval: 0.5,
                                  allowSendingDuplicates: true,
                                  connectOnInit: true,
                                  connectingPayload: authPayload,
                                  requestBodyCreator: ApolloRequestBodyCreator())
    }()
    
    /// A web socket authPayload
    var authPayloadData: [String : String] {
        let headers = getGraphQLHTTPRequestHeaders()
        debugPrint(headers)
        let authPayload = [String : String]()
        return authPayload
    }
    
    /// Method to get request header
    /// - Returns: It return headers array as completion for graphQL
    private func getGraphQLHTTPRequestHeaders() -> [String: String] {
        let authHeaders: [String: String]  = [:]
        return authHeaders
    }
    
}


/// This class is Interceptor provider for GraphQL
private class NetworkInterceptorProvider: InterceptorProvider {
    // These properties will remain the same throughout the life of the `InterceptorProvider`, even though they
    // will be handed to different interceptors.
    private let store: ApolloStore
    private let client: URLSessionClient
    
    /// Method to get request header
    /// - Parameter store: intake ApolloStore
    /// - Parameter client: intake URLSessionClient
    init(store: ApolloStore,
         client: URLSessionClient) {
        self.store = store
        self.client = client
    }
    
    /// Method to get request header
    /// - Parameter operation: intake operation for interceptor
    /// - Returns: Array of in ApolloInterceptor values
    func interceptors<Operation: GraphQLOperation>(for operation: Operation) -> [ApolloInterceptor] {
        return [
            MaxRetryInterceptor(),
            CacheReadInterceptor(store: self.store),
            CustomInterceptor(),
            NetworkFetchInterceptor(client: self.client),
            ResponseCodeInterceptor(),
            JSONResponseParsingInterceptor(cacheKeyForObject: self.store.cacheKeyForObject),
            AutomaticPersistedQueryInterceptor(),
            CacheWriteInterceptor(store: self.store)
        ]
    }
}

/// Custom interceptor for Apollo
private class CustomInterceptor: ApolloInterceptor {
    
    /// Intercept Async to provide GraphQl operation
    /// - Parameter chain: Intake RequestChain to intercept
    /// - Parameter request: Intake HTTPRequest<Operation>
    /// - Parameter response: Intake HTTPResponse<Operation>
    /// - Parameter completion: Provide Result for GraphQLResult and Error
    func interceptAsync<Operation: GraphQLOperation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Swift.Result<GraphQLResult<Operation.Data>, Error>) -> Void) {
            request.additionalHeaders = [String: String]()
            chain.proceedAsync(request: request,
                               response: response,
                               completion: completion)
        
    }   
}
