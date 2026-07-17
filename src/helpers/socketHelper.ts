import { Server } from 'socket.io';

const socket = (io: Server) => {
  io.on('connection', socket => {
    // no-op
    socket.on('disconnect', () => {
      // no-op
    });
  });
};

export const socketHelper = { socket };
