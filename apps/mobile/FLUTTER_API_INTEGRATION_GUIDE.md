# Govia Mobile & Web API Integration Guide

This guide is prepared for the **Flutter Mobile App (`gsabino365`)** developer, frontend engineers, and API integration teams.

---

## 1. Quick Reference & Endpoints

| Resource | Value / URL |
| :--- | :--- |
| **Local Base URL (Emulator)** | `http://10.0.2.2:1000/api/v1` (Android Emulator) |
| **Local Base URL (iOS Simulator)** | `http://localhost:1000/api/v1` |
| **Local Base URL (Physical Device)** | `http://<YOUR_COMPUTER_LAN_IP>:1000/api/v1` |
| **Live Interactive Swagger UI** | `http://<SERVER_HOST>:1000/api/v1/docs` |
| **Raw OpenAPI 3.0 Spec (JSON)** | `http://<SERVER_HOST>:1000/api/v1/docs.json` |
| **Postman Collection v2.1** | `postman/govia-postman-collection.json` |
| **OpenAPI Schema for Postman/Swagger** | `postman/openapi.json` |
| **Socket.IO Real-Time Server** | `http://<SERVER_HOST>:1000` |

---

## 2. Standard Request & Response Structure

### 2.1 Success Response Envelope
All API endpoints return responses adhering to this standard envelope:
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Operation completed successfully",
  "data": { ... }
}
```

### 2.2 Error Response Envelope
When validation or processing fails:
```json
{
  "success": false,
  "message": "Validation Error / Not Authorized / Not Found",
  "errorMessages": [
    {
      "path": "email",
      "message": "Invalid email address format"
    }
  ]
}
```

### 2.3 Authorization Header
Protected routes require the JSON Web Token in standard Bearer format:
```http
Authorization: Bearer <accessToken>
```

---

## 3. Authentication & User Profile Workflow

### 3.1 Sign Up / Register
- **Endpoint**: `POST /api/v1/auth/register`
- **Body (`multipart/form-data` or `application/json`)**:
```json
{
  "name": "Jane Doe",
  "email": "jane@example.com",
  "password": "Password123!",
  "role": "USER", // "USER" | "HERO"
  "phone": "+1234567890"
}
```
*Note: If sending profile avatar image, use `multipart/form-data` with field key `image`.*

### 3.2 Login
- **Endpoint**: `POST /api/v1/auth/login`
- **Body**:
```json
{
  "email": "jane@example.com",
  "password": "Password123!"
}
```
- **Response**:
```json
{
  "success": true,
  "statusCode": 200,
  "message": "User logged in successfully",
  "data": {
    "accessToken": "eyJhbGciOi...",
    "user": {
      "_id": "67cb1a...",
      "name": "Jane Doe",
      "email": "jane@example.com",
      "role": "USER",
      "image": "/uploads/user/avatar.jpg"
    }
  }
}
```

### 3.3 Forgot & Reset Password
1. **Send OTP**: `POST /api/v1/auth/forgot-password` -> `{"email": "jane@example.com"}`
2. **Verify OTP**: `POST /api/v1/auth/verify-otp` -> `{"email": "jane@example.com", "otp": "123456"}`
3. **Reset Password**: `POST /api/v1/auth/reset-password` -> `{"email": "jane@example.com", "newPassword": "NewPassword123!"}`

---

## 4. User Directory & Cross-Role Search

Use this endpoint to allow users to search anyone across the platform (all roles: `USER`, `HERO`, `ADMIN`, `SUPER_ADMIN`).

### 4.1 Search Users Across All Roles
- **Endpoint**: `GET /api/v1/user/search?searchTerm=Sarah&role=&page=1&limit=20`
- **Headers**: `Authorization: Bearer <token>`
- **Query Parameters**:
  - `searchTerm` (optional): Matches name, email, or phone.
  - `role` (optional): Filter by specific role (`USER`, `HERO`, `ADMIN`, `SUPER_ADMIN`) or leave empty to search **ALL** roles.
  - `page` (optional, default: 1)
  - `limit` (optional, default: 10)
- **Response**:
```json
{
  "success": true,
  "statusCode": 200,
  "message": "Users retrieved successfully",
  "meta": {
    "page": 1,
    "limit": 10,
    "total": 45,
    "totalPage": 5
  },
  "data": [
    {
      "_id": "67c9f801...",
      "name": "Officer Sarah Connor",
      "email": "sarah@govia.org",
      "role": "HERO",
      "image": "https://govia.org/uploads/avatars/hero-sarah.jpg",
      "phone": "+14155552671",
      "conversationId": "67c9f912..." // Direct conversation ID if exists, or null
    }
  ]
}
```

---

## 5. Messaging & Chat System

### 5.1 Initiate / Get Conversation with User
- **Endpoint**: `POST /api/v1/conversation`
- **Headers**: `Authorization: Bearer <token>`
- **Body**:
```json
{
  "participantId": "67c9f801..." // The ID of the searched user
}
```
- **Response**: Returns existing or new `Conversation` object with participants and conversation ID.

### 5.2 List User Conversations
- **Endpoint**: `GET /api/v1/conversation`
- **Headers**: `Authorization: Bearer <token>`
- **Response**: List of active conversations with last message, unread counts, and recipient profile info (name, image, role).

### 5.3 Fetch Messages in Conversation
- **Endpoint**: `GET /api/v1/message/:conversationId?page=1&limit=50`
- **Headers**: `Authorization: Bearer <token>`

### 5.4 Send Message
- **Endpoint**: `POST /api/v1/message`
- **Headers**: `Authorization: Bearer <token>`
- **Body (`application/json` or `multipart/form-data` with `files`)**:
```json
{
  "conversationId": "67c9f912...",
  "text": "Hello! I need assistance with our scheduled meeting.",
  "meetingId": "67ca1234..." // Optional: attach a meeting card to message
}
```

---

## 6. Meeting Scheduling & Zoom Recording System

### 6.1 Unified Meeting Architecture
Meetings can be created either:
1. Directly from the **Meeting Schedule Page**, or
2. From within a **Chat/Message** (Instant "Meet Now" or "Schedule Later").

**Both actions save to the exact same MongoDB `Meeting` collection and immediately appear on the Meeting Schedule Page for all assigned participants.**

### 6.2 Create Meeting Schedule (Now or Later)
- **Endpoint**: `POST /api/v1/meeting`
- **Headers**: `Authorization: Bearer <token>`
- **Body**:
```json
{
  "title": "Emergency Safety Check-in",
  "description": "Discuss neighborhood safety alerts and protocol",
  "startTime": "2026-09-06T14:30:00.000Z",
  "endTime": "2026-09-06T15:00:00.000Z",
  "isInstant": false, // Set true for instant "Meet Now"
  "participants": ["67c9f801...", "67ca3312..."],
  "conversationId": "67c9f912..." // Optional: link to chat thread
}
```
- **Response**:
```json
{
  "success": true,
  "statusCode": 201,
  "message": "Meeting scheduled successfully",
  "data": {
    "_id": "67ca1234...",
    "title": "Emergency Safety Check-in",
    "startTime": "2026-09-06T14:30:00.000Z",
    "endTime": "2026-09-06T15:00:00.000Z",
    "status": "scheduled", // "scheduled" | "live" | "ended" | "cancelled"
    "joinUrl": "https://zoom.us/j/987654321?pwd=...",
    "startUrl": "https://zoom.us/s/987654321?...",
    "recordingUrl": null,
    "participants": [ ... ]
  }
}
```

### 6.3 Meeting List (Schedule Page)
- **Endpoint**: `GET /api/v1/meeting?status=all&page=1&limit=20`
- **Headers**: `Authorization: Bearer <token>`
- **Filter**: Automatically scoped to meetings where `req.user._id` is host or participant (or all for admins).

### 6.4 UI Behavior: Join Now vs Watch Recording
The Flutter UI logic for meeting cards (both in the Schedule Page and inside Chat message cards):

```dart
// Flutter Widget Decision Logic
Widget buildMeetingActionButton(Meeting meeting) {
  if (meeting.status == 'ended' || meeting.recordingUrl != null) {
    // Meeting is completed: show "Watch Recording" button
    return ElevatedButton.icon(
      icon: Icon(Icons.play_circle_fill),
      label: Text("Watch Recording"),
      onPressed: () => openVideoPlayer(meeting.recordingUrl),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
    );
  } else if (meeting.status == 'live' || isMeetingStartingSoon(meeting)) {
    // Meeting is active: show "Join Now" button
    return ElevatedButton.icon(
      icon: Icon(Icons.videocam),
      label: Text("Join Now"),
      onPressed: () => launchUrl(Uri.parse(meeting.joinUrl)),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
    );
  } else {
    // Scheduled for future
    return OutlinedButton.icon(
      icon: Icon(Icons.calendar_today),
      label: Text("Scheduled"),
      onPressed: null,
    );
  }
}
```

---

## 7. Real-Time Socket.IO Events

Connect to Socket.IO at `http://<SERVER_HOST>:1000`.

### 7.1 Connection & Room Setup
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

IO.Socket socket = IO.io('http://10.0.2.2:1000', <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': true,
  'query': {'token': userAccessToken}
});

socket.onConnect((_) {
  print('Socket connected: ${socket.id}');
  // Join personal user room to receive targeted alerts
  socket.emit('join-user-room', {'userId': currentUserId});
});
```

### 7.2 Events Summary Table

| Event Name | Direction | Payload | Description |
| :--- | :--- | :--- | :--- |
| `join-conversation` | Client -> Server | `{"conversationId": "..."}` | Join chat room |
| `leave-conversation`| Client -> Server | `{"conversationId": "..."}` | Leave chat room |
| `send-message` | Client -> Server | `{conversationId, text, meetingId}` | Emit new message |
| `new-message` | Server -> Client | `Message` object | Real-time chat incoming message |
| `user-typing` | Both | `{conversationId, userId, isTyping}` | Typing indicator |
| `meeting-created` | Server -> Client | `Meeting` object | Notifies assigned participants of new schedule |
| `meeting-status-changed` | Server -> Client | `{meetingId, status, recordingUrl}` | Triggered when meeting ends / recording is ready |
| `emergency-alert` | Both | `{userId, location: {lat, lng}, time}` | **"I Feel Unsafe"** emergency SOS broadcast |

---

## 8. Emergency "I Feel Unsafe" Alert Integration

### 8.1 Trigger Emergency Alert via API
- **Endpoint**: `POST /api/v1/user/emergency-alert`
- **Headers**: `Authorization: Bearer <token>`
- **Body**:
```json
{
  "latitude": 37.7749,
  "longitude": -122.4194,
  "note": "Suspicious vehicle following me near Market St."
}
```
- **Socket Broadcast**: The server automatically broadcasts `emergency-alert` to all active `HERO` and `ADMIN` sockets with coordinates and user info for instant response.

---

## 9. Community Resources & AI Assistant

### 9.1 Community Resources (Hotlines, Shelters, Clinics)
- **Endpoint**: `GET /api/v1/communityResource?searchTerm=&category=&page=1&limit=20`
- Fields: `name`, `logo`, `email`, `phoneNumber`, `address`, `websiteLink`, `category`.

### 9.2 Govia AI Assistant Chat
- **Endpoint**: `POST /api/v1/aiAssistant/ask`
- **Headers**: `Authorization: Bearer <token>`
- **Body**:
```json
{
  "question": "What should I do if I feel unsafe walking home late?"
}
```
- **Response**: Returns contextual safety advice, emergency hotline recommendations, and steps to alert Govia Heroes.

---

## 10. Pre-Generated Postman & OpenAPI Assets

The following files are located in the repository for import into Postman, Insomnia, or Swagger Editor:
- **`postman/govia-postman-collection.json`**: Pre-configured collection with all environment variables, authentication scripts, and example payloads.
- **`postman/openapi.json`**: Standard OpenAPI 3.0 export for code generators (e.g. `openapi-generator-cli` for Dart/Flutter models).
