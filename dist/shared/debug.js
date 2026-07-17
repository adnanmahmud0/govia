"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.debugError = exports.debug = void 0;
/* eslint-disable @typescript-eslint/no-explicit-any */
const debug = (...args) => {
    if (process.env.NODE_ENV !== 'production') {
        console.log('[debug]', ...args);
    }
};
exports.debug = debug;
const debugError = (...args) => {
    if (process.env.NODE_ENV !== 'production') {
        console.error('[error]', ...args);
    }
};
exports.debugError = debugError;
