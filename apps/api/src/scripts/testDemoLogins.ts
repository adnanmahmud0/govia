async function testLogins() {
  const accounts = [
    { email: 'citizen@govia.com', role: 'CITIZEN', label: 'Citizen (Jordan)' },
    { email: 'adnan99mahmud@gmail.com', role: 'CITIZEN', label: 'Citizen (Adnan)' },
    { email: 'citizen.vance@govia.com', role: 'CITIZEN', label: 'Citizen (Marcus)' },
    { email: 'attorney@govia.com', role: 'ATTORNEY', label: 'Attorney (Sarah)' },
    { email: 'attorney.sterling@govia.com', role: 'ATTORNEY', label: 'Attorney (David)' },
    { email: 'doctor@govia.com', role: 'MENTAL_HEALTH_PROFESSIONAL', label: 'Mental Health (Emily)' },
    { email: 'doctor.harris@govia.com', role: 'MENTAL_HEALTH_PROFESSIONAL', label: 'Mental Health (Robert)' },
    { email: 'police@govia.com', role: 'POLICE', label: 'Police (James)' },
    { email: 'police.walker@govia.com', role: 'POLICE', label: 'Police (Patricia)' },
    { email: 'bailbonds@govia.com', role: 'BAIL_BONDSMAN', label: 'Bail Bondsman (Dana)' },
    { email: 'bailbonds.stone@govia.com', role: 'BAIL_BONDSMAN', label: 'Bail Bondsman (Victor)' },
    { email: 'admin@govia.com', role: 'SUPER_ADMIN', label: 'Super Admin' },
    { email: 'ops.admin@govia.com', role: 'ADMIN', label: 'Admin (Ops)' },
  ];

  console.log('Testing login for all 13 demo accounts with Password123! against http://127.0.0.1:5000...');

  for (const acc of accounts) {
    try {
      const res = await fetch('http://127.0.0.1:5000/api/v1/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: acc.email,
          password: 'Password123!',
          role: acc.role,
        }),
      });

      const json = await res.json();
      if (res.ok && json.success && json.data?.accessToken) {
        // Fetch profile
        const profileRes = await fetch('http://127.0.0.1:5000/api/v1/user/profile', {
          headers: {
            Authorization: `Bearer ${json.data.accessToken}`,
          },
        });
        const profileJson = await profileRes.json();
        const user = profileJson.data;
        console.log(`✅ [${acc.label}] Logged in & Profile OK: "${user?.name}" | Role: ${user?.role} | Phone: ${user?.phoneNumber} | ShortID: #${user?.shortHexId}`);
      } else {
        console.error(`❌ [${acc.label}] Login failed: HTTP ${res.status}`, json.message);
      }
    } catch (e: any) {
      console.error(`❌ [${acc.label}] Error:`, e.message);
    }
  }
}

testLogins();
