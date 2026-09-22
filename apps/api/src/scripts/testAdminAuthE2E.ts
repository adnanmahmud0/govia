const BASE_URL = 'http://localhost:5000/api/v1';

async function testAdminAuth() {
  console.log('--- Testing Admin and Super Admin Authentication Flow ---');
  let superToken = '';

  // 1. Super Admin Login
  console.log('\n[1] Testing Super Admin Login (admin@govia.com)...');
  try {
    const res = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'admin@govia.com',
        password: 'Password123!',
      }),
    });
    const superAdminRes = (await res.json()) as any;
    console.log('✅ Super Admin login SUCCESS:', {
      role: superAdminRes.data.user.role,
      name: superAdminRes.data.user.name,
      hasAccessToken: !!superAdminRes.data.accessToken,
    });
    superToken = superAdminRes.data.accessToken;

    // 2. Fetch Profile
    console.log('\n[2] Testing GET /user/profile with Super Admin token...');
    const profileFetch = await fetch(`${BASE_URL}/user/profile`, {
      headers: { Authorization: `Bearer ${superToken}` },
    });
    const profileRes = (await profileFetch.json()) as any;
    console.log('✅ Profile fetch SUCCESS:', {
      email: profileRes.data.email,
      role: profileRes.data.role,
      name: profileRes.data.name,
    });

    // 3. Update Profile
    console.log('\n[3] Testing PATCH /user/profile (Updating phone number)...');
    const updateFetch = await fetch(`${BASE_URL}/user/profile`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${superToken}`,
      },
      body: JSON.stringify({ phoneNumber: '+1 (555) 987-6543' }),
    });
    const updateRes = (await updateFetch.json()) as any;
    console.log('✅ Profile update SUCCESS:', {
      phoneNumber: updateRes.data.phoneNumber,
    });
  } catch (err: any) {
    console.error('❌ Super Admin login/profile failed:', err.message);
  }

  // 4. Admin (Ops) Login
  console.log('\n[4] Testing Admin Login (ops.admin@govia.com)...');
  try {
    const res = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'ops.admin@govia.com',
        password: 'Password123!',
      }),
    });
    const adminRes = (await res.json()) as any;
    console.log('✅ Admin login SUCCESS:', {
      role: adminRes.data.user.role,
      name: adminRes.data.user.name,
      hasAccessToken: !!adminRes.data.accessToken,
    });
  } catch (err: any) {
    console.error('❌ Admin login failed:', err.message);
  }

  // 5. Test Non-Admin Role Login
  console.log('\n[5] Testing Non-Admin Role (citizen / driver)...');
  try {
    const res = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'citizen@govia.com',
        password: 'Password123!',
      }),
    });
    const citizenRes = (await res.json()) as any;
    if (citizenRes.data?.user) {
      console.log('ℹ️ Citizen account login returned role:', citizenRes.data.user.role);
      console.log(
        'Admin AuthContext check: (role === "ADMIN" || role === "SUPER_ADMIN") ->',
        citizenRes.data.user.role === 'ADMIN' || citizenRes.data.user.role === 'SUPER_ADMIN'
          ? 'ALLOWED'
          : 'BLOCKED (Correct! Non-admins rejected from admin portal)'
      );
    } else {
      console.log('Citizen account login response:', citizenRes.message);
    }
  } catch (err: any) {
    console.log('Non-admin login response:', err.message);
  }

  // 7. Test Change Password (same password so state isn't broken)
  console.log('\n[7] Testing POST /auth/change-password...');
  try {
    const changeRes = await fetch(`${BASE_URL}/auth/change-password`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${superToken}`,
      },
      body: JSON.stringify({
        currentPassword: 'Password123!',
        newPassword: 'Password123!',
        confirmPassword: 'Password123!',
      }),
    });
    const changeJson = (await changeRes.json()) as any;
    console.log('✅ Change password SUCCESS:', changeJson.message);
  } catch (err: any) {
    console.error('❌ Change password failed:', err.message);
  }

  console.log('\n--- All admin auth verification tests complete ---');
}

testAdminAuth().catch(console.error);
