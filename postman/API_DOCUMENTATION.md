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
