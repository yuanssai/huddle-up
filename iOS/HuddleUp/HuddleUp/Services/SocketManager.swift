import Foundation
import Combine

// Note: In a real project, you would add SocketIO-Swift via Swift Package Manager
// URL: https://github.com/socketio/socket.io-client-swift
// For this demo, I'm creating a mock implementation that can be replaced with actual SocketIO

protocol SocketManagerProtocol: ObservableObject {
    func connect(token: String)
    func disconnect()
    func joinTeams(_ teamIds: [String])
    func joinChannel(_ channelId: String)
    func leaveChannel(_ channelId: String)
    func sendMessage(content: String, channelId: String)
    func editMessage(messageId: String, content: String)
    func deleteMessage(messageId: String)
    func sendTypingIndicator(channelId: String, isTyping: Bool)
    
    var isConnected: Bool { get }
    var newMessagePublisher: AnyPublisher<Message, Never> { get }
    var messageEditedPublisher: AnyPublisher<Message, Never> { get }
    var messageDeletedPublisher: AnyPublisher<String, Never> { get }
    var userTypingPublisher: AnyPublisher<SocketUserTyping, Never> { get }
    var errorPublisher: AnyPublisher<String, Never> { get }
}

class SocketManager: SocketManagerProtocol {
    static let shared = SocketManager()
    
    // MARK: - Published Properties
    @Published var isConnected = false
    
    // MARK: - Private Properties
    private let serverURL = "http://10.2.11.13:3000"
    private var cancellables = Set<AnyCancellable>()
    
    // Mock Socket.IO implementation - replace with actual SocketIO
    private var mockSocket: MockSocket?
    
    // Publishers for real-time events
    private let newMessageSubject = PassthroughSubject<Message, Never>()
    private let messageEditedSubject = PassthroughSubject<Message, Never>()
    private let messageDeletedSubject = PassthroughSubject<String, Never>()
    private let userTypingSubject = PassthroughSubject<SocketUserTyping, Never>()
    private let errorSubject = PassthroughSubject<String, Never>()
    
    var newMessagePublisher: AnyPublisher<Message, Never> {
        newMessageSubject.eraseToAnyPublisher()
    }
    
    var messageEditedPublisher: AnyPublisher<Message, Never> {
        messageEditedSubject.eraseToAnyPublisher()
    }
    
    var messageDeletedPublisher: AnyPublisher<String, Never> {
        messageDeletedSubject.eraseToAnyPublisher()
    }
    
    var userTypingPublisher: AnyPublisher<SocketUserTyping, Never> {
        userTypingSubject.eraseToAnyPublisher()
    }
    
    var errorPublisher: AnyPublisher<String, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    private init() {
        setupMockSocket()
    }
    
    // MARK: - Connection Management
    func connect(token: String) {
        print("🔌 Connecting to socket server...")
        
        // In real implementation, you would use:
        // socket = SocketIOClient(socketURL: URL(string: serverURL)!, config: [
        //     .log(true),
        //     .auth(["token": token])
        // ])
        
        mockSocket?.connect(token: token)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isConnected = true
            print("✅ Socket connected")
        }
    }
    
    func disconnect() {
        print("🔌 Disconnecting from socket server...")
        mockSocket?.disconnect()
        isConnected = false
        print("❌ Socket disconnected")
    }
    
    // MARK: - Channel Management
    func joinTeams(_ teamIds: [String]) {
        guard isConnected else { return }
        print("🏟️ Joining teams: \(teamIds)")
        mockSocket?.joinTeams(teamIds)
    }
    
    func joinChannel(_ channelId: String) {
        guard isConnected else { return }
        print("📺 Joining channel: \(channelId)")
        mockSocket?.joinChannel(channelId)
    }
    
    func leaveChannel(_ channelId: String) {
        guard isConnected else { return }
        print("🚪 Leaving channel: \(channelId)")
        mockSocket?.leaveChannel(channelId)
    }
    
    // MARK: - Message Operations
    func sendMessage(content: String, channelId: String) {
        guard isConnected else { return }
        
        let socketMessage = SocketMessage(content: content, channelId: channelId)
        mockSocket?.sendMessage(socketMessage)
        
        print("📤 Sending message to channel \(channelId): \(content)")
    }
    
    func editMessage(messageId: String, content: String) {
        guard isConnected else { return }
        
        let editMessage = SocketEditMessage(messageId: messageId, content: content)
        mockSocket?.editMessage(editMessage)
        
        print("✏️ Editing message \(messageId): \(content)")
    }
    
    func deleteMessage(messageId: String) {
        guard isConnected else { return }
        
        mockSocket?.deleteMessage(messageId)
        print("🗑️ Deleting message: \(messageId)")
    }
    
    func sendTypingIndicator(channelId: String, isTyping: Bool) {
        guard isConnected else { return }
        
        let typingEvent = SocketTypingEvent(channelId: channelId, isTyping: isTyping)
        mockSocket?.sendTypingIndicator(typingEvent)
    }
    
    // MARK: - Mock Socket Implementation
    private func setupMockSocket() {
        mockSocket = MockSocket()
        
        // Setup event handlers
        mockSocket?.onNewMessage = { [weak self] message in
            self?.newMessageSubject.send(message)
        }
        
        mockSocket?.onMessageEdited = { [weak self] message in
            self?.messageEditedSubject.send(message)
        }
        
        mockSocket?.onMessageDeleted = { [weak self] messageId in
            self?.messageDeletedSubject.send(messageId)
        }
        
        mockSocket?.onUserTyping = { [weak self] userTyping in
            self?.userTypingSubject.send(userTyping)
        }
        
        mockSocket?.onError = { [weak self] error in
            self?.errorSubject.send(error)
        }
    }
}

// MARK: - Mock Socket Implementation
// This would be replaced with actual SocketIO implementation
private class MockSocket {
    var onNewMessage: ((Message) -> Void)?
    var onMessageEdited: ((Message) -> Void)?
    var onMessageDeleted: ((String) -> Void)?
    var onUserTyping: ((SocketUserTyping) -> Void)?
    var onError: ((String) -> Void)?
    
    private var isConnected = false
    private var connectedChannels: Set<String> = []
    
    func connect(token: String) {
        isConnected = true
        
        // Simulate receiving messages
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.simulateIncomingMessage()
        }
    }
    
    func disconnect() {
        isConnected = false
        connectedChannels.removeAll()
    }
    
    func joinTeams(_ teamIds: [String]) {
        // Mock implementation
    }
    
    func joinChannel(_ channelId: String) {
        connectedChannels.insert(channelId)
    }
    
    func leaveChannel(_ channelId: String) {
        connectedChannels.remove(channelId)
    }
    
    func sendMessage(_ message: SocketMessage) {
        // In real implementation, this would emit to server
        // Server would then broadcast to all channel members
        
        // Mock: simulate message echo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let mockMessage = Message(
                id: UUID().uuidString,
                content: message.content,
                senderId: "current-user",
                channelId: message.channelId,
                teamId: "team-1",
                messageType: .text,
                fileUrl: nil,
                editedAt: nil,
                parentMessageId: nil,
                createdAt: Date(),
                updatedAt: Date(),
                sender: User.mock,
                reactions: nil
            )
            self.onNewMessage?(mockMessage)
        }
    }
    
    func editMessage(_ editMessage: SocketEditMessage) {
        // Mock implementation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let mockMessage = Message(
                id: editMessage.messageId,
                content: editMessage.content,
                senderId: "current-user",
                channelId: "channel-1",
                teamId: "team-1",
                messageType: .text,
                fileUrl: nil,
                editedAt: Date(),
                parentMessageId: nil,
                createdAt: Date().addingTimeInterval(-300),
                updatedAt: Date(),
                sender: User.mock,
                reactions: nil
            )
            self.onMessageEdited?(mockMessage)
        }
    }
    
    func deleteMessage(_ messageId: String) {
        // Mock implementation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.onMessageDeleted?(messageId)
        }
    }
    
    func sendTypingIndicator(_ typingEvent: SocketTypingEvent) {
        // Mock implementation - simulate other user typing
        if typingEvent.isTyping {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let userTyping = SocketUserTyping(
                    userId: "other-user",
                    username: "alice",
                    channelId: typingEvent.channelId,
                    isTyping: true
                )
                self.onUserTyping?(userTyping)
                
                // Stop typing after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    let userTyping = SocketUserTyping(
                        userId: "other-user",
                        username: "alice",
                        channelId: typingEvent.channelId,
                        isTyping: false
                    )
                    self.onUserTyping?(userTyping)
                }
            }
        }
    }
    
    private func simulateIncomingMessage() {
        guard isConnected else { return }
        
        let mockMessage = Message(
            id: UUID().uuidString,
            content: "Welcome to Huddle Up! 🎉",
            senderId: "demo-user",
            channelId: "general",
            teamId: "team-1",
            messageType: .text,
            fileUrl: nil,
            editedAt: nil,
            parentMessageId: nil,
            createdAt: Date(),
            updatedAt: Date(),
            sender: User(
                id: "demo-user",
                email: "demo@example.com",
                username: "demo",
                firstName: "Demo",
                lastName: "User",
                avatar: nil,
                isOnline: true,
                lastSeen: Date()
            ),
            reactions: nil
        )
        
        onNewMessage?(mockMessage)
        
        // Schedule next random message
        let randomDelay = Double.random(in: 10...30)
        DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
            self.simulateRandomMessage()
        }
    }
    
    private func simulateRandomMessage() {
        guard isConnected else { return }
        
        let messages = [
            "How's everyone doing today?",
            "Just pushed the latest updates 🚀",
            "Coffee break anyone? ☕",
            "Great work on the presentation!",
            "Looking forward to our next sprint",
            "The new feature looks amazing! 👏"
        ]
        
        let randomMessage = messages.randomElement() ?? "Hello!"
        
        let mockMessage = Message(
            id: UUID().uuidString,
            content: randomMessage,
            senderId: "alice-user",
            channelId: "general",
            teamId: "team-1",
            messageType: .text,
            fileUrl: nil,
            editedAt: nil,
            parentMessageId: nil,
            createdAt: Date(),
            updatedAt: Date(),
            sender: User(
                id: "alice-user",
                email: "alice@example.com",
                username: "alice",
                firstName: "Alice",
                lastName: "Johnson",
                avatar: nil,
                isOnline: true,
                lastSeen: Date()
            ),
            reactions: nil
        )
        
        onNewMessage?(mockMessage)
    }
}

/*
// MARK: - Real SocketIO Implementation Example
// Uncomment and use this when SocketIO-Swift is added to the project

import SocketIO

class RealSocketManager: SocketManagerProtocol {
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    func connect(token: String) {
        guard let url = URL(string: serverURL) else { return }
        
        manager = SocketManager(socketURL: url, config: [
            .log(true),
            .auth(["token": token])
        ])
        
        socket = manager?.defaultSocket
        
        setupEventHandlers()
        socket?.connect()
    }
    
    private func setupEventHandlers() {
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            print("Socket connected")
            self?.isConnected = true
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("Socket disconnected")
            self?.isConnected = false
        }
        
        socket?.on("new-message") { [weak self] data, ack in
            if let messageData = data[0] as? [String: Any],
               let jsonData = try? JSONSerialization.data(withJSONObject: messageData),
               let message = try? JSONDecoder().decode(Message.self, from: jsonData) {
                self?.newMessageSubject.send(message)
            }
        }
        
        // Add other event handlers...
    }
    
    func sendMessage(content: String, channelId: String) {
        let data = ["content": content, "channelId": channelId]
        socket?.emit("send-message", data)
    }
    
    // Implement other methods...
}
*/ 