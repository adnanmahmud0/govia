/* eslint-disable @typescript-eslint/no-explicit-any */
export const debug = (...args: any[]) => {
  if (process.env.NODE_ENV !== 'production') {
    console.log('[debug]', ...args);
  }
};

export const debugError = (...args: any[]) => {
  if (process.env.NODE_ENV !== 'production') {
    console.error('[error]', ...args);
  }
};
