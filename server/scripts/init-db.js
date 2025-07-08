const { sequelize } = require('../models');
require('dotenv').config();

const initDatabase = async () => {
  try {
    console.log('🔄 Connecting to database...');
    
    // Test database connection
    await sequelize.authenticate();
    console.log('✅ Database connection established successfully.');

    console.log('🔄 Creating database tables...');
    
    // Create all tables
    await sequelize.sync({ force: true }); // force: true will drop existing tables
    console.log('✅ Database tables created successfully.');

    console.log('🔄 Seeding initial data...');
    
    // Import models for seeding
    const { User, Team, Channel, TeamMember, ChannelMember } = require('../models');

    // Create demo users
    const demoUsers = await User.bulkCreate([
      {
        email: 'demo@huddleup.com',
        username: 'demo',
        password: 'password123',
        firstName: 'Demo',
        lastName: 'User',
      },
      {
        email: 'alice@huddleup.com',
        username: 'alice',
        password: 'password123',
        firstName: 'Alice',
        lastName: 'Johnson',
      },
      {
        email: 'bob@huddleup.com',
        username: 'bob',
        password: 'password123',
        firstName: 'Bob',
        lastName: 'Smith',
      },
    ]);

    console.log('✅ Demo users created.');

    // Create demo team
    const demoTeam = await Team.create({
      name: 'Demo Team',
      description: 'A demo team for testing Huddle Up',
      ownerId: demoUsers[0].id,
    });

    // Generate invite code
    demoTeam.generateInviteCode();
    await demoTeam.save();

    console.log('✅ Demo team created.');

    // Add users to team
    await TeamMember.bulkCreate([
      {
        userId: demoUsers[0].id,
        teamId: demoTeam.id,
        role: 'admin',
      },
      {
        userId: demoUsers[1].id,
        teamId: demoTeam.id,
        role: 'member',
      },
      {
        userId: demoUsers[2].id,
        teamId: demoTeam.id,
        role: 'member',
      },
    ]);

    console.log('✅ Team members added.');

    // Create demo channels
    const channels = await Channel.bulkCreate([
      {
        name: 'general',
        description: 'General discussion',
        teamId: demoTeam.id,
        createdById: demoUsers[0].id,
        isPrivate: false,
      },
      {
        name: 'random',
        description: 'Random conversations',
        teamId: demoTeam.id,
        createdById: demoUsers[0].id,
        isPrivate: false,
      },
      {
        name: 'development',
        description: 'Development discussions',
        teamId: demoTeam.id,
        createdById: demoUsers[0].id,
        isPrivate: false,
      },
    ]);

    console.log('✅ Demo channels created.');

    // Add users to channels
    for (const channel of channels) {
      await ChannelMember.bulkCreate([
        {
          userId: demoUsers[0].id,
          channelId: channel.id,
        },
        {
          userId: demoUsers[1].id,
          channelId: channel.id,
        },
        {
          userId: demoUsers[2].id,
          channelId: channel.id,
        },
      ]);
    }

    console.log('✅ Channel members added.');

    console.log('🎉 Database initialization completed successfully!');
    console.log('📝 Demo credentials:');
    console.log('   Email: demo@huddleup.com');
    console.log('   Password: password123');
    console.log(`   Team invite code: ${demoTeam.inviteCode}`);
    
  } catch (error) {
    console.error('❌ Database initialization failed:', error);
    throw error;
  }
};

// Run initialization if this file is executed directly
if (require.main === module) {
  initDatabase()
    .then(() => {
      console.log('✅ Database initialization completed.');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Database initialization failed:', error);
      process.exit(1);
    });
}

module.exports = initDatabase; 