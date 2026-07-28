import { model, Schema } from 'mongoose';
import { AiChatModel, IAiChat } from './aiChat.interface';

const aiChatMessageSchema = new Schema(
  {
    role: {
      type: String,
      enum: ['system', 'user', 'assistant'],
      required: true,
    },
    content: {
      type: String,
      required: true,
    },
  },
  { _id: false }
);

const aiChatSchema = new Schema<IAiChat, AiChatModel>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    title: {
      type: String,
      required: true,
      default: 'New Chat',
    },
    messages: {
      type: [aiChatMessageSchema],
      default: [],
    },
  },
  {
    timestamps: true,
  }
);

export const AiChat = model<IAiChat, AiChatModel>('AiChat', aiChatSchema);
