import { useState, useEffect, useCallback } from 'react';
import api from '@/lib/api';

export interface CommunityResource {
  _id: string;
  name: string;
  shortName?: string;
  email?: string;
  phone?: string;
  websiteUrl?: string;
  logo?: string;
  createdAt?: string;
}

interface UseCommunityResourcesReturn {
  resources: CommunityResource[];
  loading: boolean;
  error: string | null;
  refetch: () => void;
  createResource: (data: Omit<CommunityResource, '_id' | 'createdAt'>) => Promise<CommunityResource>;
  updateResource: (id: string, data: Partial<CommunityResource>) => Promise<CommunityResource>;
  deleteResource: (id: string) => Promise<void>;
}

export function useCommunityResources(): UseCommunityResourcesReturn {
  const [resources, setResources] = useState<CommunityResource[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fetchKey, setFetchKey] = useState(0);

  const fetchResources = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await api.get<CommunityResource[]>('/community-resource');
      setResources(Array.isArray(result) ? result : []);
    } catch (err: any) {
      setError(err?.message || 'Failed to fetch resources');
    } finally {
      setLoading(false);
    }
  }, [fetchKey]);

  useEffect(() => {
    fetchResources();
  }, [fetchResources]);

  const createResource = async (data: Omit<CommunityResource, '_id' | 'createdAt'>): Promise<CommunityResource> => {
    const result = await api.post<CommunityResource>('/community-resource', data);
    setFetchKey(k => k + 1);
    return result;
  };

  const updateResource = async (id: string, data: Partial<CommunityResource>): Promise<CommunityResource> => {
    const result = await api.patch<CommunityResource>(`/community-resource/${id}`, data);
    setFetchKey(k => k + 1);
    return result;
  };

  const deleteResource = async (id: string): Promise<void> => {
    await api.delete(`/community-resource/${id}`);
    setResources(prev => prev.filter(r => r._id !== id));
  };

  return {
    resources,
    loading,
    error,
    refetch: () => setFetchKey(k => k + 1),
    createResource,
    updateResource,
    deleteResource,
  };
}
