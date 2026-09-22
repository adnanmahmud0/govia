"use client";

import React, { useEffect, useMemo } from "react";
import {
  MapContainer,
  TileLayer,
  Circle,
  Marker,
  Popup,
  Tooltip,
  useMap,
  useMapEvents,
} from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import {
  GeoIncident,
  HotspotCluster,
  ResponderStation,
} from "@/hooks/useRiskMapAnalytics";
import {
  ShieldAlert,
  AlertTriangle,
  Clock,
  MapPin,
  Eye,
  Activity,
  Users,
} from "lucide-react";

interface RiskRealMapProps {
  layers: Record<string, boolean>;
  incidents?: GeoIncident[];
  hotspots?: HotspotCluster[];
  responderStations?: ResponderStation[];
  selectedCoords?: { lat: number; lng: number } | null;
  onSelectLocation?: (lat: number, lng: number) => void;
  onInspectIncident?: (incident: GeoIncident) => void;
  centerTarget?: [number, number] | null;
}

// Custom Leaflet DivIcons using inline SVGs
const createActiveBeaconIcon = () =>
  L.divIcon({
    className: "custom-beacon-icon",
    html: `
      <div style="position:relative; width:34px; height:34px; display:flex; align-items:center; justify-content:center;">
        <span style="position:absolute; width:100%; height:100%; border-radius:50%; background:#ef4444; opacity:0.75; animation: ping 1.5s cubic-bezier(0, 0, 0.2, 1) infinite;"></span>
        <div style="position:relative; width:26px; height:26px; border-radius:50%; background:#dc2626; border:2.5px solid #ffffff; display:flex; align-items:center; justify-content:center; box-shadow:0 4px 10px rgba(220,38,38,0.5);">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
        </div>
      </div>
    `,
    iconSize: [34, 34],
    iconAnchor: [17, 17],
    popupAnchor: [0, -17],
  });

const createEmergencyIcon = () =>
  L.divIcon({
    className: "custom-emergency-icon",
    html: `
      <div style="width:26px; height:26px; border-radius:50%; background:#e11d48; border:2px solid white; display:flex; align-items:center; justify-content:center; box-shadow:0 3px 8px rgba(0,0,0,0.3);">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
      </div>
    `,
    iconSize: [26, 26],
    iconAnchor: [13, 13],
    popupAnchor: [0, -13],
  });

const createEncounterIcon = () =>
  L.divIcon({
    className: "custom-encounter-icon",
    html: `
      <div style="width:26px; height:26px; border-radius:50%; background:#d97706; border:2px solid white; display:flex; align-items:center; justify-content:center; box-shadow:0 3px 8px rgba(0,0,0,0.3);">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
      </div>
    `,
    iconSize: [26, 26],
    iconAnchor: [13, 13],
    popupAnchor: [0, -13],
  });

const createConsultationIcon = () =>
  L.divIcon({
    className: "custom-consultation-icon",
    html: `
      <div style="width:24px; height:24px; border-radius:50%; background:#1554ad; border:2px solid white; display:flex; align-items:center; justify-content:center; box-shadow:0 3px 8px rgba(0,0,0,0.3);">
        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
      </div>
    `,
    iconSize: [24, 24],
    iconAnchor: [12, 12],
    popupAnchor: [0, -12],
  });

const createPrecinctIcon = () =>
  L.divIcon({
    className: "custom-precinct-icon",
    html: `
      <div style="width:26px; height:26px; border-radius:7px; background:#0d9488; border:2px solid white; display:flex; align-items:center; justify-content:center; box-shadow:0 3px 8px rgba(0,0,0,0.3);">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M9 12h6"/><path d="M12 9v6"/></svg>
      </div>
    `,
    iconSize: [26, 26],
    iconAnchor: [13, 13],
    popupAnchor: [0, -13],
  });

const createSelectedMarkerIcon = () =>
  L.divIcon({
    className: "custom-selected-marker",
    html: `
      <div style="position:relative; width:36px; height:36px; display:flex; align-items:center; justify-content:center;">
        <span style="position:absolute; width:100%; height:100%; border-radius:50%; border:2px dashed #4f46e5; animation: spin 4s linear infinite;"></span>
        <div style="width:28px; height:28px; border-radius:50%; background:#4f46e5; border:3px solid white; display:flex; align-items:center; justify-content:center; box-shadow:0 4px 12px rgba(79,70,229,0.5);">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="2" x2="12" y2="6"/><line x1="12" y1="18" x2="12" y2="22"/><line x1="2" y1="12" x2="6" y2="12"/><line x1="18" y1="12" x2="22" y2="12"/></svg>
        </div>
      </div>
    `,
    iconSize: [36, 36],
    iconAnchor: [18, 18],
    popupAnchor: [0, -18],
  });

// Map Controller for smooth fly-to when centerTarget changes
function MapFlyController({ target }: { target?: [number, number] | null }) {
  const map = useMap();
  useEffect(() => {
    if (target) {
      map.flyTo(target, 14, { duration: 1.2 });
    }
  }, [target, map]);
  return null;
}

// Map Click Handler for area selection
function MapClickHandler({ onSelectLocation }: { onSelectLocation?: (lat: number, lng: number) => void }) {
  useMapEvents({
    click(e) {
      if (onSelectLocation) {
        onSelectLocation(e.latlng.lat, e.latlng.lng);
      }
    },
  });
  return null;
}

export default function RiskRealMap({
  layers,
  incidents = [],
  hotspots = [],
  responderStations = [],
  selectedCoords,
  onSelectLocation,
  onInspectIncident,
  centerTarget,
}: RiskRealMapProps) {
  const defaultCenter: [number, number] = [40.7350, -73.9750]; // Greater NYC metro center

  // Pre-instantiated icons
  const activeBeaconIcon = useMemo(() => createActiveBeaconIcon(), []);
  const emergencyIcon = useMemo(() => createEmergencyIcon(), []);
  const encounterIcon = useMemo(() => createEncounterIcon(), []);
  const consultationIcon = useMemo(() => createConsultationIcon(), []);
  const precinctIcon = useMemo(() => createPrecinctIcon(), []);
  const selectedIcon = useMemo(() => createSelectedMarkerIcon(), []);

  return (
    <div className="h-full w-full relative z-0">
      <MapContainer
        center={defaultCenter}
        zoom={12}
        scrollWheelZoom={true}
        zoomControl={false}
        className="h-full w-full z-0 cursor-crosshair"
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        <MapFlyController target={centerTarget} />
        <MapClickHandler onSelectLocation={onSelectLocation} />

        {/* Selected Location Marker & Radius Circle */}
        {selectedCoords && (
          <>
            <Marker position={[selectedCoords.lat, selectedCoords.lng]} icon={selectedIcon}>
              <Popup className="custom-leaflet-popup">
                <div className="p-2 min-w-[200px]">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-indigo-700 uppercase tracking-wide">
                    <MapPin className="w-3.5 h-3.5" /> Inspected Coordinate
                  </div>
                  <p className="text-xs text-slate-600 mt-1 font-mono">
                    {selectedCoords.lat.toFixed(5)}, {selectedCoords.lng.toFixed(5)}
                  </p>
                  <p className="text-[11px] text-slate-500 mt-1">
                    Radius: 5km monitored zone
                  </p>
                </div>
              </Popup>
            </Marker>
            <Circle
              center={[selectedCoords.lat, selectedCoords.lng]}
              radius={5000}
              pathOptions={{
                color: "#4f46e5",
                fillColor: "#6366f1",
                fillOpacity: 0.08,
                dashArray: "6, 6",
                weight: 1.5,
              }}
            />
          </>
        )}

        {/* LAYER 1: Incident Heatmap (density heat circles calculated dynamically) */}
        {layers["Incident Heatmap"] &&
          hotspots.map((h) => {
            const isCritical = h.riskLevel === "CRITICAL";
            const isHigh = h.riskLevel === "HIGH";
            const color = isCritical ? "#ef4444" : isHigh ? "#f97316" : "#3b82f6";
            const fillColor = isCritical ? "#dc2626" : isHigh ? "#ea580c" : "#2563eb";

            return (
              <Circle
                key={`heat-${h.id}`}
                center={h.center}
                radius={h.radiusMeters}
                pathOptions={{
                  color,
                  fillColor,
                  fillOpacity: isCritical ? 0.28 : isHigh ? 0.2 : 0.12,
                  weight: 1.5,
                }}
              >
                <Tooltip direction="top" opacity={0.9}>
                  <div className="text-xs font-semibold">
                    <div className="flex items-center gap-1">
                      <span
                        className={`w-2 h-2 rounded-full ${
                          isCritical ? "bg-red-500" : isHigh ? "bg-orange-500" : "bg-blue-500"
                        }`}
                      />
                      <span>{h.name}</span>
                    </div>
                    <div className="text-[10px] text-slate-500 font-normal">
                      {h.incidentCount} incidents ({h.emergencyCount} emergency) &middot; Risk: {h.riskLevel}
                    </div>
                  </div>
                </Tooltip>
              </Circle>
            );
          })}

        {/* LAYER 2: Crisis Zones (high-risk outer rings) */}
        {layers["Crisis Zones"] &&
          hotspots
            .filter((h) => h.riskLevel === "CRITICAL" || h.riskLevel === "HIGH")
            .map((h) => (
              <Circle
                key={`crisis-${h.id}`}
                center={h.center}
                radius={h.radiusMeters * 1.3}
                pathOptions={{
                  color: "#1554ad",
                  fillColor: "#1554ad",
                  fillOpacity: 0.06,
                  dashArray: "4, 8",
                  weight: 2,
                }}
              />
            ))}

        {/* LAYER 3: Incident Markers (clickable real incident pins) */}
        {layers["Incident Markers"] &&
          incidents.map((inc) => {
            const isActive = inc.status === "ACTIVE";
            let markerIcon = consultationIcon;
            if (isActive) {
              markerIcon = activeBeaconIcon;
            } else if (inc.category === "EMERGENCY") {
              markerIcon = emergencyIcon;
            } else if (inc.category === "ENCOUNTER") {
              markerIcon = encounterIcon;
            }

            return (
              <Marker
                key={`inc-${inc.id}`}
                position={[inc.latitude, inc.longitude]}
                icon={markerIcon}
              >
                <Popup className="custom-leaflet-popup">
                  <div className="p-3 min-w-[240px] max-w-[280px]">
                    {/* Header badge */}
                    <div className="flex items-center justify-between gap-2 mb-2">
                      <span
                        className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                          isActive
                            ? "bg-red-100 text-red-700 animate-pulse"
                            : inc.category === "EMERGENCY"
                            ? "bg-rose-100 text-rose-700"
                            : inc.category === "ENCOUNTER"
                            ? "bg-amber-100 text-amber-700"
                            : "bg-blue-100 text-[#1554ad]"
                        }`}
                      >
                        {isActive ? "LIVE ACTIVE" : inc.category}
                      </span>
                      <span className="text-[10px] text-slate-400 font-mono">
                        {new Date(inc.createdAt).toLocaleTimeString([], {
                          hour: "2-digit",
                          minute: "2-digit",
                        })}
                      </span>
                    </div>

                    <h4 className="text-xs font-bold text-slate-800 line-clamp-1 mb-1">
                      {inc.topic}
                    </h4>

                    <div className="flex items-start gap-1.5 text-[11px] text-slate-500 mb-2">
                      <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0 mt-0.5" />
                      <span className="line-clamp-2">{inc.locationAddress}</span>
                    </div>

                    <div className="grid grid-cols-2 gap-1.5 py-1.5 border-t border-slate-100 text-[10px] text-slate-600 mb-3">
                      <div>
                        <span className="text-slate-400 block">Citizen:</span>
                        <span className="font-medium text-slate-800 line-clamp-1">
                          {inc.citizenName}
                        </span>
                      </div>
                      <div>
                        <span className="text-slate-400 block">Attorneys:</span>
                        <span className="font-medium text-slate-800">
                          {inc.attorneyCount} Dispatched
                        </span>
                      </div>
                    </div>

                    {onInspectIncident && (
                      <button
                        onClick={() => onInspectIncident(inc)}
                        className="w-full flex items-center justify-center gap-1.5 bg-[#1554ad] text-white py-1.5 px-3 rounded-lg text-xs font-semibold hover:bg-[#11438a] transition-colors"
                      >
                        <Eye className="w-3.5 h-3.5" />
                        Inspect Incident
                      </button>
                    )}
                  </div>
                </Popup>
              </Marker>
            );
          })}

        {/* LAYER 4: Officer & Precinct Jurisdictions */}
        {layers["Officer & Precincts"] &&
          responderStations.map((st) => (
            <Marker key={`st-${st.id}`} position={st.coords} icon={precinctIcon}>
              <Popup className="custom-leaflet-popup">
                <div className="p-2.5 min-w-[220px]">
                  <div className="flex items-center gap-1.5 text-xs font-bold text-teal-700 mb-1">
                    <Activity className="w-3.5 h-3.5" />
                    {st.type === "PRECINCT"
                      ? "Police Precinct"
                      : st.type === "LEGAL_AID"
                      ? "Legal Defense Unit"
                      : "MHP Dispatch"}
                  </div>
                  <h4 className="text-xs font-semibold text-slate-800">{st.name}</h4>
                  <p className="text-[11px] text-slate-500 mt-1">{st.address}</p>
                  <div className="mt-2 pt-2 border-t border-slate-100 flex items-center justify-between text-[10px]">
                    <span className="text-slate-500">Jurisdiction: {st.jurisdiction}</span>
                    <span className="font-bold text-teal-700 bg-teal-50 px-1.5 py-0.5 rounded">
                      {st.activeUnits} Units
                    </span>
                  </div>
                </div>
              </Popup>
            </Marker>
          ))}
      </MapContainer>
    </div>
  );
}
