"use client";

import React, { useState, useEffect } from "react";
import {
  MapPin,
  Clock,
  Users,
  Shield,
  Scale,
  Video,
  Radio,
  RefreshCw,
  Loader2,
  AlertCircle,
  PhoneOff,
  Copy,
  Eye,
  X,
  Volume2,
  Share2,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useMeetings, Meeting, MeetingUser } from "@/hooks/useMeetings";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/context/ToastContext";
import api from "@/lib/api";

function getUserInfo(user: MeetingUser | string | undefined): { name: string; email: string; phone?: string; id?: string } {
  if (!user) return { name: "Unknown", email: "—" };
  if (typeof user === "string") return { name: "User", email: user, id: user };
  return {
    name: user.name || "Unknown",
    email: user.email || "—",
    phone: user.phoneNumber,
    id: user._id,
  };
}

function getTimeAgo(dateStr?: string) {
  if (!dateStr) return "Just now";
  const diffMs = Date.now() - new Date(dateStr).getTime();
  const diffMins = Math.floor(diffMs / 60000);
  if (diffMins < 1) return "Just now";
  if (diffMins < 60) return `${diffMins}m ago`;
  const diffHours = Math.floor(diffMins / 60);
  return `${diffHours}h ago`;
}

export default function LiveCallMonitoringPage() {
  const { activeMeetings, loadingActive, errorActive, refetchActive } = useMeetings();
  const { toast } = useToast();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [endCallConfirmOpen, setEndCallConfirmOpen] = useState(false);
  const [endingCall, setEndingCall] = useState(false);
  const [activeParticipantModal, setActiveParticipantModal] = useState<{ title: string; user: { name: string; email: string; phone?: string; id?: string } } | null>(null);
  const [currentTime, setCurrentTime] = useState(0);

  // Live seconds ticker
  useEffect(() => {
    setCurrentTime(Date.now());
    const timer = setInterval(() => setCurrentTime(Date.now()), 1000);
    return () => clearInterval(timer);
  }, []);

  const selected = activeMeetings.find((m) => m._id === selectedId) || activeMeetings[0] || null;

  const citizenInfo = selected ? getUserInfo(selected.userId) : null;
  const attorneyInfo =
    selected && selected.joinedAttorneys && selected.joinedAttorneys.length > 0
      ? getUserInfo(selected.joinedAttorneys[0])
      : null;

  const calculateLiveDuration = (dateStr?: string) => {
    if (!dateStr) return "00:00";
    const diffSec = Math.floor((currentTime - new Date(dateStr).getTime()) / 1000);
    if (diffSec < 0) return "00:00";
    const mins = Math.floor(diffSec / 60).toString().padStart(2, "0");
    const secs = (diffSec % 60).toString().padStart(2, "0");
    return `${mins}:${secs}`;
  };

  const handleEndCall = async () => {
    if (!selected) return;
    setEndingCall(true);
    try {
      await api.post(`/meeting/${selected._id}/end`, { reason: "Admin terminated call" });
      toast.success("Call Ended", `Encounter room ${selected.roomName || selected._id} has been ended.`);
      setEndCallConfirmOpen(false);
      refetchActive();
    } catch (err: any) {
      toast.error("Failed to end call", err?.message);
    } finally {
      setEndingCall(false);
    }
  };

  const copyIncidentDetails = () => {
    if (!selected) return;
    const info = `Room: ${selected.roomName || selected._id}\nCitizen: ${citizenInfo?.name}\nStatus: ${selected.status}\nLocation: ${selected.locationAddress || "GPS Coordinates"}`;
    navigator.clipboard.writeText(info);
    toast.success("Copied to clipboard", "Encounter details copied.");
  };

  return (
    <div className="flex flex-col gap-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-3">
            <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">
              Live Call Monitoring
            </h1>
            {activeMeetings.length > 0 && (
              <span className="flex items-center gap-1.5 bg-red-100 text-red-700 text-xs font-bold px-3 py-1 rounded-full animate-pulse">
                <Radio className="w-3.5 h-3.5" />
                {activeMeetings.length} ACTIVE NOW
              </span>
            )}
          </div>
          <p className="text-slate-500 text-sm mt-0.5">
            Real-time active video calls, citizen encounters, and emergency monitoring.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={refetchActive}
            disabled={loadingActive}
            className="rounded-xl gap-2 text-xs"
          >
            <RefreshCw className={cn("w-3.5 h-3.5", loadingActive && "animate-spin")} />
            Refresh
          </Button>
        </div>
      </div>

      {errorActive && (
        <div className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm">
          <AlertCircle className="w-4 h-4 flex-shrink-0" />
          {errorActive}
        </div>
      )}

      {loadingActive && activeMeetings.length === 0 ? (
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-16 flex flex-col items-center justify-center gap-3 text-slate-400">
          <Loader2 className="w-8 h-8 animate-spin text-[#1554ad]" />
          <p className="font-medium text-slate-600">Connecting to live dispatch encounters...</p>
        </div>
      ) : activeMeetings.length === 0 ? (
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-16 flex flex-col items-center justify-center text-center gap-4">
          <div className="w-16 h-16 bg-blue-50 text-[#1554ad] rounded-2xl flex items-center justify-center">
            <Radio className="w-8 h-8" />
          </div>
          <h3 className="text-lg font-bold text-slate-800">No Active Calls Right Now</h3>
          <p className="text-sm text-slate-500 max-w-md">
            When a citizen or responder initiates an emergency encounter or consultation, it will appear here in real-time with live audio/video telemetry.
          </p>
          <Button variant="outline" size="sm" onClick={refetchActive} className="rounded-xl text-xs gap-1.5">
            <RefreshCw className="w-3.5 h-3.5" /> Check Again
          </Button>
        </div>
      ) : (
        <div className="flex flex-col lg:flex-row gap-5 items-start">
          {/* Left: Active Incidents list */}
          <div className="w-full lg:w-[360px] shrink-0 bg-white rounded-2xl border border-slate-100 shadow-sm p-5 flex flex-col gap-4">
            <div className="flex items-center justify-between">
              <h2 className="font-bold text-slate-800 text-base">Active Calls</h2>
              <span className="bg-blue-100 text-[#1554ad] text-xs font-semibold px-3 py-1 rounded-full">
                {activeMeetings.length} Ongoing
              </span>
            </div>

            <div className="flex flex-col gap-3">
              {activeMeetings.map((meeting) => {
                const isSelected = selected && selected._id === meeting._id;
                const user = getUserInfo(meeting.userId);
                return (
                  <button
                    key={meeting._id}
                    onClick={() => setSelectedId(meeting._id)}
                    className={cn(
                      "w-full text-left rounded-xl border p-4 flex flex-col gap-2 transition-all cursor-pointer",
                      isSelected
                        ? "border-[#1554ad] bg-blue-50/50 shadow-md shadow-[#1554ad]/10"
                        : "border-slate-100 hover:border-slate-200 hover:bg-slate-50"
                    )}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-bold px-2 py-0.5 rounded-md bg-blue-100 text-[#1554ad]">
                          {meeting.category || "ENCOUNTER"}
                        </span>
                        <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                      </div>
                      <span className="text-xs text-slate-400">
                        {getTimeAgo(meeting.startTime || meeting.createdAt)}
                      </span>
                    </div>

                    <p className="font-bold text-slate-800 text-base">{user.name}</p>

                    <div className="flex items-center gap-4 text-xs text-slate-500">
                      <span className="flex items-center gap-1 truncate max-w-[180px]">
                        <MapPin className="w-3 h-3 flex-shrink-0" />
                        {meeting.locationAddress || "GPS Active"}
                      </span>
                      <span className="flex items-center gap-1 shrink-0 font-mono font-medium text-emerald-600">
                        <Clock className="w-3 h-3" />
                        {calculateLiveDuration(meeting.startTime || meeting.createdAt)}
                      </span>
                    </div>

                    <div className="flex items-center gap-2 flex-wrap mt-1">
                      <span className="text-xs font-semibold px-2 py-0.5 rounded-md bg-emerald-100 text-emerald-600">
                        Streaming
                      </span>
                      {meeting.joinedAttorneys && meeting.joinedAttorneys.length > 0 && (
                        <span className="text-xs font-semibold px-2 py-0.5 rounded-md bg-purple-100 text-purple-700">
                          Attorney Joined
                        </span>
                      )}
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Right: Selected Encounter Live Monitor & Controls */}
          {selected && (
            <div className="flex-1 w-full bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
              {/* Header */}
              <div className="bg-[#1554ad] px-6 py-4 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
                <div>
                  <div className="flex items-center gap-2 text-white">
                    <span className="w-2.5 h-2.5 rounded-full bg-red-400 animate-ping" />
                    <h2 className="font-bold text-lg">
                      Room: {selected.roomName || selected._id.slice(-6).toUpperCase()}
                    </h2>
                  </div>
                  <p className="text-blue-200 text-xs mt-0.5">
                    {selected.topic || "Emergency Citizen Encounter Call"}
                  </p>
                </div>

                <div className="flex items-center gap-2">
                  <div className="flex items-center gap-1.5 bg-black/20 text-white px-3 py-1.5 rounded-xl font-mono text-xs">
                    <Clock className="w-3.5 h-3.5 text-emerald-300" />
                    <span>Duration: {calculateLiveDuration(selected.startTime || selected.createdAt)}</span>
                  </div>

                  <Button
                    variant="outline"
                    size="sm"
                    onClick={copyIncidentDetails}
                    className="rounded-xl border-white/20 bg-white/10 hover:bg-white/20 text-white text-xs h-8"
                  >
                    <Copy className="w-3.5 h-3.5 mr-1" />
                    Copy Info
                  </Button>

                  <Button
                    size="sm"
                    onClick={() => setEndCallConfirmOpen(true)}
                    className="rounded-xl bg-red-600 hover:bg-red-700 text-white text-xs h-8 gap-1 shadow-md shadow-red-900/20"
                  >
                    <PhoneOff className="w-3.5 h-3.5" />
                    End Call
                  </Button>
                </div>
              </div>

              <div className="p-6 flex flex-col gap-6">
                {/* Simulated Telemetry Feed Box */}
                <div className="bg-slate-900 rounded-2xl p-6 text-white relative overflow-hidden flex flex-col justify-between min-h-[200px]">
                  <div className="flex items-center justify-between z-10">
                    <div className="flex items-center gap-2">
                      <Badge className="bg-red-500/80 hover:bg-red-500 border-0 text-[10px] uppercase font-bold tracking-wider">
                        ● LIVE STREAM
                      </Badge>
                      <span className="text-xs text-slate-400 font-mono">
                        {selected.roomName || selected._id}
                      </span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-emerald-400 flex items-center gap-1">
                        <Volume2 className="w-3.5 h-3.5" /> Audio Normal
                      </span>
                      <span className="text-xs bg-slate-800 text-slate-300 px-2.5 py-1 rounded-lg">
                        720p HD
                      </span>
                    </div>
                  </div>

                  {/* Audio Waveform simulation */}
                  <div className="my-6 flex items-center justify-center gap-1">
                    {[40, 65, 30, 80, 50, 95, 45, 70, 35, 85, 60, 40, 75, 55, 90, 30, 65, 45].map((h, i) => (
                      <div
                        key={i}
                        className="w-1.5 bg-blue-400/80 rounded-full animate-pulse"
                        style={{
                          height: `${Math.max(12, (h * ((i % 3) + 1)) % 60)}px`,
                          animationDelay: `${i * 0.1}s`,
                        }}
                      />
                    ))}
                  </div>

                  <div className="flex items-center justify-between text-xs text-slate-400 border-t border-slate-800 pt-3 z-10">
                    <span>Initiated: {selected.startTime ? new Date(selected.startTime).toLocaleTimeString() : "Ongoing"}</span>
                    <span>Host: {citizenInfo?.name}</span>
                    <span>Participants: {(selected.joinedAttorneys?.length || 0) + 1}</span>
                  </div>
                </div>

                {/* Citizen & Attorney Info Cards */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {/* Citizen Card */}
                  <div className="rounded-xl border border-slate-100 bg-slate-50/50 p-4 hover:border-slate-200 transition-colors">
                    <div className="flex items-center justify-between text-slate-500 text-xs font-semibold uppercase tracking-wide mb-3">
                      <span className="flex items-center gap-1.5">
                        <Users className="w-4 h-4 text-[#1554ad]" />
                        Citizen / Caller
                      </span>
                      {citizenInfo && (
                        <button
                          onClick={() =>
                            setActiveParticipantModal({ title: "Citizen Details", user: citizenInfo })
                          }
                          className="text-xs text-[#1554ad] hover:underline font-medium flex items-center gap-1 cursor-pointer lowercase"
                        >
                          <Eye className="w-3 h-3" /> view full
                        </button>
                      )}
                    </div>
                    <div className="flex items-center gap-3">
                      <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-500 to-[#1554ad] flex items-center justify-center text-white font-bold text-sm shrink-0">
                        {citizenInfo?.name.slice(0, 2).toUpperCase()}
                      </div>
                      <div className="min-w-0">
                        <p className="font-bold text-slate-800 truncate">{citizenInfo?.name}</p>
                        <p className="text-xs text-slate-500 truncate">{citizenInfo?.email}</p>
                        {citizenInfo?.phone && (
                          <p className="text-xs text-slate-600 font-mono mt-0.5">{citizenInfo?.phone}</p>
                        )}
                        <p className="text-xs text-slate-400 flex items-center gap-1 mt-1 truncate">
                          <MapPin className="w-3 h-3 shrink-0" />
                          {selected.locationAddress || "GPS Coordinates Active"}
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* Responding Attorney Card */}
                  <div className="rounded-xl border border-slate-100 bg-slate-50/50 p-4 hover:border-slate-200 transition-colors">
                    <div className="flex items-center justify-between text-slate-500 text-xs font-semibold uppercase tracking-wide mb-3">
                      <span className="flex items-center gap-1.5">
                        <Scale className="w-4 h-4 text-purple-600" />
                        Assigned Attorney
                      </span>
                      {attorneyInfo && (
                        <button
                          onClick={() =>
                            setActiveParticipantModal({ title: "Attorney Details", user: attorneyInfo })
                          }
                          className="text-xs text-[#1554ad] hover:underline font-medium flex items-center gap-1 cursor-pointer lowercase"
                        >
                          <Eye className="w-3 h-3" /> view full
                        </button>
                      )}
                    </div>
                    {attorneyInfo ? (
                      <div className="flex items-center gap-3">
                        <div className="w-12 h-12 rounded-full bg-gradient-to-br from-purple-500 to-indigo-700 flex items-center justify-center text-white font-bold text-sm shrink-0">
                          {attorneyInfo.name.slice(0, 2).toUpperCase()}
                        </div>
                        <div className="min-w-0">
                          <p className="font-bold text-slate-800 truncate">{attorneyInfo.name}</p>
                          <p className="text-xs text-slate-500 truncate">{attorneyInfo.email}</p>
                          <span className="inline-block mt-1 text-xs font-semibold px-2 py-0.5 rounded-md bg-purple-100 text-purple-700">
                            Active in Session
                          </span>
                        </div>
                      </div>
                    ) : (
                      <div className="flex items-center gap-3 text-slate-400 py-3">
                        <Scale className="w-8 h-8 opacity-40" />
                        <div>
                          <p className="text-sm font-medium text-slate-700">Awaiting Attorney Claim</p>
                          <p className="text-xs text-slate-400">No attorney has joined the call yet.</p>
                        </div>
                      </div>
                    )}
                  </div>
                </div>

                {/* Technical Encounter Telemetry */}
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                  <div className="rounded-xl border p-4 flex flex-col items-center gap-1 bg-emerald-50 border-emerald-100">
                    <Video className="w-6 h-6 text-emerald-600 mb-1" />
                    <p className="text-xs font-semibold text-slate-600">Call Status</p>
                    <p className="text-xs font-bold text-emerald-700">{selected.status}</p>
                  </div>

                  <div className="rounded-xl border p-4 flex flex-col items-center gap-1 bg-blue-50 border-blue-100">
                    <Shield className="w-6 h-6 text-[#1554ad] mb-1" />
                    <p className="text-xs font-semibold text-slate-600">Category</p>
                    <p className="text-xs font-bold text-[#1554ad]">{selected.category}</p>
                  </div>

                  <div className="rounded-xl border p-4 flex flex-col items-center gap-1 bg-purple-50 border-purple-100">
                    <Scale className="w-6 h-6 text-purple-600 mb-1" />
                    <p className="text-xs font-semibold text-slate-600">Responders</p>
                    <p className="text-xs font-bold text-purple-700">
                      {selected.joinedAttorneys?.length ? "Connected" : "Dispatched"}
                    </p>
                  </div>

                  <div className="rounded-xl border border-red-100 bg-red-50 p-4 flex flex-col items-center gap-1">
                    <Radio className="w-6 h-6 text-red-500 animate-pulse mb-1" />
                    <p className="text-xs font-semibold text-slate-600">Stream</p>
                    <p className="text-xs font-bold text-red-600">Encrypted Live</p>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* End Call Confirmation Dialog */}
      {endCallConfirmOpen && selected && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={() => setEndCallConfirmOpen(false)} />
          <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6 z-10 space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center">
                <PhoneOff className="w-5 h-5 text-red-600" />
              </div>
              <div>
                <h3 className="font-bold text-slate-800">End Live Encounter</h3>
                <p className="text-xs text-slate-500">Room: {selected.roomName || selected._id}</p>
              </div>
            </div>
            <p className="text-sm text-slate-600">
              Are you sure you want to terminate this live encounter call? All participants will be disconnected immediately and the session recorded to history.
            </p>
            <div className="flex gap-3 pt-2">
              <Button
                variant="outline"
                onClick={() => setEndCallConfirmOpen(false)}
                className="flex-1 rounded-xl"
              >
                Cancel
              </Button>
              <Button
                onClick={handleEndCall}
                disabled={endingCall}
                className="flex-1 rounded-xl bg-red-600 hover:bg-red-700 text-white"
              >
                {endingCall ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : null}
                Terminate Call
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Participant Details Modal */}
      {activeParticipantModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="absolute inset-0 bg-black/40 backdrop-blur-sm"
            onClick={() => setActiveParticipantModal(null)}
          />
          <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6 z-10 space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-slate-800 text-base">{activeParticipantModal.title}</h3>
              <button
                onClick={() => setActiveParticipantModal(null)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
            <div className="bg-slate-50 rounded-xl p-4 space-y-2.5 text-sm">
              <div>
                <p className="text-xs text-slate-400">Full Name</p>
                <p className="font-semibold text-slate-800">{activeParticipantModal.user.name}</p>
              </div>
              <div>
                <p className="text-xs text-slate-400">Email Address</p>
                <p className="font-semibold text-slate-800">{activeParticipantModal.user.email}</p>
              </div>
              {activeParticipantModal.user.phone && (
                <div>
                  <p className="text-xs text-slate-400">Phone</p>
                  <p className="font-semibold text-slate-800">{activeParticipantModal.user.phone}</p>
                </div>
              )}
            </div>
            <Button
              onClick={() => setActiveParticipantModal(null)}
              className="w-full rounded-xl bg-[#1554ad] hover:bg-[#1554ad]/90 text-white"
            >
              Done
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
