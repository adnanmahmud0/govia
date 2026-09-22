"use client";

import React from "react";
import {
  LogOut,
  ChevronDown,
  Menu,
  User as UserIcon,
  Shield,
  Crown,
  Bell,
  Check,
  Phone,
  AlertTriangle,
  Info,
} from "lucide-react";
import Link from "next/link";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { useAuth } from "@/context/AuthContext";
import { useNotifications } from "@/hooks/useNotifications";

interface TopBarProps {
  onMenuToggle?: () => void;
}

export default function TopBar({ onMenuToggle }: TopBarProps) {
  const { user, logout, isSuperAdmin } = useAuth();
  const { notifications, unreadCount, markAsRead, markAllAsRead } = useNotifications();

  const getInitials = (name?: string) => {
    if (!name) return isSuperAdmin ? "SA" : "AD";
    const parts = name.trim().split(" ");
    if (parts.length >= 2) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return name.slice(0, 2).toUpperCase();
  };

  const recentNotifications = notifications.slice(0, 4);

  return (
    <div className="flex items-center justify-between px-4 md:px-8 py-4 border-b border-slate-100 bg-white sticky top-0 z-10 h-16 shadow-xs">
      <div className="flex items-center gap-4">
        <button
          onClick={onMenuToggle}
          className="lg:hidden p-2 hover:bg-slate-100 rounded-lg transition-colors cursor-pointer"
        >
          <Menu className="h-6 w-6 text-slate-600" />
        </button>
        <div className="flex items-center gap-2">
          <span className="text-slate-700 text-sm font-semibold">
            Govia Admin Portal
          </span>
          <span
            className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold tracking-wide ${
              isSuperAdmin
                ? "bg-amber-100 text-amber-800 border border-amber-200"
                : "bg-blue-100 text-blue-800 border border-blue-200"
            }`}
          >
            {isSuperAdmin ? (
              <>
                <Crown className="w-2.5 h-2.5 text-amber-600" />
                <span>SUPER ADMIN</span>
              </>
            ) : (
              <>
                <Shield className="w-2.5 h-2.5 text-blue-600" />
                <span>ADMIN</span>
              </>
            )}
          </span>
        </div>
      </div>

      <div className="flex items-center gap-3">
        {/* Notification Bell Dropdown */}
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <button className="relative p-2 hover:bg-slate-100 rounded-xl transition-colors text-slate-500 hover:text-slate-700 outline-none cursor-pointer">
              <Bell className="w-5 h-5" />
              {unreadCount > 0 && (
                <span className="absolute top-1 right-1 w-4 h-4 bg-red-500 text-white rounded-full text-[9px] font-bold flex items-center justify-center animate-pulse">
                  {unreadCount > 9 ? "9+" : unreadCount}
                </span>
              )}
            </button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-80 shadow-xl border-slate-100 rounded-2xl p-2">
            <div className="flex items-center justify-between px-3 py-2 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <span className="font-bold text-sm text-slate-800">Notifications</span>
                {unreadCount > 0 && (
                  <span className="bg-blue-100 text-[#1554ad] text-[10px] font-bold px-2 py-0.5 rounded-full">
                    {unreadCount} New
                  </span>
                )}
              </div>
              {unreadCount > 0 && (
                <button
                  onClick={() => markAllAsRead()}
                  className="text-[11px] text-[#1554ad] hover:underline font-medium cursor-pointer"
                >
                  Mark all read
                </button>
              )}
            </div>

            <div className="py-1 space-y-1">
              {recentNotifications.length === 0 ? (
                <div className="text-center py-6 text-slate-400 text-xs">
                  No notifications yet
                </div>
              ) : (
                recentNotifications.map((n) => {
                  const notifId = n._id || n.id || "";
                  return (
                    <div
                      key={notifId}
                      onClick={() => !n.isRead && markAsRead(notifId)}
                      className={`p-2.5 rounded-xl transition-colors cursor-pointer text-left flex items-start gap-2.5 ${
                        n.isRead ? "hover:bg-slate-50 opacity-70" : "bg-blue-50/40 hover:bg-blue-50"
                      }`}
                    >
                      <div className="mt-0.5">
                        {n.type === "emergency" ? (
                          <Phone className="w-4 h-4 text-red-500 shrink-0" />
                        ) : n.type === "dispatch" ? (
                          <AlertTriangle className="w-4 h-4 text-amber-500 shrink-0" />
                        ) : (
                          <Info className="w-4 h-4 text-[#1554ad] shrink-0" />
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-semibold text-slate-800 leading-tight truncate">
                          {n.title}
                        </p>
                        <p className="text-[11px] text-slate-500 line-clamp-1 mt-0.5">
                          {n.subtitle}
                        </p>
                      </div>
                      {!n.isRead && (
                        <span className="w-2 h-2 rounded-full bg-[#1554ad] mt-1.5 shrink-0" />
                      )}
                    </div>
                  );
                })
              )}
            </div>

            <DropdownMenuSeparator />
            <DropdownMenuItem asChild className="cursor-pointer justify-center text-center">
              <Link
                href="/notification"
                className="w-full text-center text-xs font-semibold text-[#1554ad] py-1.5"
              >
                View all notifications →
              </Link>
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>

        {/* User Profile Dropdown */}
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <button className="flex items-center gap-3 text-right hover:bg-slate-50 p-1.5 rounded-xl transition-colors outline-none cursor-pointer">
              <div className="hidden sm:block">
                <div className="text-sm font-semibold text-slate-800 leading-tight">
                  {user?.name || (isSuperAdmin ? "Super Administrator" : "Administrator")}
                </div>
                <div className="text-[11px] text-slate-400 font-medium">
                  {user?.email || "admin@govia.com"}
                </div>
              </div>
              {user?.image ? (
                <img
                  src={user.image}
                  alt={user.name || "Admin"}
                  className="h-9 w-9 rounded-full object-cover border border-slate-200 shadow-xs"
                />
              ) : (
                <div
                  className={`h-9 w-9 rounded-full flex items-center justify-center text-white text-xs font-bold shadow-xs ${
                    isSuperAdmin
                      ? "bg-gradient-to-tr from-amber-600 to-amber-500"
                      : "bg-gradient-to-tr from-blue-700 to-blue-500"
                  }`}
                >
                  {getInitials(user?.name)}
                </div>
              )}
              <ChevronDown className="w-4 h-4 text-slate-400" />
            </button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-60 shadow-lg border-slate-200 rounded-xl">
            <DropdownMenuLabel className="pb-1">
              <div className="font-semibold text-slate-900">{user?.name || "Admin"}</div>
              <div className="text-xs text-slate-400 font-normal truncate">
                {user?.email}
              </div>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem asChild className="cursor-pointer">
              <Link href="/profile" className="flex items-center">
                <UserIcon className="mr-2 h-4 w-4 text-slate-500" />
                <span>Profile Settings</span>
              </Link>
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem
              onClick={() => logout()}
              className="text-red-600 focus:text-red-700 focus:bg-red-50 cursor-pointer"
            >
              <LogOut className="mr-2 h-4 w-4" />
              <span>Sign Out</span>
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </div>
  );
}
