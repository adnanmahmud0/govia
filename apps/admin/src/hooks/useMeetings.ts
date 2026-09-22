import { useState, useEffect, useCallback } from 'react';
import api from '@/lib/api';

export interface MeetingUser {
  _id: string;
  name: string;
  email: string;
  role: string;
  image?: string;
  phoneNumber?: string;
}

export interface Meeting {
  _id: string;
  roomName: string;
  topic: string;
  meetingType: 'INSTANT' | 'SCHEDULED' | 'EMERGENCY';
  category: 'ENCOUNTER' | 'EMERGENCY' | 'CONSULTATION';
  status: 'SCHEDULED' | 'ACTIVE' | 'COMPLETED' | 'CANCELLED';
  startTime?: string;
  endedAt?: string;
  durationMinutes?: number;
  latitude?: number;
  longitude?: number;
  locationAddress?: string;
  userId: MeetingUser | string;
  participantId?: MeetingUser | string;
  joinedAttorneys?: (MeetingUser | string)[];
  joinedParticipants?: (MeetingUser | string)[];
  createdAt?: string;
  updatedAt?: string;
}

interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPage: number;
}

interface UseMeetingsReturn {
  activeMeetings: Meeting[];
  allMeetings: Meeting[];
  allMeta: PaginationMeta | null;
  loadingActive: boolean;
  loadingAll: boolean;
  errorActive: string | null;
  errorAll: string | null;
  page: number;
  setPage: (p: number) => void;
  statusFilter: string;
  setStatusFilter: (s: string) => void;
  refetchActive: () => void;
  refetchAll: () => void;
}

export function useMeetings(): UseMeetingsReturn {
  const [activeMeetings, setActiveMeetings] = useState<Meeting[]>([]);
  const [allMeetings, setAllMeetings] = useState<Meeting[]>([]);
  const [allMeta, setAllMeta] = useState<PaginationMeta | null>(null);
  const [loadingActive, setLoadingActive] = useState(false);
  const [loadingAll, setLoadingAll] = useState(false);
  const [errorActive, setErrorActive] = useState<string | null>(null);
  const [errorAll, setErrorAll] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState('');
  const [activeKey, setActiveKey] = useState(0);
  const [allKey, setAllKey] = useState(0);

  const fetchActive = useCallback(async () => {
    setLoadingActive(true);
    setErrorActive(null);
    try {
      const result = await api.get<Meeting[]>('/meeting/active');
      setActiveMeetings(Array.isArray(result) ? result : []);
    } catch (err: any) {
      setErrorActive(err?.message || 'Failed to fetch active meetings');
    } finally {
      setLoadingActive(false);
    }
  }, [activeKey]);

  const fetchAll = useCallback(async () => {
    setLoadingAll(true);
    setErrorAll(null);
    try {
      const params = new URLSearchParams();
      params.set('page', String(page));
      params.set('limit', '15');
      if (statusFilter) params.set('status', statusFilter);
      const result = await api.get<{ meta: PaginationMeta; data: Meeting[] }>(
        `/meeting/admin-all?${params.toString()}`
      );
      if (result && typeof result === 'object' && 'data' in result) {
        setAllMeetings((result as any).data || []);
        setAllMeta((result as any).meta || null);
      } else {
        setAllMeetings(Array.isArray(result) ? result : []);
        setAllMeta(null);
      }
    } catch (err: any) {
      setErrorAll(err?.message || 'Failed to fetch meetings');
    } finally {
      setLoadingAll(false);
    }
  }, [page, statusFilter, allKey]);

  useEffect(() => { fetchActive(); }, [fetchActive]);
  useEffect(() => { fetchAll(); }, [fetchAll]);

  // Auto-refresh active meetings every 30s
  useEffect(() => {
    const interval = setInterval(() => {
      setActiveKey(k => k + 1);
    }, 30000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => { setPage(1); }, [statusFilter]);

  return {
    activeMeetings,
    allMeetings,
    allMeta,
    loadingActive,
    loadingAll,
    errorActive,
    errorAll,
    page,
    setPage,
    statusFilter,
    setStatusFilter,
    refetchActive: () => setActiveKey(k => k + 1),
    refetchAll: () => setAllKey(k => k + 1),
  };
}
