# Huddle Up - Team Communication App

A modern, Slack-inspired team communication platform with real-time messaging, built with Node.js backend and iOS SwiftUI frontend.

## 🚀 Features

### Core Functionality
- **User Authentication** - Register, login, and manage user profiles
- **Team Management** - Create teams, invite members with unique codes
- **Channel Organization** - Create public/private channels for focused discussions
- **Real-time Messaging** - Instant messaging with Socket.IO
- **Message Reactions** - React to messages with emojis
- **Online Status** - See who's online and when they were last active

### Technical Features
- **PostgreSQL Database** - Robust relational database with Sequelize ORM
- **JWT Authentication** - Secure token-based authentication
- **Docker Support** - One-command deployment with Docker Compose
- **iOS Native App** - SwiftUI-based mobile application
- **RESTful API** - Clean API design following REST principles
- **Real-time Updates** - WebSocket connections for instant updates

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   iOS App       │    │   Node.js API   │    │   PostgreSQL    │
│   (SwiftUI)     │◄──►│   (Express)     │◄──►│   Database      │
│                 │    │                 │    │                 │
│ • Authentication│    │ • JWT Auth      │    │ • Users         │
│ • Real-time Chat│    │ • Socket.IO     │    │ • Teams         │
│ • Team/Channels │    │ • RESTful API   │    │ • Channels      │
│ • Modern UI     │    │ • Business Logic│    │ • Messages      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🛠️ Tech Stack

### Backend
- **Node.js** with Express.js framework
- **PostgreSQL** database with Sequelize ORM
- **Socket.IO** for real-time communication
- **JWT** for authentication
- **bcryptjs** for password hashing
- **Docker** for containerization

### Frontend (iOS)
- **SwiftUI** for modern UI development
- **URLSession** for HTTP requests
- **Socket.IO Client** for real-time updates
- **Combine** for reactive programming

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Node.js 18+ (for development)
- Xcode 15+ (for iOS development)
- iOS device or simulator

### 1. Start the Backend Services

```bash
# Clone the repository
git clone <your-repo-url>
cd huddle-up

# Start PostgreSQL and Node.js server
docker-compose up -d

# The server will automatically:
# 1. Start PostgreSQL database
# 2. Initialize database tables
# 3. Seed demo data
# 4. Start the API server on port 3000
```

### 2. Open iOS Project

```bash
# Open the iOS project in Xcode
open iOS/HuddleUp/HuddleUp.xcodeproj
```

### 3. Run the iOS App

1. Select your target device/simulator in Xcode
2. Update the server URL in the app if needed (default: localhost:3000)
3. Build and run the project (⌘+R)

## 📱 Demo Credentials

The system comes with pre-loaded demo data:

- **Email**: `demo@huddleup.com`
- **Password**: `password123`
- **Team**: Demo Team with #general, #random, #development channels

Additional demo users:
- `alice@huddleup.com` / `password123`
- `bob@huddleup.com` / `password123`

## 🔧 Development

### Server Development

```bash
cd server

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Run in development mode
npm run dev

# Initialize database manually
npm run init-db
```

### Environment Variables

```env
NODE_ENV=development
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=huddle_up
DB_USER=postgres
DB_PASSWORD=password123
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=24h
```

### iOS Development

1. Open `iOS/HuddleUp/HuddleUp.xcodeproj` in Xcode
2. Update server URL in `NetworkManager.swift` if needed
3. Build and run on device or simulator

## 📊 Database Schema

### Users
- id (UUID, Primary Key)
- email (String, Unique)
- username (String, Unique)
- password (String, Hashed)
- firstName, lastName (String)
- isOnline, lastSeen (Boolean, Date)

### Teams
- id (UUID, Primary Key)
- name, description (String)
- ownerId (UUID, Foreign Key)
- inviteCode (String, Unique)

### Channels
- id (UUID, Primary Key)
- name, description (String)
- teamId (UUID, Foreign Key)
- createdById (UUID, Foreign Key)
- isPrivate (Boolean)

### Messages
- id (UUID, Primary Key)
- content (Text)
- senderId, channelId, teamId (UUID, Foreign Keys)
- messageType (Enum: text, file, image, system)
- editedAt (Date, Optional)

## 🔄 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user
- `PUT /api/auth/profile` - Update user profile
- `POST /api/auth/logout` - User logout

### Teams
- `POST /api/teams` - Create new team
- `GET /api/teams` - Get user's teams
- `GET /api/teams/:id` - Get team details
- `POST /api/teams/join` - Join team with invite code
- `POST /api/teams/:id/invite` - Generate invite code
- `DELETE /api/teams/:id/leave` - Leave team

### Channels
- `POST /api/channels` - Create new channel
- `GET /api/channels/team/:teamId` - Get team channels
- `GET /api/channels/:id` - Get channel details
- `GET /api/channels/:id/messages` - Get channel messages
- `POST /api/channels/:id/join` - Join channel
- `DELETE /api/channels/:id/leave` - Leave channel

### Messages
- `POST /api/messages` - Send message
- `PUT /api/messages/:id` - Edit message
- `DELETE /api/messages/:id` - Delete message
- `POST /api/messages/:id/reaction` - Add/remove reaction

## 🔌 WebSocket Events

### Client Events
- `join-teams` - Join team rooms
- `join-channel` - Join specific channel
- `leave-channel` - Leave channel
- `send-message` - Send new message
- `edit-message` - Edit existing message
- `delete-message` - Delete message
- `typing` - Typing indicator

### Server Events
- `new-message` - New message received
- `message-edited` - Message was edited
- `message-deleted` - Message was deleted
- `user-typing` - User typing status
- `error` - Error occurred

## 🐳 Docker Services

The `docker-compose.yml` includes:

1. **PostgreSQL Database** (port 5432)
2. **Node.js API Server** (port 3000)
3. **pgAdmin** (port 5050) - Database management tool

### Useful Commands

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f server

# Stop all services
docker-compose down

# Reset database (removes all data)
docker-compose down -v

# Access database directly
docker-compose exec postgres psql -U postgres -d huddle_up
```

## 🧪 Testing

### Backend Testing

```bash
cd server
npm test
```

### Manual Testing

1. Start the backend services
2. Use the demo credentials to log in
3. Test team creation and joining
4. Create channels and send messages
5. Test real-time features with multiple users

## 🚢 Deployment

### Production Deployment

1. Update environment variables for production
2. Use proper SSL certificates
3. Configure production database
4. Set up proper Docker volumes for data persistence

```bash
# Production environment
docker-compose -f docker-compose.prod.yml up -d
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support, please open an issue on the GitHub repository or contact the development team.

---

**Built with ❤️ for modern team communication**
