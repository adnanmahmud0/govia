import { Server, Socket } from 'socket.io';
import { Types } from 'mongoose';
import config from '../config';
import { jwtHelper } from './jwtHelper';
import { Conversation } from '../app/modules/conversation/conversation.model';

let ioInstance: Server | null = null;

type ISocketUser = {
  id: string;
  role: string;
  email: string;
};

const socket = (io: Server) => {
  ioInstance = io;

  // Handshake authentication middleware
  io.use((socket: Socket, next) => {
    try {
      const token =
        (socket.handshake.auth?.token as string | undefined) ||
        (socket.handshake.headers?.authorization as string | undefined)?.replace(
          /^Bearer\s+/i,
          ''
        ) ||
        (socket.handshake.query?.token as string | undefined);

      if (!token) {
        return next(new Error('Authentication error: Token required'));
      }

      const decoded = jwtHelper.verifyToken(
        token,
        config.jwt.jwt_secret as string
      ) as unknown as ISocketUser;

      if (!decoded || !decoded.id) {
        return next(new Error('Authentication error: Invalid token'));
      }

      socket.data.user = decoded;
      next();
    } catch {
      return next(new Error('Authentication error: Failed to authenticate token'));
    }
  });

  io.on('connection', (socket: Socket) => {
    const user = socket.data.user as ISocketUser;

    // Automatically join the verified user's personal and role rooms
    if (user?.id) {
      socket.join(`user_${user.id}`);
    }
    if (user?.role) {
      socket.join(`role_${user.role}`);
    }

    // Join a conversation room (only if user is a verified participant)
    socket.on('join_conversation', async (conversationId: string) => {
      if (!conversationId || !Types.ObjectId.isValid(conversationId)) {
        socket.emit('socket_error', { message: 'Invalid conversation ID' });
        return;
      }

      try {
        const isParticipant = await Conversation.exists({
          _id: new Types.ObjectId(conversationId),
          participants: new Types.ObjectId(user.id),
        });

        if (isParticipant) {
          socket.join(`conversation_${conversationId}`);
        } else {
          socket.emit('socket_error', {
            message: 'You are not a participant in this conversation',
          });
        }
      } catch {
        socket.emit('socket_error', {
          message: 'Failed to verify conversation access',
        });
      }
    });

    // Leave a conversation room
    socket.on('leave_conversation', (conversationId: string) => {
      if (conversationId) {
        socket.leave(`conversation_${conversationId}`);
      }
    });

    // Real-time typing indicators with anti-spoofing
    socket.on('typing', (data: { conversationId: string; name?: string }) => {
      if (data?.conversationId) {
        socket.to(`conversation_${data.conversationId}`).emit('typing', {
          conversationId: data.conversationId,
          userId: user.id,
          name: data.name,
        });
      }
    });

    socket.on('stop_typing', (data: { conversationId: string }) => {
      if (data?.conversationId) {
        socket.to(`conversation_${data.conversationId}`).emit('stop_typing', {
          conversationId: data.conversationId,
          userId: user.id,
        });
      }
    });

    socket.on('disconnect', () => {
      // Disconnected cleanly
    });
  });
};

const emitToUser = (userId: string, event: string, data: unknown) => {
  if (ioInstance) {
    ioInstance.to(`user_${userId}`).emit(event, data);
  }
};

const emitToConversation = (conversationId: string, event: string, data: unknown) => {
  if (ioInstance) {
    ioInstance.to(`conversation_${conversationId}`).emit(event, data);
  }
};

const emitToRole = (role: string, event: string, data: unknown) => {
  if (ioInstance) {
    ioInstance.to(`role_${role}`).emit(event, data);
  }
};

const broadcast = (event: string, data: unknown) => {
  if (ioInstance) {
    ioInstance.emit(event, data);
  }
};

export const socketHelper = {
  socket,
  emitToUser,
  emitToConversation,
  emitToRole,
  broadcast,
};
