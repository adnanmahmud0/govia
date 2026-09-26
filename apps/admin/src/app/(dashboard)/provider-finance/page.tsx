"use client";

import React, { useState, useEffect } from "react";
import {
  DollarSign,
  Percent,
  TrendingUp,
  ArrowUpRight,
  ShieldCheck,
  Search,
  RefreshCw,
  ExternalLink,
  CheckCircle2,
  AlertCircle,
  Clock,
  Scale,
  FileText,
} from "lucide-react";
import { api } from "@/lib/api";

interface CommissionSetting {
  platformCommissionPercent: number;
  updatedBy?: string;
  updatedAt?: string;
}

interface ProviderTransaction {
  _id: string;
  transactionId: string;
  citizenId: {
    _id: string;
    name: string;
    email: string;
  };
  providerId: {
    _id: string;
    name: string;
    email: string;
    role: string;
    lawFirmName?: string;
    companyName?: string;
  };
  role: "ATTORNEY" | "BAIL_BONDSMAN";
  type: "RETAINER" | "ENCOUNTER_FEE";
  grossAmount: number;
  platformFee: number;
  providerAmount: number;
  currency: string;
  status: "PENDING" | "COMPLETED" | "FAILED";
  stripeTransferId?: string;
  failureReason?: string;
  createdAt: string;
}

export default function ProviderFinancePage() {
  const [commission, setCommission] = useState<number>(10);
  const [initialCommission, setInitialCommission] = useState<number>(10);
  const [isSavingCommission, setIsSavingCommission] = useState<boolean>(false);
  const [commissionSuccessMsg, setCommissionSuccessMsg] = useState<string>("");

  const [transactions, setTransactions] = useState<ProviderTransaction[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [filterType, setFilterType] = useState<string>("ALL");
  const [filterRole, setFilterRole] = useState<string>("ALL");

  useEffect(() => {
    fetchCommission();
    fetchTransactions();
  }, []);

  const fetchCommission = async () => {
    try {
      const res = await api.get<CommissionSetting>(
        "/provider-payment/admin/commission"
      );
      if (res && typeof res.platformCommissionPercent === "number") {
        setCommission(res.platformCommissionPercent);
        setInitialCommission(res.platformCommissionPercent);
      }
    } catch (err) {
      console.error("Error fetching commission setting:", err);
    }
  };

  const fetchTransactions = async () => {
    setIsLoading(true);
    try {
      const res = await api.get<{ transactions: ProviderTransaction[] }>(
        "/provider-payment/transactions?limit=100"
      );
      if (res && Array.isArray(res.transactions)) {
        setTransactions(res.transactions);
      }
    } catch (err) {
      console.error("Error fetching provider transactions:", err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSaveCommission = async () => {
    setIsSavingCommission(true);
    setCommissionSuccessMsg("");
    try {
      await api.put("/provider-payment/admin/commission", {
        platformCommissionPercent: commission,
      });
      setInitialCommission(commission);
      setCommissionSuccessMsg(
        `Global platform commission updated to ${commission}% successfully!`
      );
      setTimeout(() => setCommissionSuccessMsg(""), 5000);
    } catch (err: any) {
      alert(err?.message || "Failed to update commission setting");
    } finally {
      setIsSavingCommission(false);
    }
  };

  // Calculations
  const totalGross = transactions.reduce((acc, t) => acc + (t.grossAmount || 0), 0);
  const totalPlatformFees = transactions.reduce((acc, t) => acc + (t.platformFee || 0), 0);
  const totalPayouts = transactions.reduce((acc, t) => acc + (t.providerAmount || 0), 0);

  const filteredTransactions = transactions.filter((t) => {
    if (filterType !== "ALL" && t.type !== filterType) return false;
    if (filterRole !== "ALL" && t.role !== filterRole) return false;
    if (!searchQuery.trim()) return true;

    const q = searchQuery.toLowerCase();
    const citizenName = t.citizenId?.name?.toLowerCase() || "";
    const providerName = t.providerId?.name?.toLowerCase() || "";
    const txId = t.transactionId?.toLowerCase() || "";
    return citizenName.includes(q) || providerName.includes(q) || txId.includes(q);
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Provider Payouts & Commission
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Configure global platform revenue share and monitor Stripe Connect Express transfers.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <a
            href="https://dashboard.stripe.com/test/connect/accounts/overview"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold bg-[#635BFF] text-white hover:bg-[#5349e0] transition-colors shadow-sm"
          >
            <span>Stripe Connect Dashboard</span>
            <ExternalLink className="h-4 w-4" />
          </a>
          <button
            onClick={() => {
              fetchCommission();
              fetchTransactions();
            }}
            className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 bg-white text-slate-700 hover:bg-slate-50 text-sm font-medium transition-colors"
          >
            <RefreshCw className={`h-4 w-4 ${isLoading ? "animate-spin" : ""}`} />
            <span>Refresh</span>
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Platform Commission
            </span>
            <div className="p-2 rounded-xl bg-blue-50 text-[#1554ad]">
              <Percent className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-extrabold text-slate-900">
              {commission}%
            </span>
            <span className="text-xs text-emerald-600 font-semibold">Active Rate</span>
          </div>
          <p className="text-xs text-slate-500 mt-1">Retained by GoVia on all fees</p>
        </div>

        <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Platform Revenue
            </span>
            <div className="p-2 rounded-xl bg-emerald-50 text-emerald-600">
              <TrendingUp className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-extrabold text-slate-900">
              ${totalPlatformFees.toFixed(2)}
            </span>
          </div>
          <p className="text-xs text-slate-500 mt-1">Total revenue collected</p>
        </div>

        <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Provider Payouts
            </span>
            <div className="p-2 rounded-xl bg-purple-50 text-purple-600">
              <DollarSign className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-extrabold text-slate-900">
              ${totalPayouts.toFixed(2)}
            </span>
          </div>
          <p className="text-xs text-slate-500 mt-1">Transferred via Stripe Express</p>
        </div>

        <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Total Volume
            </span>
            <div className="p-2 rounded-xl bg-amber-50 text-amber-600">
              <ShieldCheck className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-extrabold text-slate-900">
              ${totalGross.toFixed(2)}
            </span>
            <span className="text-xs text-slate-500">
              ({transactions.length} txns)
            </span>
          </div>
          <p className="text-xs text-slate-500 mt-1">Gross transaction value</p>
        </div>
      </div>

      {/* Commission Configuration Card */}
      <div className="p-6 rounded-2xl bg-white border border-slate-200 shadow-xs">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-5 border-b border-slate-100">
          <div>
            <h2 className="text-lg font-bold text-slate-900">
              Global Platform Commission Setting
            </h2>
            <p className="text-sm text-slate-500 mt-0.5">
              Specify the default percentage retained by GoVia whenever a citizen activates a preferred retainer or when an emergency encounter auto-payout executes.
            </p>
          </div>
          {commissionSuccessMsg && (
            <div className="flex items-center gap-2 text-xs font-semibold text-emerald-700 bg-emerald-50 px-3 py-1.5 rounded-lg border border-emerald-200">
              <CheckCircle2 className="h-4 w-4" />
              <span>{commissionSuccessMsg}</span>
            </div>
          )}
        </div>

        <div className="mt-6 max-w-2xl space-y-5">
          <div className="space-y-2">
            <div className="flex justify-between items-center text-sm font-semibold text-slate-700">
              <span>Commission Percentage:</span>
              <span className="text-lg font-extrabold text-[#1554ad]">{commission}%</span>
            </div>
            <input
              type="range"
              min="0"
              max="50"
              step="1"
              value={commission}
              onChange={(e) => setCommission(Number(e.target.value))}
              className="w-full h-2 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-[#1554ad]"
            />
            <div className="flex justify-between text-xs text-slate-400">
              <span>0% (Free for providers)</span>
              <span>10% (Default)</span>
              <span>25%</span>
              <span>50% (Max)</span>
            </div>
          </div>

          {/* Dynamic Example Simulator */}
          <div className="p-4 rounded-xl bg-slate-50 border border-slate-200/80 space-y-2">
            <p className="text-xs font-semibold text-slate-600 uppercase tracking-wider">
              Payout Preview Simulator (Example: $100.00 service fee)
            </p>
            <div className="grid grid-cols-2 gap-4 text-sm pt-1">
              <div className="p-3 bg-white rounded-lg border border-slate-200">
                <span className="text-xs text-slate-500 block">GoVia Platform Fee:</span>
                <span className="text-lg font-bold text-slate-900">
                  ${((100 * commission) / 100).toFixed(2)}
                </span>
                <span className="text-xs text-slate-400 block">Retained in platform account</span>
              </div>
              <div className="p-3 bg-white rounded-lg border border-slate-200">
                <span className="text-xs text-slate-500 block">Provider Net Payout:</span>
                <span className="text-lg font-bold text-emerald-600">
                  ${((100 * (100 - commission)) / 100).toFixed(2)}
                </span>
                <span className="text-xs text-slate-400 block">Deposited to provider bank</span>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-3 pt-2">
            <button
              onClick={handleSaveCommission}
              disabled={isSavingCommission || commission === initialCommission}
              className={`px-5 py-2.5 rounded-xl text-sm font-bold text-white transition-all ${
                commission === initialCommission
                  ? "bg-slate-300 cursor-not-allowed"
                  : "bg-[#1554ad] hover:bg-[#11448b] shadow-sm cursor-pointer"
              }`}
            >
              {isSavingCommission ? "Saving Setting..." : "Save Commission Rate"}
            </button>
            {commission !== initialCommission && (
              <button
                onClick={() => setCommission(initialCommission)}
                className="px-4 py-2.5 text-sm font-medium text-slate-600 hover:text-slate-900"
              >
                Reset
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Transactions Table Section */}
      <div className="rounded-2xl bg-white border border-slate-200 shadow-xs overflow-hidden">
        <div className="p-5 border-b border-slate-100 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h2 className="text-lg font-bold text-slate-900">
              Provider Payment Transactions
            </h2>
            <p className="text-sm text-slate-500 mt-0.5">
              Live audit record of monthly retainer coverage and encounter auto-payouts.
            </p>
          </div>

          {/* Filters & Search */}
          <div className="flex flex-wrap items-center gap-3">
            <div className="relative">
              <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
              <input
                type="text"
                placeholder="Search citizen or provider..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9 pr-3 py-1.5 rounded-xl border border-slate-200 text-sm focus:outline-hidden focus:ring-2 focus:ring-blue-500 w-56"
              />
            </div>

            <select
              value={filterType}
              onChange={(e) => setFilterType(e.target.value)}
              className="py-1.5 px-3 rounded-xl border border-slate-200 text-sm font-medium text-slate-700 bg-white"
            >
              <option value="ALL">All Types</option>
              <option value="RETAINER">Retainer (Monthly)</option>
              <option value="ENCOUNTER_FEE">Encounter (Auto-Payout)</option>
            </select>

            <select
              value={filterRole}
              onChange={(e) => setFilterRole(e.target.value)}
              className="py-1.5 px-3 rounded-xl border border-slate-200 text-sm font-medium text-slate-700 bg-white"
            >
              <option value="ALL">All Providers</option>
              <option value="ATTORNEY">Attorney</option>
              <option value="BAIL_BONDSMAN">Bail Bondsman</option>
            </select>
          </div>
        </div>

        {/* Table Content */}
        <div className="overflow-x-auto">
          {isLoading ? (
            <div className="p-12 text-center text-slate-400">
              <RefreshCw className="h-6 w-6 animate-spin mx-auto mb-2 text-[#1554ad]" />
              <p className="text-sm font-medium">Loading transaction records...</p>
            </div>
          ) : filteredTransactions.length === 0 ? (
            <div className="p-12 text-center text-slate-400">
              <DollarSign className="h-8 w-8 mx-auto mb-2 text-slate-300" />
              <p className="text-sm font-medium text-slate-600">No transactions recorded yet</p>
              <p className="text-xs text-slate-400 mt-1">
                When citizens activate preferred providers or meetings finish, payouts will appear here.
              </p>
            </div>
          ) : (
            <table className="w-full text-left border-collapse text-sm">
              <thead>
                <tr className="border-b border-slate-100 bg-slate-50/70 text-slate-500 text-xs font-semibold uppercase tracking-wider">
                  <th className="py-3 px-4">Date</th>
                  <th className="py-3 px-4">Transaction ID</th>
                  <th className="py-3 px-4">Type</th>
                  <th className="py-3 px-4">Citizen</th>
                  <th className="py-3 px-4">Provider</th>
                  <th className="py-3 px-4">Gross</th>
                  <th className="py-3 px-4">Platform Fee</th>
                  <th className="py-3 px-4">Provider Net</th>
                  <th className="py-3 px-4">Stripe Transfer</th>
                  <th className="py-3 px-4">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredTransactions.map((tx) => (
                  <tr key={tx._id} className="hover:bg-slate-50/60 transition-colors">
                    <td className="py-3.5 px-4 text-xs text-slate-500 whitespace-nowrap">
                      {new Date(tx.createdAt).toLocaleDateString()}
                      <span className="block text-[10px] text-slate-400">
                        {new Date(tx.createdAt).toLocaleTimeString([], {
                          hour: "2-digit",
                          minute: "2-digit",
                        })}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 font-mono text-xs font-bold text-slate-700">
                      {tx.transactionId}
                    </td>
                    <td className="py-3.5 px-4">
                      {tx.type === "RETAINER" ? (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-blue-50 text-blue-700 border border-blue-200">
                          Retainer (30d)
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
                          Encounter Call
                        </span>
                      )}
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="font-semibold text-slate-800">
                        {tx.citizenId?.name || "Citizen"}
                      </div>
                      <div className="text-xs text-slate-400">
                        {tx.citizenId?.email}
                      </div>
                    </td>
                    <td className="py-3.5 px-4">
                      <div className="font-semibold text-slate-800 flex items-center gap-1.5">
                        {tx.role === "ATTORNEY" ? (
                          <Scale className="h-3.5 w-3.5 text-blue-600" />
                        ) : (
                          <FileText className="h-3.5 w-3.5 text-teal-600" />
                        )}
                        <span>{tx.providerId?.name || "Provider"}</span>
                      </div>
                      <div className="text-xs text-slate-400">
                        {tx.providerId?.lawFirmName ||
                          tx.providerId?.companyName ||
                          tx.role}
                      </div>
                    </td>
                    <td className="py-3.5 px-4 font-bold text-slate-900 whitespace-nowrap">
                      ${tx.grossAmount.toFixed(2)}
                    </td>
                    <td className="py-3.5 px-4 text-xs font-semibold text-slate-600 whitespace-nowrap">
                      ${tx.platformFee.toFixed(2)}
                    </td>
                    <td className="py-3.5 px-4 font-bold text-emerald-600 whitespace-nowrap">
                      ${tx.providerAmount.toFixed(2)}
                    </td>
                    <td className="py-3.5 px-4 font-mono text-xs text-slate-500 whitespace-nowrap">
                      {tx.stripeTransferId ? (
                        <a
                          href={`https://dashboard.stripe.com/test/transfers/${tx.stripeTransferId}`}
                          target="_blank"
                          rel="noreferrer"
                          className="text-[#635BFF] hover:underline flex items-center gap-1"
                        >
                          <span>{tx.stripeTransferId.slice(-8)}</span>
                          <ArrowUpRight className="h-3 w-3" />
                        </a>
                      ) : (
                        <span className="text-slate-400">—</span>
                      )}
                    </td>
                    <td className="py-3.5 px-4">
                      {tx.status === "COMPLETED" ? (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700">
                          <CheckCircle2 className="h-3.5 w-3.5" />
                          <span>Paid</span>
                        </span>
                      ) : tx.status === "PENDING" ? (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold bg-amber-50 text-amber-700">
                          <Clock className="h-3.5 w-3.5" />
                          <span>Pending</span>
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold bg-rose-50 text-rose-700">
                          <AlertCircle className="h-3.5 w-3.5" />
                          <span>Failed</span>
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}
