import { User } from '../app/modules/user/user.model';
import config from '../config';
import { USER_ROLES } from '../enums/user';

const payload = {
  name: 'Administrator',
  email: config.super_admin.email,
  role: USER_ROLES.SUPER_ADMIN,
  password: config.super_admin.password,
  verified: true,
};

export const seedSuperAdmin = async () => {
  const isExistSuperAdmin = await User.findOne({
    email: config.super_admin.email,
    role: USER_ROLES.SUPER_ADMIN,
  });
  if (!isExistSuperAdmin) {
    await User.create(payload);
    // no-op
  }
};

export const seedDemoAttorney = async () => {
  const email = 'attorney@govia.com';
  const role = USER_ROLES.ATTORNEY;
  const attorneyPayload = {
    name: 'Attorney Sarah Jenkins',
    email,
    role,
    password: 'Password123!',
    verified: true,
    status: 'active',
    licensedStatesToPractice: 'Nationwide, OH, NY, CA, TX, GA',
    barAssociationNumber: 'OH-882910',
    lawFirmName: 'Jenkins & Associates Legal Defense',
    phoneNumber: '+1 (555) 019-2834',
  };

  const existingAttorney = await User.findOne({ email, role });
  if (!existingAttorney) {
    await User.create(attorneyPayload);
  } else {
    // Ensure verified and active
    existingAttorney.verified = true;
    existingAttorney.status = 'active';
    existingAttorney.password = 'Password123!';
    existingAttorney.licensedStatesToPractice = 'Nationwide, OH, NY, CA, TX, GA';
    existingAttorney.barAssociationNumber = 'OH-882910';
    existingAttorney.lawFirmName = 'Jenkins & Associates Legal Defense';
    await existingAttorney.save();
  }
};
