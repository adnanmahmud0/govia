export type IVerifyEmail = {
  email: string;
  role: string;
  oneTimeCode: number;
};

export type ILoginData = {
  email: string;
  role: string;
  password: string;
};

export type IAuthResetPassword = {
  newPassword: string;
  confirmPassword: string;
};

export type IChangePassword = {
  currentPassword: string;
  newPassword: string;
  confirmPassword: string;
};
