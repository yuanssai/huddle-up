import SwiftUI

struct TeamDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let team: Team
    @ObservedObject var teamViewModel: TeamViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showingInviteCode = false
    @State private var showingLeaveConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            Text(team.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            if let description = team.description, !description.isEmpty {
                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Stats
                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            Text("\(team.memberCount)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Members")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(team.channels?.count ?? 0)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Channels")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text(team.createdAt.timeAgoShort)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Created")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Members Section
                    if let members = team.members, !members.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Members")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(Array(members.prefix(5)), id: \.id) { member in
                                    HStack {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text(String(member.firstName.prefix(1)))
                                                    .font(.title2)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.white)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(member.displayName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            HStack {
                                                Text("@\(member.username)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                
                                                if member.TeamMember.role == .admin {
                                                    Text("• Admin")
                                                        .font(.caption)
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                
                                if members.count > 5 {
                                    Text("and \(members.count - 5) more...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        if isUserAdmin {
                            Button(action: {
                                showingInviteCode = true
                            }) {
                                Label("Show Invite Code", systemImage: "qrcode")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                        
                        if canLeaveTeam {
                            Button(action: {
                                showingLeaveConfirmation = true
                            }) {
                                Label("Leave Team", systemImage: "rectangle.portrait.and.arrow.right")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingInviteCode) {
            InviteCodeView(team: team)
        }
        .alert("Leave Team", isPresented: $showingLeaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                teamViewModel.leaveTeam(team)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to leave \(team.name)? You'll need a new invite to rejoin.")
        }
    }
    
    private var isUserAdmin: Bool {
        guard let userId = authViewModel.currentUser?.id else { return false }
        return teamViewModel.isUserAdmin(in: team, userId: userId)
    }
    
    private var canLeaveTeam: Bool {
        guard let userId = authViewModel.currentUser?.id else { return false }
        return teamViewModel.canLeaveTeam(team, userId: userId)
    }
}

struct InviteCodeView: View {
    @Environment(\.dismiss) private var dismiss
    let team: Team
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Invite Code")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Share this code with team members")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Invite Code Display
                VStack(spacing: 16) {
                    Text(team.inviteCode ?? "No invite code")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .textSelection(.enabled)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            if let inviteCode = team.inviteCode {
                                UIPasteboard.general.string = inviteCode
                            }
                        }) {
                            Label("Copy", systemImage: "doc.on.clipboard")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            shareInviteCode()
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func shareInviteCode() {
        guard let inviteCode = team.inviteCode else { return }
        
        let shareText = "Join our team '\(team.name)' on Huddle Up!\n\nInvite Code: \(inviteCode)"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// Helper extension for date formatting
extension Date {
    var timeAgoShort: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

struct TeamDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTeam = Team(
            id: "1",
            name: "Sample Team",
            description: "This is a sample team for preview",
            ownerId: "user1",
            inviteCode: "ABC-123-DEF",
            isPublic: false,
            createdAt: Date(),
            updatedAt: Date(),
            members: [],
            channels: []
        )
        
        TeamDetailView(team: sampleTeam, teamViewModel: TeamViewModel())
            .environmentObject(AuthViewModel())
    }
} 