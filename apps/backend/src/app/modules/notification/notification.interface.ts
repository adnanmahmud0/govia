import { Model, Types } from 'mongoose';

export type INotificationType =
  | 'emergency'
  | 'dispatch'
  | 'consultation'
  | 'legal'
  | 'medical'
  | 'bail'
  | 'duty'
  | 'message'
  | 'vault'
  | 'system'
  | string;

export type INotificationLink = {
  label: string;
  url: string;
}

export type INotification = {
  _id?: Types.ObjectId;
  userId: Types.ObjectId;
  type: INotificationType;
  title: string;
  subtitle: string;
  resourceType?: string;
  resourceId?: string;
  link?: INotificationLink;
  isRead: boolean;
  readAt?: Date;
  icon?: string;
  metadata?: Record<string, unknown>;
  createdAt: Date;
  updatedAt: Date;
}

export type NotificationModel = Model<INotification>;
