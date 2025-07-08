import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    let channel: Channel
    
    @StateObject private var messageViewModel = MessageViewModel()
    @State private var messageText = ""
    @State private var showingChannelInfo = false
    @FocusState private var isMessageFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat Messages
                messagesView
                
                // Typing Indicator
                if !messageViewModel.typingUsers.isEmpty {
                    typingIndicator
                }
                
                // Message Input
                messageInputView
            }
            .navigationTitle(channel.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingChannelInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
        .onAppear {
            messageViewModel.loadMessages(for: channel.id)
        }
        .onDisappear {
            messageViewModel.cleanup()
        }
        .sheet(isPresented: $showingChannelInfo) {
            ChannelInfoView(channel: channel)
        }
        .alert("Error", isPresented: $messageViewModel.showingError) {
            Button("OK") {
                messageViewModel.dismissError()
            }
        } message: {
            Text(messageViewModel.errorMessage ?? "An error occurred")
        }
    }
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Load more button
                    if messageViewModel.hasMoreMessages {
                        Button(action: {
                            messageViewModel.loadMoreMessages()
                        }) {
                            HStack {
                                if messageViewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                Text("Load more messages")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 12)
                        }
                        .disabled(messageViewModel.isLoading)
                    }
                    
                    // Messages
                    ForEach(messageViewModel.messages) { message in
                        MessageRowView(
                            message: message,
                            currentUserId: authViewModel.currentUser?.id ?? "",
                            onEdit: { message, newContent in
                                messageViewModel.editMessage(message, newContent: newContent)
                            },
                            onDelete: { message in
                                messageViewModel.deleteMessage(message)
                            },
                            onReaction: { message, emoji in
                                messageViewModel.addReaction(to: message, emoji: emoji)
                            }
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .refreshable {
                messageViewModel.loadMessages(for: channel.id, refresh: true)
            }
            .onChange(of: messageViewModel.messages.count) { _, _ in
                // Auto-scroll to bottom when new message arrives
                if let lastMessage = messageViewModel.messages.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 6, height: 6)
                        .scaleEffect(0.8)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: messageViewModel.typingUsers.count
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray5))
            .cornerRadius(16)
            
            Text(messageViewModel.typingIndicatorText)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    private var messageInputView: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack(spacing: 12) {
                // Message text field
                HStack {
                    TextField("Message #\(channel.name)", text: $messageText, axis: .vertical)
                        .focused($isMessageFieldFocused)
                        .lineLimit(1...6)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .onChange(of: messageText) { _, newValue in
                            if !newValue.isEmpty {
                                messageViewModel.startTyping(in: channel.id)
                            } else {
                                messageViewModel.stopTyping(in: channel.id)
                            }
                        }
                        .onSubmit {
                            sendMessage()
                        }
                }
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: messageViewModel.isSending ? "hourglass" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(canSendMessage ? .blue : .gray)
                }
                .disabled(!canSendMessage || messageViewModel.isSending)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
    }
    
    private var canSendMessage: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func sendMessage() {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        messageViewModel.sendMessage(content: content, to: channel.id)
        messageText = ""
        messageViewModel.stopTyping(in: channel.id)
    }
}

struct MessageRowView: View {
    let message: Message
    let currentUserId: String
    let onEdit: (Message, String) -> Void
    let onDelete: (Message) -> Void
    let onReaction: (Message, String) -> Void
    
    @State private var showingEditDialog = false
    @State private var editText = ""
    @State private var showingDeleteConfirmation = false
    @State private var showingReactionPicker = false
    
    private let reactionEmojis = ["👍", "❤️", "😂", "😮", "😢", "😡"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // User avatar
                if let sender = message.sender {
                    UserAvatarView(user: sender, size: 36)
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 36, height: 36)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Header with name and time
                    HStack {
                        Text(message.sender?.displayName ?? "Unknown")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(message.timeString)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if message.isEdited {
                            Text("(edited)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if isOwnMessage {
                            Menu {
                                Button("Edit") {
                                    editText = message.content
                                    showingEditDialog = true
                                }
                                
                                Button("Delete", role: .destructive) {
                                    showingDeleteConfirmation = true
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Message content
                    Text(message.content)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                    
                    // Reactions
                    if let reactions = message.reactions, !reactions.isEmpty {
                        reactionView(reactions)
                    }
                }
                .contextMenu {
                    Button("React") {
                        showingReactionPicker = true
                    }
                    
                    if isOwnMessage {
                        Button("Edit") {
                            editText = message.content
                            showingEditDialog = true
                        }
                        
                        Button("Delete", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showingEditDialog) {
            EditMessageView(
                originalText: message.content,
                editText: $editText
            ) { newContent in
                onEdit(message, newContent)
            }
        }
        .alert("Delete Message", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete(message)
            }
        } message: {
            Text("Are you sure you want to delete this message?")
        }
        .actionSheet(isPresented: $showingReactionPicker) {
            ActionSheet(
                title: Text("Add Reaction"),
                buttons: reactionEmojis.map { emoji in
                    .default(Text(emoji)) {
                        onReaction(message, emoji)
                    }
                } + [.cancel()]
            )
        }
    }
    
    private var isOwnMessage: Bool {
        message.senderId == currentUserId
    }
    
    private func reactionView(_ reactions: [MessageReaction]) -> some View {
        HStack {
            ForEach(groupedReactions(reactions), id: \.emoji) { group in
                Button(action: {
                    onReaction(message, group.emoji)
                }) {
                    HStack(spacing: 4) {
                        Text(group.emoji)
                            .font(.caption)
                        
                        Text("\(group.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(group.userReacted ? Color.blue.opacity(0.2) : Color(.systemGray6))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func groupedReactions(_ reactions: [MessageReaction]) -> [ReactionGroup] {
        let grouped = Dictionary(grouping: reactions, by: { $0.emoji })
        return grouped.map { emoji, reactions in
            ReactionGroup(
                emoji: emoji,
                count: reactions.count,
                userReacted: reactions.contains { $0.userId == currentUserId }
            )
        }
    }
}

struct ReactionGroup {
    let emoji: String
    let count: Int
    let userReacted: Bool
}

struct EditMessageView: View {
    @Environment(\.dismiss) private var dismiss
    let originalText: String
    @Binding var editText: String
    let onSave: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Edit Message")
                    .font(.headline)
                    .padding(.top, 20)
                
                TextField("Message", text: $editText, axis: .vertical)
                    .lineLimit(3...10)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Spacer()
                
                Button("Save") {
                    onSave(editText)
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                )
                .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ChannelInfoView: View {
    @Environment(\.dismiss) private var dismiss
    let channel: Channel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: channel.isPrivate ? "lock.fill" : "number")
                            .font(.system(size: 50))
                            .foregroundColor(channel.isPrivate ? .orange : .gray)
                        
                        Text(channel.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if let description = channel.description, !description.isEmpty {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Info
                    VStack(spacing: 16) {
                        ProfileInfoCard(
                            title: "Channel Information",
                            items: [
                                ("Name", channel.displayName),
                                ("Type", channel.isPrivate ? "Private Channel" : "Public Channel"),
                                ("Members", "\(channel.memberCount)"),
                                ("Created", channel.createdAt.formatted(date: .abbreviated, time: .omitted))
                            ]
                        )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Channel Info")
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
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleChannel = Channel(
            id: "1",
            name: "general",
            description: "General discussion",
            teamId: "team1",
            createdById: "user1",
            isPrivate: false,
            lastMessageId: nil,
            createdAt: Date(),
            updatedAt: Date(),
            members: nil,
            lastMessage: nil
        )
        
        ChatView(channel: sampleChannel)
            .environmentObject(AuthViewModel())
    }
} 