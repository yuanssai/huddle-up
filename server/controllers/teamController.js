const { Team, User, Channel, TeamMember, ChannelMember } = require('../models');
const { Op } = require('sequelize');

const createTeam = async (req, res) => {
  try {
    const { name, description } = req.body;
    const userId = req.user.id;

    // Create team
    const team = await Team.create({
      name,
      description,
      ownerId: userId
    });

    // Generate invite code
    team.generateInviteCode();
    await team.save();

    // Add owner as admin member
    await TeamMember.create({
      userId: userId,
      teamId: team.id,
      role: 'admin'
    });

    // Create default channels
    const generalChannel = await Channel.create({
      name: 'general',
      description: 'General discussion',
      teamId: team.id,
      createdById: userId,
      isPrivate: false
    });

    const randomChannel = await Channel.create({
      name: 'random',
      description: 'Random conversations',
      teamId: team.id,
      createdById: userId,
      isPrivate: false
    });

    // Add owner to channels
    await ChannelMember.bulkCreate([
      { userId: userId, channelId: generalChannel.id },
      { userId: userId, channelId: randomChannel.id }
    ]);

    const populatedTeam = await Team.findByPk(team.id, {
      include: [
        {
          model: User,
          as: 'members',
          attributes: ['id', 'firstName', 'lastName', 'username', 'email'],
          through: { attributes: ['role', 'joinedAt'] }
        },
        {
          model: Channel,
          as: 'channels'
        }
      ]
    });

    res.status(201).json({
      message: 'Team created successfully',
      team: populatedTeam
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const getTeams = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // First, get all teams where the user is a member
    const userTeams = await TeamMember.findAll({
      where: { userId: userId },
      attributes: ['teamId']
    });
    
    const teamIds = userTeams.map(tm => tm.teamId);
    
    // Then get full team data including all members
    const teams = await Team.findAll({
      where: { id: { [Op.in]: teamIds } },
      include: [
        {
          model: User,
          as: 'members',
          attributes: ['id', 'firstName', 'lastName', 'username', 'email'],
          through: { attributes: ['role', 'joinedAt'] }
        },
        {
          model: Channel,
          as: 'channels'
        }
      ]
    });

    res.json(teams);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const getTeam = async (req, res) => {
  try {
    const { teamId } = req.params;
    const userId = req.user.id;

    const team = await Team.findByPk(teamId, {
      include: [
        {
          model: User,
          as: 'members',
          attributes: ['id', 'firstName', 'lastName', 'username', 'email', 'isOnline', 'lastSeen'],
          through: { attributes: ['role', 'joinedAt'] }
        },
        {
          model: Channel,
          as: 'channels'
        }
      ]
    });

    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Check if user is a member of the team
    const isMember = team.members.some(member => member.id === userId);
    if (!isMember) {
      return res.status(403).json({ error: 'Access denied' });
    }

    res.json(team);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const joinTeam = async (req, res) => {
  try {
    const { inviteCode } = req.body;
    const userId = req.user.id;

    const team = await Team.findOne({ where: { inviteCode } });
    if (!team) {
      return res.status(404).json({ error: 'Invalid invite code' });
    }

    // Check if user is already a member
    const existingMember = await TeamMember.findOne({
      where: {
        userId: userId,
        teamId: team.id
      }
    });

    if (existingMember) {
      return res.status(400).json({ error: 'Already a member of this team' });
    }

    // Add user to team
    await TeamMember.create({
      userId: userId,
      teamId: team.id,
      role: 'member'
    });

    // Add user to all public channels
    const publicChannels = await Channel.findAll({
      where: {
        teamId: team.id,
        isPrivate: false
      }
    });

    for (const channel of publicChannels) {
      await ChannelMember.create({
        userId: userId,
        channelId: channel.id
      });
    }

    const populatedTeam = await Team.findByPk(team.id, {
      include: [
        {
          model: User,
          as: 'members',
          attributes: ['id', 'firstName', 'lastName', 'username', 'email'],
          through: { attributes: ['role', 'joinedAt'] }
        },
        {
          model: Channel,
          as: 'channels'
        }
      ]
    });

    res.json({
      message: 'Joined team successfully',
      team: populatedTeam
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const generateInviteCode = async (req, res) => {
  try {
    const { teamId } = req.params;
    const userId = req.user.id;

    const team = await Team.findByPk(teamId);
    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Check if user is owner or admin
    if (team.ownerId !== userId) {
      const teamMember = await TeamMember.findOne({
        where: {
          userId: userId,
          teamId: teamId,
          role: 'admin'
        }
      });

      if (!teamMember) {
        return res.status(403).json({ error: 'Permission denied' });
      }
    }

    const inviteCode = team.generateInviteCode();
    await team.save();

    res.json({ inviteCode });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const leaveTeam = async (req, res) => {
  try {
    const { teamId } = req.params;
    const userId = req.user.id;

    const team = await Team.findByPk(teamId);
    if (!team) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Can't leave if you're the owner
    if (team.ownerId === userId) {
      return res.status(400).json({ error: 'Owner cannot leave team' });
    }

    // Remove user from team
    await TeamMember.destroy({
      where: {
        userId: userId,
        teamId: teamId
      }
    });

    // Remove user from all channels in this team
    const teamChannels = await Channel.findAll({
      where: { teamId: teamId }
    });

    for (const channel of teamChannels) {
      await ChannelMember.destroy({
        where: {
          userId: userId,
          channelId: channel.id
        }
      });
    }

    res.json({ message: 'Left team successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  createTeam,
  getTeams,
  getTeam,
  joinTeam,
  generateInviteCode,
  leaveTeam
}; 