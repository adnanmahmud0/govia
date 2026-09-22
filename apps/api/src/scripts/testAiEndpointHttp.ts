async function testHttp() {
  // Login first as demo citizen
  const loginRes = await fetch('http://127.0.0.1:5000/api/v1/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'adnan99mahmud@gmail.com',
      password: 'Password123!',
      role: 'CITIZEN',
    }),
  });

  const loginData = (await loginRes.json()) as any;
  if (!loginData.success) {
    console.error('Login failed:', loginData);
    return;
  }

  const token = loginData.data.accessToken;
  console.log('Logged in, got token');

  // Call POST /aiAssistant
  console.log('Sending question to /api/v1/aiAssistant ...');
  const aiRes = await fetch('http://127.0.0.1:5000/api/v1/aiAssistant', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      prompt: 'What are my rights if a police officer pulls me over at night?',
    }),
  });

  const aiData = (await aiRes.json()) as any;
  console.log('AI Response status:', aiRes.status);
  console.log('AI Response body:', JSON.stringify(aiData, null, 2));

  if (aiData.success && aiData.data.chatId) {
    const chatId = aiData.data.chatId;
    // Get chat history
    const histRes = await fetch(`http://127.0.0.1:5000/api/v1/aiAssistant/chats/${chatId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    console.log('Chat history status:', histRes.status);
    const histData = (await histRes.json()) as any;
    console.log('Chat history messages:', histData.data?.messages?.length);
  }
}

testHttp().catch(console.error);
