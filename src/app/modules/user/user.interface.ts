import { Model } from 'mongoose';
import { USER_ROLES } from '../../../enums/user';

export type IUser = {
  name: string;
  role: USER_ROLES;
  email: string;
  password: string;
  image?: string;
  status: 'active' | 'delete';
  verified: boolean;
  subRole?: string;
  phoneNumber?: string;
  languagesSpoken?: string;
  preferredAttorney?: string;
  preferredBailBondsman?: string;
  licensedStatesToPractice?: string;
  barAssociationNumber?: string;
  lawFirmName?: string;
  officeName?: string;
  datePassedTheBar?: string;
  medicalLicenseNumber?: string;
  specialization?: string;
  companyName?: string;
  businessAddress?: string;
  badgeNumber?: string;
  assignedNumber?: string;
  departmentOrPrecinct?: string;
  didCarNumberChange?: string;
  newCarNumber?: string;
  licenseNumber?: string;
  authentication?: {
    isResetPassword: boolean;
    oneTimeCode: number;
    expireAt: Date;
  };
};

export type UserModal = {
  isExistUserById(id: string): Promise<IUser | null>;
  isExistUserByEmail(email: string): Promise<IUser | null>;
  isExistUserByEmailAndRole(email: string, role: string): Promise<IUser | null>;
  isMatchPassword(password: string, hashPassword: string): Promise<boolean>;
} & Model<IUser>;
