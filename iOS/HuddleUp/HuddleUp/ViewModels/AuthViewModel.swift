import Foundation
import Combine
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    private let networkManager = NetworkManager.shared
    private let socketManager = SocketManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkAuthenticationStatus()
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
    
    private func checkAuthenticationStatus() {
        guard networkManager.hasAuthToken else {
            isAuthenticated = false
            return
        }
        
        getCurrentUser()
    }
    
    func login(email: String, password: String) {
        print("🔑 [AuthViewModel] Starting login for email: \(email)")
        
        guard !email.isEmpty && !password.isEmpty else {
            print("❌ [AuthViewModel] Empty email or password")
            showError("Please enter both email and password")
            return
        }
        
        guard isValidEmail(email) else {
            print("❌ [AuthViewModel] Invalid email format")
            showError("Please enter a valid email address")
            return
        }
        
        print("🔄 [AuthViewModel] Validation passed, starting network request")
        isLoading = true
        errorMessage = nil
        
        networkManager.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    print("🔑 [AuthViewModel] Login completion received")
                    self?.isLoading = false
                    
                    switch completion {
                    case .finished:
                        print("✅ [AuthViewModel] Login completed successfully")
                        break
                    case .failure(let error):
                        print("❌ [AuthViewModel] Login failed: \(error)")
                        self?.handleAuthError(error)
                    }
                },
                receiveValue: { [weak self] response in
                    print("✅ [AuthViewModel] Login successful for user: \(response.user.email ?? "unknown")")
                    self?.currentUser = response.user
                    self?.isAuthenticated = true
                    self?.connectSocket(token: response.token)
                    
                    // Store user info locally
                    self?.saveUserInfo(response.user)
                    
                    // Refresh user data after a short delay to get updated online status
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self?.refreshUserData()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func register(
        email: String,
        username: String,
        password: String,
        firstName: String,
        lastName: String
    ) {
        guard !email.isEmpty && !username.isEmpty && !password.isEmpty else {
            showError("Please fill in all required fields")
            return
        }
        
        guard isValidEmail(email) else {
            showError("Please enter a valid email address")
            return
        }
        
        guard isValidUsername(username) else {
            showError("Username must be 3-30 characters and contain only letters, numbers, and underscores")
            return
        }
        
        guard isValidPassword(password) else {
            showError("Password must be at least 6 characters long")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.register(
            email: email,
            username: username,
            password: password,
            firstName: firstName,
            lastName: lastName
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.handleAuthError(error)
                }
            },
            receiveValue: { [weak self] response in
                self?.currentUser = response.user
                self?.isAuthenticated = true
                self?.connectSocket(token: response.token)
                
                // Store user info locally
                self?.saveUserInfo(response.user)
                
                // Refresh user data after a short delay to get updated online status
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self?.refreshUserData()
                }
            }
        )
        .store(in: &cancellables)
    }
    
    func logout() {
        isLoading = true
        
        networkManager.logout()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    self?.performLogout()
                },
                receiveValue: { [weak self] _ in
                    self?.performLogout()
                }
            )
            .store(in: &cancellables)
    }
    
    private func performLogout() {
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
        
        // Disconnect socket
        socketManager.disconnect()
        
        // Clear stored data
        clearUserInfo()
        networkManager.clearAuthToken()
    }
    
    private func getCurrentUser() {
        networkManager.getCurrentUser()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure:
                        // Token might be invalid, logout
                        self?.performLogout()
                    }
                },
                receiveValue: { [weak self] user in
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    
                    // Connect socket with stored token
                    if let token = UserDefaults.standard.string(forKey: "auth_token") {
                        self?.connectSocket(token: token)
                    }
                    
                    // Refresh user data after a short delay to get updated online status
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self?.refreshUserData()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func connectSocket(token: String) {
        socketManager.connect(token: token)
        
        // Listen for socket connection status
        socketManager.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    // When socket connects successfully, refresh user data to get updated online status
                    self?.refreshUserData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func refreshUserData() {
        networkManager.getCurrentUser()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] user in
                    self?.currentUser = user
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleAuthError(_ error: Error) {
        print("🚨 [AuthViewModel] Handling auth error: \(error)")
        print("🚨 [AuthViewModel] Error type: \(type(of: error))")
        
        if let networkError = error as? NetworkError {
            print("🚨 [AuthViewModel] Network error: \(networkError)")
            switch networkError {
            case .unauthorized:
                showError("Invalid credentials. Please try again.")
            case .serverError(let message):
                showError(message)
            default:
                showError(networkError.localizedDescription)
            }
        } else if let urlError = error as? URLError {
            print("🚨 [AuthViewModel] URL error: \(urlError)")
            print("🚨 [AuthViewModel] URL error code: \(urlError.code)")
            print("🚨 [AuthViewModel] URL error description: \(urlError.localizedDescription)")
            handleNetworkError(error)
        } else {
            print("🚨 [AuthViewModel] Unknown error: \(error.localizedDescription)")
            showError("An unexpected error occurred. Please try again.")
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
    
    // MARK: - Validation
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidUsername(_ username: String) -> Bool {
        let usernameRegex = "^[a-zA-Z0-9_]{3,30}$"
        let usernamePredicate = NSPredicate(format:"SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    // MARK: - Local Storage
    private func saveUserInfo(_ user: User) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(user) {
            UserDefaults.standard.set(encoded, forKey: "current_user")
        }
    }
    
    private func clearUserInfo() {
        UserDefaults.standard.removeObject(forKey: "current_user")
    }
    
    // MARK: - Helper Methods
    var displayName: String {
        currentUser?.displayName ?? "Unknown User"
    }
    
    var userInitials: String {
        currentUser?.initials ?? "?"
    }
    
    var isOnline: Bool {
        currentUser?.isOnline ?? false
    }
}

// MARK: - Error Handling Extension
extension AuthViewModel {
    func handleNetworkError(_ error: Error) {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                showError("No internet connection. Please check your network.")
            case .timedOut:
                showError("Request timed out. Please try again.")
            case .cannotFindHost:
                showError("Cannot connect to server. Please try again later.")
            default:
                showError("Network error: \(urlError.localizedDescription)")
            }
        } else {
            showError("An unexpected error occurred: \(error.localizedDescription)")
        }
    }
} 