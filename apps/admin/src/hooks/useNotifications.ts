import { useState, useEffect, useCallback } from 'react';
import api from '@/lib/api';

export interface Notification {
  _id: string;
  id?: string;
  type: string;
  title: string;
  subtitle: string;
  resourceType?: string;
  resourceId?: string;
  isRead: boolean;
  readAt?: string;
  icon?: string;
  createdAt: string;
}

interface UseNotificationsReturn {
  notifications: Notification[];
  loading: boolean;
  error: string | null;
  unreadCount: number;
  refetch: () => void;
  markAsRead: (id: string) => Promise<void>;
  markAllAsRead: () => Promise<void>;
  deleteNotification: (id: string) => Promise<void>;
}

export function useNotifications(): UseNotificationsReturn {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fetchKey, setFetchKey] = useState(0);

  const fetchNotifications = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await api.get<Notification[]>('/notification');
      setNotifications(Array.isArray(result) ? result : []);
    } catch (err: any) {
      setError(err?.message || 'Failed to fetch notifications');
    } finally {
      setLoading(false);
    }
  }, [fetchKey]);

  useEffect(() => {
    fetchNotifications();
  }, [fetchNotifications]);

  const markAsRead = async (id: string) => {
    try {
      await api.patch(`/notification/${id}/read`);
      setNotifications(prev =>
        prev.map(n => (n._id === id || n.id === id) ? { ...n, isRead: true } : n)
      );
    } catch {
      // silently fail, refetch on next user action
    }
  };

  const markAllAsRead = async () => {
    try {
      await api.patch('/notification/read-all');
      setNotifications(prev => prev.map(n => ({ ...n, isRead: true })));
    } catch {
      //
    }
  };

  const deleteNotification = async (id: string) => {
    try {
      await api.delete(`/notification/${id}`);
      setNotifications(prev => prev.filter(n => n._id !== id && n.id !== id));
    } catch (err: any) {
      throw new Error(err?.message || 'Failed to delete notification');
    }
  };

  const unreadCount = notifications.filter(n => !n.isRead).length;

  return {
    notifications,
    loading,
    error,
    unreadCount,
    refetch: () => setFetchKey(k => k + 1),
    markAsRead,
    markAllAsRead,
    deleteNotification,
  };
}
