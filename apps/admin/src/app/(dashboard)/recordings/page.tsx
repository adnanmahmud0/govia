"use client";

import React, { useState, useEffect } from "react";
import {
  Video,
  Play,
  Download,
  Copy,
  Trash2,
  RefreshCw,
  Search,
  Filter,
  CheckCircle2,
  AlertTriangle,
  Server,
  Cloud,
  Key,
  Shield,
  Eye,
  EyeOff,
  ExternalLink,
  Clock,
  HardDrive,
  FileVideo,
  Radio,
  Check,
  X,
  Lock,
  Layers,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useRecordings, RecordedMeeting, StorageSettingData } from "@/hooks/useRecordings";
import { useToast } from "@/context/ToastContext";

const PROVIDER_PRESETS: Record<
  string,
  {
    name: string;
    description: string;
    defaultRegion: string;
    defaultEndpoint: string;
    badge?: string;
  }
> = {
  CLOUDFLARE_R2: {
    name: "Cloudflare R2",
    description: "S3-compatible storage with 100% zero egress/download bandwidth fees.",
    defaultRegion: "auto",
    defaultEndpoint: "https://<ACCOUNT_ID>.r2.cloudflarestorage.com",
    badge: "Recommended",
  },
  AWS_S3: {
    name: "Amazon AWS S3",
    description: "Industry-standard object storage across global AWS availability zones.",
    defaultRegion: "us-east-1",
    defaultEndpoint: "",
  },
  DIGITALOCEAN_SPACES: {
    name: "DigitalOcean Spaces",
    description: "Simple, high-performance object storage with built-in CDN distribution.",
    defaultRegion: "nyc3",
    defaultEndpoint: "https://nyc3.digitaloceanspaces.com",
  },
  MINIO: {
    name: "MinIO / Self-Hosted",
    description: "Private high-performance S3-compatible cloud storage deployed on your infrastructure.",
    defaultRegion: "us-east-1",
    defaultEndpoint: "http://localhost:9000",
  },
};

export default function RecordingsPage() {
  const {
    recordings,
    summary,
    meta,
    loadingRecordings,
    settings,
    loadingSettings,
    searchTerm,
    setSearchTerm,
    categoryFilter,
    setCategoryFilter,
    page,
    setPage,
    refetchRecordings,
    saveSettings,
    testConnection,
    deleteRecording,
  } = useRecordings();

  const { toast } = useToast();

  // Active Video Modal
  const [playingVideo, setPlayingVideo] = useState<{
    url: string;
    title: string;
    date: string;
    category: string;
    citizen: string;
  } | null>(null);

  // Form state for Credentials
  const [formData, setFormData] = useState<Partial<StorageSettingData>>({
    provider: "AWS_S3",
    bucket: "",
    region: "us-east-1",
    accessKey: "",
    secretKey: "",
    endpoint: "",
    livekitUrl: "",
    livekitApiKey: "",
    livekitApiSecret: "",
    autoRecordMeetings: true,
  });

  const [showSecretKey, setShowSecretKey] = useState(false);
  const [showLivekitSecret, setShowLivekitSecret] = useState(false);
  const [testingConnection, setTestingConnection] = useState(false);
  const [savingSettings, setSavingSettings] = useState(false);
  const [testResult, setTestResult] = useState<{ success: boolean; message: string } | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  // Synchronize form with loaded settings
  useEffect(() => {
    if (settings) {
      setFormData({
        provider: settings.provider || "AWS_S3",
        bucket: settings.bucket || "",
        region: settings.region || "us-east-1",
        accessKey: settings.accessKey || "",
        secretKey: "",
        endpoint: settings.endpoint || "",
        livekitUrl: settings.livekitUrl || "",
        livekitApiKey: settings.livekitApiKey || "",
        livekitApiSecret: "",
        autoRecordMeetings: settings.autoRecordMeetings ?? true,
      });
    }
  }, [settings]);

  const handleProviderSelect = (provider: any) => {
    const preset = PROVIDER_PRESETS[provider];
    setFormData((prev) => ({
      ...prev,
      provider,
      region: preset?.defaultRegion || prev.region,
      endpoint: preset?.defaultEndpoint || "",
    }));
    setTestResult(null);
  };

  const handleTestConnection = async () => {
    setTestingConnection(true);
    setTestResult(null);
    try {
      const payload = { ...formData };
      if (payload.secretKey && (payload.secretKey.includes("•") || payload.secretKey.includes("*"))) {
        delete payload.secretKey;
      }
      if (payload.livekitApiSecret && (payload.livekitApiSecret.includes("•") || payload.livekitApiSecret.includes("*"))) {
        delete payload.livekitApiSecret;
      }
      const res: any = await testConnection(payload);
      setTestResult({
        success: true,
        message: res?.message || "Storage credentials verified successfully!",
      });
      toast.success("Storage credentials test successful!");
    } catch (err: any) {
      setTestResult({
        success: false,
        message: err?.message || "Connection test failed. Please verify credentials.",
      });
      toast.error(err?.message || "Storage connection test failed");
    } finally {
      setTestingConnection(false);
    }
  };

  const handleSaveSettings = async (e: React.FormEvent) => {
    e.preventDefault();
    setSavingSettings(true);
    try {
      const payload = { ...formData };
      if (payload.secretKey && (payload.secretKey.includes("•") || payload.secretKey.includes("*"))) {
        delete payload.secretKey;
      }
      if (payload.livekitApiSecret && (payload.livekitApiSecret.includes("•") || payload.livekitApiSecret.includes("*"))) {
        delete payload.livekitApiSecret;
      }
      await saveSettings(payload);
      toast.success("Storage and recording credentials saved and applied!");
      setTestResult(null);
    } catch (err: any) {
      toast.error(err?.message || "Failed to save storage settings");
    } finally {
      setSavingSettings(false);
    }
  };

  const handleCopyLink = (url: string) => {
    navigator.clipboard.writeText(url);
    toast.success("Recording link copied to clipboard");
  };

  const handleDelete = async (meetingId: string) => {
    if (!confirm("Are you sure you want to remove this recording from the system?")) return;
    setDeletingId(meetingId);
    try {
      await deleteRecording(meetingId);
      toast.success("Recording removed successfully");
    } catch (err: any) {
      toast.error(err?.message || "Failed to delete recording");
    } finally {
      setDeletingId(null);
    }
  };

  return (
    <div className="flex flex-col gap-6 pb-12">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2.5">
            <h1 className="text-3xl font-bold text-slate-800 tracking-tight">
              Meeting Recordings & Storage
            </h1>
            <Badge
              className={`text-xs font-semibold px-2.5 py-0.5 gap-1.5 ${
                summary?.isConfigured
                  ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                  : "bg-amber-50 text-amber-700 border-amber-200"
              }`}
            >
              <span
                className={`w-2 h-2 rounded-full ${
                  summary?.isConfigured ? "bg-emerald-500" : "bg-amber-500 animate-pulse"
                }`}
              />
              {summary?.isConfigured ? `${summary.provider} Active` : "Setup Required"}
            </Badge>
          </div>
          <p className="text-slate-500 mt-1 text-sm">
            Centralized repository for incident videos, evidence archives, and dynamic cloud storage credentials.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={refetchRecordings}
            disabled={loadingRecordings}
            className="rounded-xl border-slate-200 text-slate-600 gap-1.5 h-9"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loadingRecordings ? "animate-spin text-[#1554ad]" : ""}`} />
            Refresh Library
          </Button>
        </div>
      </div>

      {/* KPI Stats Strip */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card className="rounded-2xl border-slate-200 shadow-xs bg-white">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                Total Recordings
              </p>
              <h3 className="text-2xl font-black text-slate-800 mt-1">
                {summary?.totalRecordings || 0}
              </h3>
              <p className="text-[11px] text-slate-500 mt-0.5">Completed video sessions</p>
            </div>
            <div className="w-11 h-11 rounded-xl bg-blue-50 flex items-center justify-center text-[#1554ad]">
              <Video className="w-5 h-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="rounded-2xl border-slate-200 shadow-xs bg-white">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                Storage Volume
              </p>
              <h3 className="text-2xl font-black text-slate-800 mt-1">
                {summary?.totalSizeMB ? `${summary.totalSizeMB} MB` : "0 MB"}
              </h3>
              <p className="text-[11px] text-slate-500 mt-0.5">Occupied cloud bucket space</p>
            </div>
            <div className="w-11 h-11 rounded-xl bg-indigo-50 flex items-center justify-center text-indigo-600">
              <HardDrive className="w-5 h-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="rounded-2xl border-slate-200 shadow-xs bg-white">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                Total Duration
              </p>
              <h3 className="text-2xl font-black text-slate-800 mt-1">
                {summary?.totalDurationMinutes || 0} <span className="text-sm font-normal text-slate-500">mins</span>
              </h3>
              <p className="text-[11px] text-slate-500 mt-0.5">Recorded footage length</p>
            </div>
            <div className="w-11 h-11 rounded-xl bg-amber-50 flex items-center justify-center text-amber-600">
              <Clock className="w-5 h-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="rounded-2xl border-slate-200 shadow-xs bg-white">
          <CardContent className="p-4 flex items-center justify-between">
            <div>
              <p className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                Active Cloud Bucket
              </p>
              <h3 className="text-lg font-bold text-slate-800 mt-1 truncate max-w-[140px]">
                {summary?.bucket || "Not Configured"}
              </h3>
              <p className="text-[11px] text-emerald-600 mt-0.5 truncate">
                {summary?.provider || "S3 Storage"}
              </p>
            </div>
            <div className="w-11 h-11 rounded-xl bg-emerald-50 flex items-center justify-center text-emerald-600">
              <Cloud className="w-5 h-5" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs defaultValue="library" className="w-full">
        <TabsList className="bg-slate-100 p-1 rounded-xl w-full max-w-md grid grid-cols-2">
          <TabsTrigger
            value="library"
            className="rounded-lg text-xs font-bold py-2 data-[state=active]:bg-white data-[state=active]:text-[#1554ad] data-[state=active]:shadow-xs"
          >
            <Video className="w-3.5 h-3.5 mr-1.5" />
            Recordings Library
          </TabsTrigger>
          <TabsTrigger
            value="storage"
            className="rounded-lg text-xs font-bold py-2 data-[state=active]:bg-white data-[state=active]:text-[#1554ad] data-[state=active]:shadow-xs"
          >
            <Server className="w-3.5 h-3.5 mr-1.5" />
            Storage & Credentials Setup
          </TabsTrigger>
        </TabsList>

        {/* ─── TAB 1: RECORDINGS LIBRARY ───────────────────────────────────────── */}
        <TabsContent value="library" className="mt-4 flex flex-col gap-4">
          {/* Filters Bar */}
          <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-xs flex flex-wrap items-center justify-between gap-3">
            <div className="flex flex-wrap items-center gap-3 w-full sm:w-auto">
              <div className="relative w-full sm:w-72">
                <Input
                  type="text"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  placeholder="Search topic, room, citizen..."
                  className="pl-9 h-9 text-xs rounded-xl bg-slate-50 border-slate-200"
                />
                <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              </div>

              <div className="flex items-center gap-1.5">
                <span className="text-xs font-semibold text-slate-500">Category:</span>
                <Select value={categoryFilter} onValueChange={setCategoryFilter}>
                  <SelectTrigger className="h-9 w-44 rounded-xl text-xs bg-slate-50 border-slate-200">
                    <SelectValue placeholder="All Categories" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="ALL">All Categories</SelectItem>
                    <SelectItem value="ENCOUNTER">Police Encounters</SelectItem>
                    <SelectItem value="EMERGENCY">Emergency Calls</SelectItem>
                    <SelectItem value="CONSULTATION">Consultations</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <span className="text-xs text-slate-500">
              Showing <span className="font-bold text-slate-800">{recordings.length}</span> of{" "}
              <span className="font-bold text-slate-800">{meta?.total || 0}</span> recordings
            </span>
          </div>

          {/* Recordings Grid */}
          {loadingRecordings ? (
            <div className="bg-white rounded-2xl border border-slate-200 p-12 text-center text-slate-400 flex flex-col items-center justify-center gap-2">
              <RefreshCw className="w-6 h-6 animate-spin text-[#1554ad]" />
              <p className="text-sm font-medium">Loading meeting recordings archive...</p>
            </div>
          ) : recordings.length === 0 ? (
            <div className="bg-white rounded-2xl border border-slate-200 p-12 text-center text-slate-400 flex flex-col items-center justify-center gap-3">
              <FileVideo className="w-12 h-12 text-slate-300" />
              <div>
                <h4 className="font-bold text-slate-700 text-sm">No Recordings Found</h4>
                <p className="text-xs text-slate-500 mt-0.5">
                  Recordings will automatically populate here as soon as meetings are recorded via LiveKit Egress.
                </p>
              </div>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {recordings.map((meeting) => {
                const rec = meeting.recordings?.[0];
                const videoUrl = rec?.playUrl || meeting.recordingUrl || "";
                const citizenName = meeting.userId?.name || "Citizen User";
                const attorneyName = meeting.joinedAttorneys?.[0]?.name;

                return (
                  <Card
                    key={meeting._id}
                    className="rounded-2xl border-slate-200 shadow-xs bg-white overflow-hidden hover:border-slate-300 hover:shadow-md transition-all flex flex-col justify-between"
                  >
                    <div>
                      {/* Video Header Card Mockup / Preview Banner */}
                      <div className="relative bg-slate-900 h-36 flex items-center justify-center overflow-hidden group">
                        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/30 to-transparent z-10" />

                        <div className="w-12 h-12 rounded-full bg-white/20 backdrop-blur-md border border-white/40 flex items-center justify-center text-white z-20 group-hover:scale-110 group-hover:bg-[#1554ad] transition-all cursor-pointer shadow-lg"
                          onClick={() => {
                            if (videoUrl) {
                              setPlayingVideo({
                                url: videoUrl,
                                title: meeting.topic,
                                date: new Date(meeting.createdAt).toLocaleString(),
                                category: meeting.category,
                                citizen: citizenName,
                              });
                            } else {
                              toast.error("Video URL is being processed or unavailable");
                            }
                          }}
                        >
                          <Play className="w-5 h-5 fill-white translate-x-0.5" />
                        </div>

                        {/* Badges on Video Preview */}
                        <div className="absolute top-3 left-3 z-20">
                          <Badge
                            className={`text-[9px] font-bold uppercase tracking-wide ${
                              meeting.category === "EMERGENCY"
                                ? "bg-rose-500 text-white"
                                : meeting.category === "ENCOUNTER"
                                ? "bg-amber-500 text-white"
                                : "bg-[#1554ad] text-white"
                            }`}
                          >
                            {meeting.category}
                          </Badge>
                        </div>

                        <div className="absolute top-3 right-3 z-20">
                          <span className="text-[10px] font-mono text-white/90 bg-black/50 px-2 py-0.5 rounded-md backdrop-blur-xs">
                            {meeting.durationMinutes || 0}m
                          </span>
                        </div>

                        <div className="absolute bottom-2.5 left-3 right-3 z-20 text-left">
                          <p className="text-white font-bold text-xs truncate drop-shadow-xs">
                            {meeting.topic}
                          </p>
                          <p className="text-slate-300 text-[10px] font-mono truncate">
                            Room: {meeting.roomName}
                          </p>
                        </div>
                      </div>

                      {/* Card Content */}
                      <CardContent className="p-4 flex flex-col gap-2.5 text-xs">
                        <div className="grid grid-cols-2 gap-2 text-[11px] pb-2 border-b border-slate-100">
                          <div>
                            <span className="text-slate-400 block text-[10px]">Citizen:</span>
                            <span className="font-semibold text-slate-800 truncate block">
                              {citizenName}
                            </span>
                          </div>
                          <div>
                            <span className="text-slate-400 block text-[10px]">Attorney:</span>
                            <span className="font-semibold text-slate-800 truncate block">
                              {attorneyName || "None Dispatched"}
                            </span>
                          </div>
                        </div>

                        <div className="flex items-center justify-between text-[11px] text-slate-500">
                          <span>Recorded On:</span>
                          <span className="font-medium text-slate-700">
                            {new Date(meeting.createdAt).toLocaleDateString()} &middot;{" "}
                            {new Date(meeting.createdAt).toLocaleTimeString([], {
                              hour: "2-digit",
                              minute: "2-digit",
                            })}
                          </span>
                        </div>

                        {rec?.fileSize ? (
                          <div className="flex items-center justify-between text-[11px] text-slate-500">
                            <span>File Size:</span>
                            <span className="font-mono text-slate-700">
                              {Math.round((rec.fileSize / (1024 * 1024)) * 10) / 10} MB (MP4)
                            </span>
                          </div>
                        ) : null}
                      </CardContent>
                    </div>

                    {/* Card Footer Actions */}
                    <div className="px-4 py-3 bg-slate-50/80 border-t border-slate-100 flex items-center justify-between gap-2">
                      <Button
                        size="sm"
                        onClick={() => {
                          if (videoUrl) {
                            setPlayingVideo({
                              url: videoUrl,
                              title: meeting.topic,
                              date: new Date(meeting.createdAt).toLocaleString(),
                              category: meeting.category,
                              citizen: citizenName,
                            });
                          }
                        }}
                        className="bg-[#1554ad] hover:bg-[#11438a] text-white rounded-xl text-xs h-8 flex-1 gap-1.5"
                      >
                        <Play className="w-3.5 h-3.5 fill-white" />
                        Watch
                      </Button>

                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleCopyLink(videoUrl)}
                        title="Copy direct playable video URL"
                        className="rounded-xl border-slate-200 text-slate-600 hover:text-slate-900 h-8 w-8 p-0"
                      >
                        <Copy className="w-3.5 h-3.5" />
                      </Button>

                      <a
                        href={videoUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        download
                        title="Download MP4"
                      >
                        <Button
                          variant="outline"
                          size="sm"
                          className="rounded-xl border-slate-200 text-slate-600 hover:text-slate-900 h-8 w-8 p-0"
                        >
                          <Download className="w-3.5 h-3.5" />
                        </Button>
                      </a>

                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleDelete(meeting._id)}
                        disabled={deletingId === meeting._id}
                        title="Delete Recording"
                        className="rounded-xl border-rose-200 text-rose-600 hover:bg-rose-50 h-8 w-8 p-0"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </Button>
                    </div>
                  </Card>
                );
              })}
            </div>
          )}

          {/* Pagination */}
          {meta && meta.totalPage > 1 && (
            <div className="flex items-center justify-center gap-2 mt-4">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage(Math.max(1, page - 1))}
                disabled={page <= 1}
                className="rounded-xl text-xs"
              >
                Previous
              </Button>
              <span className="text-xs text-slate-500 font-medium px-2">
                Page {page} of {meta.totalPage}
              </span>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage(Math.min(meta.totalPage, page + 1))}
                disabled={page >= meta.totalPage}
                className="rounded-xl text-xs"
              >
                Next
              </Button>
            </div>
          )}
        </TabsContent>

        {/* ─── TAB 2: DYNAMIC STORAGE & CREDENTIALS SETUP ────────────────────── */}
        <TabsContent value="storage" className="mt-4 flex flex-col gap-6">
          <form onSubmit={handleSaveSettings} className="flex flex-col gap-6">
            {/* Provider Preset Picker */}
            <Card className="rounded-2xl border-slate-200 shadow-xs bg-white">
              <CardHeader className="p-6 pb-4 border-b border-slate-100">
                <CardTitle className="text-base font-bold text-slate-800 flex items-center gap-2">
                  <Cloud className="w-5 h-5 text-[#1554ad]" />
                  Choose S3-Compatible Cloud Storage Engine
                </CardTitle>
                <CardDescription className="text-xs text-slate-500">
                  Select your infrastructure provider. Govia LiveKit Egress will automatically composite and push MP4 recordings to this bucket.
                </CardDescription>
              </CardHeader>
              <CardContent className="p-6">
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
                  {Object.entries(PROVIDER_PRESETS).map(([key, preset]) => {
                    const isSelected = formData.provider === key;
                    return (
                      <div
                        key={key}
                        onClick={() => handleProviderSelect(key)}
                        className={`p-4 rounded-2xl border cursor-pointer transition-all flex flex-col justify-between gap-3 relative ${
                          isSelected
                            ? "bg-blue-50/50 border-[#1554ad] ring-2 ring-[#1554ad]/10 shadow-xs"
                            : "bg-slate-50/50 border-slate-200 hover:bg-slate-100/60"
                        }`}
                      >
                        <div>
                          <div className="flex items-center justify-between gap-2 mb-1.5">
                            <h4 className="text-xs font-bold text-slate-800">{preset.name}</h4>
                            {preset.badge && (
                              <Badge className="bg-emerald-100 text-emerald-700 text-[9px] font-extrabold px-1.5 py-0.2">
                                {preset.badge}
                              </Badge>
                            )}
                          </div>
                          <p className="text-[11px] text-slate-500 leading-relaxed">
                            {preset.description}
                          </p>
                        </div>
                        <div className="flex items-center gap-1.5 text-[10px] font-semibold text-slate-600">
                          <span
                            className={`w-3.5 h-3.5 rounded-full border flex items-center justify-center ${
                              isSelected
                                ? "bg-[#1554ad] border-[#1554ad] text-white"
                                : "border-slate-300"
                            }`}
                          >
                            {isSelected && <Check className="w-2.5 h-2.5" />}
                          </span>
                          <span>{isSelected ? "Selected Provider" : "Select"}</span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </CardContent>
            </Card>

            {/* S3 Storage Credentials */}
            <Card className="rounded-2xl border-slate-200 shadow-xs bg-white">
              <CardHeader className="p-6 pb-4 border-b border-slate-100">
                <CardTitle className="text-base font-bold text-slate-800 flex items-center gap-2">
                  <Key className="w-5 h-5 text-[#1554ad]" />
                  S3 Storage Credentials ({PROVIDER_PRESETS[formData.provider || "AWS_S3"]?.name})
                </CardTitle>
                <CardDescription className="text-xs text-slate-500">
                  Credentials are encrypted and loaded dynamically without requiring server reboot.
                </CardDescription>
              </CardHeader>
              <CardContent className="p-6 grid grid-cols-1 md:grid-cols-2 gap-4">
                {/* Bucket */}
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-slate-700">
                    S3 Bucket Name <span className="text-rose-500">*</span>
                  </label>
                  <Input
                    type="text"
                    required
                    value={formData.bucket}
                    onChange={(e) => setFormData({ ...formData, bucket: e.target.value })}
                    placeholder="e.g. govia-recordings"
                    className="rounded-xl text-xs h-9"
                  />
                  <span className="text-[10px] text-slate-400">Target bucket where MP4 video files will be stored.</span>
                </div>

                {/* Region */}
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-slate-700">
                    Region <span className="text-rose-500">*</span>
                  </label>
                  <Input
                    type="text"
                    required
                    value={formData.region}
                    onChange={(e) => setFormData({ ...formData, region: e.target.value })}
                    placeholder={formData.provider === "CLOUDFLARE_R2" ? "auto" : "us-east-1"}
                    className="rounded-xl text-xs h-9"
                  />
                  <span className="text-[10px] text-slate-400">
                    Use <code className="bg-slate-100 px-1 py-0.5 rounded">auto</code> for Cloudflare R2, or region code for AWS/Spaces.
                  </span>
                </div>

                {/* Access Key */}
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-slate-700">
                    Access Key ID <span className="text-rose-500">*</span>
                  </label>
                  <Input
                    type="text"
                    required
                    value={formData.accessKey}
                    onChange={(e) => setFormData({ ...formData, accessKey: e.target.value })}
                    placeholder="AKIA..."
                    className="rounded-xl text-xs h-9 font-mono"
                  />
                  <span className="text-[10px] text-slate-400">IAM User Access Key or R2 Token ID.</span>
                </div>

                {/* Secret Key */}
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-slate-700">
                    Secret Access Key <span className="text-rose-500">*</span>
                  </label>
                  <div className="relative">
                    <Input
                      type={showSecretKey ? "text" : "password"}
                      value={formData.secretKey}
                      onChange={(e) => setFormData({ ...formData, secretKey: e.target.value })}
                      placeholder={settings?.maskedSecretKey ? "Leave blank to keep existing secret" : "Secret Key"}
                      className="rounded-xl text-xs h-9 font-mono pr-10"
                    />
                    <button
                      type="button"
                      onClick={() => setShowSecretKey(!showSecretKey)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                    >
                      {showSecretKey ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                  <span className="text-[10px] text-slate-400">Keep confidential. Stored securely.</span>
                </div>

                {/* Endpoint (Optional / Provider Specific) */}
                <div className="flex flex-col gap-1.5 md:col-span-2">
                  <label className="text-xs font-bold text-slate-700">
                    Custom S3 Endpoint URL (Optional)
                  </label>
                  <Input
                    type="text"
                    value={formData.endpoint}
                    onChange={(e) => setFormData({ ...formData, endpoint: e.target.value })}
                    placeholder="https://<ACCOUNT_ID>.r2.cloudflarestorage.com or leave blank for AWS S3"
                    className="rounded-xl text-xs h-9 font-mono"
                  />
                  <span className="text-[10px] text-slate-400">
                    Required for Cloudflare R2, MinIO, or DigitalOcean Spaces. Leave blank if using default AWS S3.
                  </span>
                </div>
              </CardContent>
            </Card>

            {/* LiveKit WebRTC Cloud Credentials */}
            <Card className="rounded-2xl border-slate-200 shadow-xs bg-white">
              <CardHeader className="p-6 pb-4 border-b border-slate-100">
                <CardTitle className="text-base font-bold text-slate-800 flex items-center gap-2">
                  <Radio className="w-5 h-5 text-[#1554ad]" />
                  LiveKit WebRTC Cloud Infrastructure
                </CardTitle>
                <CardDescription className="text-xs text-slate-500">
                  Controls the live audio/video media routing and Egress recording engine.
                </CardDescription>
              </CardHeader>
              <CardContent className="p-6 grid grid-cols-1 md:grid-cols-2 gap-4">
                {/* LiveKit URL */}
                <div className="flex flex-col gap-1.5 md:col-span-2">
                  <label className="text-xs font-bold text-slate-700">
                    LiveKit Server URL (WebSocket)
                  </label>
                  <Input
                    type="text"
                    value={formData.livekitUrl}
                    onChange={(e) => setFormData({ ...formData, livekitUrl: e.target.value })}
                    placeholder="wss://govia-0f13ke90.livekit.cloud"
                    className="rounded-xl text-xs h-9 font-mono"
                  />
                </div>

                {/* LiveKit API Key */}
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-slate-700">
                    LiveKit API Key
                  </label>
                  <Input
                    type="text"
                    value={formData.livekitApiKey}
                    onChange={(e) => setFormData({ ...formData, livekitApiKey: e.target.value })}
                    placeholder="API6NLt8C36WoQ8"
                    className="rounded-xl text-xs h-9 font-mono"
                  />
                </div>

                {/* LiveKit Secret */}
                <div className="flex flex-col gap-1.5">
                  <label className="text-xs font-bold text-slate-700">
                    LiveKit API Secret
                  </label>
                  <div className="relative">
                    <Input
                      type={showLivekitSecret ? "text" : "password"}
                      value={formData.livekitApiSecret}
                      onChange={(e) => setFormData({ ...formData, livekitApiSecret: e.target.value })}
                      placeholder={settings?.maskedLivekitSecret ? "Leave blank to keep existing" : "API Secret"}
                      className="rounded-xl text-xs h-9 font-mono pr-10"
                    />
                    <button
                      type="button"
                      onClick={() => setShowLivekitSecret(!showLivekitSecret)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                    >
                      {showLivekitSecret ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                </div>

                {/* Webhook helper banner */}
                <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200 md:col-span-2 flex flex-col gap-1.5 text-xs">
                  <div className="flex items-center gap-1.5 font-bold text-slate-800">
                    <Server className="w-4 h-4 text-[#1554ad]" />
                    LiveKit Cloud Webhook Callback URL:
                  </div>
                  <div className="flex items-center justify-between bg-white border border-slate-200 rounded-lg px-3 py-2">
                    <code className="text-[11px] font-mono text-slate-700 truncate">
                      http://172.252.13.197:9777/api/v1/meeting/webhook/livekit
                    </code>
                    <Button
                      type="button"
                      size="sm"
                      variant="ghost"
                      onClick={() => {
                        navigator.clipboard.writeText("http://172.252.13.197:9777/api/v1/meeting/webhook/livekit");
                        toast.success("Webhook URL copied to clipboard");
                      }}
                      className="h-7 text-[11px] text-[#1554ad] font-bold"
                    >
                      Copy URL
                    </Button>
                  </div>
                  <span className="text-[10px] text-slate-500">
                    Configure this URL in your LiveKit Cloud Console under <strong>Settings &gt; Webhooks</strong> with events: <code className="bg-slate-200/60 px-1 py-0.5 rounded">egress_ended</code>, <code className="bg-slate-200/60 px-1 py-0.5 rounded">egress_updated</code>, <code className="bg-slate-200/60 px-1 py-0.5 rounded">room_finished</code>.
                  </span>
                </div>
              </CardContent>
            </Card>

            {/* Test Connection Alert Box */}
            {testResult && (
              <div
                className={`p-4 rounded-2xl border text-xs flex items-center justify-between ${
                  testResult.success
                    ? "bg-emerald-50 border-emerald-200 text-emerald-800"
                    : "bg-rose-50 border-rose-200 text-rose-800"
                }`}
              >
                <div className="flex items-center gap-2">
                  {testResult.success ? (
                    <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                  ) : (
                    <AlertTriangle className="w-4 h-4 text-rose-600 shrink-0" />
                  )}
                  <span className="font-medium">{testResult.message}</span>
                </div>
                <button
                  type="button"
                  onClick={() => setTestResult(null)}
                  className="text-slate-400 hover:text-slate-600 ml-2"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            )}

            {/* Action Buttons */}
            <div className="flex flex-wrap items-center justify-end gap-3 pt-2">
              <Button
                type="button"
                variant="outline"
                onClick={handleTestConnection}
                disabled={testingConnection || !formData.bucket || !formData.accessKey}
                className="rounded-xl text-xs h-10 gap-1.5 border-slate-300"
              >
                <RefreshCw className={`w-3.5 h-3.5 ${testingConnection ? "animate-spin text-[#1554ad]" : ""}`} />
                {testingConnection ? "Verifying..." : "Test Connection"}
              </Button>

              <Button
                type="submit"
                disabled={savingSettings}
                className="bg-[#1554ad] hover:bg-[#11438a] text-white rounded-xl text-xs h-10 px-5 gap-1.5"
              >
                <Check className="w-3.5 h-3.5" />
                {savingSettings ? "Saving & Applying..." : "Save & Apply Credentials"}
              </Button>
            </div>
          </form>
        </TabsContent>
      </Tabs>

      {/* Video Player Modal */}
      {playingVideo && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 backdrop-blur-md p-4 animate-in fade-in duration-150">
          <div className="relative bg-slate-900 border border-slate-800 rounded-2xl shadow-2xl w-full max-w-3xl overflow-hidden flex flex-col">
            {/* Player Header */}
            <div className="px-5 py-3.5 bg-slate-950/80 border-b border-slate-800 flex items-center justify-between text-white">
              <div className="flex items-center gap-2 overflow-hidden">
                <FileVideo className="w-4 h-4 text-[#1554ad] shrink-0" />
                <div className="overflow-hidden">
                  <h3 className="font-bold text-sm truncate">{playingVideo.title}</h3>
                  <p className="text-[10px] text-slate-400 truncate">
                    {playingVideo.citizen} &middot; {playingVideo.date}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setPlayingVideo(null)}
                className="text-slate-400 hover:text-white transition-colors p-1"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Video Canvas */}
            <div className="relative aspect-video w-full bg-black flex items-center justify-center">
              <video
                src={playingVideo.url}
                controls
                autoPlay
                className="w-full h-full object-contain"
              >
                Your browser does not support HTML5 video playback.
              </video>
            </div>

            {/* Player Footer */}
            <div className="px-5 py-3 bg-slate-950 border-t border-slate-800 flex items-center justify-between text-xs text-slate-400">
              <span className="font-mono text-[11px] truncate max-w-sm">
                {playingVideo.url}
              </span>
              <div className="flex items-center gap-2">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleCopyLink(playingVideo.url)}
                  className="rounded-lg text-xs h-7 border-slate-700 bg-slate-900 text-slate-200 hover:bg-slate-800"
                >
                  <Copy className="w-3 h-3 mr-1" /> Copy Link
                </Button>
                <a href={playingVideo.url} target="_blank" rel="noopener noreferrer" download>
                  <Button
                    size="sm"
                    className="bg-[#1554ad] hover:bg-[#11438a] text-white rounded-lg text-xs h-7"
                  >
                    <Download className="w-3 h-3 mr-1" /> Download
                  </Button>
                </a>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
