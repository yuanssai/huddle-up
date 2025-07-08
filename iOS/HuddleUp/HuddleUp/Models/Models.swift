import Foundation

// MARK: - User Models
struct User: Identifiable, Codable, Equatable {
    let id: String
    let email: String?
    let username: String
    let firstName: String
    let lastName: String
    let avatar: String?
    let isOnline: Bool?
    let lastSeen: Date?
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var displayName: String {
        fullName.isEmpty ? username : fullName
    }
    
    var initials: String {
        let components = [firstName, lastName].filter { !$0.isEmpty }
        return components.map { String($0.prefix(1)) }.joined().uppercased()
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let username: String
    let password: String
    let firstName: String
    let lastName: String
}

struct AuthResponse: Codable {
    let message: String
    let token: String
    let user: User
}

// MARK: - Team Models
struct Team: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String?
    let ownerId: String
    let inviteCode: String?
    let isPublic: Bool
    let createdAt: Date
    let updatedAt: Date
    let members: [TeamMemberWithUser]?
    let channels: [Channel]?
    
    var memberCount: Int {
        members?.count ?? 0
    }
}

struct TeamMember: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let teamId: String
    let role: TeamRole
    let joinedAt: Date
    let user: User?
}

struct TeamMemberWithUser: Identifiable, Codable, Equatable {
    let id: String
    let firstName: String
    let lastName: String
    let username: String
    let email: String
    let TeamMember: TeamMemberInfo
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var displayName: String {
        fullName.isEmpty ? username : fullName
    }
}

struct TeamMemberInfo: Codable, Equatable {
    let role: TeamRole
    let joinedAt: Date
}

enum TeamRole: String, Codable, CaseIterable {
    case admin
    case member
    
    var displayName: String {
        switch self {
        case .admin:
            return "Admin"
        case .member:
            return "Member"
        }
    }
}

struct CreateTeamRequest: Codable {
    let name: String
    let description: String?
}

struct JoinTeamRequest: Codable {
    let inviteCode: String
}

// MARK: - Channel Models
struct Channel: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String?
    let teamId: String
    let createdById: String
    let isPrivate: Bool
    let lastMessageId: String?
    let createdAt: Date
    let updatedAt: Date
    let members: [ChannelMemberWithUser]?
    let lastMessage: Message?
    
    var displayName: String {
        name.hasPrefix("#") ? name : "#\(name)"
    }
    
    var memberCount: Int {
        members?.count ?? 0
    }
}

struct CreateChannelRequest: Codable {
    let name: String
    let description: String?
    let teamId: String
    let isPrivate: Bool
}

struct ChannelMemberWithUser: Identifiable, Codable, Equatable {
    let id: String
    let firstName: String
    let lastName: String
    let username: String
    let email: String?
    let ChannelMember: ChannelMemberInfo
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var displayName: String {
        fullName.isEmpty ? username : fullName
    }
}

struct ChannelMemberInfo: Codable, Equatable {
    let joinedAt: Date
}

// MARK: - Message Models
struct Message: Identifiable, Codable, Equatable {
    let id: String
    let content: String
    let senderId: String
    let channelId: String
    let teamId: String
    let messageType: MessageType
    let fileUrl: String?
    let editedAt: Date?
    let parentMessageId: String?
    let createdAt: Date
    let updatedAt: Date
    let sender: User?
    let reactions: [MessageReaction]?
    
    var isEdited: Bool {
        editedAt != nil
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(createdAt) {
            formatter.dateFormat = "HH:mm"
        } else if calendar.isDate(createdAt, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "E HH:mm"
        } else {
            formatter.dateFormat = "MMM d, HH:mm"
        }
        
        return formatter.string(from: createdAt)
    }
}

enum MessageType: String, Codable, CaseIterable {
    case text
    case file
    case image
    case system
}

struct MessageReaction: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let messageId: String
    let emoji: String
    let createdAt: Date
    let user: User?
}

struct SendMessageRequest: Codable {
    let content: String
    let channelId: String
}

struct EditMessageRequest: Codable {
    let content: String
}

struct AddReactionRequest: Codable {
    let emoji: String
}

// MARK: - Response Models
struct APIResponse<T: Codable>: Codable {
    let message: String?
    let data: T?
}

struct ErrorResponse: Codable {
    let error: String
}

// MARK: - Socket Events
struct SocketMessage: Codable {
    let content: String
    let channelId: String
}

struct SocketEditMessage: Codable {
    let messageId: String
    let content: String
}

struct SocketTypingEvent: Codable {
    let channelId: String
    let isTyping: Bool
}

struct SocketUserTyping: Codable, Equatable {
    let userId: String
    let username: String
    let channelId: String
    let isTyping: Bool
}



// MARK: - Extensions
extension Date {
    static func from(string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string) ?? ISO8601DateFormatter().date(from: string)
    }
}

// MARK: - Mock Data (for previews)
extension User {
    static let mock = User(
        id: "1",
        email: "demo@huddleup.com",
        username: "demo",
        firstName: "Demo",
        lastName: "User",
        avatar: nil,
        isOnline: true,
        lastSeen: Date()
    )
}

extension Team {
    static let mock = Team(
        id: "1",
        name: "Demo Team",
        description: "A demo team for testing",
        ownerId: "1",
        inviteCode: "demo-invite",
        isPublic: false,
        createdAt: Date(),
        updatedAt: Date(),
        members: nil,
        channels: nil
    )
}

extension Channel {
    static let mock = Channel(
        id: "1",
        name: "#general",
        description: "General discussion",
        teamId: "1",
        createdById: "1",
        isPrivate: false,
        lastMessageId: nil,
        createdAt: Date(),
        updatedAt: Date(),
        members: nil,
        lastMessage: nil
    )
}

extension Message {
    static let mock = Message(
        id: "1",
        content: "Hello, world!",
        senderId: "1",
        channelId: "1",
        teamId: "1",
        messageType: .text,
        fileUrl: nil,
        editedAt: nil,
        parentMessageId: nil,
        createdAt: Date(),
        updatedAt: Date(),
        sender: User.mock,
        reactions: nil
    )
} 