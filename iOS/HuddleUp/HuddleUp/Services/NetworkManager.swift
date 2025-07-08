import Foundation
import Combine
import os.log

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let baseURL = "http://10.2.11.13:3000/api"
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.huddleup.app", category: "NetworkManager")
    
    @Published var isLoading = false
    @Published var error: String?
    
    private var authToken: String? {
        get {
            UserDefaults.standard.string(forKey: "auth_token")
        }
        set {
            if let token = newValue {
                UserDefaults.standard.set(token, forKey: "auth_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "auth_token")
            }
        }
    }
    
    private init() {}
    
    // MARK: - Generic Request Method
    private func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, Error> {
        let fullURL = "\(baseURL)\(endpoint)"
        logger.info("🌐 Making \(method.rawValue) request to: \(fullURL)")
        
        guard let url = URL(string: fullURL) else {
            logger.error("❌ Invalid URL: \(fullURL)")
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Disable caching to ensure fresh data
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            logger.info("🔐 Using auth token")
        } else {
            logger.info("🔓 No auth token")
        }
        
        if let body = body {
            request.httpBody = body
            if let bodyString = String(data: body, encoding: .utf8) {
                logger.info("📤 Request body: \(bodyString)")
            }
        }
        
        logger.info("📡 Starting network request...")
        
        return session.dataTaskPublisher(for: request)
            .handleEvents(
                receiveSubscription: { [weak self] _ in
                    self?.logger.info("🔄 Request started")
                },
                receiveOutput: { [weak self] output in
                    self?.logger.info("✅ Response received - Status: \((output.response as? HTTPURLResponse)?.statusCode ?? 0)")
                    if let responseString = String(data: output.data, encoding: .utf8) {
                        self?.logger.info("📥 Response data: \(responseString)")
                    }
                },
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.logger.info("🎉 Request completed successfully")
                    case .failure(let error):
                        self?.logger.error("❌ Request failed with error: \(error.localizedDescription)")
                    }
                }
            )
            .map(\.data)
            .tryMap { [weak self] data in
                self?.logger.info("🔍 Attempting to decode JSON for type: \(responseType)")
                self?.logger.info("🔍 Raw data size: \(data.count) bytes")
                
                do {
                    let decoder = self?.createJSONDecoder() ?? JSONDecoder()
                    let result = try decoder.decode(responseType, from: data)
                    self?.logger.info("✅ Successfully decoded JSON")
                    return result
                } catch {
                    self?.logger.error("🚨 JSON decode error: \(error.localizedDescription)")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            self?.logger.error("🚨 Key not found: \(key.stringValue)")
                            self?.logger.error("🚨 Context: \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            self?.logger.error("🚨 Type mismatch: \(type)")
                            self?.logger.error("🚨 Context: \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            self?.logger.error("🚨 Value not found: \(type)")
                            self?.logger.error("🚨 Context: \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            self?.logger.error("🚨 Data corrupted: \(context.debugDescription)")
                        @unknown default:
                            self?.logger.error("🚨 Unknown decoding error")
                        }
                    }
                    throw NetworkError.decodingError
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func createJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }
    
    private func createJSONEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    // MARK: - Authentication
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, Error> {
        let loginRequest = LoginRequest(email: email, password: password)
        
        guard let body = try? createJSONEncoder().encode(loginRequest) else {
            return Fail(error: NetworkError.encodingError).eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/auth/login",
            method: .POST,
            body: body,
            responseType: AuthResponse.self
        )
        .handleEvents(receiveOutput: { [weak self] response in
            self?.authToken = response.token
        })
        .eraseToAnyPublisher()
    }
    
    func register(
        email: String,
        username: String,
        password: String,
        firstName: String,
        lastName: String
    ) -> AnyPublisher<AuthResponse, Error> {
        let registerRequest = RegisterRequest(
            email: email,
            username: username,
            password: password,
            firstName: firstName,
            lastName: lastName
        )
        
        guard let body = try? createJSONEncoder().encode(registerRequest) else {
            return Fail(error: NetworkError.encodingError).eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/auth/register",
            method: .POST,
            body: body,
            responseType: AuthResponse.self
        )
        .handleEvents(receiveOutput: { [weak self] response in
            self?.authToken = response.token
        })
        .eraseToAnyPublisher()
    }
    
    func getCurrentUser() -> AnyPublisher<User, Error> {
        return request(
            endpoint: "/auth/me",
            responseType: User.self
        )
    }
    
    func logout() -> AnyPublisher<APIResponse<String>, Error> {
        return request(
            endpoint: "/auth/logout",
            method: .POST,
            responseType: APIResponse<String>.self
        )
        .handleEvents(receiveOutput: { [weak self] _ in
            self?.authToken = nil
        })
        .eraseToAnyPublisher()
    }
    
    // MARK: - Teams
    func getTeams() -> AnyPublisher<[Team], Error> {
        return request(
            endpoint: "/teams",
            responseType: [Team].self
        )
    }
    
    func getTeam(id: String) -> AnyPublisher<Team, Error> {
        return request(
            endpoint: "/teams/\(id)",
            responseType: Team.self
        )
    }
    
    func createTeam(name: String, description: String?) -> AnyPublisher<APIResponse<Team>, Error> {
        let createRequest = CreateTeamRequest(name: name, description: description)
        
        guard let body = try? createJSONEncoder().encode(createRequest) else {
            return Fail(error: NetworkError.encodingError).eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/teams",
            method: .POST,
            body: body,
            responseType: APIResponse<Team>.self
        )
    }
    
    func joinTeam(inviteCode: String) -> AnyPublisher<APIResponse<Team>, Error> {
        let joinRequest = JoinTeamRequest(inviteCode: inviteCode)
        
        guard let body = try? createJSONEncoder().encode(joinRequest) else {
            return Fail(error: NetworkError.encodingError).eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/teams/join",
            method: .POST,
            body: body,
            responseType: APIResponse<Team>.self
        )
    }
    
    func generateInviteCode(teamId: String) -> AnyPublisher<[String: String], Error> {
        return request(
            endpoint: "/teams/\(teamId)/invite",
            method: .POST,
            responseType: [String: String].self
        )
    }
    
    func leaveTeam(id: String) -> AnyPublisher<APIResponse<String>, Error> {
        return request(
            endpoint: "/teams/\(id)/leave",
            method: .POST,
            responseType: APIResponse<String>.self
        )
    }
    
    // MARK: - Channels
    func getChannels(teamId: String) -> AnyPublisher<[Channel], Error> {
        return request(
            endpoint: "/channels/team/\(teamId)",
            responseType: [Channel].self
        )
    }
    
    func getChannel(id: String) -> AnyPublisher<Channel, Error> {
        return request(
            endpoint: "/channels/\(id)",
            responseType: Channel.self
        )
    }
    
    func createChannel(
        name: String,
        description: String?,
        teamId: String,
        isPrivate: Bool
    ) -> AnyPublisher<APIResponse<Channel>, Error> {
        let createRequest = CreateChannelRequest(
            name: name,
            description: description,
            teamId: teamId,
            isPrivate: isPrivate
        )
        
        guard let body = try? createJSONEncoder().encode(createRequest) else {
            return Fail(error: NetworkError.encodingError).eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/channels",
            method: .POST,
            body: body,
            responseType: APIResponse<Channel>.self
        )
    }
    
    func joinChannel(id: String) -> AnyPublisher<APIResponse<Channel>, Error> {
        return request(
            endpoint: "/channels/\(id)/join",
            method: .POST,
            responseType: APIResponse<Channel>.self
        )
    }
    
    func leaveChannel(id: String) -> AnyPublisher<APIResponse<String>, Error> {
        return request(
            endpoint: "/channels/\(id)/leave",
            method: .POST,
            responseType: APIResponse<String>.self
        )
    }
    
    // MARK: - Messages
    func getMessages(channelId: String, page: Int = 1, limit: Int = 50) -> AnyPublisher<[Message], Error> {
        return request(
            endpoint: "/channels/\(channelId)/messages?page=\(page)&limit=\(limit)",
            responseType: [Message].self
        )
    }
    
    func sendMessage(content: String, channelId: String) -> AnyPublisher<APIResponse<Message>, Error> {
        let sendRequest = SendMessageRequest(content: content, channelId: channelId)
        
        guard let body = try? createJSONEncoder().encode(sendRequest) else {
            return Fail(error: NetworkError.encodingError).eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/messages",
            method: .POST,
            body: body,
            responseType: APIResponse<Message>.self
        )
    }
    
    func editMessage(id: String, content: String) -> AnyPublisher<APIResponse<Message>, Error> {
        let editRequest = EditMessageRequest(content: content)
        
        guard let body = try? createJSONEncoder().encode(editRequest) else {
            return Fail(error: NetworkError.encodingError).eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/messages/\(id)",
            method: .PUT,
            body: body,
            responseType: APIResponse<Message>.self
        )
    }
    
    func deleteMessage(id: String) -> AnyPublisher<APIResponse<String>, Error> {
        return request(
            endpoint: "/messages/\(id)",
            method: .DELETE,
            responseType: APIResponse<String>.self
        )
    }
    
    func addReaction(messageId: String, emoji: String) -> AnyPublisher<APIResponse<Message>, Error> {
        let reactionRequest = AddReactionRequest(emoji: emoji)
        
        guard let body = try? createJSONEncoder().encode(reactionRequest) else {
            return Fail(error: NetworkError.encodingError).eraseToAnyPublisher()
        }
        
        return request(
            endpoint: "/messages/\(messageId)/reaction",
            method: .POST,
            body: body,
            responseType: APIResponse<Message>.self
        )
    }
    
    // MARK: - Helper Methods
    func setAuthToken(_ token: String) {
        authToken = token
    }
    
    func clearAuthToken() {
        authToken = nil
    }
    
    var hasAuthToken: Bool {
        return authToken != nil
    }
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case encodingError
    case decodingError
    case serverError(String)
    case unauthorized
    case notFound
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingError:
            return "Failed to encode request"
        case .decodingError:
            return "Failed to decode response"
        case .serverError(let message):
            return message
        case .unauthorized:
            return "Unauthorized access"
        case .notFound:
            return "Resource not found"
        case .unknown:
            return "An unknown error occurred"
        }
    }
} 