import SwiftUI

struct TeamChannelsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    let team: Team
    
    @StateObject private var channelViewModel = ChannelViewModel()
    @State private var showingCreateChannel = false
    @State private var selectedChannel: Channel?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Team header
                teamHeader
                
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
            .navigationTitle("\(team.name) Channels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateChannel = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateChannel) {
            CreateChannelView(
                teamId: team.id,
                channelViewModel: channelViewModel,
                teamViewModel: TeamViewModel()
            )
        }
        .sheet(item: $selectedChannel) { channel in
            ChatView(channel: channel)
        }
        .onAppear {
            channelViewModel.loadChannels(for: team.id)
        }
        .alert("Error", isPresented: $channelViewModel.showingError) {
            Button("OK") {
                channelViewModel.dismissError()
            }
        } message: {
            Text(channelViewModel.errorMessage ?? "An error occurred")
        }
    }
    
    private var teamHeader: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(team.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let description = team.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Text("\(team.memberCount) members • \(channelViewModel.channelCount) channels")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "person.3.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
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
                
                Text("Create your first channel to start communicating with \(team.name)")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var channelsList: some View {
        ScrollView(.vertical, showsIndicators: false) {
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
            .padding(.bottom, 20)
        }
        .refreshable {
            channelViewModel.loadChannels(for: team.id, forceRefresh: true)
        }
    }
}

struct TeamChannelsView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTeam = Team(
            id: "1",
            name: "Sample Team",
            description: "A sample team for preview",
            ownerId: "user1",
            inviteCode: "invite123",
            isPublic: false,
            createdAt: Date(),
            updatedAt: Date(),
            members: nil,
            channels: nil
        )
        
        TeamChannelsView(team: sampleTeam)
            .environmentObject(AuthViewModel())
    }
} 