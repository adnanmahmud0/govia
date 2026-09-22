"use client";

import React, { useState, useEffect } from "react";
import { DataTable, ColumnDef } from "@/components/tables/DataTable";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Loader2,
  Search,
  RefreshCw,
  AlertCircle,
  Download,
  Eye,
  X,
  MapPin,
  Clock,
  Video,
  ExternalLink,
} from "lucide-react";
import { useMeetings, Meeting, MeetingUser } from "@/hooks/useMeetings";
import { useToast } from "@/context/ToastContext";

function getUserName(u: MeetingUser | string | undefined): string {
  if (!u) return "—";
  if (typeof u === "string") return "User";
  return u.name || "—";
}

function getUserEmail(u: MeetingUser | string | undefined): string {
  if (!u) return "—";
  if (typeof u === "string") return u;
  return u.email || "—";
}

const statusBadgeColors: Record<string, string> = {
  COMPLETED: "bg-emerald-100 text-emerald-700",
  ACTIVE: "bg-blue-100 text-[#1554ad]",
  SCHEDULED: "bg-amber-100 text-amber-700",
  CANCELLED: "bg-red-100 text-red-700",
};

export default function CallHistoryPage() {
  const {
    allMeetings,
    allMeta,
    loadingAll,
    errorAll,
    page,
    setPage,
    statusFilter,
    setStatusFilter,
    refetchAll,
  } = useMeetings();

  const { toast } = useToast();
  const [searchTerm, setSearchTerm] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("all");
  const [dateFilter, setDateFilter] = useState("all");
  const [selectedMeeting, setSelectedMeeting] = useState<Meeting | null>(null);
  const [referenceTime, setReferenceTime] = useState(0);

  useEffect(() => {
    setReferenceTime(Date.now());
  }, []);

  const filteredMeetings = allMeetings.filter((m) => {
    // Search
    if (searchTerm.trim()) {
      const term = searchTerm.toLowerCase();
      const room = (m.roomName || "").toLowerCase();
      const host = getUserName(m.userId).toLowerCase();
      const cat = (m.category || "").toLowerCase();
      if (!room.includes(term) && !host.includes(term) && !cat.includes(term)) {
        return false;
      }
    }

    // Category
    if (categoryFilter !== "all" && m.category !== categoryFilter) {
      return false;
    }

    // Date range
    if (dateFilter !== "all" && referenceTime > 0) {
      const d = m.startTime || m.createdAt;
      if (!d) return false;
      const meetingDate = new Date(d).getTime();
      if (dateFilter === "today" && referenceTime - meetingDate > 86400000) return false;
      if (dateFilter === "week" && referenceTime - meetingDate > 86400000 * 7) return false;
      if (dateFilter === "month" && referenceTime - meetingDate > 86400000 * 30) return false;
    }

    return true;
  });

  const handleExportCSV = () => {
    if (filteredMeetings.length === 0) {
      toast.info("No records to export");
      return;
    }
    const headers = ["Room Name", "Category", "Citizen Name", "Responders Count", "Duration Mins", "Status", "Date"];
    const rows = filteredMeetings.map((m) => [
      `"${m.roomName || m._id}"`,
      `"${m.category || "ENCOUNTER"}"`,
      `"${getUserName(m.userId)}"`,
      `"${m.joinedAttorneys?.length || 0}"`,
      `"${m.durationMinutes || 0}"`,
      `"${m.status || "COMPLETED"}"`,
      `"${m.startTime || m.createdAt ? new Date(m.startTime || m.createdAt!).toLocaleString() : ""}"`,
    ]);
    const csvContent =
      "data:text/csv;charset=utf-8," + [headers.join(","), ...rows.map((r) => r.join(","))].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `call_history_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    toast.success("Call history exported to CSV");
  };

  const columns: ColumnDef<Meeting>[] = [
    {
      header: "Incident / Room",
      cell: (m) => (
        <span className="text-[#1554ad] font-mono font-medium">
          {m.roomName || `INC-${m._id.slice(-6).toUpperCase()}`}
        </span>
      ),
    },
    {
      header: "Category",
      cell: (m) => (
        <Badge variant="secondary" className="font-normal text-xs bg-slate-100 text-slate-700 border-0">
          {m.category || "ENCOUNTER"}
        </Badge>
      ),
    },
    {
      header: "Citizen / Caller",
      cell: (m) => (
        <div className="font-medium text-slate-800 text-sm">
          {getUserName(m.userId)}
        </div>
      ),
    },
    {
      header: "Responders",
      cell: (m) => {
        const atts = m.joinedAttorneys || [];
        if (atts.length === 0) return <span className="text-slate-300 text-xs">No attorney</span>;
        return (
          <span className="text-slate-700 text-xs font-medium">
            {atts.map((a) => getUserName(a)).join(", ")}
          </span>
        );
      },
    },
    {
      header: "Duration",
      cell: (m) => (
        <span className="text-slate-600 text-xs font-mono">
          {m.durationMinutes ? `${m.durationMinutes} min` : "—"}
        </span>
      ),
    },
    {
      header: "Date & Time",
      cell: (m) => {
        const d = m.startTime || m.createdAt;
        if (!d) return <span className="text-slate-400">—</span>;
        return (
          <span className="text-slate-500 text-xs">
            {new Date(d).toLocaleDateString()}{" "}
            {new Date(d).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
          </span>
        );
      },
    },
    {
      header: "Status",
      cell: (m) => (
        <Badge
          className={`${statusBadgeColors[m.status] || "bg-slate-100 text-slate-700"} border-0 text-xs font-medium`}
        >
          {m.status || "COMPLETED"}
        </Badge>
      ),
    },
    {
      header: "Action",
      cell: (m) => (
        <button
          onClick={() => setSelectedMeeting(m)}
          className="p-1.5 hover:bg-slate-100 rounded-lg text-slate-500 hover:text-[#1554ad] transition-colors cursor-pointer"
          title="View encounter log"
        >
          <Eye className="w-4 h-4" />
        </button>
      ),
      className: "text-right",
    },
  ];

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">Call History</h1>
          <p className="text-slate-500 text-sm mt-0.5">
            Review past call incidents, encounter logs, and connected responders.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={handleExportCSV}
            className="rounded-xl gap-2 text-xs"
          >
            <Download className="w-3.5 h-3.5" />
            Export CSV
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={refetchAll}
            disabled={loadingAll}
            className="rounded-xl gap-2 text-xs"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loadingAll ? "animate-spin" : ""}`} />
            Refresh
          </Button>
        </div>
      </div>

      {errorAll && (
        <div className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm">
          <AlertCircle className="w-4 h-4 flex-shrink-0" />
          {errorAll}
        </div>
      )}

      <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm space-y-4">
        {/* Multi-filter bar */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <Input
              placeholder="Search room, citizen, or topic..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-9 rounded-xl border-slate-200 h-10 text-sm"
            />
          </div>

          <Select
            value={statusFilter || "all"}
            onValueChange={(v) => setStatusFilter(v === "all" ? "" : v)}
          >
            <SelectTrigger className="rounded-xl border-slate-200 h-10 text-sm">
              <SelectValue placeholder="Status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Statuses</SelectItem>
              <SelectItem value="COMPLETED">Completed</SelectItem>
              <SelectItem value="ACTIVE">Active</SelectItem>
              <SelectItem value="SCHEDULED">Scheduled</SelectItem>
              <SelectItem value="CANCELLED">Cancelled</SelectItem>
            </SelectContent>
          </Select>

          <Select value={categoryFilter} onValueChange={setCategoryFilter}>
            <SelectTrigger className="rounded-xl border-slate-200 h-10 text-sm">
              <SelectValue placeholder="Category" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Categories</SelectItem>
              <SelectItem value="ENCOUNTER">Encounter</SelectItem>
              <SelectItem value="EMERGENCY">Emergency</SelectItem>
              <SelectItem value="CONSULTATION">Consultation</SelectItem>
            </SelectContent>
          </Select>

          <Select value={dateFilter} onValueChange={setDateFilter}>
            <SelectTrigger className="rounded-xl border-slate-200 h-10 text-sm">
              <SelectValue placeholder="Timeframe" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Time</SelectItem>
              <SelectItem value="today">Today</SelectItem>
              <SelectItem value="week">Past 7 Days</SelectItem>
              <SelectItem value="month">Past 30 Days</SelectItem>
            </SelectContent>
          </Select>
        </div>

        {/* Table */}
        {loadingAll ? (
          <div className="flex items-center justify-center py-20 gap-3 text-slate-400">
            <Loader2 className="w-5 h-5 animate-spin" />
            <span className="font-medium">Loading call records...</span>
          </div>
        ) : filteredMeetings.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 text-slate-400 gap-2">
            <Search className="w-8 h-8 opacity-40" />
            <p className="font-medium">No call history records found</p>
            <p className="text-sm">Encounter calls and meetings will appear here after completion.</p>
          </div>
        ) : (
          <DataTable
            columns={columns}
            data={filteredMeetings}
            pagination={
              allMeta && allMeta.totalPage > 1
                ? {
                    currentPage: page,
                    totalPages: allMeta.totalPage,
                    onPageChange: setPage,
                  }
                : undefined
            }
          />
        )}
      </div>

      {/* Incident Details Modal */}
      {selectedMeeting && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="absolute inset-0 bg-black/40 backdrop-blur-sm"
            onClick={() => setSelectedMeeting(null)}
          />
          <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg p-6 space-y-5 z-10 max-h-[90vh] overflow-y-auto">
            <div className="flex items-start justify-between">
              <div>
                <span className="text-xs font-mono text-[#1554ad] font-bold">
                  {selectedMeeting.roomName || selectedMeeting._id}
                </span>
                <h3 className="text-xl font-bold text-slate-800 mt-0.5">
                  {selectedMeeting.topic || "Encounter Log"}
                </h3>
              </div>
              <button
                onClick={() => setSelectedMeeting(null)}
                className="text-slate-400 hover:text-slate-600 rounded-lg p-1"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="flex items-center gap-2">
              <Badge className="bg-blue-100 text-[#1554ad] border-0 text-xs">
                {selectedMeeting.category || "ENCOUNTER"}
              </Badge>
              <Badge
                className={`${statusBadgeColors[selectedMeeting.status] || "bg-slate-100 text-slate-700"} border-0 text-xs`}
              >
                {selectedMeeting.status}
              </Badge>
              {selectedMeeting.durationMinutes ? (
                <span className="text-xs text-slate-500 font-mono">
                  {selectedMeeting.durationMinutes} minutes duration
                </span>
              ) : null}
            </div>

            <div className="bg-slate-50/80 rounded-xl p-4 space-y-3 border border-slate-100 text-sm">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <p className="text-xs text-slate-400 font-medium">Citizen / Caller</p>
                  <p className="font-semibold text-slate-800 mt-0.5">
                    {getUserName(selectedMeeting.userId)}
                  </p>
                  <p className="text-xs text-slate-500">{getUserEmail(selectedMeeting.userId)}</p>
                </div>
                <div>
                  <p className="text-xs text-slate-400 font-medium">Incident Location</p>
                  <p className="text-xs text-slate-700 font-medium mt-0.5 flex items-center gap-1">
                    <MapPin className="w-3.5 h-3.5 text-[#1554ad] shrink-0" />
                    {selectedMeeting.locationAddress || "GPS Coordinates Logged"}
                  </p>
                </div>
              </div>

              <div className="pt-2 border-t border-slate-200/60">
                <p className="text-xs text-slate-400 font-medium mb-1">Responding Advocates & Responders</p>
                {selectedMeeting.joinedAttorneys && selectedMeeting.joinedAttorneys.length > 0 ? (
                  <div className="space-y-1">
                    {selectedMeeting.joinedAttorneys.map((a, idx) => (
                      <div key={idx} className="flex items-center justify-between text-xs bg-white p-2 rounded-lg border border-slate-100">
                        <span className="font-semibold text-slate-700">{getUserName(a)}</span>
                        <span className="text-slate-400">{getUserEmail(a)}</span>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-xs text-slate-400 italic">No advocate joined during this encounter</p>
                )}
              </div>

              <div className="pt-2 border-t border-slate-200/60 grid grid-cols-2 gap-3 text-xs text-slate-500">
                <div>
                  <span className="text-slate-400 block">Start Time:</span>
                  <span className="font-medium text-slate-700">
                    {selectedMeeting.startTime
                      ? new Date(selectedMeeting.startTime).toLocaleString()
                      : "—"}
                  </span>
                </div>
                <div>
                  <span className="text-slate-400 block">Ended At:</span>
                  <span className="font-medium text-slate-700">
                    {selectedMeeting.endedAt
                      ? new Date(selectedMeeting.endedAt).toLocaleString()
                      : "—"}
                  </span>
                </div>
              </div>
            </div>

            <Button
              onClick={() => setSelectedMeeting(null)}
              className="w-full rounded-xl bg-[#1554ad] hover:bg-[#1554ad]/90 text-white"
            >
              Close
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
