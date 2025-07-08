import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                AuthenticationView()
                    .environmentObject(authViewModel)
            }
        }
        .alert("Error", isPresented: $authViewModel.showingError) {
            Button("OK") {
                authViewModel.dismissError()
            }
        } message: {
            Text(authViewModel.errorMessage ?? "An error occurred")
        }
    }
}

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingRegister = false
    
    var body: some View {
        NavigationView {
            VStack {
                if showingRegister {
                    RegisterView(showingRegister: $showingRegister)
                } else {
                    LoginView(showingRegister: $showingRegister)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            TeamListView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Teams")
                }
            
            ChannelListView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Channels")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
} 