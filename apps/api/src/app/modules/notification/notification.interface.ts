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

export interface INotificationLink {
  label: string;
  url: string;
}

export interface INotification {
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
  createdAt: Date;
  updatedAt: Date;
}

export type NotificationModel = Model<INotification>;
