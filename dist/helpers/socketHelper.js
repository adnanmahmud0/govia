"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.socketHelper = void 0;
const socket = (io) => {
    io.on('connection', socket => {
        // no-op
        socket.on('disconnect', () => {
            // no-op
        });
    });
};
exports.socketHelper = { socket };
