import { z } from 'zod';

const createUserZodSchema = z.object({
  body: z.object({
    name: z.string({ required_error: 'Name is required' }),
    role: z.string({ required_error: 'Role is required' }),
    email: z.string({ required_error: 'Email is required' }),
    password: z.string({ required_error: 'Password is required' }),
    image: z.string().optional(),
    subRole: z.string().optional(),
    phoneNumber: z.string().optional(),
    languagesSpoken: z.string().optional(),
    preferredAttorney: z.string().optional(),
    preferredBailBondsman: z.string().optional(),
    licensedStatesToPractice: z.string().optional(),
    barAssociationNumber: z.string().optional(),
    lawFirmName: z.string().optional(),
    officeName: z.string().optional(),
    datePassedTheBar: z.string().optional(),
    medicalLicenseNumber: z.string().optional(),
    specialization: z.string().optional(),
    companyName: z.string().optional(),
    businessAddress: z.string().optional(),
    badgeNumber: z.string().optional(),
    assignedNumber: z.string().optional(),
    departmentOrPrecinct: z.string().optional(),
    didCarNumberChange: z.string().optional(),
    newCarNumber: z.string().optional(),
    licenseNumber: z.string().optional(),
  }),
});

const updateUserZodSchema = z.object({
  name: z.string().optional(),
  email: z.string().optional(),
  image: z.string().optional(),
});

const adminUpdateUserZodSchema = z.object({
  body: z.object({
    name: z.string().optional(),
    role: z.string().optional(),
    email: z.string().optional(),
    password: z.string().optional(),
    image: z.string().optional(),
    subRole: z.string().optional(),
    phoneNumber: z.string().optional(),
    languagesSpoken: z.string().optional(),
    preferredAttorney: z.string().optional(),
    preferredBailBondsman: z.string().optional(),
    licensedStatesToPractice: z.string().optional(),
    barAssociationNumber: z.string().optional(),
    lawFirmName: z.string().optional(),
    officeName: z.string().optional(),
    datePassedTheBar: z.string().optional(),
    medicalLicenseNumber: z.string().optional(),
    specialization: z.string().optional(),
    companyName: z.string().optional(),
    businessAddress: z.string().optional(),
    badgeNumber: z.string().optional(),
    assignedNumber: z.string().optional(),
    departmentOrPrecinct: z.string().optional(),
    didCarNumberChange: z.string().optional(),
    newCarNumber: z.string().optional(),
    licenseNumber: z.string().optional(),
    status: z.enum(['active', 'inactive', 'delete']).optional(),
  }),
});

export const UserValidation = {
  createUserZodSchema,
  updateUserZodSchema,
  adminUpdateUserZodSchema,
};
