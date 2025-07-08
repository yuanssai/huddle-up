import Foundation
import Combine

extension Notification.Name {
    static let channelCountChanged = Notification.Name("channelCountChanged")
    static let teamMemberCountChanged = Notification.Name("teamMemberCountChanged")
}

@MainActor
class ChannelViewModel: ObservableObject {
    @Published var channels: [Channel] = []
    @Published var selectedChannel: Channel?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    @Published var showingCreateChannel = false
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Current team ID to load channels for
    private var currentTeamId: String?
    
    init() {
        setupErrorHandling()
    }
    
    private func setupErrorHandling() {
        networkManager.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Channel Operations
    
    func loadChannels(for teamId: String, forceRefresh: Bool = false) {
        guard currentTeamId != teamId || forceRefresh else { return }
        
        currentTeamId = teamId
        isLoading = true
        errorMessage = nil
        
        networkManager.getChannels(teamId: teamId)
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
                receiveValue: { [weak self] channels in
                    self?.channels = channels
                    
                    // Select first channel if none selected
                    if self?.selectedChannel == nil && !channels.isEmpty {
                        self?.selectedChannel = channels.first
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func createChannel(name: String, description: String, teamId: String, isPrivate: Bool = false) {
        guard !name.isEmpty else {
            showError("Channel name cannot be empty")
            return
        }
        
        guard !teamId.isEmpty else {
            showError("Team ID is required")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.createChannel(
            name: name,
            description: description,
            teamId: teamId,
            isPrivate: isPrivate
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
                            receiveValue: { [weak self] response in
                    if let channel = response.data {
                        self?.channels.append(channel)
                        self?.selectedChannel = channel
                    }
                    self?.showingCreateChannel = false
                    // Reload channels to get the complete data
                    if let teamId = self?.currentTeamId {
                        self?.loadChannels(for: teamId, forceRefresh: true)
                    }
                    // Notify that channel count changed
                    NotificationCenter.default.post(name: .channelCountChanged, object: nil)
                }
        )
        .store(in: &cancellables)
    }
    
    func joinChannel(_ channel: Channel) {
        isLoading = true
        errorMessage = nil
        
        networkManager.joinChannel(id: channel.id)
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
                    // Update channel with new member info
                    if let index = self?.channels.firstIndex(where: { $0.id == channel.id }) {
                        if let channel = response.data {
                            self?.channels[index] = channel
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func leaveChannel(_ channel: Channel) {
        isLoading = true
        errorMessage = nil
        
        networkManager.leaveChannel(id: channel.id)
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
                    // Remove channel from list if it's private and user left
                    if channel.isPrivate {
                        self?.channels.removeAll { $0.id == channel.id }
                        
                        // Select another channel if the current one was removed
                        if self?.selectedChannel?.id == channel.id {
                            self?.selectedChannel = self?.channels.first
                        }
                    } else {
                        // Update channel member list
                        if self?.channels.firstIndex(where: { $0.id == channel.id }) != nil {
                            // Note: You might want to refresh the channel data here
                            self?.refreshChannel(channel)
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshChannel(_ channel: Channel) {
        networkManager.getChannel(id: channel.id)
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
                receiveValue: { [weak self] updatedChannel in
                    if let index = self?.channels.firstIndex(where: { $0.id == channel.id }) {
                        self?.channels[index] = updatedChannel
                        
                        // Update selected channel if it's the same
                        if self?.selectedChannel?.id == channel.id {
                            self?.selectedChannel = updatedChannel
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshChannels() {
        guard let teamId = currentTeamId else { return }
        
        networkManager.getChannels(teamId: teamId)
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
                receiveValue: { [weak self] channels in
                    self?.channels = channels
                    
                    // Update selected channel if it still exists
                    if let selectedChannelId = self?.selectedChannel?.id,
                       let updatedChannel = channels.first(where: { $0.id == selectedChannelId }) {
                        self?.selectedChannel = updatedChannel
                    } else if self?.selectedChannel != nil && !channels.isEmpty {
                        self?.selectedChannel = channels.first
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    
    func selectChannel(_ channel: Channel) {
        selectedChannel = channel
    }
    
    func isUserMember(of channel: Channel, userId: String) -> Bool {
        return channel.members?.contains(where: { $0.id == userId }) ?? false
    }
    
    func canJoinChannel(_ channel: Channel, userId: String) -> Bool {
        // User can join if it's a public channel and they're not already a member
        return !channel.isPrivate && !isUserMember(of: channel, userId: userId)
    }
    
    func canLeaveChannel(_ channel: Channel, userId: String) -> Bool {
        // User can leave if they're a member and it's not a general channel
        return isUserMember(of: channel, userId: userId) && 
               channel.name.lowercased() != "#general"
    }
    
    // MARK: - Channel Types
    
    var publicChannels: [Channel] {
        channels.filter { !$0.isPrivate }
    }
    
    var privateChannels: [Channel] {
        channels.filter { $0.isPrivate }
    }
    
    var joinedChannels: [Channel] {
        // This would need user ID from auth context
        // For now, return all channels
        return channels
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
                showError("Channel not found")
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
    
    var hasChannels: Bool {
        !channels.isEmpty
    }
    
    var selectedChannelMemberCount: Int {
        selectedChannel?.memberCount ?? 0
    }
    
    var channelCount: Int {
        channels.count
    }
    
    var publicChannelCount: Int {
        publicChannels.count
    }
    
    var privateChannelCount: Int {
        privateChannels.count
    }
    
    // MARK: - UI State
    
    func showCreateChannelDialog() {
        showingCreateChannel = true
    }
    
    func hideCreateChannelDialog() {
        showingCreateChannel = false
    }
    
    // MARK: - Channel Filtering
    
    func filterChannels(by searchText: String) -> [Channel] {
        guard !searchText.isEmpty else { return channels }
        
        return channels.filter { channel in
            channel.name.localizedCaseInsensitiveContains(searchText) ||
            channel.description?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        channels.removeAll()
        selectedChannel = nil
        currentTeamId = nil
        cancellables.removeAll()
    }
} 