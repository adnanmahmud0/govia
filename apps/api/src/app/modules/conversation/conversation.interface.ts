import { Model, Types } from 'mongoose';

export type IConversation = {
  participants: Types.ObjectId[];
  directKey?: string;
  lastMessage?: Types.ObjectId;
  lastMessageText?: string;
  lastMessageAt?: Date;
  createdAt?: Date;
  updatedAt?: Date;
};

export type ConversationModel = Model<IConversation, Record<string, unknown>>;
