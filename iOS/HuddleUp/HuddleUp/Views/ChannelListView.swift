import SwiftUI

struct ChannelListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var teamViewModel = TeamViewModel()
    @StateObject private var channelViewModel = ChannelViewModel()
    @State private var showingCreateChannel = false
    @State private var selectedChannel: Channel?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with team info
                if let selectedTeam = teamViewModel.selectedTeam {
                    teamHeader(selectedTeam)
                } else {
                    noTeamHeader
                }
                
                Divider()
                
                // Search bar
                searchBar
                
                // Channel content
                if channelViewModel.isLoading && channelViewModel.channels.isEmpty {
                    loadingView
                } else if channelViewModel.hasChannels {
                    channelsList
                } else {
                    emptyChannelsState
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                if let teamId = teamViewModel.selectedTeam?.id {
                    channelViewModel.loadChannels(for: teamId, forceRefresh: true)
                }
                teamViewModel.refreshCurrentTeam()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingCreateChannel) {
            CreateChannelView(
                teamId: nil,  // 从Channels页面创建时允许选择任意团队
                channelViewModel: channelViewModel,
                teamViewModel: teamViewModel
            )
        }
        .sheet(item: $selectedChannel) { channel in
            ChatView(channel: channel)
        }
        .onAppear {
            if let teamId = teamViewModel.selectedTeam?.id {
                channelViewModel.loadChannels(for: teamId)
            }
        }
        .onChange(of: teamViewModel.selectedTeam) { _, newTeam in
            if let teamId = newTeam?.id {
                channelViewModel.loadChannels(for: teamId)
            } else {
                channelViewModel.cleanup()
            }
        }
        .alert("Error", isPresented: $channelViewModel.showingError) {
            Button("OK") {
                channelViewModel.dismissError()
            }
        } message: {
            Text(channelViewModel.errorMessage ?? "An error occurred")
        }
    }
    
    private func teamHeader(_ team: Team) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(team.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(team.memberCount) members • \(channelViewModel.channelCount) channels")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingCreateChannel = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
    
    private var noTeamHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No Team Selected")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Go to Teams tab to select or join a team")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search channels", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading channels...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyChannelsState: some View {
        VStack(spacing: 30) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("No Channels Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Create your first channel to start communicating")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if teamViewModel.selectedTeam != nil {
                Button(action: {
                    showingCreateChannel = true
                }) {
                    Label("Create Channel", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var channelsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                let filteredChannels = searchText.isEmpty ? channelViewModel.channels : channelViewModel.filterChannels(by: searchText)
                
                // Public Channels Section
                let publicChannels = filteredChannels.filter { !$0.isPrivate }
                if !publicChannels.isEmpty {
                    ChannelSectionView(
                        title: "Channels",
                        channels: publicChannels,
                        onChannelTap: { channel in
                            selectedChannel = channel
                            channelViewModel.selectChannel(channel)
                        }
                    )
                }
                
                // Private Channels Section
                let privateChannels = filteredChannels.filter { $0.isPrivate }
                if !privateChannels.isEmpty {
                    ChannelSectionView(
                        title: "Private Channels",
                        channels: privateChannels,
                        onChannelTap: { channel in
                            selectedChannel = channel
                            channelViewModel.selectChannel(channel)
                        }
                    )
                }
                
                // Create Channel Button
                if teamViewModel.selectedTeam != nil {
                    VStack(spacing: 12) {
                        Button(action: {
                            showingCreateChannel = true
                        }) {
                            Label("Create Channel", systemImage: "plus.circle")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
            .padding(.bottom, 20)
        }
    }
}

struct ChannelSectionView: View {
    let title: String
    let channels: [Channel]
    let onChannelTap: (Channel) -> Void
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(title.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(channels.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Channels List
            if isExpanded {
                ForEach(channels) { channel in
                    ChannelRowView(
                        channel: channel,
                        onTap: {
                            onChannelTap(channel)
                        }
                    )
                }
            }
        }
    }
}

struct ChannelRowView: View {
    let channel: Channel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Channel Icon
                Image(systemName: channel.isPrivate ? "lock.fill" : "number")
                    .font(.system(size: 16))
                    .foregroundColor(channel.isPrivate ? .orange : .gray)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let description = channel.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Member count
                if channel.memberCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("\(channel.memberCount)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Unread indicator (placeholder)
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .opacity(0) // Hidden for now, can be shown when there are unread messages
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
        )
    }
}

#Preview {
    ChannelListView()
        .environmentObject(AuthViewModel())
} 