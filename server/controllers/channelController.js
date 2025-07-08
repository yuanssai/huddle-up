const { Channel, Team, Message, User, TeamMember, ChannelMember } = require('../models');
const { Op } = require('sequelize');

const createChannel = async (req, res) => {
  try {
    const { name, description, teamId, isPrivate } = req.body;
    const userId = req.user.id;

    // Check if user is admin of the team
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

    // Create channel
    const channel = await Channel.create({
      name,
      description,
      teamId: teamId,
      createdById: userId,
      isPrivate: isPrivate || false
    });

    // Add creator to channel
    await ChannelMember.create({
      userId: userId,
      channelId: channel.id
    });

    // If public channel, add all team members
    if (!isPrivate) {
      const teamMembers = await TeamMember.findAll({
        where: { teamId: teamId }
      });
      
      const channelMembers = teamMembers.map(member => ({
        userId: member.userId,
        channelId: channel.id
      }));
      
      // Remove duplicate for creator
      const filteredMembers = channelMembers.filter(member => member.userId !== userId);
      await ChannelMember.bulkCreate(filteredMembers);
    }

    const populatedChannel = await Channel.findByPk(channel.id, {
      include: [
        {
          model: User,
          as: 'members',
          attributes: ['id', 'firstName', 'lastName', 'username', 'email'],
          through: { attributes: ['joinedAt'] }
        },
        {
          model: User,
          as: 'createdBy',
          attributes: ['id', 'firstName', 'lastName', 'username']
        }
      ]
    });

    res.status(201).json({
      message: 'Channel created successfully',
      channel: populatedChannel
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const getChannels = async (req, res) => {
  try {
    const { teamId } = req.params;
    const userId = req.user.id;

    // Check if user is member of the team
    const teamMember = await TeamMember.findOne({
      where: {
        userId: userId,
        teamId: teamId
      }
    });

    if (!teamMember) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const channels = await Channel.findAll({
      where: {
        teamId: teamId,
        [Op.or]: [
          { isPrivate: false },
          { '$members.id$': userId }
        ]
      },
      include: [
        {
          model: User,
          as: 'members',
          attributes: ['id', 'firstName', 'lastName', 'username', 'email'],
          through: { attributes: ['joinedAt'] },
          required: false
        },
        {
          model: Message,
          as: 'lastMessage',
          include: [{
            model: User,
            as: 'sender',
            attributes: ['id', 'firstName', 'lastName', 'username']
          }]
        }
      ],
      order: [['createdAt', 'ASC']]
    });

    res.json(channels);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const getChannel = async (req, res) => {
  try {
    const { channelId } = req.params;
    const userId = req.user.id;

    const channelMember = await ChannelMember.findOne({
      where: {
        userId: userId,
        channelId: channelId
      }
    });

    if (!channelMember) {
      return res.status(404).json({ error: 'Channel not found' });
    }

    const channel = await Channel.findByPk(channelId, {
      include: [
        {
          model: User,
          as: 'members',
          attributes: ['id', 'firstName', 'lastName', 'username', 'email', 'isOnline'],
          through: { attributes: ['joinedAt'] }
        },
        {
          model: User,
          as: 'createdBy',
          attributes: ['id', 'firstName', 'lastName', 'username']
        }
      ]
    });

    res.json(channel);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const joinChannel = async (req, res) => {
  try {
    const { channelId } = req.params;
    const userId = req.user.id;

    const channel = await Channel.findByPk(channelId);
    if (!channel) {
      return res.status(404).json({ error: 'Channel not found' });
    }

    // Check if user is member of the team
    const teamMember = await TeamMember.findOne({
      where: {
        userId: userId,
        teamId: channel.teamId
      }
    });

    if (!teamMember) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Check if already a member
    const existingMember = await ChannelMember.findOne({
      where: {
        userId: userId,
        channelId: channelId
      }
    });

    if (existingMember) {
      return res.status(400).json({ error: 'Already a member of this channel' });
    }

    // Add user to channel
    await ChannelMember.create({
      userId: userId,
      channelId: channelId
    });

    res.json({ message: 'Joined channel successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const leaveChannel = async (req, res) => {
  try {
    const { channelId } = req.params;
    const userId = req.user.id;

    const channel = await Channel.findByPk(channelId);
    if (!channel) {
      return res.status(404).json({ error: 'Channel not found' });
    }

    // Remove user from channel
    await ChannelMember.destroy({
      where: {
        userId: userId,
        channelId: channelId
      }
    });

    res.json({ message: 'Left channel successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

const getChannelMessages = async (req, res) => {
  try {
    const { channelId } = req.params;
    const userId = req.user.id;
    const { page = 1, limit = 50 } = req.query;

    // Check if user is member of the channel
    const channelMember = await ChannelMember.findOne({
      where: {
        userId: userId,
        channelId: channelId
      }
    });

    if (!channelMember) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const messages = await Message.findAll({
      where: { channelId: channelId },
      include: [
        {
          model: User,
          as: 'sender',
          attributes: ['id', 'firstName', 'lastName', 'username', 'email']
        }
      ],
      order: [['createdAt', 'DESC']],
      limit: parseInt(limit),
      offset: (parseInt(page) - 1) * parseInt(limit)
    });

    res.json(messages.reverse());
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

module.exports = {
  createChannel,
  getChannels,
  getChannel,
  joinChannel,
  leaveChannel,
  getChannelMessages
}; 