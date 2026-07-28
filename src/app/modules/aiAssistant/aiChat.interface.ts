import { Model, Types } from 'mongoose';

export type IAiChatMessage = {
  role: 'system' | 'user' | 'assistant';
  content: string;
};

export type IAiChat = {
  userId: Types.ObjectId;
  title: string;
  messages: IAiChatMessage[];
  createdAt?: Date;
  updatedAt?: Date;
};

export type AiChatModel = Model<IAiChat, Record<string, unknown>>;
