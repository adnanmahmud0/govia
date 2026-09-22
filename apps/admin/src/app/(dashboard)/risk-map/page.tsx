"use client";

import React, { useState } from "react";
import dynamic from "next/dynamic";
import {
  ShieldAlert,
  AlertTriangle,
  Radio,
  Clock,
  CheckCircle2,
  MapPin,
  RefreshCw,
  Target,
  Plus,
  Minus,
  Navigation,
  Layers,
  ChevronRight,
  Eye,
  X,
  Flame,
  Activity,
  User,
  Scale,
  Shield,
  Compass,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  useRiskMapAnalytics,
  GeoIncident,
  HotspotCluster,
} from "@/hooks/useRiskMapAnalytics";
import Link from "next/link";

// Dynamically import maps to avoid SSR issues with Leaflet
const RiskRealMap = dynamic(() => import("@/components/maps/RiskRealMap"), {
  ssr: false,
  loading: () => (
    <div className="h-full w-full bg-slate-100 animate-pulse flex flex-col items-center justify-center gap-2 text-slate-400">
      <Compass className="w-8 h-8 animate-spin text-[#1554ad]" />
      <span className="text-sm font-medium">Initializing Tactical Geospatial Radar...</span>
    </div>
  ),
});

const MapPickerDialog = dynamic(() => import("@/components/maps/MapPickerDialog"), {
  ssr: false,
});

export default function RiskMapPage() {
  const {
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
    refetch,
  } = useRiskMapAnalytics();

  const [layers, setLayers] = useState<Record<string, boolean>>({
    "Incident Markers": true,
    "Incident Heatmap": true,
    "Crisis Zones": true,
    "Officer & Precincts": true,
  });

  const [isMapDialogOpen, setIsMapDialogOpen] = useState(false);
  const [centerTarget, setCenterTarget] = useState<[number, number] | null>(null);
  const [inspectedIncident, setInspectedIncident] = useState<GeoIncident | null>(null);

  const toggleLayer = (key: string) => {
    setLayers((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const handleLocationSave = (lat: number, lng: number) => {
    setSelectedCoords({ lat, lng });
    setCenterTarget([lat, lng]);
  };

  const handleFlyToHotspot = (hotspot: HotspotCluster) => {
    setCenterTarget(hotspot.center);
    setSelectedCoords({ lat: hotspot.center[0], lng: hotspot.center[1] });
  };

  const handleResetLocation = () => {
    setSelectedCoords(null);
    setCenterTarget([40.7350, -73.9750]);
  };

  const summary = data?.summary || {
    totalIncidents: 0,
    activeCriticalIncidents: 0,
    avgResponseTimeMinutes: 2.4,
    deEscalationRate: 96.2,
    highRiskHotspotsCount: 0,
  };

  const hotspots = data?.hotspots || [];
  const incidents = data?.incidents || [];
  const responderStations = data?.responderStations || [];
  const inspectedZone = data?.inspectedZone;

  return (
    <div className="flex flex-col gap-6 pb-12">
      {/* Header & Main Control Strip */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-3xl font-bold text-slate-800 tracking-tight">
              Risk Map & Analytics
            </h1>
            <Badge className="bg-rose-50 text-rose-700 border-rose-200 gap-1.5 px-2.5 py-1 text-xs font-semibold">
              <span className="w-2 h-2 rounded-full bg-rose-500 animate-ping" />
              Live Tactical Feed
            </Badge>
          </div>
          <p className="text-slate-500 mt-1 text-sm">
            Real-time geospatial situational awareness, crisis hotspots, and legal responder telemetry.
          </p>
        </div>

        {/* Action Controls */}
        <div className="flex flex-wrap items-center gap-3">
          {/* Selected Area Indicator / Picker */}
          <div className="flex items-center gap-2 bg-white border border-slate-200 rounded-xl px-3 py-2 shadow-xs">
            <MapPin className="w-4 h-4 text-[#1554ad] shrink-0" />
            <button
              onClick={() => setIsMapDialogOpen(true)}
              className="text-xs font-medium text-slate-700 hover:text-[#1554ad] transition-colors text-left"
            >
              {selectedCoords
                ? `${selectedCoords.lat.toFixed(4)}, ${selectedCoords.lng.toFixed(4)}`
                : "Select Risk Radius Area"}
            </button>
            {selectedCoords && (
              <button
                onClick={handleResetLocation}
                title="Clear selected area"
                className="text-slate-400 hover:text-rose-500 transition-colors ml-1 p-0.5"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            )}
          </div>

          <Button
            variant="outline"
            size="sm"
            onClick={refetch}
            disabled={loading}
            className="rounded-xl border-slate-200 text-slate-600 gap-1.5 h-9"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? "animate-spin text-[#1554ad]" : ""}`} />
            Refresh Radar
          </Button>
        </div>
      </div>

      {/* KPI Tactical Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-3.5">
        <Card className="rounded-2xl border-slate-200 shadow-xs bg-white">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                Total Incidents
              </p>
              <h3 className="text-2xl font-black text-slate-800 mt-1">
                {summary.totalIncidents}
              </h3>
              <p className="text-[11px] text-slate-500 mt-0.5">Monitored encounters</p>
            </div>
            <div className="w-11 h-11 rounded-xl bg-blue-50 flex items-center justify-center text-[#1554ad]">
              <Shield className="w-5 h-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="rounded-2xl border-rose-100 shadow-xs bg-gradient-to-br from-white to-rose-50/40">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-[11px] font-bold text-rose-600 uppercase tracking-wider flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-rose-500 animate-ping" />
                Active Sessions
              </p>
              <h3 className="text-2xl font-black text-rose-700 mt-1">
                {summary.activeCriticalIncidents}
              </h3>
              <p className="text-[11px] text-rose-500 mt-0.5">Live emergency radar</p>
            </div>
            <div className="w-11 h-11 rounded-xl bg-rose-100 flex items-center justify-center text-rose-600">
              <Radio className="w-5 h-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="rounded-2xl border-slate-200 shadow-xs bg-white">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-[11px] font-bold text-amber-600 uppercase tracking-wider">
                Crisis Hotspots
              </p>
              <h3 className="text-2xl font-black text-amber-600 mt-1">
                {summary.highRiskHotspotsCount}
              </h3>
              <p className="text-[11px] text-slate-500 mt-0.5">High-frequency corridors</p>
            </div>
            <div className="w-11 h-11 rounded-xl bg-amber-50 flex items-center justify-center text-amber-600">
              <Flame className="w-5 h-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="rounded-2xl border-slate-200 shadow-xs bg-white">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                Avg Dispatch Speed
              </p>
              <h3 className="text-2xl font-black text-slate-800 mt-1">
                {summary.avgResponseTimeMinutes} <span className="text-sm font-normal text-slate-500">min</span>
              </h3>
              <p className="text-[11px] text-slate-500 mt-0.5">Attorney join latency</p>
            </div>
            <div className="w-11 h-11 rounded-xl bg-indigo-50 flex items-center justify-center text-indigo-600">
              <Clock className="w-5 h-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="rounded-2xl border-slate-200 shadow-xs bg-white col-span-2 md:col-span-1">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                De-escalation
              </p>
              <h3 className="text-2xl font-black text-emerald-600 mt-1">
                {summary.deEscalationRate}%
              </h3>
              <p className="text-[11px] text-slate-500 mt-0.5">Safe resolution rate</p>
            </div>
            <div className="w-11 h-11 rounded-xl bg-emerald-50 flex items-center justify-center text-emerald-600">
              <CheckCircle2 className="w-5 h-5" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filter Toolbar */}
      <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-xs flex flex-wrap items-center justify-between gap-3">
        <div className="flex flex-wrap items-center gap-3">
          {/* Timeframe */}
          <div className="flex items-center gap-1.5">
            <span className="text-xs font-semibold text-slate-500">Period:</span>
            <Select value={timeframe} onValueChange={setTimeframe}>
              <SelectTrigger className="h-8 w-32 rounded-xl text-xs bg-slate-50 border-slate-200">
                <SelectValue placeholder="Period" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="24h">Last 24 Hours</SelectItem>
                <SelectItem value="7d">Last 7 Days</SelectItem>
                <SelectItem value="30d">Last 30 Days</SelectItem>
                <SelectItem value="all">All Historical</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Category Filter */}
          <div className="flex items-center gap-1.5">
            <span className="text-xs font-semibold text-slate-500">Type:</span>
            <Select value={categoryFilter} onValueChange={setCategoryFilter}>
              <SelectTrigger className="h-8 w-44 rounded-xl text-xs bg-slate-50 border-slate-200">
                <SelectValue placeholder="Incident Type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="ALL">All Categories</SelectItem>
                <SelectItem value="ENCOUNTER">Police Encounters</SelectItem>
                <SelectItem value="EMERGENCY">Emergency Calls</SelectItem>
                <SelectItem value="CONSULTATION">Legal Consultations</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Status Filter */}
          <div className="flex items-center gap-1.5">
            <span className="text-xs font-semibold text-slate-500">Status:</span>
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="h-8 w-36 rounded-xl text-xs bg-slate-50 border-slate-200">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="ALL">All Status</SelectItem>
                <SelectItem value="ACTIVE">Live Active</SelectItem>
                <SelectItem value="COMPLETED">Resolved / Past</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>

        {/* Total Display */}
        <div className="text-xs text-slate-500 font-medium">
          Showing <span className="font-bold text-slate-800">{incidents.length}</span> incident points across{" "}
          <span className="font-bold text-slate-800">{hotspots.length}</span> calculated clusters
        </div>
      </div>

      {/* Main Map & Intelligence Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left: Interactive Tactical Map (8 Cols) */}
        <div className="lg:col-span-8 flex flex-col gap-4">
          <div
            className="relative rounded-2xl overflow-hidden border border-slate-200 shadow-sm bg-slate-100"
            style={{ height: 600 }}
          >
            <RiskRealMap
              layers={layers}
              incidents={incidents}
              hotspots={hotspots}
              responderStations={responderStations}
              selectedCoords={selectedCoords}
              onSelectLocation={(lat, lng) => {
                setSelectedCoords({ lat, lng });
              }}
              onInspectIncident={(inc) => {
                setInspectedIncident(inc);
              }}
              centerTarget={centerTarget}
            />

            {/* Floating Layer Toggle Panel */}
            <div className="absolute top-4 left-4 bg-white/95 backdrop-blur-md rounded-xl shadow-lg border border-slate-100 p-3.5 flex flex-col gap-2 min-w-[190px] z-10">
              <div className="flex items-center gap-1.5 text-xs font-bold text-slate-800 mb-0.5">
                <Layers className="w-3.5 h-3.5 text-[#1554ad]" />
                Tactical Layers
              </div>
              {Object.entries(layers).map(([key, checked]) => (
                <label
                  key={key}
                  className="flex items-center gap-2 cursor-pointer select-none text-xs text-slate-700 hover:text-slate-900 transition-colors"
                >
                  <input
                    type="checkbox"
                    checked={checked}
                    onChange={() => toggleLayer(key)}
                    className="rounded border-slate-300 text-[#1554ad] focus:ring-[#1554ad] w-3.5 h-3.5"
                  />
                  <span>{key}</span>
                </label>
              ))}
            </div>

            {/* Floating Zoom & Center Controls */}
            <div className="absolute bottom-16 right-4 flex flex-col gap-1.5 z-10">
              <button
                onClick={() => setCenterTarget([40.7350, -73.9750])}
                title="Recenter Radar"
                className="w-9 h-9 bg-white/95 backdrop-blur-sm rounded-xl shadow-md flex items-center justify-center text-slate-600 hover:text-[#1554ad] hover:bg-white transition-all border border-slate-100"
              >
                <Target className="w-4 h-4" />
              </button>
            </div>

            {/* Floating Map Legend */}
            <div className="absolute bottom-4 left-4 flex flex-wrap items-center gap-3 bg-white/90 backdrop-blur-md rounded-xl px-3.5 py-2 shadow-md border border-slate-100 z-10">
              <div className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-rose-500 animate-ping" />
                <span className="text-[10px] font-bold text-slate-700">Active Alert</span>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-amber-500" />
                <span className="text-[10px] font-bold text-slate-700">Encounter</span>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-[#1554ad]" />
                <span className="text-[10px] font-bold text-slate-700">Consultation</span>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-teal-500" />
                <span className="text-[10px] font-bold text-slate-700">Precinct / Defense</span>
              </div>
            </div>
          </div>

          {/* Quick Recent Incidents Strip */}
          <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-xs">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-xs font-bold text-slate-700 uppercase tracking-wider flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5 text-[#1554ad]" />
                Latest Incident Telemetry Logs
              </h3>
              <Link
                href="/call-history"
                className="text-xs text-[#1554ad] font-semibold hover:underline flex items-center gap-1"
              >
                View Full Audit Logs <ChevronRight className="w-3 h-3" />
              </Link>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              {incidents.slice(0, 3).map((inc) => (
                <div
                  key={inc.id}
                  onClick={() => {
                    setCenterTarget([inc.latitude, inc.longitude]);
                    setInspectedIncident(inc);
                  }}
                  className="p-3 rounded-xl border border-slate-100 bg-slate-50/60 hover:bg-slate-100/80 cursor-pointer transition-all flex flex-col justify-between gap-2"
                >
                  <div className="flex items-center justify-between">
                    <span
                      className={`text-[9px] font-extrabold px-1.5 py-0.5 rounded ${
                        inc.status === "ACTIVE"
                          ? "bg-rose-100 text-rose-700 animate-pulse"
                          : inc.category === "EMERGENCY"
                          ? "bg-red-100 text-red-700"
                          : inc.category === "ENCOUNTER"
                          ? "bg-amber-100 text-amber-700"
                          : "bg-blue-100 text-blue-700"
                      }`}
                    >
                      {inc.status === "ACTIVE" ? "ACTIVE" : inc.category}
                    </span>
                    <span className="text-[10px] text-slate-400">
                      {new Date(inc.createdAt).toLocaleDateString()}
                    </span>
                  </div>
                  <div>
                    <h4 className="text-xs font-bold text-slate-800 line-clamp-1">{inc.topic}</h4>
                    <p className="text-[11px] text-slate-500 line-clamp-1 mt-0.5 flex items-center gap-1">
                      <MapPin className="w-3 h-3 shrink-0" />
                      {inc.locationAddress}
                    </p>
                  </div>
                  <div className="text-[10px] text-slate-600 flex items-center justify-between border-t border-slate-200/60 pt-1.5">
                    <span>{inc.citizenName}</span>
                    <span className="font-semibold text-[#1554ad]">Inspect &rarr;</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Right: Tactical Analytics & Hotspots Sidebar (4 Cols) */}
        <div className="lg:col-span-4 flex flex-col gap-4">
          {/* Selected Zone Intelligence Inspector */}
          <Card className="rounded-2xl border-slate-200 shadow-xs bg-white overflow-hidden">
            <CardHeader className="p-4 pb-2 border-b border-slate-100 bg-slate-50/50">
              <div className="flex items-center justify-between">
                <CardTitle className="text-xs font-bold uppercase tracking-wider text-slate-700 flex items-center gap-1.5">
                  <Target className="w-4 h-4 text-[#1554ad]" />
                  Inspected Sector Dossier
                </CardTitle>
                {selectedCoords && (
                  <Badge
                    className={`text-[10px] font-bold ${
                      inspectedZone?.riskLevel === "CRITICAL"
                        ? "bg-rose-100 text-rose-700 border-rose-200"
                        : inspectedZone?.riskLevel === "HIGH"
                        ? "bg-amber-100 text-amber-700 border-amber-200"
                        : "bg-blue-100 text-blue-700 border-blue-200"
                    }`}
                  >
                    {inspectedZone?.riskLevel || "NORMAL"}
                  </Badge>
                )}
              </div>
            </CardHeader>
            <CardContent className="p-4 flex flex-col gap-3">
              {selectedCoords && inspectedZone ? (
                <>
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-slate-500">Center Coordinates:</span>
                    <span className="font-mono font-medium text-slate-800">
                      {selectedCoords.lat.toFixed(4)}, {selectedCoords.lng.toFixed(4)}
                    </span>
                  </div>

                  <div className="flex items-center justify-between text-xs">
                    <span className="text-slate-500">Monitored Perimeter:</span>
                    <span className="font-medium text-slate-800">5.0 km Radius</span>
                  </div>

                  {/* Threat Score Bar */}
                  <div className="flex flex-col gap-1.5 py-2 border-y border-slate-100">
                    <div className="flex items-center justify-between text-xs">
                      <span className="font-semibold text-slate-700">Threat & Density Index</span>
                      <span className="font-bold text-slate-900">{inspectedZone.riskScore} / 100</span>
                    </div>
                    <div className="w-full bg-slate-100 h-2 rounded-full overflow-hidden">
                      <div
                        className={`h-full rounded-full ${
                          inspectedZone.riskScore >= 70
                            ? "bg-rose-600"
                            : inspectedZone.riskScore >= 45
                            ? "bg-amber-500"
                            : "bg-[#1554ad]"
                        }`}
                        style={{ width: `${inspectedZone.riskScore}%` }}
                      />
                    </div>
                  </div>

                  <div className="text-xs text-slate-600">
                    <span className="font-bold text-slate-900">{inspectedZone.incidentCount}</span> incidents detected in this perimeter:
                  </div>

                  {/* Incidents within radius */}
                  <div className="flex flex-col gap-2 max-h-48 overflow-y-auto pr-1">
                    {inspectedZone.incidents.length > 0 ? (
                      inspectedZone.incidents.slice(0, 5).map((inc) => (
                        <div
                          key={inc.id}
                          onClick={() => setInspectedIncident(inc)}
                          className="p-2 rounded-lg bg-slate-50 hover:bg-slate-100 border border-slate-100 cursor-pointer text-xs flex items-center justify-between transition-colors"
                        >
                          <div className="overflow-hidden">
                            <p className="font-medium text-slate-800 truncate">{inc.topic}</p>
                            <p className="text-[10px] text-slate-400 truncate">{inc.citizenName}</p>
                          </div>
                          <span className="text-[10px] font-bold text-[#1554ad] shrink-0">View</span>
                        </div>
                      ))
                    ) : (
                      <p className="text-xs text-slate-400 italic">No incidents recorded in this perimeter.</p>
                    )}
                  </div>
                </>
              ) : (
                <div className="text-center py-6 text-slate-400 text-xs">
                  <Compass className="w-8 h-8 mx-auto mb-2 text-slate-300" />
                  Click anywhere on the map or click a hotspot below to inspect localized risk telemetry.
                </div>
              )}
            </CardContent>
          </Card>

          {/* Top High-Risk Hotspots Leaderboard */}
          <Card className="rounded-2xl border-slate-200 shadow-xs bg-white">
            <CardHeader className="p-4 pb-2 border-b border-slate-100">
              <CardTitle className="text-xs font-bold uppercase tracking-wider text-slate-700 flex items-center gap-1.5">
                <Flame className="w-4 h-4 text-amber-500" />
                Priority Crisis Hotspots
              </CardTitle>
            </CardHeader>
            <CardContent className="p-4 flex flex-col gap-2.5">
              {hotspots.length > 0 ? (
                hotspots.slice(0, 5).map((h, index) => (
                  <div
                    key={h.id}
                    onClick={() => handleFlyToHotspot(h)}
                    className="p-3 rounded-xl border border-slate-100 bg-slate-50/50 hover:bg-slate-100 hover:border-slate-200 cursor-pointer transition-all flex items-center justify-between"
                  >
                    <div className="flex items-center gap-2.5 overflow-hidden">
                      <span className="w-5 h-5 rounded-full bg-slate-200 text-slate-700 flex items-center justify-center text-[10px] font-bold shrink-0">
                        {index + 1}
                      </span>
                      <div className="overflow-hidden">
                        <h4 className="text-xs font-bold text-slate-800 truncate">{h.name}</h4>
                        <p className="text-[10px] text-slate-500">
                          {h.incidentCount} calls &middot; {h.emergencyCount} emergencies
                        </p>
                      </div>
                    </div>
                    <Badge
                      className={`text-[9px] font-bold shrink-0 ${
                        h.riskLevel === "CRITICAL"
                          ? "bg-rose-100 text-rose-700 border-rose-200"
                          : h.riskLevel === "HIGH"
                          ? "bg-amber-100 text-amber-700 border-amber-200"
                          : "bg-blue-100 text-blue-700 border-blue-200"
                      }`}
                    >
                      {h.riskLevel}
                    </Badge>
                  </div>
                ))
              ) : (
                <p className="text-xs text-slate-400 py-4 text-center">No active hotspots identified.</p>
              )}
            </CardContent>
          </Card>

          {/* Incident Category Distribution */}
          <Card className="rounded-2xl border-slate-200 shadow-xs bg-white">
            <CardHeader className="p-4 pb-2 border-b border-slate-100">
              <CardTitle className="text-xs font-bold uppercase tracking-wider text-slate-700 flex items-center gap-1.5">
                <Activity className="w-4 h-4 text-[#1554ad]" />
                Encounter Distribution
              </CardTitle>
            </CardHeader>
            <CardContent className="p-4 flex flex-col gap-3">
              {/* Encounter */}
              <div className="flex flex-col gap-1">
                <div className="flex justify-between text-xs font-medium">
                  <span className="text-slate-600 flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-amber-500" />
                    Police Encounters
                  </span>
                  <span className="font-bold text-slate-800">
                    {data?.categoryDistribution.encounter.count || 0} ({data?.categoryDistribution.encounter.percentage || 0}%)
                  </span>
                </div>
                <div className="w-full bg-slate-100 h-1.5 rounded-full overflow-hidden">
                  <div
                    className="bg-amber-500 h-full rounded-full"
                    style={{ width: `${data?.categoryDistribution.encounter.percentage || 0}%` }}
                  />
                </div>
              </div>

              {/* Emergency */}
              <div className="flex flex-col gap-1">
                <div className="flex justify-between text-xs font-medium">
                  <span className="text-slate-600 flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-rose-500" />
                    Emergencies & Crises
                  </span>
                  <span className="font-bold text-slate-800">
                    {data?.categoryDistribution.emergency.count || 0} ({data?.categoryDistribution.emergency.percentage || 0}%)
                  </span>
                </div>
                <div className="w-full bg-slate-100 h-1.5 rounded-full overflow-hidden">
                  <div
                    className="bg-rose-500 h-full rounded-full"
                    style={{ width: `${data?.categoryDistribution.emergency.percentage || 0}%` }}
                  />
                </div>
              </div>

              {/* Consultations */}
              <div className="flex flex-col gap-1">
                <div className="flex justify-between text-xs font-medium">
                  <span className="text-slate-600 flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-[#1554ad]" />
                    Legal & MHP Consultations
                  </span>
                  <span className="font-bold text-slate-800">
                    {data?.categoryDistribution.consultation.count || 0} ({data?.categoryDistribution.consultation.percentage || 0}%)
                  </span>
                </div>
                <div className="w-full bg-slate-100 h-1.5 rounded-full overflow-hidden">
                  <div
                    className="bg-[#1554ad] h-full rounded-full"
                    style={{ width: `${data?.categoryDistribution.consultation.percentage || 0}%` }}
                  />
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Area Picker Dialog */}
      <MapPickerDialog
        open={isMapDialogOpen}
        onClose={() => setIsMapDialogOpen(false)}
        onSave={handleLocationSave}
        initialLocation={selectedCoords ? [selectedCoords.lat, selectedCoords.lng] : undefined}
      />

      {/* Incident Detail Modal */}
      {inspectedIncident && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4 animate-in fade-in duration-150">
          <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden flex flex-col">
            {/* Modal Header */}
            <div className="bg-[#1554ad] px-6 py-4 flex items-center justify-between text-white">
              <div className="flex items-center gap-2">
                <ShieldAlert className="w-5 h-5" />
                <h3 className="font-bold text-base">Tactical Incident Dossier</h3>
              </div>
              <button
                onClick={() => setInspectedIncident(null)}
                className="text-blue-200 hover:text-white transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-6 flex flex-col gap-4 text-sm">
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div>
                  <h4 className="font-bold text-slate-900 text-base">{inspectedIncident.topic}</h4>
                  <p className="text-xs text-slate-400 font-mono mt-0.5">Room: {inspectedIncident.roomName}</p>
                </div>
                <Badge
                  className={`text-xs font-bold ${
                    inspectedIncident.status === "ACTIVE"
                      ? "bg-rose-100 text-rose-700"
                      : "bg-emerald-100 text-emerald-700"
                  }`}
                >
                  {inspectedIncident.status}
                </Badge>
              </div>

              <div className="grid grid-cols-2 gap-3 text-xs">
                <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block mb-1">Citizen User</span>
                  <div className="font-bold text-slate-800">{inspectedIncident.citizenName}</div>
                  <div className="text-[11px] text-slate-500">{inspectedIncident.citizenEmail}</div>
                </div>

                <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block mb-1">Category & Type</span>
                  <div className="font-bold text-[#1554ad]">{inspectedIncident.category}</div>
                  <div className="text-[11px] text-slate-500">{inspectedIncident.meetingType} Call</div>
                </div>

                <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block mb-1">Timestamp & Duration</span>
                  <div className="font-bold text-slate-800">
                    {new Date(inspectedIncident.createdAt).toLocaleString()}
                  </div>
                  <div className="text-[11px] text-slate-500">{inspectedIncident.durationMinutes} minutes</div>
                </div>

                <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-100">
                  <span className="text-slate-400 block mb-1">Legal Dispatches</span>
                  <div className="font-bold text-slate-800">
                    {inspectedIncident.attorneyCount} Dispatched
                  </div>
                  <div className="text-[11px] text-emerald-600">Active De-escalation</div>
                </div>
              </div>

              <div className="p-3 rounded-xl bg-slate-50 border border-slate-100 flex items-start gap-2 text-xs">
                <MapPin className="w-4 h-4 text-[#1554ad] shrink-0 mt-0.5" />
                <div>
                  <span className="font-semibold text-slate-800 block">Incident Location Address</span>
                  <span className="text-slate-600">{inspectedIncident.locationAddress}</span>
                  <span className="text-[11px] text-slate-400 font-mono block mt-1">
                    GPS: {inspectedIncident.latitude}, {inspectedIncident.longitude}
                  </span>
                </div>
              </div>
            </div>

            {/* Modal Footer */}
            <div className="px-6 py-3.5 bg-slate-50 border-t border-slate-100 flex items-center justify-between">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setInspectedIncident(null)}
                className="rounded-xl text-xs"
              >
                Close Dossier
              </Button>
              <div className="flex gap-2">
                {inspectedIncident.status === "ACTIVE" ? (
                  <Link href="/live-call-monitoring">
                    <Button size="sm" className="bg-rose-600 hover:bg-rose-700 text-white rounded-xl text-xs gap-1">
                      <Radio className="w-3.5 h-3.5 animate-pulse" />
                      Open Live Call
                    </Button>
                  </Link>
                ) : (
                  <Link href="/call-history">
                    <Button size="sm" className="bg-[#1554ad] hover:bg-[#11438a] text-white rounded-xl text-xs gap-1">
                      <Clock className="w-3.5 h-3.5" />
                      View in Call History
                    </Button>
                  </Link>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
