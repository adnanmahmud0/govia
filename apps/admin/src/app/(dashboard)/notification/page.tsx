"use client";

import React, { useState } from "react";
import {
  Bell,
  AlertTriangle,
  CheckCircle2,
  Info,
  ShieldAlert,
  Phone,
  Trash2,
  Check,
  Scale,
  HeartPulse,
  FileKey,
  RefreshCw,
  Loader2,
  AlertCircle,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useNotifications, Notification } from "@/hooks/useNotifications";
import { Button } from "@/components/ui/button";

type FilterType = "all" | "unread" | "emergency" | "system";

const typeConfig: Record<string, { icon: React.ReactNode; iconBg: string; iconColor: string }> = {
  emergency: {
    icon: <Phone className="w-5 h-5" />,
    iconBg: "bg-red-100",
    iconColor: "text-red-600",
  },
  dispatch: {
    icon: <ShieldAlert className="w-5 h-5" />,
    iconBg: "bg-blue-100",
    iconColor: "text-[#1554ad]",
  },
  legal: {
    icon: <Scale className="w-5 h-5" />,
    iconBg: "bg-purple-100",
    iconColor: "text-purple-600",
  },
  medical: {
    icon: <HeartPulse className="w-5 h-5" />,
    iconBg: "bg-emerald-100",
    iconColor: "text-emerald-600",
  },
  bail: {
    icon: <FileKey className="w-5 h-5" />,
    iconBg: "bg-amber-100",
    iconColor: "text-amber-600",
  },
  system: {
    icon: <Info className="w-5 h-5" />,
    iconBg: "bg-slate-100",
    iconColor: "text-slate-600",
  },
  default: {
    icon: <Bell className="w-5 h-5" />,
    iconBg: "bg-slate-100",
    iconColor: "text-slate-600",
  },
};

function getTimeAgo(dateStr?: string) {
  if (!dateStr) return "Just now";
  const diffMs = Date.now() - new Date(dateStr).getTime();
  const diffMins = Math.floor(diffMs / 60000);
  if (diffMins < 1) return "Just now";
  if (diffMins < 60) return `${diffMins}m ago`;
  const diffHours = Math.floor(diffMins / 60);
  if (diffHours < 24) return `${diffHours}h ago`;
  const diffDays = Math.floor(diffHours / 24);
  return `${diffDays}d ago`;
}

export default function NotificationPage() {
  const {
    notifications,
    loading,
    error,
    unreadCount,
    refetch,
    markAsRead,
    markAllAsRead,
    deleteNotification,
  } = useNotifications();

  const [activeFilter, setActiveFilter] = useState<FilterType>("all");
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  const filtered = notifications.filter((n) => {
    if (activeFilter === "unread") return !n.isRead;
    if (activeFilter === "emergency") return n.type === "emergency" || n.type === "dispatch";
    if (activeFilter === "system") return n.type === "system";
    return true;
  });

  const handleMarkRead = async (id: string) => {
    await markAsRead(id);
  };

  const handleMarkAllRead = async () => {
    setActionLoading("all");
    try {
      await markAllAsRead();
    } finally {
      setActionLoading(null);
    }
  };

  const handleDelete = async (id: string) => {
    setActionLoading(id);
    try {
      await deleteNotification(id);
    } finally {
      setActionLoading(null);
    }
  };

  return (
    <div className="flex flex-col gap-6 max-w-4xl mx-auto py-2">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">Notifications</h1>
          <p className="text-slate-500 text-sm mt-0.5">Stay updated with system alerts, dispatch events, and user activity.</p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={refetch}
            disabled={loading}
            className="rounded-xl gap-2 text-xs"
          >
            <RefreshCw className={cn("w-3.5 h-3.5", loading && "animate-spin")} />
            Refresh
          </Button>
          {unreadCount > 0 && (
            <Button
              onClick={handleMarkAllRead}
              disabled={actionLoading === "all"}
              className="flex items-center gap-2 rounded-xl bg-[#1554ad] hover:bg-[#1554ad]/90 text-white text-xs"
              size="sm"
            >
              <Check className="w-3.5 h-3.5" />
              Mark all as read
            </Button>
          )}
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm">
          <AlertCircle className="w-4 h-4 flex-shrink-0" />
          {error}
        </div>
      )}

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-5 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-blue-50 flex items-center justify-center text-[#1554ad]">
            <Bell className="w-5 h-5" />
          </div>
          <div>
            <p className="text-2xl font-bold text-slate-800">{notifications.length}</p>
            <p className="text-xs text-slate-500">Total Notifications</p>
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-5 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-amber-50 flex items-center justify-center text-amber-500">
            <AlertTriangle className="w-5 h-5" />
          </div>
          <div>
            <p className="text-2xl font-bold text-slate-800">{unreadCount}</p>
            <p className="text-xs text-slate-500">Unread Alerts</p>
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-5 flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-red-50 flex items-center justify-center text-red-500">
            <ShieldAlert className="w-5 h-5" />
          </div>
          <div>
            <p className="text-2xl font-bold text-slate-800">
              {notifications.filter((n) => n.type === "emergency" || n.type === "dispatch").length}
            </p>
            <p className="text-xs text-slate-500">Emergencies / Dispatches</p>
          </div>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-2 bg-white rounded-xl border border-slate-100 shadow-sm p-1.5 w-fit">
        {(
          [
            { key: "all" as FilterType, label: "All", count: notifications.length },
            { key: "unread" as FilterType, label: "Unread", count: unreadCount },
            {
              key: "emergency" as FilterType,
              label: "Emergencies",
              count: notifications.filter((n) => n.type === "emergency" || n.type === "dispatch").length,
            },
            {
              key: "system" as FilterType,
              label: "System",
              count: notifications.filter((n) => n.type === "system").length,
            },
          ] as const
        ).map((f) => (
          <button
            key={f.key}
            onClick={() => setActiveFilter(f.key)}
            className={cn(
              "flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all",
              activeFilter === f.key
                ? "bg-[#1554ad] text-white shadow-md shadow-[#1554ad]/20"
                : "text-slate-500 hover:text-slate-700 hover:bg-slate-50"
            )}
          >
            {f.label}
            <span
              className={cn(
                "text-xs px-1.5 py-0.5 rounded-full font-bold",
                activeFilter === f.key ? "bg-white/20 text-white" : "bg-slate-100 text-slate-500"
              )}
            >
              {f.count}
            </span>
          </button>
        ))}
      </div>

      {/* Notifications List */}
      <div className="flex flex-col gap-2">
        {loading && notifications.length === 0 ? (
          <div className="bg-white rounded-2xl border border-slate-100 shadow-sm py-16 flex flex-col items-center justify-center gap-3 text-slate-400">
            <Loader2 className="w-6 h-6 animate-spin text-[#1554ad]" />
            <span className="font-medium text-sm">Loading notifications...</span>
          </div>
        ) : filtered.length === 0 ? (
          <div className="bg-white rounded-2xl border border-slate-100 shadow-sm py-16 flex flex-col items-center gap-3 text-center">
            <div className="w-14 h-14 rounded-full bg-slate-100 flex items-center justify-center">
              <Bell className="w-6 h-6 text-slate-400" />
            </div>
            <p className="text-slate-700 font-semibold">No notifications found</p>
            <p className="text-slate-400 text-sm">You are all caught up!</p>
          </div>
        ) : (
          filtered.map((notif) => {
            const notifId = notif._id || notif.id || "";
            const config = typeConfig[notif.type] || typeConfig.default;
            return (
              <div
                key={notifId}
                className={cn(
                  "group bg-white rounded-2xl border transition-all hover:shadow-md flex items-start gap-4 p-5",
                  notif.isRead
                    ? "border-slate-100 shadow-sm"
                    : "border-[#1554ad]/30 bg-blue-50/20 shadow-sm shadow-[#1554ad]/5"
                )}
              >
                {/* Icon with unread dot */}
                <div className="relative shrink-0 mt-0.5">
                  <div
                    className={cn(
                      "w-11 h-11 rounded-xl flex items-center justify-center",
                      config.iconBg,
                      config.iconColor
                    )}
                  >
                    {config.icon}
                  </div>
                  {!notif.isRead && (
                    <span className="absolute -top-1 -right-1 w-3 h-3 bg-[#1554ad] rounded-full border-2 border-white" />
                  )}
                </div>

                {/* Content */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <p className={cn("font-semibold text-sm", notif.isRead ? "text-slate-700" : "text-slate-900")}>
                      {notif.title}
                    </p>
                    <span className="text-xs text-slate-400 shrink-0">{getTimeAgo(notif.createdAt)}</span>
                  </div>
                  <p className="text-sm text-slate-500 mt-1 leading-relaxed">{notif.subtitle}</p>
                </div>

                {/* Actions */}
                <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity shrink-0">
                  {!notif.isRead && (
                    <button
                      onClick={() => handleMarkRead(notifId)}
                      title="Mark as read"
                      className="p-2 rounded-lg text-slate-400 hover:text-[#1554ad] hover:bg-blue-50 transition-colors"
                    >
                      <Check className="w-4 h-4" />
                    </button>
                  )}
                  <button
                    onClick={() => handleDelete(notifId)}
                    disabled={actionLoading === notifId}
                    title="Delete notification"
                    className="p-2 rounded-lg text-slate-400 hover:text-red-500 hover:bg-red-50 transition-colors"
                  >
                    {actionLoading === notifId ? (
                      <Loader2 className="w-4 h-4 animate-spin text-red-500" />
                    ) : (
                      <Trash2 className="w-4 h-4" />
                    )}
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
