import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingLogoutConfirmation = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        if let user = authViewModel.currentUser {
                            UserAvatarView(user: user, size: 100)
                            
                            VStack(spacing: 8) {
                                Text(user.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("@\(user.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(user.email ?? "No email")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Online Status
                            HStack {
                                Circle()
                                    .fill((user.isOnline ?? false) ? Color.green : Color.gray)
                                    .frame(width: 8, height: 8)
                                
                                Text((user.isOnline ?? false) ? "Online" : "Offline")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 100, height: 100)
                            
                            Text("Unknown User")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Profile Info Cards
                    VStack(spacing: 16) {
                        if let user = authViewModel.currentUser {
                            ProfileInfoCard(
                                title: "Account Information",
                                items: [
                                    ("First Name", user.firstName),
                                    ("Last Name", user.lastName),
                                    ("Username", user.username),
                                    ("Email", user.email ?? "No email")
                                ]
                            )
                            
                            if let lastSeen = user.lastSeen {
                                ProfileInfoCard(
                                    title: "Activity",
                                    items: [
                                        ("Last Seen", lastSeen.formatted(date: .abbreviated, time: .shortened)),
                                        ("Status", (user.isOnline ?? false) ? "Online" : "Offline")
                                    ]
                                )
                            }
                        }
                    }
                    
                    // Actions - 这些按钮必须能够被访问到
                    VStack(spacing: 12) {
                        Button(action: {
                            // Future: Edit profile functionality
                        }) {
                            Label("Edit Profile", systemImage: "pencil")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .disabled(true) // Disabled for now
                        
                        Button(action: {
                            showingLogoutConfirmation = true
                        }) {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 20)
                    
                    // App Info
                    VStack(spacing: 8) {
                        Text("Huddle Up")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text("Version 1.0.0")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Additional content to demonstrate scrolling
                    VStack(spacing: 16) {
                        Text("Scroll Test")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 8) {
                            Text("If you can see this section, scrolling is working correctly.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            // Add numbered items to test scrolling
                            ForEach(1...5, id: \.self) { index in
                                Text("Scroll test item \(index)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(16)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                    }
                    .padding(.top, 20)
                    
                    // Bottom spacer to ensure all content is accessible
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, 20)
                .frame(minHeight: geometry.size.height)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .alert("Sign Out", isPresented: $showingLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authViewModel.logout()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

struct ProfileInfoCard: View {
    let title: String
    let items: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(items, id: \.0) { item in
                    HStack {
                        Text(item.0)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(item.1)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
} 