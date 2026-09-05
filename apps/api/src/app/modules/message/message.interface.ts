import { Model, Types } from 'mongoose';

export type IMessage = {
  conversationId: Types.ObjectId;
  sender: Types.ObjectId;
  receiver: Types.ObjectId;
  text?: string;
  attachment?: string;
  messageType: 'text' | 'image' | 'file' | 'meeting';
  meetingId?: Types.ObjectId;
  read: boolean;
  createdAt?: Date;
  updatedAt?: Date;
};

export type MessageModel = Model<IMessage, Record<string, unknown>>;
