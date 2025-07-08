import Foundation
import Combine

@MainActor
class TeamViewModel: ObservableObject {
    @Published var teams: [Team] = []
    @Published var selectedTeam: Team?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    @Published var showingCreateTeam = false
    @Published var showingJoinTeam = false
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupErrorHandling()
        loadTeams()
        setupAutoRefresh()
    }
    
    private func setupErrorHandling() {
        networkManager.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    private func setupAutoRefresh() {
        // Auto-refresh teams every 30 seconds to get updated member/channel counts
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshTeamsInBackground()
            }
            .store(in: &cancellables)
        
        // Listen for channel count changes
        NotificationCenter.default.publisher(for: .channelCountChanged)
            .sink { [weak self] _ in
                self?.refreshCurrentTeam()
            }
            .store(in: &cancellables)
        
        // Listen for team member count changes
        NotificationCenter.default.publisher(for: .teamMemberCountChanged)
            .sink { [weak self] _ in
                self?.refreshCurrentTeam()
            }
            .store(in: &cancellables)
    }
    
    private func refreshTeamsInBackground() {
        // Refresh without showing loading indicator
        networkManager.getTeams()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] teams in
                    self?.teams = teams
                    
                    // Update selected team if it still exists
                    if let selectedTeamId = self?.selectedTeam?.id,
                       let updatedTeam = teams.first(where: { $0.id == selectedTeamId }) {
                        self?.selectedTeam = updatedTeam
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Team Operations
    
    func loadTeams(forceRefresh: Bool = false) {
        isLoading = true
        errorMessage = nil
        
        networkManager.getTeams()
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
                receiveValue: { [weak self] teams in
                    self?.teams = teams
                    
                    // Select first team if none selected
                    if self?.selectedTeam == nil && !teams.isEmpty {
                        self?.selectedTeam = teams.first
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func createTeam(name: String, description: String) {
        guard !name.isEmpty else {
            showError("Team name cannot be empty")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.createTeam(name: name, description: description)
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
                    if let team = response.data {
                        self?.teams.append(team)
                        self?.selectedTeam = team
                    }
                    self?.showingCreateTeam = false
                    // Reload teams to get the complete data
                    self?.loadTeams(forceRefresh: true)
                }
            )
            .store(in: &cancellables)
    }
    
    func joinTeam(inviteCode: String) {
        guard !inviteCode.isEmpty else {
            showError("Invite code cannot be empty")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.joinTeam(inviteCode: inviteCode)
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
                    if let team = response.data {
                        // Check if team already exists in list
                        if let existingIndex = self?.teams.firstIndex(where: { $0.id == team.id }) {
                            self?.teams[existingIndex] = team
                        } else {
                            self?.teams.append(team)
                        }
                        self?.selectedTeam = team
                    }
                    self?.showingJoinTeam = false
                    // Reload teams to get the complete data
                    self?.loadTeams(forceRefresh: true)
                    // Notify that team member count changed
                    NotificationCenter.default.post(name: .teamMemberCountChanged, object: nil)
                }
            )
            .store(in: &cancellables)
    }
    
    func leaveTeam(_ team: Team) {
        isLoading = true
        errorMessage = nil
        
        networkManager.leaveTeam(id: team.id)
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
                    self?.teams.removeAll { $0.id == team.id }
                    
                    // Select another team if the current one was removed
                    if self?.selectedTeam?.id == team.id {
                        self?.selectedTeam = self?.teams.first
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func generateInviteCode(for team: Team) {
        isLoading = true
        errorMessage = nil
        
        networkManager.generateInviteCode(teamId: team.id)
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
                    // Update the team with new invite code
                    if let index = self?.teams.firstIndex(where: { $0.id == team.id }) {
                        let updatedTeam = team
                        // Note: This assumes the response includes the new invite code
                        // You might need to adjust based on your API response structure
                        self?.teams[index] = updatedTeam
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshTeam(_ team: Team) {
        networkManager.getTeam(id: team.id)
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
                receiveValue: { [weak self] updatedTeam in
                    if let index = self?.teams.firstIndex(where: { $0.id == team.id }) {
                        self?.teams[index] = updatedTeam
                        
                        // Update selected team if it's the same
                        if self?.selectedTeam?.id == team.id {
                            self?.selectedTeam = updatedTeam
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshCurrentTeam() {
        guard let selectedTeam = selectedTeam else { return }
        refreshTeam(selectedTeam)
    }
    
    // MARK: - Helper Methods
    
    func selectTeam(_ team: Team) {
        selectedTeam = team
    }
    
    func isUserAdmin(in team: Team, userId: String) -> Bool {
        return team.ownerId == userId || 
               team.members?.first(where: { $0.id == userId })?.TeamMember.role == .admin
    }
    
    func canLeaveTeam(_ team: Team, userId: String) -> Bool {
        // User can leave team if they're not the owner or if there are other admins
        return team.ownerId != userId
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
                showError("Team not found")
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
    
    var hasTeams: Bool {
        !teams.isEmpty
    }
    
    var selectedTeamMemberCount: Int {
        selectedTeam?.memberCount ?? 0
    }
    
    var selectedTeamChannelCount: Int {
        selectedTeam?.channels?.count ?? 0
    }
    
    // MARK: - UI State
    
    func showCreateTeamDialog() {
        showingCreateTeam = true
    }
    
    func showJoinTeamDialog() {
        showingJoinTeam = true
    }
    
    func hideCreateTeamDialog() {
        showingCreateTeam = false
    }
    
    func hideJoinTeamDialog() {
        showingJoinTeam = false
    }
} 