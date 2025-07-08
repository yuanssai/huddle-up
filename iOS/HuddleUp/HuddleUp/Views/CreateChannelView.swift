import SwiftUI

struct CreateChannelView: View {
    @Environment(\.dismiss) private var dismiss
    let teamId: String?  // 可选的预选团队ID
    @ObservedObject var channelViewModel: ChannelViewModel
    @ObservedObject var teamViewModel: TeamViewModel
    
    @State private var selectedTeamId: String = ""
    @State private var channelName = ""
    @State private var channelDescription = ""
    @State private var isPrivate = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, description
    }
    
    var selectedTeam: Team? {
        teamViewModel.teams.first { $0.id == selectedTeamId }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Create Channel")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Channels are where your team communicates")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        // Team Selection (only show if no teamId provided)
                        if teamId == nil {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Select Team")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Menu {
                                    ForEach(teamViewModel.teams) { team in
                                        Button(action: {
                                            selectedTeamId = team.id
                                        }) {
                                            HStack {
                                                Text(team.name)
                                                if selectedTeamId == team.id {
                                                    Spacer()
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        if let team = selectedTeam {
                                            Text(team.name)
                                                .foregroundColor(.primary)
                                        } else {
                                            Text("Choose a team...")
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        } else {
                            // Show selected team info when teamId is provided
                            if let team = teamViewModel.teams.first(where: { $0.id == teamId }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Creating channel for")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        Text(team.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                        
                                        Spacer()
                                        
                                        Text("\(team.members?.count ?? 0) members")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Channel Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Channel Name")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text("#")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextField("e.g. marketing", text: $channelName)
                                    .focused($focusedField, equals: .name)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(focusedField == .name ? Color.blue : Color.clear, lineWidth: 2)
                            )
                            
                            if !channelName.isEmpty && !isValidChannelName {
                                Text("Channel names must be lowercase, without spaces or periods, and can't be longer than 21 characters")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Channel Description Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (Optional)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            TextField("What's this channel about?", text: $channelDescription, axis: .vertical)
                                .focused($focusedField, equals: .description)
                                .lineLimit(3...6)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(focusedField == .description ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        }
                        
                        // Privacy Toggle
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $isPrivate) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: isPrivate ? "lock.fill" : "number")
                                            .foregroundColor(isPrivate ? .orange : .gray)
                                        
                                        Text("Make private")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Text(isPrivate ? "Only specific people can access this channel" : "Anyone in the team can join this channel")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                        }
                        .padding(.top, 8)
                    }
                    
                    // Create Button
                    Button(action: createChannel) {
                        HStack {
                            if channelViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text("Create Channel")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isFormValid ? Color.blue : Color.gray)
                        )
                    }
                    .disabled(!isFormValid || channelViewModel.isLoading)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Set initial team selection
            if let teamId = teamId {
                selectedTeamId = teamId
            } else if let firstTeam = teamViewModel.teams.first {
                selectedTeamId = firstTeam.id
            }
            
            focusedField = .name
        }
        .onSubmit {
            if focusedField == .name {
                focusedField = .description
            } else if isFormValid {
                createChannel()
            }
        }
        .onChange(of: channelName) { _, newValue in
            // Auto-format channel name
            channelName = formatChannelName(newValue)
        }
    }
    
    private var isFormValid: Bool {
        let hasValidName = !channelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isValidChannelName
        let hasSelectedTeam = !selectedTeamId.isEmpty
        return hasValidName && hasSelectedTeam
    }
    
    private var isValidChannelName: Bool {
        let trimmedName = channelName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.count <= 21 && 
               trimmedName.range(of: "^[a-z0-9\\-_]+$", options: .regularExpression) != nil
    }
    
    private func formatChannelName(_ input: String) -> String {
        return input
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: ".", with: "")
            .prefix(21)
            .description
    }
    
    private func createChannel() {
        let trimmedName = channelName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = channelDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        channelViewModel.createChannel(
            name: trimmedName,
            description: trimmedDescription.isEmpty ? "" : trimmedDescription,
            teamId: selectedTeamId,
            isPrivate: isPrivate
        )
        
        // The view will be dismissed by the ChannelViewModel when successful
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !channelViewModel.showingError {
                dismiss()
            }
        }
    }
}

struct CreateChannelView_Previews: PreviewProvider {
    static var previews: some View {
        CreateChannelView(
            teamId: nil,
            channelViewModel: ChannelViewModel(),
            teamViewModel: TeamViewModel()
        )
    }
} 