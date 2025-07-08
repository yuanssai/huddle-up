import Foundation
import Combine

@MainActor
class MessageViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var showingError = false
    @Published var typingUsers: [String] = []
    @Published var hasMoreMessages = true
    
    private let networkManager = NetworkManager.shared
    private let socketManager = SocketManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Current channel ID to load messages for
    private var currentChannelId: String?
    private var currentPage = 1
    private let messagesPerPage = 50
    
    // Typing indicator management
    private var typingTimer: Timer?
    private var isTyping = false
    
    init() {
        setupErrorHandling()
        setupSocketHandlers()
    }
    
    private func setupErrorHandling() {
        networkManager.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    private func setupSocketHandlers() {
        // Listen for new messages
        socketManager.newMessagePublisher
            .sink { [weak self] message in
                self?.handleNewMessage(message)
            }
            .store(in: &cancellables)
        
        // Listen for message edits
        socketManager.messageEditedPublisher
            .sink { [weak self] message in
                self?.handleMessageEdited(message)
            }
            .store(in: &cancellables)
        
        // Listen for message deletions
        socketManager.messageDeletedPublisher
            .sink { [weak self] messageId in
                self?.handleMessageDeleted(messageId)
            }
            .store(in: &cancellables)
        
        // Listen for typing indicators
        socketManager.userTypingPublisher
            .sink { [weak self] (typingInfo: SocketUserTyping) in
                self?.handleUserTyping(typingInfo)
            }
            .store(in: &cancellables)
        
        // Listen for socket errors
        socketManager.errorPublisher
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Message Operations
    
    func loadMessages(for channelId: String, refresh: Bool = false) {
        guard currentChannelId != channelId || refresh else { return }
        
        if currentChannelId != channelId {
            currentChannelId = channelId
            currentPage = 1
            messages.removeAll()
            hasMoreMessages = true
        }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.getMessages(
            channelId: channelId,
            page: currentPage,
            limit: messagesPerPage
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.handleError(error)
                }
            },
            receiveValue: { [weak self] newMessages in
                if refresh {
                    self?.messages = newMessages
                } else {
                    self?.messages.insert(contentsOf: newMessages, at: 0)
                }
                
                self?.hasMoreMessages = newMessages.count == self?.messagesPerPage
                
                // Join channel for socket updates
                if let channelId = self?.currentChannelId {
                    self?.socketManager.joinChannel(channelId)
                }
            }
        )
        .store(in: &cancellables)
    }
    
    func loadMoreMessages() {
        guard let channelId = currentChannelId, hasMoreMessages, !isLoading else { return }
        
        currentPage += 1
        loadMessages(for: channelId)
    }
    
    func sendMessage(content: String, to channelId: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Message cannot be empty")
            return
        }
        
        isSending = true
        errorMessage = nil
        
        networkManager.sendMessage(content: content, channelId: channelId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isSending = false
                    
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] response in
                    // Message will be added via socket update
                    // But add it immediately for better UX
                    if let message = response.data {
                        self?.addMessageToList(message)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func editMessage(_ message: Message, newContent: String) {
        guard !newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Message cannot be empty")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.editMessage(id: message.id, content: newContent)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] response in
                    // Message will be updated via socket update
                    if let message = response.data {
                        self?.updateMessageInList(message)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteMessage(_ message: Message) {
        isLoading = true
        errorMessage = nil
        
        networkManager.deleteMessage(id: message.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] _ in
                    // Message will be removed via socket update
                    self?.removeMessageFromList(message.id)
                }
            )
            .store(in: &cancellables)
    }
    
    func addReaction(to message: Message, emoji: String) {
        networkManager.addReaction(messageId: message.id, emoji: emoji)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] response in
                    // Message will be updated via socket update
                    if let message = response.data {
                        self?.updateMessageInList(message)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Typing Indicators
    
    func startTyping(in channelId: String) {
        guard !isTyping else { return }
        
        isTyping = true
        socketManager.sendTypingIndicator(channelId: channelId, isTyping: true)
        
        // Stop typing after 3 seconds of inactivity
        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.stopTyping(in: channelId)
            }
        }
    }
    
    func stopTyping(in channelId: String) {
        guard isTyping else { return }
        
        isTyping = false
        typingTimer?.invalidate()
        typingTimer = nil
        
        socketManager.sendTypingIndicator(channelId: channelId, isTyping: false)
    }
    
    // MARK: - Socket Event Handlers
    
    private func handleNewMessage(_ message: Message) {
        // Only add if it's for the current channel
        guard message.channelId == currentChannelId else { return }
        
        addMessageToList(message)
    }
    
    private func handleMessageEdited(_ message: Message) {
        // Only update if it's for the current channel
        guard message.channelId == currentChannelId else { return }
        
        updateMessageInList(message)
    }
    
    private func handleMessageDeleted(_ messageId: String) {
        removeMessageFromList(messageId)
    }
    
    private func handleUserTyping(_ typingInfo: SocketUserTyping) {
        // Only handle if it's for the current channel
        guard typingInfo.channelId == currentChannelId else { return }
        
        if typingInfo.isTyping {
            if !typingUsers.contains(typingInfo.username) {
                typingUsers.append(typingInfo.username)
            }
        } else {
            typingUsers.removeAll { $0 == typingInfo.username }
        }
        
        // Auto-remove typing indicator after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.typingUsers.removeAll { $0 == typingInfo.username }
        }
    }
    
    // MARK: - Message List Management
    
    private func addMessageToList(_ message: Message) {
        // Avoid duplicates
        guard !messages.contains(where: { $0.id == message.id }) else { return }
        
        // Insert in chronological order
        if let index = messages.firstIndex(where: { $0.createdAt > message.createdAt }) {
            messages.insert(message, at: index)
        } else {
            messages.append(message)
        }
    }
    
    private func updateMessageInList(_ message: Message) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
        }
    }
    
    private func removeMessageFromList(_ messageId: String) {
        messages.removeAll { $0.id == messageId }
    }
    
    // MARK: - Helper Methods
    
    func canEditMessage(_ message: Message, userId: String) -> Bool {
        return message.senderId == userId
    }
    
    func canDeleteMessage(_ message: Message, userId: String) -> Bool {
        return message.senderId == userId
    }
    
    func groupMessagesByDate() -> [(Date, [Message])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: messages) { message in
            calendar.startOfDay(for: message.createdAt)
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                showError("You don't have permission to perform this action")
            case .serverError(let message):
                showError(message)
            case .notFound:
                showError("Message not found")
            default:
                showError(networkError.localizedDescription)
            }
        } else {
            showError("An unexpected error occurred: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        
        // Auto-dismiss error after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.showingError = false
            self.errorMessage = nil
        }
    }
    
    func dismissError() {
        showingError = false
        errorMessage = nil
    }
    
    // MARK: - Computed Properties
    
    var hasMessages: Bool {
        !messages.isEmpty
    }
    
    var messageCount: Int {
        messages.count
    }
    
    var typingIndicatorText: String {
        guard !typingUsers.isEmpty else { return "" }
        
        if typingUsers.count == 1 {
            return "\(typingUsers.first!) is typing..."
        } else if typingUsers.count == 2 {
            return "\(typingUsers.joined(separator: " and ")) are typing..."
        } else {
            return "Several people are typing..."
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        messages.removeAll()
        typingUsers.removeAll()
        currentChannelId = nil
        currentPage = 1
        hasMoreMessages = true
        
        // Leave current channel socket room
        if let channelId = currentChannelId {
            socketManager.leaveChannel(channelId)
        }
        
        typingTimer?.invalidate()
        typingTimer = nil
        
        cancellables.removeAll()
    }
} 