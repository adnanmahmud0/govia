import bcrypt from 'bcrypt';
import { User } from '../app/modules/user/user.model';
import { CommunityResource } from '../app/modules/communityResource/communityResource.model';
import config from '../config';
import { USER_ROLES } from '../enums/user';

export const demoAccounts = [
  // --- CITIZEN ROLE ---
  {
    name: 'Adnan Mahmud',
    email: 'adnan99mahmud@gmail.com',
    role: USER_ROLES.CITIZEN,
    password: 'Password123!',
    verified: true,
    status: 'active' as const,
    phoneNumber: '+1 (555) 012-3456',
    languagesSpoken: 'English, Spanish',
    preferredAttorney: 'Jenkins & Associates Legal Defense',
    preferredBailBondsman: 'Dana Bail Bonds & Surety Services',
    image: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
  },
  {
    name: 'Jordan Hayes',
    email: 'citizen@govia.com',
    role: USER_ROLES.CITIZEN,
    password: 'Password123!',
    verified: true,
    status: 'active' as const,
    phoneNumber: '+1 (555) 013-8822',
    languagesSpoken: 'English',
    preferredAttorney: 'Sterling Law Group LLP',
    preferredBailBondsman: 'Freedom Fast Bail Bonds LLC',
    image: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
  },
  {
    name: 'Marcus Vance',
    email: 'citizen.vance@govia.com',
    role: USER_ROLES.CITIZEN,
    password: 'Password123!',
    verified: true,
    status: 'active' as const,
    phoneNumber: '+1 (555) 014-7890',
    languagesSpoken: 'English, French',
    preferredAttorney: 'Jenkins & Associates Legal Defense',
    preferredBailBondsman: 'Dana Bail Bonds & Surety Services',
    image: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&auto=format&fit=crop&q=80',
  },

  // --- ATTORNEY ROLE ---
  {
    name: 'Attorney Sarah Jenkins',
    email: 'attorney@govia.com',
    role: USER_ROLES.ATTORNEY,
    password: 'Password123!',
    verified: true,
    status: 'active' as const,
    phoneNumber: '+1 (555) 019-2834',
    languagesSpoken: 'English, Spanish',
    lawFirmName: 'Jenkins & Associates Legal Defense',
    barAssociationNumber: 'OH-882910',
    licensedStatesToPractice: 'Nationwide, OH, NY, CA, TX, GA',
    specialization: 'Criminal Defense & Constitutional Rights',
    officeName: 'Main Downtown Chambers',
    datePassedTheBar: '2015-06-12',
    image: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&auto=format&fit=crop&q=80',
  },
  {
    name: 'Attorney David Sterling',
    email: 'attorney.sterling@govia.com',
    role: USER_ROLES.ATTORNEY,
    password: 'Password123!',
    verified: true,
    status: 'active' as const,
    phoneNumber: '+1 (555) 018-4421',
    languagesSpoken: 'English',
    lawFirmName: 'Sterling Law Group LLP',
    barAssociationNumber: 'NY-542190',
    licensedStatesToPractice: 'NY, NJ, CT, PA',
    specialization: 'Civil Rights & Emergency Dispatch Defense',
    officeName: 'Midtown Legal Center',
    datePassedTheBar: '2012-11-04',
    image: 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400&auto=format&fit=crop&q=80',
  },

  // --- MENTAL HEALTH PROFESSIONAL ROLE ---
  {
    name: 'Dr. Emily Chen, PsyD',
    email: 'doctor@govia.com',
    role: USER_ROLES.MENTAL_HEALTH_PROFESSIONAL,
    password: 'Password123!',
    verified: true,
    status: 'active' as const,
    phoneNumber: '+1 (555) 017-3399',
    languagesSpoken: 'English, Mandarin',
    medicalLicenseNumber: 'PSY-89214-OH',
    specialization: 'Crisis De-escalation & Trauma Counseling',
    companyName: 'Govia Crisis Response Network',
    businessAddress: '1200 Health Park Blvd, Suite 400, Columbus, OH',
    assignedNumber: 'CR-CHEN-01',
    image: 'https://images.unsplash.com/photo-1594824813515-5801b7a2d1d0?w=400&auto=format&fit=crop&q=80',
  },
  {
    name: 'Dr. Robert Harris, LCSW',
    email: 'doctor.harris@govia.com',
    role: USER_ROLES.MENTAL_HEALTH_PROFESSIONAL,
    password: 'Password123!',
    verified: true,
    status: 'active' as const,
    phoneNumber: '+1 (555) 016-5512',
    languagesSpoken: 'English',
    medicalLicenseNumber: 'SW-44120-NY',
    specialization: 'Community Mental Health & Acute Care',
    companyName: 'Metro Wellness & Support Center',
    businessAddress: '450 Lexington Ave, New York, NY',
    assignedNumber: 'CR-HARRIS-02',
    image: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&auto=format&fit=crop&q=80',
  },

  // --- POLICE ROLE ---
  {
    name: 'Officer James Miller',
    email: 'police@govia.com',
    role: USER_ROLES.POLICE,
    subRole: 'Officer',
    password: 'Password123!',
    verified: true,
    status: 'active' as const,
    phoneNumber: '+1 (555) 015-8833',
    languagesSpoken: 'English',
    badgeNumber: 'CPD-4402',
    assignedNumber: 'UNIT-71',
    departmentOrPrecinct: 'Central Metro Division - Precinct 4',
    licenseNumber: 'LEO-991240',
    image: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&auto=format&fit=crop&q=80',
  },
  {
    name: 'Sergeant Patricia Walker',
    email: 'police.walker@govia.com',
    role: USER_ROLES.POLICE,
    subRole: 'Sergeant',
    password: 'Password123!',
    verified: true,
    status: 'active' as const,
    phoneNumber: '+1 (555) 013-6622',
    languagesSpoken: 'English, Spanish',
    badgeNumber: 'CPD-2108',
    assignedNumber: 'PATROL-12',
    departmentOrPrecinct: 'Traffic & Highway Patrol Division',
    licenseNumber: 'LEO-773194',
    image: 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&auto=format&fit=crop&q=80',
  },

  // --- BAIL BONDSMAN ROLE ---
  {
    name: 'Dana Morgan',
    email: 'bailbonds@govia.com',
    role: USER_ROLES.BAIL_BONDSMAN,
    password: 'Password123!',
    verified: true,
    status: 'active' as const,
    phoneNumber: '+1 (555) 011-9988',
    languagesSpoken: 'English',
    companyName: 'Dana Bail Bonds & Surety Services',
    licenseNumber: 'BB-OH-90214',
    businessAddress: '350 Court St, Suite 101, Cincinnati, OH',
    image: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&auto=format&fit=crop&q=80',
  },
  {
    name: 'Victor Stone',
    email: 'bailbonds.stone@govia.com',
    role: USER_ROLES.BAIL_BONDSMAN,
    password: 'Password123!',
    verified: true,
    status: 'active' as const,
    phoneNumber: '+1 (555) 012-7711',
    languagesSpoken: 'English, Spanish',
    companyName: 'Freedom Fast Bail Bonds LLC',
    licenseNumber: 'BB-TX-44810',
    businessAddress: '800 Justice Plaza, Dallas, TX',
    image: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&auto=format&fit=crop&q=80',
  },

  // --- ADMIN & SUPER ADMIN ---
  {
    name: 'Super Administrator',
    email: config.super_admin.email || 'admin@govia.com',
    role: USER_ROLES.SUPER_ADMIN,
    password: 'Password123!',
    verified: true,
    status: 'active' as const,
    phoneNumber: '+1 (555) 010-0001',
    languagesSpoken: 'English',
    image: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&auto=format&fit=crop&q=80',
  },
  {
    name: 'Operations Administrator',
    email: 'ops.admin@govia.com',
    role: USER_ROLES.ADMIN,
    password: 'Password123!',
    verified: true,
    status: 'active' as const,
    phoneNumber: '+1 (555) 010-0002',
    languagesSpoken: 'English',
    image: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&auto=format&fit=crop&q=80',
  },
];

export const seedDemoAccounts = async () => {
  for (const account of demoAccounts) {
    const { email, role, password, ...rest } = account;
    const existingUser = await User.findOne({ email, role });

    if (!existingUser) {
      await User.create({
        email,
        role,
        password,
        ...rest,
      });
    } else {
      const hashedPassword = await bcrypt.hash(password, Number(config.bcrypt_salt_rounds));
      await User.updateOne(
        { _id: existingUser._id },
        {
          $set: {
            ...rest,
            verified: true,
            status: 'active',
            password: hashedPassword,
          },
        }
      );
    }
  }

  // Seed initial community resources if not yet present
  await seedCommunityResources();
};

export const defaultCommunityResources = [
  {
    name: 'Dana Bond',
    shortName: 'Dana Bail Bonds',
    email: 'danaacyinsurance@gmail.com',
    phone: '2164108911',
    websiteUrl: 'https://DanaBond.com',
  },
  {
    name: 'American Civil Liberties Union',
    shortName: 'ACLU',
    websiteUrl: 'https://www.aclu.org',
  },
  {
    name: 'Legal Aid Society',
    shortName: 'LAS',
    websiteUrl: 'https://www.legalaidinfo.org',
  },
  {
    name: 'National Association for the Advancement of Colored People',
    shortName: 'NAACP',
    websiteUrl: 'https://naacp.org',
  },
  {
    name: 'Southern Poverty Law Center',
    shortName: 'SPLC',
    websiteUrl: 'https://www.splcenter.org',
  },
  {
    name: 'Equal Justice Initiative',
    shortName: 'EJI',
    websiteUrl: 'https://eji.org',
  },
  {
    name: 'People, Places, and Dreams',
    shortName: 'PPD',
    websiteUrl: 'https://peopleplacesdreams.org',
  },
  {
    name: 'Black Mental Health Alliance',
    shortName: 'BMHA',
    websiteUrl: 'https://blackmentalhealth.com',
  },
  {
    name: 'Friend a Felon',
    shortName: 'FAF',
    websiteUrl: 'https://www.friendafelon.com',
  },
  {
    name: 'Federal Bureau of Investigation / Civil Rights',
    shortName: 'FBI.gov',
    websiteUrl: 'https://www.fbi.gov',
  },
  {
    name: 'DOJ Civil Rights Division',
    shortName: 'Civil Rights Div',
    websiteUrl: 'https://www.justice.gov/crt',
  },
  {
    name: 'National Association for Civilian Oversight of Law Enforcement',
    shortName: 'NACOLE',
    websiteUrl: 'https://www.nacole.org',
  },
  {
    name: 'State of Ohio Governor Official Portal',
    shortName: 'Governor.Ohio',
    websiteUrl: 'https://governor.ohio.gov',
  },
];

export const seedCommunityResources = async () => {
  const count = await CommunityResource.countDocuments();
  if (count === 0) {
    await CommunityResource.insertMany(defaultCommunityResources);
  }
};

export const seedSuperAdmin = async () => {
  const superAdmin = demoAccounts.find(a => a.role === USER_ROLES.SUPER_ADMIN);
  if (superAdmin) {
    const existing = await User.findOne({
      email: superAdmin.email,
      role: USER_ROLES.SUPER_ADMIN,
    });
    if (!existing) {
      await User.create(superAdmin);
    }
  }
};

export const seedDemoAttorney = async () => {
  const attorney = demoAccounts.find(a => a.role === USER_ROLES.ATTORNEY);
  if (attorney) {
    const existing = await User.findOne({
      email: attorney.email,
      role: USER_ROLES.ATTORNEY,
    });
    if (!existing) {
      await User.create(attorney);
    }
  }
};
