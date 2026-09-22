import { useState, useEffect, useCallback } from "react";
import api from "@/lib/api";

export interface RecordingItem {
  id?: string;
  fileType?: string;
  fileExtension?: string;
  fileSize?: number;
  playUrl?: string;
  downloadUrl?: string;
  recordingType?: string;
  recordingStart?: string;
  recordingEnd?: string;
}

export interface RecordedMeeting {
  _id: string;
  topic: string;
  roomName: string;
  category: "ENCOUNTER" | "EMERGENCY" | "CONSULTATION";
  meetingType: string;
  status: string;
  durationMinutes: number;
  locationAddress?: string;
  recordingUrl?: string;
  recordings?: RecordingItem[];
  userId?: {
    _id: string;
    name: string;
    email: string;
    role: string;
    image?: string;
  };
  participantId?: {
    _id: string;
    name: string;
    email: string;
    role: string;
  };
  joinedAttorneys?: Array<{
    _id: string;
    name: string;
    email: string;
  }>;
  createdAt: string;
  endedAt?: string;
}

export interface StorageSettingData {
  provider: "AWS_S3" | "CLOUDFLARE_R2" | "DIGITALOCEAN_SPACES" | "MINIO" | "CUSTOM";
  bucket: string;
  region: string;
  accessKey: string;
  secretKey?: string;
  maskedSecretKey?: string;
  endpoint?: string;
  publicDomain?: string;
  livekitUrl?: string;
  livekitApiKey?: string;
  livekitApiSecret?: string;
  maskedLivekitSecret?: string;
  autoRecordMeetings: boolean;
  isActive: boolean;
}

export interface RecordingsSummary {
  totalRecordings: number;
  totalDurationMinutes: number;
  totalSizeMB: number;
  provider: string;
  bucket: string;
  isConfigured: boolean;
}

export function useRecordings() {
  const [recordings, setRecordings] = useState<RecordedMeeting[]>([]);
  const [summary, setSummary] = useState<RecordingsSummary | null>(null);
  const [meta, setMeta] = useState<any>(null);
  const [loadingRecordings, setLoadingRecordings] = useState(true);
  const [errorRecordings, setErrorRecordings] = useState<string | null>(null);

  // Settings
  const [settings, setSettings] = useState<StorageSettingData | null>(null);
  const [loadingSettings, setLoadingSettings] = useState(true);
  const [errorSettings, setErrorSettings] = useState<string | null>(null);

  // Filters
  const [searchTerm, setSearchTerm] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("ALL");
  const [page, setPage] = useState(1);
  const [refreshKey, setRefreshKey] = useState(0);

  const fetchRecordings = useCallback(async () => {
    setLoadingRecordings(true);
    setErrorRecordings(null);
    try {
      const params = new URLSearchParams();
      params.set("page", String(page));
      params.set("limit", "12");
      if (categoryFilter && categoryFilter !== "ALL") params.set("category", categoryFilter);
      if (searchTerm) params.set("searchTerm", searchTerm);

      const res = await api.get<{
        meta: any;
        summary: RecordingsSummary;
        data: RecordedMeeting[];
      }>(`/recording-settings/recordings?${params.toString()}`);

      setRecordings(res.data || []);
      setSummary(res.summary || null);
      setMeta(res.meta || null);
    } catch (err: any) {
      setErrorRecordings(err?.message || "Failed to fetch recordings library");
    } finally {
      setLoadingRecordings(false);
    }
  }, [page, categoryFilter, searchTerm, refreshKey]);

  const fetchSettings = useCallback(async () => {
    setLoadingSettings(true);
    setErrorSettings(null);
    try {
      const res = await api.get<StorageSettingData>("/recording-settings");
      setSettings(res);
    } catch (err: any) {
      setErrorSettings(err?.message || "Failed to load storage settings");
    } finally {
      setLoadingSettings(false);
    }
  }, [refreshKey]);

  useEffect(() => {
    fetchRecordings();
  }, [fetchRecordings]);

  useEffect(() => {
    fetchSettings();
  }, [fetchSettings]);

  const saveSettings = async (payload: Partial<StorageSettingData>) => {
    const res = await api.post<StorageSettingData>("/recording-settings", payload);
    setSettings(res);
    setRefreshKey((k) => k + 1);
    return res;
  };

  const testConnection = async (payload: Partial<StorageSettingData>) => {
    return await api.post("/recording-settings/test-connection", payload);
  };

  const deleteRecording = async (meetingId: string) => {
    await api.delete(`/recording-settings/recordings/${meetingId}`);
    setRefreshKey((k) => k + 1);
  };

  return {
    recordings,
    summary,
    meta,
    loadingRecordings,
    errorRecordings,
    settings,
    loadingSettings,
    errorSettings,
    searchTerm,
    setSearchTerm,
    categoryFilter,
    setCategoryFilter,
    page,
    setPage,
    refetchRecordings: () => setRefreshKey((k) => k + 1),
    refetchSettings: fetchSettings,
    saveSettings,
    testConnection,
    deleteRecording,
  };
}
