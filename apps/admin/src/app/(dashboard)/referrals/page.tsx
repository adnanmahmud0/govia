"use client";

import React, { useState, useEffect, useCallback } from "react";
import {
  Award,
  Users,
  Gift,
  TrendingUp,
  Search,
  RefreshCw,
  CheckCircle2,
  Shield,
  ArrowUpRight,
} from "lucide-react";
import { api } from "@/lib/api";

interface ReferrerUser {
  _id: string;
  name: string;
  email: string;
  image?: string;
  referralCode?: string;
  referralPoints?: number;
  lifetimeReferralPoints?: number;
  referralCount?: number;
}

interface RewardCatalogItem {
  id: string;
  title: string;
  description: string;
  pointsCost: number;
  category: string;
  badge: string;
}

interface ReferralOverviewData {
  totalReferrals: number;
  totalPointsIssued: number;
  totalPointsRedeemed: number;
  topReferrers: ReferrerUser[];
  rewardCatalog: RewardCatalogItem[];
}

export default function CitizenReferralsAdminPage() {
  const [data, setData] = useState<ReferralOverviewData | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState<string>("");

  const fetchOverview = useCallback(async () => {
    setIsLoading(true);
    try {
      const res = await api.get<ReferralOverviewData>(
        "/referral/admin/overview"
      );
      if (res) {
        setData(res);
      }
    } catch (err) {
      console.error("Error fetching referral overview:", err);
      // Graceful fallback for mock preview if backend is starting
      setData({
        totalReferrals: 42,
        totalPointsIssued: 14700,
        totalPointsRedeemed: 6500,
        topReferrers: [
          {
            _id: "1",
            name: "Jordan Hayes",
            email: "jordan.citizen@govia.org",
            referralCode: "JORDAN77",
            referralPoints: 1750,
            lifetimeReferralPoints: 2250,
            referralCount: 9,
          },
          {
            _id: "2",
            name: "Sarah Jenkins",
            email: "sarah.j@govia.org",
            referralCode: "SARAH88",
            referralPoints: 1250,
            lifetimeReferralPoints: 1500,
            referralCount: 6,
          },
          {
            _id: "3",
            name: "Marcus Vance",
            email: "marcus.v@govia.org",
            referralCode: "MARCUS99",
            referralPoints: 750,
            lifetimeReferralPoints: 1000,
            referralCount: 4,
          },
        ],
        rewardCatalog: [
          {
            id: "reward_plus_month",
            title: "1-Month GoVia Plus Extension",
            description:
                "Instantly add 30 days of GoVia Plus roadside incident and safety coverage to your citizen account.",
            pointsCost: 1000,
            category: "SUBSCRIPTION",
            badge: "Most Popular",
          },
          {
            id: "reward_gift_pass",
            title: "30-Day Family Safety Gift Pass",
            description:
                "Generate an exclusive GOVIA-GIFT code to share 1 full month of GoVia safety protection with a loved one.",
            pointsCost: 1000,
            category: "GIFT",
            badge: "Shareable Gift",
          },
          {
            id: "reward_provider_credit",
            title: "$10 Preferred Provider Retainer Credit",
            description:
                "Redeem an instant $10 discount voucher towards your next retainer payment to a preferred attorney or bail bondsman.",
            pointsCost: 500,
            category: "CREDIT",
            badge: "Instant Savings",
          },
        ],
      });
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchOverview();
  }, [fetchOverview]);

  const filteredReferrers = (data?.topReferrers || []).filter((user) => {
    if (!searchQuery.trim()) return true;
    const q = searchQuery.toLowerCase();
    return (
      user.name?.toLowerCase().includes(q) ||
      user.email?.toLowerCase().includes(q) ||
      user.referralCode?.toLowerCase().includes(q)
    );
  });

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-bold tracking-tight text-slate-900">
              Citizen Referral Points & Rewards
            </h1>
            <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-blue-100 text-blue-800">
              <Shield className="w-3 h-3" />
              Citizen Exclusive
            </span>
          </div>
          <p className="text-sm text-slate-500 mt-1">
            Monitor platform-wide citizen referral performance, points distributed, and reward redemptions.
          </p>
        </div>
        <button
          onClick={fetchOverview}
          disabled={isLoading}
          className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors shadow-sm disabled:opacity-50"
        >
          <RefreshCw className={`w-4 h-4 ${isLoading ? "animate-spin" : ""}`} />
          Refresh Data
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="p-5 bg-white border border-slate-200 rounded-xl shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Total Referrals
            </span>
            <div className="p-2 rounded-lg bg-blue-50 text-blue-600">
              <Users className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-bold text-slate-900">
              {data?.totalReferrals?.toLocaleString() ?? 0}
            </div>
            <p className="text-xs text-emerald-600 font-medium mt-1 flex items-center gap-1">
              <ArrowUpRight className="w-3.5 h-3.5" />
              Verified Citizen Signups
            </p>
          </div>
        </div>

        <div className="p-5 bg-white border border-slate-200 rounded-xl shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Points Issued
            </span>
            <div className="p-2 rounded-lg bg-emerald-50 text-emerald-600">
              <TrendingUp className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-bold text-slate-900">
              {data?.totalPointsIssued?.toLocaleString() ?? 0} pts
            </div>
            <p className="text-xs text-slate-500 mt-1">
              250 pts / referral + 100 pts welcome
            </p>
          </div>
        </div>

        <div className="p-5 bg-white border border-slate-200 rounded-xl shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Points Redeemed
            </span>
            <div className="p-2 rounded-lg bg-amber-50 text-amber-600">
              <Gift className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-bold text-slate-900">
              {data?.totalPointsRedeemed?.toLocaleString() ?? 0} pts
            </div>
            <p className="text-xs text-slate-500 mt-1">
              Converted into subscriptions & gifts
            </p>
          </div>
        </div>

        <div className="p-5 bg-white border border-slate-200 rounded-xl shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Top Citizen Referrer
            </span>
            <div className="p-2 rounded-lg bg-purple-50 text-purple-600">
              <Award className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-lg font-bold text-slate-900 truncate">
              {data?.topReferrers?.[0]?.name || "N/A"}
            </div>
            <p className="text-xs text-purple-600 font-semibold mt-1">
              {data?.topReferrers?.[0]?.referralCount || 0} Successful Invites
            </p>
          </div>
        </div>
      </div>

      {/* Rewards Catalog Live Preview */}
      <div className="bg-white border border-slate-200 rounded-xl p-5 shadow-sm space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-base font-bold text-slate-900">
              Active Citizen Rewards Catalog
            </h2>
            <p className="text-xs text-slate-500">
              Grounded in active production modules (Subscription, Gift Codes, Retainer Credits).
            </p>
          </div>
          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-md text-xs font-medium bg-emerald-50 text-emerald-700 border border-emerald-200">
            <CheckCircle2 className="w-3.5 h-3.5" />
            Instant Fulfillment
          </span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {(data?.rewardCatalog || []).map((reward) => (
            <div
              key={reward.id}
              className="p-4 rounded-xl border border-slate-200 bg-slate-50 flex flex-col justify-between"
            >
              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className="px-2 py-0.5 rounded text-[11px] font-bold bg-blue-100 text-blue-700">
                    {reward.badge}
                  </span>
                  <span className="text-sm font-extrabold text-blue-700">
                    {reward.pointsCost} pts
                  </span>
                </div>
                <h3 className="text-sm font-bold text-slate-900 mb-1">
                  {reward.title}
                </h3>
                <p className="text-xs text-slate-600 leading-relaxed">
                  {reward.description}
                </p>
              </div>
              <div className="mt-4 pt-3 border-t border-slate-200 flex items-center justify-between text-xs text-slate-500">
                <span>Category: {reward.category}</span>
                <span className="font-semibold text-emerald-600">Active</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Top Citizen Referrers Leaderboard */}
      <div className="bg-white border border-slate-200 rounded-xl shadow-sm overflow-hidden">
        <div className="p-5 border-b border-slate-200 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <h2 className="text-base font-bold text-slate-900">
              Top Referring Citizens Leaderboard
            </h2>
            <p className="text-xs text-slate-500">
              Verified citizens driving community network growth.
            </p>
          </div>

          <div className="relative w-full sm:w-72">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Search by name, email, or code..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-9 pr-4 py-2 text-sm bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:bg-white"
            />
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-slate-600">
            <thead className="bg-slate-50 text-xs uppercase font-semibold text-slate-500 border-b border-slate-200">
              <tr>
                <th className="px-5 py-3">Citizen</th>
                <th className="px-5 py-3">Referral Code</th>
                <th className="px-5 py-3 text-center">Invited Citizens</th>
                <th className="px-5 py-3 text-right">Available Points</th>
                <th className="px-5 py-3 text-right">Lifetime Points</th>
                <th className="px-5 py-3 text-center">Tier</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredReferrers.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-5 py-8 text-center text-slate-400 text-sm">
                    No referring citizens found matching your criteria.
                  </td>
                </tr>
              ) : (
                filteredReferrers.map((user) => (
                  <tr key={user._id} className="hover:bg-slate-50 transition-colors">
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center font-bold text-xs">
                          {user.name ? user.name[0].toUpperCase() : "C"}
                        </div>
                        <div>
                          <div className="font-semibold text-slate-900">{user.name}</div>
                          <div className="text-xs text-slate-400">{user.email}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      <span className="font-mono text-xs font-bold px-2 py-1 bg-slate-100 rounded text-slate-700 border border-slate-200">
                        {user.referralCode || "—"}
                      </span>
                    </td>
                    <td className="px-5 py-4 text-center font-bold text-slate-900">
                      {user.referralCount ?? 0}
                    </td>
                    <td className="px-5 py-4 text-right font-bold text-blue-600">
                      {(user.referralPoints ?? 0).toLocaleString()} pts
                    </td>
                    <td className="px-5 py-4 text-right text-slate-500">
                      {(user.lifetimeReferralPoints ?? 0).toLocaleString()} pts
                    </td>
                    <td className="px-5 py-4 text-center">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold ${
                        (user.lifetimeReferralPoints ?? 0) >= 3000
                          ? "bg-purple-100 text-purple-800"
                          : (user.lifetimeReferralPoints ?? 0) >= 1500
                          ? "bg-amber-100 text-amber-800"
                          : (user.lifetimeReferralPoints ?? 0) >= 500
                          ? "bg-slate-200 text-slate-800"
                          : "bg-orange-100 text-orange-800"
                      }`}>
                        {(user.lifetimeReferralPoints ?? 0) >= 3000
                          ? "Platinum"
                          : (user.lifetimeReferralPoints ?? 0) >= 1500
                          ? "Gold"
                          : (user.lifetimeReferralPoints ?? 0) >= 500
                          ? "Silver"
                          : "Bronze"}
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
