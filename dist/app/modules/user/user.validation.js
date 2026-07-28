"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UserValidation = void 0;
const zod_1 = require("zod");
const createUserZodSchema = zod_1.z.object({
    body: zod_1.z.object({
        name: zod_1.z.string({ required_error: 'Name is required' }),
        role: zod_1.z.string({ required_error: 'Role is required' }),
        email: zod_1.z.string({ required_error: 'Email is required' }),
        password: zod_1.z.string({ required_error: 'Password is required' }),
        image: zod_1.z.string().optional(),
        subRole: zod_1.z.string().optional(),
        phoneNumber: zod_1.z.string().optional(),
        languagesSpoken: zod_1.z.string().optional(),
        preferredAttorney: zod_1.z.string().optional(),
        preferredBailBondsman: zod_1.z.string().optional(),
        licensedStatesToPractice: zod_1.z.string().optional(),
        barAssociationNumber: zod_1.z.string().optional(),
        lawFirmName: zod_1.z.string().optional(),
        officeName: zod_1.z.string().optional(),
        datePassedTheBar: zod_1.z.string().optional(),
        medicalLicenseNumber: zod_1.z.string().optional(),
        specialization: zod_1.z.string().optional(),
        companyName: zod_1.z.string().optional(),
        businessAddress: zod_1.z.string().optional(),
        badgeNumber: zod_1.z.string().optional(),
        assignedNumber: zod_1.z.string().optional(),
        departmentOrPrecinct: zod_1.z.string().optional(),
        didCarNumberChange: zod_1.z.string().optional(),
        newCarNumber: zod_1.z.string().optional(),
        licenseNumber: zod_1.z.string().optional(),
    }),
});
const updateUserZodSchema = zod_1.z.object({
    name: zod_1.z.string().optional(),
    email: zod_1.z.string().optional(),
    image: zod_1.z.string().optional(),
});
const adminUpdateUserZodSchema = zod_1.z.object({
    body: zod_1.z.object({
        name: zod_1.z.string().optional(),
        role: zod_1.z.string().optional(),
        email: zod_1.z.string().optional(),
        password: zod_1.z.string().optional(),
        image: zod_1.z.string().optional(),
        subRole: zod_1.z.string().optional(),
        phoneNumber: zod_1.z.string().optional(),
        languagesSpoken: zod_1.z.string().optional(),
        preferredAttorney: zod_1.z.string().optional(),
        preferredBailBondsman: zod_1.z.string().optional(),
        licensedStatesToPractice: zod_1.z.string().optional(),
        barAssociationNumber: zod_1.z.string().optional(),
        lawFirmName: zod_1.z.string().optional(),
        officeName: zod_1.z.string().optional(),
        datePassedTheBar: zod_1.z.string().optional(),
        medicalLicenseNumber: zod_1.z.string().optional(),
        specialization: zod_1.z.string().optional(),
        companyName: zod_1.z.string().optional(),
        businessAddress: zod_1.z.string().optional(),
        badgeNumber: zod_1.z.string().optional(),
        assignedNumber: zod_1.z.string().optional(),
        departmentOrPrecinct: zod_1.z.string().optional(),
        didCarNumberChange: zod_1.z.string().optional(),
        newCarNumber: zod_1.z.string().optional(),
        licenseNumber: zod_1.z.string().optional(),
        status: zod_1.z.enum(['active', 'inactive', 'delete']).optional(),
    }),
});
exports.UserValidation = {
    createUserZodSchema,
    updateUserZodSchema,
    adminUpdateUserZodSchema,
};
