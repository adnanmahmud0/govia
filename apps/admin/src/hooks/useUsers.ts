import { useState, useEffect, useCallback } from 'react';
import api from '@/lib/api';

export interface User {
  _id: string;
  name: string;
  email: string;
  role: string;
  status: 'active' | 'inactive' | 'delete';
  image?: string;
  phoneNumber?: string;
  verified: boolean;
  // role-specific fields
  badgeNumber?: string;
  departmentOrPrecinct?: string;
  barAssociationNumber?: string;
  lawFirmName?: string;
  licensedStatesToPractice?: string;
  datePassedTheBar?: string;
  medicalLicenseNumber?: string;
  specialization?: string;
  companyName?: string;
  businessAddress?: string;
  licenseNumber?: string;
  preferredAttorney?: string;
  preferredBailBondsman?: string;
  createdAt?: string;
}

interface UseUsersOptions {
  role?: string;
  autoFetch?: boolean;
}

interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPage: number;
}

interface UseUsersReturn {
  users: User[];
  meta: PaginationMeta | null;
  loading: boolean;
  error: string | null;
  page: number;
  setPage: (p: number) => void;
  searchTerm: string;
  setSearchTerm: (s: string) => void;
  statusFilter: string;
  setStatusFilter: (s: string) => void;
  refetch: () => void;
  createUser: (data: Partial<User> & { password: string }) => Promise<User>;
  updateUser: (id: string, data: Partial<User>) => Promise<User>;
  deleteUser: (id: string) => Promise<void>;
}

export function useUsers({ role, autoFetch = true }: UseUsersOptions = {}): UseUsersReturn {
  const [users, setUsers] = useState<User[]>([]);
  const [meta, setMeta] = useState<PaginationMeta | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [fetchKey, setFetchKey] = useState(0);

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      params.set('page', String(page));
      params.set('limit', '10');
      if (role) params.set('role', role);
      if (searchTerm) params.set('searchTerm', searchTerm);
      if (statusFilter) params.set('status', statusFilter);

      const result = await api.get<{ meta: PaginationMeta; data: User[] }>(
        `/user?${params.toString()}`
      );
      // handle both { meta, data } and plain array
      if (result && typeof result === 'object' && 'data' in result) {
        setUsers((result as any).data || []);
        setMeta((result as any).meta || null);
      } else {
        setUsers(Array.isArray(result) ? result : []);
        setMeta(null);
      }
    } catch (err: any) {
      setError(err?.message || 'Failed to fetch users');
    } finally {
      setLoading(false);
    }
  }, [role, page, searchTerm, statusFilter, fetchKey]);

  useEffect(() => {
    if (autoFetch) {
      const timer = setTimeout(fetchUsers, 300);
      return () => clearTimeout(timer);
    }
  }, [fetchUsers, autoFetch]);

  const refetch = () => setFetchKey(k => k + 1);

  const createUser = async (data: Partial<User> & { password: string }): Promise<User> => {
    const result = await api.post<User>('/user/create-user', data);
    refetch();
    return result;
  };

  const updateUser = async (id: string, data: Partial<User>): Promise<User> => {
    const result = await api.patch<User>(`/user/${id}`, data);
    refetch();
    return result;
  };

  const deleteUser = async (id: string): Promise<void> => {
    await api.delete(`/user/${id}`);
    refetch();
  };

  // Reset page when search/filter/role changes
  useEffect(() => {
    setPage(1);
  }, [searchTerm, statusFilter, role]);

  return {
    users,
    meta,
    loading,
    error,
    page,
    setPage,
    searchTerm,
    setSearchTerm,
    statusFilter,
    setStatusFilter,
    refetch,
    createUser,
    updateUser,
    deleteUser,
  };
}
