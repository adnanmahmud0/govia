import { model, Schema } from 'mongoose';
import { ConversationModel, IConversation } from './conversation.interface';

const conversationSchema = new Schema<IConversation, ConversationModel>(
  {
    participants: [
      {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true,
      },
    ],
    directKey: {
      type: String,
      unique: true,
      sparse: true,
      index: true,
    },
    lastMessage: {
      type: Schema.Types.ObjectId,
      ref: 'Message',
    },
    lastMessageText: {
      type: String,
    },
    lastMessageAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

// Index for fast participant query
conversationSchema.index({ participants: 1 });

export const Conversation = model<IConversation, ConversationModel>(
  'Conversation',
  conversationSchema
);
