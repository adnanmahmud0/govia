# Govia API Documentation

This document outlines the available REST API endpoints for the Govia project.

## Base URL
`http://localhost:3000/api/v1`

---

## Auth Endpoints

### 1. Login
- **Endpoint**: `/auth/login`
- **Method**: `POST`
- **Description**: Authenticate a user and receive access tokens.
- **Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "password123"
  }
  ```

### 2. Refresh Token
- **Endpoint**: `/auth/refresh`
- **Method**: `POST`
- **Description**: Refresh an expired access token using a refresh token (typically sent via cookies).

### 3. Forget Password
- **Endpoint**: `/auth/forget-password`
- **Method**: `POST`
- **Description**: Request a password reset OTP.
- **Body**:
  ```json
  {
    "email": "user@example.com"
  }
  ```

### 4. Verify Email
- **Endpoint**: `/auth/verify-email`
- **Method**: `POST`
- **Description**: Verify user email using the OTP sent to their email.
- **Body**:
  ```json
  {
    "email": "user@example.com",
    "oneTimeCode": "123456"
  }
  ```

### 5. Resend Verify Email
- **Endpoint**: `/auth/resend-verify-email`
- **Method**: `POST`
- **Description**: Request a new verification OTP.
- **Body**:
  ```json
  {
    "email": "user@example.com"
  }
  ```

### 6. Reset Password
- **Endpoint**: `/auth/reset-password`
- **Method**: `POST`
- **Headers**: `Authorization: Bearer <token>`
- **Description**: Reset the password using the token provided after OTP verification.
- **Body**:
  ```json
  {
    "password": "newpassword123"
  }
  ```

### 7. Change Password
- **Endpoint**: `/auth/change-password`
- **Method**: `POST`
- **Headers**: `Authorization: Bearer <token>`
- **Description**: Change password for an already authenticated user.
- **Body**:
  ```json
  {
    "oldPassword": "password123",
    "newPassword": "newpassword123"
  }
  ```

---

## User Endpoints

### 1. Register
- **Endpoint**: `/user/register`
- **Method**: `POST`
- **Description**: Register a new user (role defaults to `USER` or specified via payload depending on config).
- **Body**:
  ```json
  {
    "name": "John Doe",
    "email": "johndoe@example.com",
    "password": "password123",
    "role": "CITIZEN"
  }
  ```

### 2. Get Profile
- **Endpoint**: `/user/profile`
- **Method**: `GET`
- **Headers**: `Authorization: Bearer <token>`
- **Description**: Get the profile of the currently authenticated user.

### 3. Update Profile
- **Endpoint**: `/user/profile`
- **Method**: `PATCH`
- **Headers**: `Authorization: Bearer <token>`
- **Description**: Update the profile of the currently authenticated user. Uses `multipart/form-data` to support image uploads.
- **Form Data**:
  - `data`: JSON string `{"name": "John Updated"}`
  - `image`: File (optional)

---

## Admin Management Endpoints

These endpoints require `SUPER_ADMIN` or `ADMIN` roles.

### 1. Get All Users (with Filtering)
- **Endpoint**: `/user`
- **Method**: `GET`
- **Headers**: `Authorization: Bearer <token>`
- **Query Parameters**:
  - `role`: Filter users by role (e.g., `CITIZEN`, `POLICE`, `ATTORNEY`).
  - `searchTerm`: Search by name or email.
- **Description**: Get a paginated list of all users.

### 2. Create User (Bypass OTP)
- **Endpoint**: `/user/create-user`
- **Method**: `POST`
- **Headers**: `Authorization: Bearer <token>`
- **Description**: Admin endpoint to create a user and instantly verify them.
- **Body**:
  ```json
  {
    "name": "Jane Police",
    "email": "jane.police@example.com",
    "password": "password123",
    "role": "POLICE",
    "badgeNumber": "P-12345"
  }
  ```

### 3. Get Single User
- **Endpoint**: `/user/:id`
- **Method**: `GET`
- **Headers**: `Authorization: Bearer <token>`
- **Description**: Get detailed information for a specific user.

### 4. Update User
- **Endpoint**: `/user/:id`
- **Method**: `PATCH`
- **Headers**: `Authorization: Bearer <token>`
- **Description**: Admin endpoint to update any user's profile, including their `status` (active/inactive). Uses `multipart/form-data`.
- **Form Data**:
  - `data`: JSON string `{"status": "inactive", "badgeNumber": "123"}`
  - `image`: File (optional)

### 5. Delete User
- **Endpoint**: `/user/:id`
- **Method**: `DELETE`
- **Headers**: `Authorization: Bearer <token>`
- **Description**: Permanently delete a user from the database.

---

## Messaging Endpoints (Cross-Role)

All authenticated roles (`CITIZEN`, `ATTORNEY`, `POLICE`, `MENTAL_HEALTH_PROFESSIONAL`, `BAIL_BONDSMAN`, `ADMIN`, `SUPER_ADMIN`, `USER`) can message each other.

### 1. Create or Get Conversation
- **Endpoint**: `/conversation`
- **Method**: `POST`
- **Headers**: `Authorization: Bearer <token>`
- **Body**:
  ```json
  {
    "participantId": "64bcde1234567890abcdef12"
  }
  ```
- **Description**: Get existing direct thread with another user or initialize a new one. Deduplicated atomically using sorted composite keys to eliminate race conditions.
- **Response**: Returns conversation object including `unreadCount`.

### 2. Get User Conversations (Inbox)
- **Endpoint**: `/conversation`
- **Method**: `GET`
- **Headers**: `Authorization: Bearer <token>`
- **Query Parameters (Optional)**:
  - `page`: Page number
  - `limit`: Number of conversations per page
- **Description**: Returns all conversation threads for the logged-in user with latest message snippets, participant profiles, and real-time **`unreadCount`** for each conversation.

### 3. Get Single Conversation Details
- **Endpoint**: `/conversation/:id`
- **Method**: `GET`
- **Headers**: `Authorization: Bearer <token>`
- **Description**: Returns conversation details including `unreadCount`.

### 4. Send Message
- **Endpoint**: `/message`
- **Method**: `POST`
- **Headers**: `Authorization: Bearer <token>`
- **Body (JSON or multipart/form-data)**:
  ```json
  {
    "conversationId": "64bcde1234567890abcdef12",
    "text": "Hello, I need legal consultation regarding my case.",
    "messageType": "text",
    "meetingId": "optional_meeting_id"
  }
  ```
  *(For attachments, send as multipart/form-data with file key `image`, `media`, or `doc`, and optional JSON string in `data` field. At least one of `text`, attachment, or `meetingId` is required).*

### 5. Get Messages for Conversation
- **Endpoint**: `/message/:conversationId`
- **Method**: `GET`
- **Headers**: `Authorization: Bearer <token>`
- **Query Parameters**:
  - `page`: Page number (default: 1 — **returns the most recent 50 messages in ascending display order**)
  - `limit`: Number of messages (default: 50)

### 6. Mark Messages as Read
- **Endpoint**: `/message/read/:conversationId`
- **Method**: `PATCH`
- **Headers**: `Authorization: Bearer <token>`

### 7. Search Users for Messaging (Cross-Role Directory)
- **Endpoint**: `/message/search-users` *(also accessible via `/conversation/search-users`)*
- **Method**: `GET`
- **Headers**: `Authorization: Bearer <token>`
- **Query Parameters**:
  - `searchTerm`: Query string to match against `name`, `email`, `role`, `phoneNumber`, `specialization`, `lawFirmName`, `officeName`, `badgeNumber`, `companyName` (optional)
  - `role`: Filter users by role (`CITIZEN`, `ATTORNEY`, `POLICE`, `MENTAL_HEALTH_PROFESSIONAL`, `BAIL_BONDSMAN`, `ADMIN`, `SUPER_ADMIN`, `USER`) (optional)
  - `page`: Page number (default: 1)
  - `limit`: Number of users (default: 20)
- **Description**: Allows any authenticated user to search for other active users across all roles to start or continue conversations. Automatically checks and attaches the direct **`conversationId`** if a conversation thread already exists between the logged-in user and that searched user (or `null` if they haven't messaged yet).
- **Response Example**:
  ```json
  {
    "success": true,
    "statusCode": 200,
    "message": "Users retrieved successfully for messaging",
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 1,
      "totalPage": 1
    },
    "data": [
      {
        "_id": "64bcde1234567890abcdef12",
        "name": "Jane Attorney",
        "email": "jane@attorney.com",
        "role": "ATTORNEY",
        "image": "https://i.ibb.co/z5YHLV9/profile.png",
        "phoneNumber": "+123456789",
        "lawFirmName": "Jane Legal LLC",
        "specialization": "Criminal Defense",
        "conversationId": "651234567890abcdef123456"
      }
    ]
  }
  ```

### 8. Open or Create Chat (Action on User Click)
- **Endpoint**: `/message/open-chat` *(also accessible via `/conversation`)*
- **Method**: `POST`
- **Headers**: `Authorization: Bearer <token>`
- **Body**:
  ```json
  {
    "participantId": "64bcde1234567890abcdef12"
  }
  ```
- **Description**: Click action triggered when tapping any user from the search results. If a thread already exists, it retrieves it; if not, it initializes a new direct conversation atomically. Returns the full conversation object with `_id`, allowing the client to immediately navigate into `/message/:conversationId` and start messaging.

### 9. Create Meeting Directly Inside Chat (Now or Later)
- **Endpoint**: `/message/meeting`
- **Method**: `POST`
- **Headers**: `Authorization: Bearer <token>`
- **Description**: Creates a meeting with the counterparty in the conversation thread. Supports both instant meetings ("Now") and scheduled future meetings ("Later"). Automatically generates an interactive chat bubble (`messageType: 'meeting'`) and adds the meeting to both users' Schedule Page (`/meeting/schedule`).
- **Body (Instant Consultation / "Now")**:
  ```json
  {
    "conversationId": "651234567890abcdef123456",
    "topic": "Quick Case Consultation",
    "meetingType": "INSTANT"
  }
  ```
- **Body (Scheduled Meeting / "Later")**:
  ```json
  {
    "conversationId": "651234567890abcdef123456",
    "topic": "Preliminary Case Discussion",
    "meetingType": "SCHEDULED",
    "startTime": "2026-09-05T14:00:00.000Z",
    "durationMinutes": 45,
    "timezone": "America/New_York",
    "agenda": "Review documentation and discuss trial strategy"
  }
  ```
- **Response**: Returns the created meeting document and posts the interactive message card into the chat. Both participants receive real-time socket events (`new_message` and `inbox_update`).

---

## Real-Time Socket.IO Integration

### Connection & Authentication
Connect to the Socket.IO server with JWT authentication in the handshake:
```javascript
import { io } from "socket.io-client";

const socket = io("http://localhost:5000", {
  auth: {
    token: "<jwt_access_token>"
  }
});
```
*(Connections without a valid token will be rejected with an authentication error).*

### Automatic Rooms
Upon successful handshake, the server automatically joins the socket to:
- `user_<userId>`: For private user notifications and inbox updates.
- `role_<USER_ROLE>`: For role broadcasts (e.g. `role_ATTORNEY` for emergency alerts).

### Client Events (Emit)
- **`join_conversation`**: `socket.emit("join_conversation", conversationId)` (Server verifies participant access before joining).
- **`leave_conversation`**: `socket.emit("leave_conversation", conversationId)`.
- **`typing`**: `socket.emit("typing", { conversationId, name })`.
- **`stop_typing`**: `socket.emit("stop_typing", { conversationId })`.

### Server Events (Listen)
- **`new_message`**: Broadcasted to `conversation_<conversationId>` when a new message arrives (including meeting cards).
- **`meeting_ended`**: Emitted to `conversation_<conversationId>` and assigned users when a meeting ends. Contains the updated meeting document with `status: 'COMPLETED'` and `recordingUrl`, allowing the client to replace "Join Now" with "View Recording" without reloading.
- **`meeting_updated`**: Emitted when meeting recordings finish processing in the cloud.
- **`inbox_update`**: Emitted to `user_<userId>` with `{ conversationId, lastMessage, lastMessageText, lastMessageAt, unreadCount }` to update the inbox screen in real time.
- **`messages_read`**: Emitted to `conversation_<conversationId>` with `{ conversationId, readerId }`.

---

## Meeting & Schedule Endpoints (All Roles)

### 1. View Meeting Schedule List Page
- **Endpoint**: `/meeting/schedule` *(or alias `/meeting/my-meetings`)*
- **Method**: `GET`
- **Headers**: `Authorization: Bearer <token>`
- **Access**: Open to **ALL roles** (`CITIZEN`, `ATTORNEY`, `POLICE`, `MENTAL_HEALTH_PROFESSIONAL`, `BAIL_BONDSMAN`, `ADMIN`, `SUPER_ADMIN`, `USER`).
- **Query Parameters**:
  - `timeFilter`: `'upcoming'` (returns `SCHEDULED` and `ACTIVE` meetings) or `'past'` (returns `COMPLETED` and `CANCELLED` meetings).
  - `status`: `'SCHEDULED'`, `'ACTIVE'`, `'COMPLETED'`, or `'CANCELLED'`.
  - `meetingType`: `'SCHEDULED'`, `'INSTANT'`, or `'EMERGENCY'`.
  - `page`: Page number (e.g. `1`).
  - `limit`: Items per page (e.g. `10`).
- **Description**: Returns meetings where the authenticated user is either the host (`userId`), the assigned invitee (`participantId`), or a joined attorney.
- **Response Example**:
  ```json
  {
    "success": true,
    "statusCode": 200,
    "message": "User meetings retrieved successfully",
    "data": [
      {
        "_id": "65ab1234567890abcdef1234",
        "topic": "Preliminary Case Discussion",
        "meetingType": "SCHEDULED",
        "status": "SCHEDULED",
        "startTime": "2026-09-05T14:00:00.000Z",
        "durationMinutes": 45,
        "joinUrl": "https://zoom.us/j/123456789?pwd=...",
        "startUrl": "https://zoom.us/s/123456789?...",
        "recordingUrl": "",
        "recordings": [],
        "userId": {
          "_id": "64bcde1234567890abcdef11",
          "name": "Citizen John",
          "email": "john@citizen.com",
          "role": "CITIZEN",
          "image": "https://i.ibb.co/..."
        },
        "participantId": {
          "_id": "64bcde1234567890abcdef12",
          "name": "Jane Attorney",
          "email": "jane@attorney.com",
          "role": "ATTORNEY",
          "image": "https://i.ibb.co/..."
        }
      }
    ]
  }
  ```

### 2. Create Meeting Schedule (Schedule Page)
- **Endpoint**: `/meeting/schedule`
- **Method**: `POST`
- **Headers**: `Authorization: Bearer <token>`
- **Access**: Open to all roles.
- **Body**:
  ```json
  {
    "participantId": "64bcde1234567890abcdef12",
    "conversationId": "651234567890abcdef123456",
    "topic": "Case Planning & Strategy",
    "startTime": "2026-09-10T16:00:00.000Z",
    "durationMinutes": 60,
    "timezone": "America/New_York",
    "agenda": "Detailed evidentiary review"
  }
  ```
- **Description**: Schedules a Zoom meeting. If `conversationId` is provided, it automatically posts a meeting message card in the chat and synchronizes with both users' schedule lists.

### 3. Start Instant Meeting (Govia Consultation)
- **Endpoint**: `/meeting/start-govia`
- **Method**: `POST`
- **Headers**: `Authorization: Bearer <token>`
- **Body**:
  ```json
  {
    "topic": "Immediate Consultation",
    "participantId": "64bcde1234567890abcdef12",
    "conversationId": "651234567890abcdef123456"
  }
  ```

### 4. End Meeting (Replaces "Join Now" with Recording)
- **Endpoint**: `/meeting/:id/end`
- **Method**: `PATCH`
- **Headers**: `Authorization: Bearer <token>`
- **Description**: Called by the meeting host or assigned participant when the call ends. Marks meeting as `COMPLETED`, saves `endedAt`, immediately queries Zoom Cloud Recordings, attaches `recordingUrl` and `recordings` directly to the meeting, and emits real-time `meeting_ended` socket events.
- **Response Example**:
  ```json
  {
    "success": true,
    "statusCode": 200,
    "message": "Meeting ended successfully and recordings fetched",
    "data": {
      "_id": "65ab1234567890abcdef1234",
      "topic": "Preliminary Case Discussion",
      "status": "COMPLETED",
      "endedAt": "2026-09-05T14:46:12.000Z",
      "recordingUrl": "https://zoom.us/rec/share/abcd...",
      "recordings": [
        {
          "id": "rec_001",
          "fileType": "MP4",
          "playUrl": "https://zoom.us/rec/play/...",
          "downloadUrl": "https://zoom.us/rec/download/..."
        }
      ]
    }
  }
  ```

### 5. Refresh / Sync Cloud Recordings
- **Endpoint**: `/meeting/:id/sync-recording` *(or `GET /meeting/:meetingId/recordings`)*
- **Method**: `PATCH`
- **Headers**: `Authorization: Bearer <token>`
- **Description**: Synchronizes cloud recordings from Zoom if the recording took a few minutes to process after call completion. Automatically persists `recordingUrl` to MongoDB and emits `meeting_updated`.

### 6. Cancel Scheduled Meeting
- **Endpoint**: `/meeting/:id/cancel`
- **Method**: `PATCH`
- **Headers**: `Authorization: Bearer <token>`

---

## Frontend UI Display Rules: "Join Now" vs "View Recording"

Both on the **Schedule List Page** and in the **Chat Message Bubble**, the frontend inspects `meeting.status`:

| Meeting Status | Button Displayed | Target URL |
| :--- | :--- | :--- |
| `SCHEDULED` | **"Join Now"** (or "Start Meeting" for host) | `meeting.joinUrl` (or `meeting.startUrl` for host) |
| `ACTIVE` | **"Join Now"** | `meeting.joinUrl` |
| `COMPLETED` | **"View Recording"** *(Replaces Join Now)* | `meeting.recordingUrl` (or `meeting.recordings[0].playUrl`) |
| `CANCELLED` | **"Meeting Cancelled"** (Disabled) | N/A |


