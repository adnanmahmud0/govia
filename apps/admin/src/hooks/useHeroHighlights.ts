import { useState, useEffect, useCallback } from 'react';
import api from '@/lib/api';

export interface HeroHighlight {
  _id: string;
  officerName: string;
  badgeNumber?: string;
  agency: string;
  carNumber: string;
  respectRating: number;
  deEscalationRating: number;
  communicationRating: number;
  whatDidOfficerDoWell: string;
  incidentDate: string;
  incidentLocation: string;
  shareWithAgency: boolean;
  includeInMetrics: boolean;
  shareWithCourt: boolean;
  uploadedBy?: { _id: string; name: string; email: string };
  createdAt: string;
}

interface UseHeroHighlightsReturn {
  highlights: HeroHighlight[];
  loading: boolean;
  error: string | null;
  refetch: () => void;
}

export function useHeroHighlights(): UseHeroHighlightsReturn {
  const [highlights, setHighlights] = useState<HeroHighlight[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fetchKey, setFetchKey] = useState(0);

  const fetchHighlights = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await api.get<HeroHighlight[]>('/hero-highlight');
      setHighlights(Array.isArray(result) ? result : []);
    } catch (err: any) {
      setError(err?.message || 'Failed to fetch hero highlights');
    } finally {
      setLoading(false);
    }
  }, [fetchKey]);

  useEffect(() => {
    fetchHighlights();
  }, [fetchHighlights]);

  return {
    highlights,
    loading,
    error,
    refetch: () => setFetchKey(k => k + 1),
  };
}
