"use client";

import React, { useState } from "react";
import {
  Star,
  TrendingUp,
  RefreshCw,
  Loader2,
  AlertCircle,
  Shield,
  Award,
  Download,
  Eye,
  X,
  Search,
  CheckCircle,
  MapPin,
  Calendar,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useHeroHighlights, HeroHighlight } from "@/hooks/useHeroHighlights";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/context/ToastContext";

type FilterType = "all" | "5star" | "highdeescalation";

function StarRating({ rating }: { rating: number }) {
  const rounded = Math.round(rating);
  return (
    <div className="flex items-center gap-0.5">
      {Array.from({ length: 5 }).map((_, i) => (
        <Star
          key={i}
          className={cn(
            "w-3.5 h-3.5",
            i < rounded ? "fill-amber-400 text-amber-400" : "fill-slate-200 text-slate-200"
          )}
        />
      ))}
      <span className="text-xs font-bold text-slate-700 ml-1.5">{rating.toFixed(1)}</span>
    </div>
  );
}

function getTimeAgo(dateStr?: string) {
  if (!dateStr) return "Recent";
  const diffMs = Date.now() - new Date(dateStr).getTime();
  const diffHours = Math.floor(diffMs / 3600000);
  if (diffHours < 1) return "Just now";
  if (diffHours < 24) return `${diffHours}h ago`;
  const diffDays = Math.floor(diffHours / 24);
  return `${diffDays}d ago`;
}

export default function HeroHighlightPage() {
  const { highlights, loading, error, refetch } = useHeroHighlights();
  const { toast } = useToast();
  const [filter, setFilter] = useState<FilterType>("all");
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedHighlight, setSelectedHighlight] = useState<HeroHighlight | null>(null);

  const filteredHighlights = highlights.filter((h) => {
    if (searchTerm.trim()) {
      const term = searchTerm.toLowerCase();
      const name = (h.officerName || "").toLowerCase();
      const badge = (h.badgeNumber || "").toLowerCase();
      const agency = (h.agency || "").toLowerCase();
      if (!name.includes(term) && !badge.includes(term) && !agency.includes(term)) {
        return false;
      }
    }

    const avg =
      ((h.respectRating || 0) + (h.deEscalationRating || 0) + (h.communicationRating || 0)) / 3;
    if (filter === "5star") return avg >= 4.7;
    if (filter === "highdeescalation") return (h.deEscalationRating || 0) >= 4.5;
    return true;
  });

  const handleExportCSV = () => {
    if (filteredHighlights.length === 0) {
      toast.info("No records to export");
      return;
    }
    const headers = [
      "Officer Name",
      "Agency",
      "Badge Number",
      "Car Number",
      "Respect Rating",
      "De-escalation Rating",
      "Communication Rating",
      "Incident Date",
      "Feedback Quote",
    ];
    const rows = filteredHighlights.map((h) => [
      `"${h.officerName || ""}"`,
      `"${h.agency || ""}"`,
      `"${h.badgeNumber || ""}"`,
      `"${h.carNumber || ""}"`,
      `"${h.respectRating || 5}"`,
      `"${h.deEscalationRating || 5}"`,
      `"${h.communicationRating || 5}"`,
      `"${h.incidentDate ? new Date(h.incidentDate).toLocaleDateString() : ""}"`,
      `"${(h.whatDidOfficerDoWell || "").replace(/"/g, '""')}"`,
    ]);
    const csvContent =
      "data:text/csv;charset=utf-8," + [headers.join(","), ...rows.map((r) => r.join(","))].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `hero_highlights_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    toast.success("Commendations exported to CSV");
  };

  const filterBtns: { key: FilterType; label: string; icon?: React.ReactNode }[] = [
    { key: "all", label: "All Highlights" },
    { key: "5star", label: "Top Rated (5★)", icon: <Star className="w-3.5 h-3.5" /> },
    { key: "highdeescalation", label: "De-escalation Champions", icon: <TrendingUp className="w-3.5 h-3.5" /> },
  ];

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-slate-800 tracking-tight">Hero Highlights</h1>
          <p className="text-slate-500 text-sm mt-0.5">
            Community officer commendations, conduct reports, and positive citizen feedback.
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
            onClick={refetch}
            disabled={loading}
            className="rounded-xl gap-2 text-xs"
          >
            <RefreshCw className={cn("w-3.5 h-3.5", loading && "animate-spin")} />
            Refresh
          </Button>
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm">
          <AlertCircle className="w-4 h-4 flex-shrink-0" />
          {error}
        </div>
      )}

      {/* Filter and Search Bar */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
        <div className="flex items-center gap-2 flex-wrap">
          {filterBtns.map((btn) => (
            <button
              key={btn.key}
              onClick={() => setFilter(btn.key)}
              className={cn(
                "flex items-center gap-1.5 px-4 py-2 rounded-full text-xs font-semibold transition-all border cursor-pointer",
                filter === btn.key
                  ? "bg-[#1554ad] text-white border-[#1554ad] shadow-md shadow-[#1554ad]/20"
                  : "bg-white text-slate-600 border-slate-200 hover:border-slate-300 hover:bg-slate-50"
              )}
            >
              {btn.icon}
              {btn.label}
            </button>
          ))}
        </div>

        <div className="relative w-full sm:w-72">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <Input
            placeholder="Search officer or agency..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-9 rounded-xl border-slate-200 h-10 text-xs"
          />
        </div>
      </div>

      {/* Content */}
      {loading && highlights.length === 0 ? (
        <div className="flex items-center justify-center py-20 gap-3 text-slate-400">
          <Loader2 className="w-6 h-6 animate-spin text-[#1554ad]" />
          <span className="font-medium text-sm">Loading highlights...</span>
        </div>
      ) : filteredHighlights.length === 0 ? (
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-12 flex flex-col items-center justify-center text-center gap-3">
          <div className="w-14 h-14 bg-amber-50 text-amber-600 rounded-2xl flex items-center justify-center">
            <Award className="w-7 h-7" />
          </div>
          <h3 className="text-base font-bold text-slate-800">No Commendations Found</h3>
          <p className="text-sm text-slate-500 max-w-sm">
            {highlights.length === 0
              ? "Citizen feedback and officer commendations will appear here once submitted from the mobile app."
              : "No highlights match your search criteria."}
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
          {filteredHighlights.map((hero) => {
            const avgRating =
              ((hero.respectRating || 5) + (hero.deEscalationRating || 5) + (hero.communicationRating || 5)) / 3;
            const initials = (hero.officerName || "Officer")
              .split(" ")
              .map((n) => n[0])
              .slice(0, 2)
              .join("")
              .toUpperCase();

            return (
              <div
                key={hero._id}
                onClick={() => setSelectedHighlight(hero)}
                className="bg-white rounded-2xl border border-slate-100 shadow-sm p-5 flex flex-col gap-4 hover:shadow-md hover:border-slate-200 transition-all cursor-pointer group"
              >
                {/* Header */}
                <div className="flex items-start gap-3">
                  <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-600 to-indigo-700 flex items-center justify-center text-white font-bold text-sm shrink-0 shadow-sm group-hover:scale-105 transition-transform">
                    {initials}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-bold text-slate-800 leading-tight truncate">{hero.officerName}</p>
                    <p className="text-xs text-slate-500 mt-0.5 truncate">{hero.agency || "Law Enforcement"}</p>
                    {hero.badgeNumber && (
                      <p className="text-xs text-slate-400">Badge #{hero.badgeNumber}</p>
                    )}
                  </div>
                </div>

                {/* Feedback Quote */}
                <div className="bg-slate-50 rounded-xl p-4 relative flex-1">
                  <span className="text-[#1554ad] text-2xl font-serif leading-none absolute top-2 left-3 select-none">
                    "
                  </span>
                  <p className="text-slate-600 text-xs leading-relaxed pt-3 pl-2 line-clamp-3">
                    {hero.whatDidOfficerDoWell ||
                      "Outstanding professionalism and composure shown during the encounter."}
                  </p>
                </div>

                {/* Ratings details */}
                <div className="grid grid-cols-3 gap-2 text-center text-xs border-t border-slate-100 pt-3">
                  <div className="bg-slate-50 rounded-lg p-1.5">
                    <p className="text-slate-400 text-[9px] uppercase font-semibold">Respect</p>
                    <p className="font-bold text-slate-700">{hero.respectRating || 5}★</p>
                  </div>
                  <div className="bg-slate-50 rounded-lg p-1.5">
                    <p className="text-slate-400 text-[9px] uppercase font-semibold">De-escalate</p>
                    <p className="font-bold text-slate-700">{hero.deEscalationRating || 5}★</p>
                  </div>
                  <div className="bg-slate-50 rounded-lg p-1.5">
                    <p className="text-slate-400 text-[9px] uppercase font-semibold">Comm</p>
                    <p className="font-bold text-slate-700">{hero.communicationRating || 5}★</p>
                  </div>
                </div>

                {/* Footer */}
                <div className="flex items-center justify-between pt-1">
                  <StarRating rating={avgRating} />
                  <span className="text-xs text-slate-400">
                    {getTimeAgo(hero.incidentDate || hero.createdAt)}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Commendation Details Modal */}
      {selectedHighlight && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="absolute inset-0 bg-black/40 backdrop-blur-sm"
            onClick={() => setSelectedHighlight(null)}
          />
          <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg p-6 space-y-5 z-10 max-h-[90vh] overflow-y-auto">
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-600 to-indigo-700 text-white font-bold text-sm flex items-center justify-center">
                  {(selectedHighlight.officerName || "OF").slice(0, 2).toUpperCase()}
                </div>
                <div>
                  <h3 className="text-xl font-bold text-slate-800">{selectedHighlight.officerName}</h3>
                  <p className="text-xs text-slate-500">{selectedHighlight.agency}</p>
                </div>
              </div>
              <button
                onClick={() => setSelectedHighlight(null)}
                className="text-slate-400 hover:text-slate-600 rounded-lg p-1"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Officer details grid */}
            <div className="grid grid-cols-2 gap-3 bg-slate-50 rounded-xl p-3.5 text-xs">
              <div>
                <span className="text-slate-400 block">Badge Number:</span>
                <span className="font-semibold text-slate-700">{selectedHighlight.badgeNumber || "—"}</span>
              </div>
              <div>
                <span className="text-slate-400 block">Car / Patrol Unit:</span>
                <span className="font-semibold text-slate-700">{selectedHighlight.carNumber || "—"}</span>
              </div>
              <div>
                <span className="text-slate-400 block">Incident Date:</span>
                <span className="font-semibold text-slate-700">
                  {selectedHighlight.incidentDate
                    ? new Date(selectedHighlight.incidentDate).toLocaleDateString()
                    : "—"}
                </span>
              </div>
              <div>
                <span className="text-slate-400 block">Incident Location:</span>
                <span className="font-semibold text-slate-700">
                  {selectedHighlight.incidentLocation || "City Limits"}
                </span>
              </div>
            </div>

            {/* Citizen Feedback */}
            <div>
              <p className="text-xs font-semibold text-slate-700 uppercase tracking-wide mb-1.5">
                Citizen Commendation & Feedback
              </p>
              <div className="bg-blue-50/50 border border-blue-100 rounded-xl p-4 text-sm text-slate-700 leading-relaxed italic">
                "{selectedHighlight.whatDidOfficerDoWell}"
              </div>
            </div>

            {/* Ratings breakdown */}
            <div>
              <p className="text-xs font-semibold text-slate-700 uppercase tracking-wide mb-2">
                Performance Ratings
              </p>
              <div className="grid grid-cols-3 gap-3 text-center">
                <div className="bg-slate-50 rounded-xl p-3">
                  <p className="text-xs text-slate-500">Respect</p>
                  <p className="text-lg font-bold text-slate-800 mt-1">{selectedHighlight.respectRating} / 5</p>
                </div>
                <div className="bg-slate-50 rounded-xl p-3">
                  <p className="text-xs text-slate-500">De-escalation</p>
                  <p className="text-lg font-bold text-slate-800 mt-1">{selectedHighlight.deEscalationRating} / 5</p>
                </div>
                <div className="bg-slate-50 rounded-xl p-3">
                  <p className="text-xs text-slate-500">Communication</p>
                  <p className="text-lg font-bold text-slate-800 mt-1">{selectedHighlight.communicationRating} / 5</p>
                </div>
              </div>
            </div>

            {/* Submitter details if populated */}
            {selectedHighlight.uploadedBy && (
              <div className="text-xs text-slate-400 border-t border-slate-100 pt-3">
                Submitted by: <span className="font-medium text-slate-600">{selectedHighlight.uploadedBy.name}</span> ({selectedHighlight.uploadedBy.email})
              </div>
            )}

            <Button
              onClick={() => setSelectedHighlight(null)}
              className="w-full rounded-xl bg-[#1554ad] hover:bg-[#1554ad]/90 text-white"
            >
              Close Commendation
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
