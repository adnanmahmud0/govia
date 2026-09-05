/**
 * Standard API response structure
 */
export interface ApiResponse<T = unknown> {
  success: boolean;
  statusCode: number;
  message: string;
  data?: T;
  meta?: PaginationMeta;
}

/**
 * Standard API error response structure
 */
export interface ApiErrorResponse {
  success: false;
  statusCode: number;
  message: string;
  errorMessages?: Array<{
    path: string | number;
    message: string;
  }>;
  stack?: string;
}

/**
 * Pagination metadata
 */
export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPage?: number;
}

/**
 * Govia User Roles
 */
export enum USER_ROLES {
  CITIZEN = 'CITIZEN',
  ATTORNEY = 'ATTORNEY',
  POLICE = 'POLICE',
  MENTAL_HEALTH_PROFESSIONAL = 'MENTAL_HEALTH_PROFESSIONAL',
  BAIL_BONDSMAN = 'BAIL_BONDSMAN',
  ADMIN = 'ADMIN',
  SUPER_ADMIN = 'SUPER_ADMIN',
  USER = 'USER',
}

/**
 * Common User interface
 */
export interface IUser {
  id: string;
  name: string;
  email: string;
  role: USER_ROLES | string;
  image?: string;
  phoneNumber?: string;
  address?: string;
  barNumber?: string;
  lawFirmName?: string;
  badgeNumber?: string;
  department?: string;
  licenseNumber?: string;
  specialization?: string;
  companyName?: string;
  isVerified?: boolean;
  status?: 'active' | 'blocked';
  createdAt?: string | Date;
  updatedAt?: string | Date;
}

/**
 * Govia Meeting Type and Status
 */
export type MeetingType = 'INSTANT' | 'SCHEDULED' | 'EMERGENCY';
export type MeetingStatus = 'SCHEDULED' | 'ACTIVE' | 'COMPLETED' | 'CANCELLED';

export interface IMeetingRecordingFile {
  id?: string;
  fileType?: string;
  fileExtension?: string;
  fileSize?: number;
  playUrl?: string;
  downloadUrl?: string;
  recordingType?: string;
  recordingStart?: string;
  recordingEnd?: string;
}

export interface IMeeting {
  id: string;
  userId: string | IUser;
  participantId?: string | IUser;
  conversationId?: string;
  zoomMeetingId: string;
  topic: string;
  joinUrl: string;
  startUrl: string;
  meetingType: MeetingType;
  startTime?: string | Date;
  durationMinutes?: number;
  timezone?: string;
  agenda?: string;
  status: MeetingStatus;
  joinedAttorneys?: string[] | IUser[];
  recordingUrl?: string;
  recordings?: IMeetingRecordingFile[];
  endedAt?: string | Date;
  createdAt?: string | Date;
  updatedAt?: string | Date;
}
