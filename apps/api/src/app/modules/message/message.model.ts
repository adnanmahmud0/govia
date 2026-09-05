import { model, Schema } from 'mongoose';
import { IMessage, MessageModel } from './message.interface';

const messageSchema = new Schema<IMessage, MessageModel>(
  {
    conversationId: {
      type: Schema.Types.ObjectId,
      ref: 'Conversation',
      required: true,
      index: true,
    },
    sender: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    receiver: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    text: {
      type: String,
    },
    attachment: {
      type: String,
    },
    messageType: {
      type: String,
      enum: ['text', 'image', 'file', 'meeting'],
      default: 'text',
    },
    meetingId: {
      type: Schema.Types.ObjectId,
      ref: 'Meeting',
    },
    read: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

messageSchema.index({ conversationId: 1, createdAt: -1 });
messageSchema.index({ conversationId: 1, receiver: 1, read: 1 });

export const Message = model<IMessage, MessageModel>('Message', messageSchema);
