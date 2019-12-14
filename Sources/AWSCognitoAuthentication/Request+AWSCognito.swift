import AWSCognitoAuthenticationKit
import Vapor

public extension Request {
    /// helper function that returns if request with bearer token is cognito access authenticated
    /// - returns:
    ///     An access token object that contains the user name and id
    func authenticateAccessToken() -> EventLoopFuture<AWSCognitoAccessToken> {
        guard let bearer = headers.bearerAuthorization else {
            return self.eventLoop.makeFailedFuture(AWSCognitoError.unauthorized(reason: "No bearer token"))
        }
        return self.application.awsCognito.authenticatable.authenticate(accessToken: bearer.token, on: eventLoop)
    }

    /// helper function that returns if request with bearer token is cognito id authenticated and returns contents in the payload type
    /// - returns:
    ///     The payload contained in the token. See `authenticate<Payload: Codable>(idToken:on:)` for more details
    func authenticateIdToken<Payload: Codable>() -> EventLoopFuture<Payload> {
        guard let bearer = headers.bearerAuthorization else {
            return self.eventLoop.makeFailedFuture(AWSCognitoError.unauthorized(reason: "No bearer token"))
        }
        return self.application.awsCognito.authenticatable.authenticate(idToken: bearer.token, on: eventLoop)
    }
}

/// extend Vapor Request to provide Cognito context
extension Request: AWSCognitoEventLoopWithContext {
    public var cognitoContextData: CognitoIdentityProvider.ContextDataType? {
        let host = headers["Host"].first ?? "localhost:8080"
        guard let remoteAddress = remoteAddress else { return nil }
        let ipAddress: String
        switch remoteAddress {
        case .v4(let address):
            ipAddress = address.host
        case .v6(let address):
            ipAddress = address.host
        default:
            return nil
        }

        //guard let ipAddress = req.http.remotePeer.hostname ?? req.http.channel?.remoteAddress?.description else { return nil }
        let httpHeaders = headers.map { CognitoIdentityProvider.HttpHeader(headerName: $0.name, headerValue: $0.value) }
        let contextData = CognitoIdentityProvider.ContextDataType(
            httpHeaders: httpHeaders,
            ipAddress: ipAddress,
            serverName: host,
            serverPath: url.path)
        return contextData
    }
}