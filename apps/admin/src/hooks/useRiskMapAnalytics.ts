import { useState, useEffect, useCallback } from "react";
import api from "@/lib/api";

export interface GeoIncident {
  id: string;
  roomName: string;
  topic: string;
  category: "ENCOUNTER" | "EMERGENCY" | "CONSULTATION";
  meetingType: "INSTANT" | "SCHEDULED" | "EMERGENCY";
  status: "SCHEDULED" | "ACTIVE" | "COMPLETED" | "CANCELLED";
  latitude: number;
  longitude: number;
  locationAddress: string;
  createdAt: string;
  endedAt?: string;
  durationMinutes: number;
  citizenName: string;
  citizenEmail: string;
  attorneyCount: number;
  isEmergency: boolean;
}

export interface HotspotCluster {
  id: string;
  name: string;
  center: [number, number]; // [lat, lng]
  incidentCount: number;
  emergencyCount: number;
  encounterCount: number;
  riskLevel: "CRITICAL" | "HIGH" | "MODERATE" | "LOW";
  radiusMeters: number;
  recentTopics: string[];
}

export interface ResponderStation {
  id: string;
  name: string;
  type: "PRECINCT" | "LEGAL_AID" | "MHP_DISPATCH";
  coords: [number, number];
  address: string;
  jurisdiction: string;
  activeUnits: number;
}

export interface InspectedZone {
  lat: number;
  lng: number;
  radiusKm: number;
  incidentCount: number;
  riskLevel: "CRITICAL" | "HIGH" | "MODERATE" | "LOW";
  riskScore: number;
  incidents: GeoIncident[];
}

export interface RiskAnalyticsData {
  summary: {
    totalIncidents: number;
    activeCriticalIncidents: number;
    avgResponseTimeMinutes: number;
    deEscalationRate: number;
    highRiskHotspotsCount: number;
  };
  categoryDistribution: {
    encounter: { count: number; percentage: number };
    emergency: { count: number; percentage: number };
    consultation: { count: number; percentage: number };
  };
  hourlyDistribution: { hour: number; label: string; count: number }[];
  hotspots: HotspotCluster[];
  incidents: GeoIncident[];
  responderStations: ResponderStation[];
  inspectedZone?: InspectedZone;
}

export function useRiskMapAnalytics() {
  const [data, setData] = useState<RiskAnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Filters
  const [timeframe, setTimeframe] = useState<string>("7d");
  const [categoryFilter, setCategoryFilter] = useState<string>("ALL");
  const [statusFilter, setStatusFilter] = useState<string>("ALL");
  const [selectedCoords, setSelectedCoords] = useState<{ lat: number; lng: number } | null>(null);
  const [radiusKm, setRadiusKm] = useState<number>(5);

  const [refreshKey, setRefreshKey] = useState(0);

  const fetchAnalytics = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      if (timeframe) params.set("timeframe", timeframe);
      if (categoryFilter && categoryFilter !== "ALL") params.set("category", categoryFilter);
      if (statusFilter && statusFilter !== "ALL") params.set("status", statusFilter);
      if (selectedCoords) {
        params.set("lat", String(selectedCoords.lat));
        params.set("lng", String(selectedCoords.lng));
        params.set("radiusKm", String(radiusKm));
      }

      const res = await api.get<RiskAnalyticsData>(`/meeting/risk-analytics?${params.toString()}`);
      setData(res);
    } catch (err: any) {
      setError(err?.message || "Failed to load risk map analytics");
    } finally {
      setLoading(false);
    }
  }, [timeframe, categoryFilter, statusFilter, selectedCoords, radiusKm, refreshKey]);

  useEffect(() => {
    fetchAnalytics();
  }, [fetchAnalytics]);

  // Polling every 30s to keep live incident radar active
  useEffect(() => {
    const timer = setInterval(() => {
      setRefreshKey((k) => k + 1);
    }, 30000);
    return () => clearInterval(timer);
  }, []);

  return {
    data,
    loading,
    error,
    timeframe,
    setTimeframe,
    categoryFilter,
    setCategoryFilter,
    statusFilter,
    setStatusFilter,
    selectedCoords,
    setSelectedCoords,
    radiusKm,
    setRadiusKm,
    refetch: () => setRefreshKey((k) => k + 1),
  };
}
