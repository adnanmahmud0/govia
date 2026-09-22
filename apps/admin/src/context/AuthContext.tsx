"use client";

import React, {
  createContext,
  useContext,
  useEffect,
  useState,
  useCallback,
} from "react";
import { useRouter, usePathname } from "next/navigation";
import {
  api,
  getAuthToken,
  getStoredUser,
  setAuthSession,
  clearAuthSession,
} from "@/lib/api";

export interface AdminUser {
  id: string;
  name: string;
  email: string;
  role: "ADMIN" | "SUPER_ADMIN" | string;
  image?: string;
  phoneNumber?: string;
}

interface AuthContextType {
  user: AdminUser | null;
  token: string | null;
  loading: boolean;
  isAuthenticated: boolean;
  isSuperAdmin: boolean;
  isAdmin: boolean;
  login: (email: string, password: string, role?: string) => Promise<AdminUser>;
  logout: () => Promise<void>;
  updateProfile: (data: Partial<AdminUser>) => Promise<AdminUser>;
  refreshProfile: () => Promise<AdminUser | null>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [user, setUser] = useState<AdminUser | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const refreshProfile = useCallback(async (): Promise<AdminUser | null> => {
    try {
      const currentToken = getAuthToken();
      if (!currentToken) {
        setUser(null);
        setToken(null);
        return null;
      }

      const profile = await api.get<AdminUser>("/user/profile");
      if (
        profile &&
        (profile.role === "ADMIN" || profile.role === "SUPER_ADMIN")
      ) {
        setUser(profile);
        setToken(currentToken);
        setAuthSession(currentToken, undefined, profile);
        return profile;
      } else {
        // Not an authorized admin role
        clearAuthSession();
        setUser(null);
        setToken(null);
        return null;
      }
    } catch {
      clearAuthSession();
      setUser(null);
      setToken(null);
      return null;
    }
  }, []);

  // Initialize from storage on mount
  useEffect(() => {
    const initAuth = async () => {
      const storedToken = getAuthToken();
      const storedUser = getStoredUser();

      if (storedToken && storedUser) {
        // Fast optimistic hydration from localStorage
        setUser(storedUser);
        setToken(storedToken);

        // Verify with server in background
        await refreshProfile();
      } else if (storedToken) {
        await refreshProfile();
      }

      setLoading(false);
    };

    initAuth();
  }, [refreshProfile]);

  const login = async (
    email: string,
    password: string,
    role?: string
  ): Promise<AdminUser> => {
    const payload: { email: string; password: string; role?: string } = {
      email: email.trim().toLowerCase(),
      password,
    };
    if (role) {
      payload.role = role;
    }

    const response = await api.post<any>("/auth/login", payload, {
      requiresAuth: false,
    });

    const accessToken = response.accessToken;
    const refreshToken = response.refreshToken;
    const loggedUser: AdminUser = response.user;

    if (!loggedUser || !accessToken) {
      throw new Error("Invalid response received from server");
    }

    // Role verification: only ADMIN and SUPER_ADMIN can enter Admin Portal
    if (loggedUser.role !== "ADMIN" && loggedUser.role !== "SUPER_ADMIN") {
      clearAuthSession();
      throw new Error(
        `Access Denied: Account with role "${loggedUser.role}" is not authorized. Only Administrators and Super Administrators may log in here.`
      );
    }

    setAuthSession(accessToken, refreshToken, loggedUser);
    setUser(loggedUser);
    setToken(accessToken);

    return loggedUser;
  };

  const logout = async () => {
    try {
      await api.post("/auth/logout", {}, { requiresAuth: true }).catch(() => {});
    } finally {
      clearAuthSession();
      setUser(null);
      setToken(null);
      router.push("/login");
    }
  };

  const updateProfile = async (data: Partial<AdminUser>): Promise<AdminUser> => {
    const updated = await api.patch<AdminUser>("/user/profile", data);
    setUser(updated);
    if (token) {
      setAuthSession(token, undefined, updated);
    }
    return updated;
  };

  const isAuthenticated = !!user && !!token;
  const isSuperAdmin = user?.role === "SUPER_ADMIN";
  const isAdmin = user?.role === "ADMIN";

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        loading,
        isAuthenticated,
        isSuperAdmin,
        isAdmin,
        login,
        logout,
        updateProfile,
        refreshProfile,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
