import jwt, { JwtPayload } from 'jsonwebtoken';
import type { StringValue } from 'ms';

const createToken = (
  payload: object,
  secret: string,
  expireTime: StringValue | number
) => {
  return jwt.sign(payload, secret, { expiresIn: expireTime });
};

const verifyToken = (token: string, secret: string) => {
  return jwt.verify(token, secret) as JwtPayload;
};

export const jwtHelper = { createToken, verifyToken };
