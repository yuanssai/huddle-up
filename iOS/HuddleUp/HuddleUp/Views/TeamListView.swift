import SwiftUI

struct TeamListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var teamViewModel = TeamViewModel()
    @State private var showingCreateTeam = false
    @State private var showingJoinTeam = false
    @State private var selectedTeam: Team?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                header
                
                // Content
                if teamViewModel.isLoading && teamViewModel.teams.isEmpty {
                    loadingView
                } else if teamViewModel.hasTeams {
                    teamsList
                } else {
                    emptyState
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                teamViewModel.loadTeams(forceRefresh: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: .teamMemberCountChanged)) { _ in
                teamViewModel.refreshCurrentTeam()
            }
        }
        .sheet(isPresented: $showingCreateTeam) {
            CreateTeamView(teamViewModel: teamViewModel)
        }
        .sheet(isPresented: $showingJoinTeam) {
            JoinTeamView(teamViewModel: teamViewModel)
        }
        .sheet(item: $selectedTeam) { team in
            TeamDetailView(team: team, teamViewModel: teamViewModel)
        }
        .alert("Error", isPresented: $teamViewModel.showingError) {
            Button("OK") {
                teamViewModel.dismissError()
            }
        } message: {
            Text(teamViewModel.errorMessage ?? "An error occurred")
        }
    }
    
    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Teams")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Select or create a team")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // User avatar
                Button(action: {
                    // Profile action could be handled here
                }) {
                    if let user = authViewModel.currentUser {
                        UserAvatarView(user: user, size: 36)
                    } else {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 36, height: 36)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading teams...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyState: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("No Teams Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Create your first team or join an existing one to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 12) {
                Button(action: {
                    showingCreateTeam = true
                }) {
                    Label("Create Team", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    showingJoinTeam = true
                }) {
                    Label("Join Team", systemImage: "person.badge.plus")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var teamsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(teamViewModel.teams) { team in
                    TeamCardView(
                        team: team,
                        isSelected: teamViewModel.selectedTeam?.id == team.id,
                        onTap: {
                            teamViewModel.selectTeam(team)
                        },
                        onDetailTap: {
                            selectedTeam = team
                        }
                    )
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showingCreateTeam = true
                    }) {
                        Label("Create New Team", systemImage: "plus.circle")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showingJoinTeam = true
                    }) {
                        Label("Join Team", systemImage: "person.badge.plus")
                            .font(.headline)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }
}

struct TeamCardView: View {
    let team: Team
    let isSelected: Bool
    let onTap: () -> Void
    let onDetailTap: () -> Void
    
    @State private var showingChannels = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(team.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let description = team.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Button(action: onDetailTap) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            HStack {
                Label("\(team.memberCount)", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let channelCount = team.channels?.count {
                    Label("\(channelCount)", systemImage: "bubble.left.and.bubble.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Navigate to channels button
                Button(action: {
                    showingChannels = true
                }) {
                    HStack(spacing: 4) {
                        Text("View Channels")
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(16)
        .sheet(isPresented: $showingChannels) {
            TeamChannelsView(team: team)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
        .onTapGesture {
            onTap()
        }
    }
}

struct UserAvatarView: View {
    let user: User
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue)
                .frame(width: size, height: size)
            
            Text(user.initials)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(.white)
        }
        .overlay(
            Circle()
                .stroke((user.isOnline ?? false) ? Color.green : Color.gray, lineWidth: 2)
        )
    }
}

#Preview {
    TeamListView()
        .environmentObject(AuthViewModel())
} 