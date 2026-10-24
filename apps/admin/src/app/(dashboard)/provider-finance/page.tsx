"use client";

import React, { useState, useEffect, useCallback } from "react";
import {
  DollarSign,
  TrendingUp,
  ShieldCheck,
  Search,
  RefreshCw,
  ExternalLink,
  CheckCircle2,
  AlertCircle,
  Clock,
  Scale,
  FileText,
  Save,
} from "lucide-react";
import { api } from "@/lib/api";

interface ServiceChargeSetting {
  attorneyServiceFee: number;
  bailBondsmanServiceFee: number;
  platformCommissionPercent?: number;
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
  providerId?: {
    _id: string;
    name: string;
    email: string;
    role: string;
    lawFirmName?: string;
    companyName?: string;
  };
  role: "ATTORNEY" | "BAIL_BONDSMAN";
  type: string;
  grossAmount: number;
  platformFee?: number;
  providerAmount?: number;
  currency: string;
  status: "PENDING" | "COMPLETED" | "FAILED";
  createdAt: string;
}

export default function ProviderFinancePage() {
  const [attorneyFee, setAttorneyFee] = useState<number>(50);
  const [bondsmanFee, setBondsmanFee] = useState<number>(30);
  const [initialAttorneyFee, setInitialAttorneyFee] = useState<number>(50);
  const [initialBondsmanFee, setInitialBondsmanFee] = useState<number>(30);

  const [isSavingFees, setIsSavingFees] = useState<boolean>(false);
  const [saveSuccessMsg, setSaveSuccessMsg] = useState<string>("");

  const [transactions, setTransactions] = useState<ProviderTransaction[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [filterRole, setFilterRole] = useState<string>("ALL");

  const fetchServiceCharges = useCallback(async () => {
    try {
      const res = await api.get<ServiceChargeSetting>(
        "/provider-payment/service-charge"
      );
      if (res) {
        if (typeof res.attorneyServiceFee === "number") {
          setAttorneyFee(res.attorneyServiceFee);
          setInitialAttorneyFee(res.attorneyServiceFee);
        }
        if (typeof res.bailBondsmanServiceFee === "number") {
          setBondsmanFee(res.bailBondsmanServiceFee);
          setInitialBondsmanFee(res.bailBondsmanServiceFee);
        }
      }
    } catch (err) {
      console.error("Error fetching service charge setting:", err);
    }
  }, []);

  const fetchTransactions = useCallback(async () => {
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
  }, []);

  useEffect(() => {
    fetchServiceCharges();
    fetchTransactions();
  }, [fetchServiceCharges, fetchTransactions]);

  const handleSaveServiceCharges = async () => {
    setIsSavingFees(true);
    setSaveSuccessMsg("");
    try {
      await api.put("/provider-payment/admin/service-charge", {
        attorneyServiceFee: attorneyFee,
        bailBondsmanServiceFee: bondsmanFee,
      });
      setInitialAttorneyFee(attorneyFee);
      setInitialBondsmanFee(bondsmanFee);
      setSaveSuccessMsg(
        `Platform service charges updated successfully! (Attorney: $${attorneyFee.toFixed(2)}, Bail Bondsman: $${bondsmanFee.toFixed(2)})`
      );
      setTimeout(() => setSaveSuccessMsg(""), 5000);
    } catch (err: unknown) {
      alert((err as Error)?.message || "Failed to update service charges");
    } finally {
      setIsSavingFees(false);
    }
  };

  const hasChanges =
    attorneyFee !== initialAttorneyFee || bondsmanFee !== initialBondsmanFee;

  // Calculations
  const completedTransactions = transactions.filter((t) => t.status === "COMPLETED");
  const totalRevenue = completedTransactions.reduce(
    (acc, t) => acc + (t.grossAmount || 0),
    0
  );

  const filteredTransactions = transactions.filter((t) => {
    if (filterRole !== "ALL" && t.role !== filterRole) return false;
    if (!searchQuery.trim()) return true;

    const q = searchQuery.toLowerCase();
    const citizenName = t.citizenId?.name?.toLowerCase() || "";
    const citizenEmail = t.citizenId?.email?.toLowerCase() || "";
    const providerName = t.providerId?.name?.toLowerCase() || "";
    const txId = t.transactionId?.toLowerCase() || "";
    return (
      citizenName.includes(q) ||
      citizenEmail.includes(q) ||
      providerName.includes(q) ||
      txId.includes(q)
    );
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900">
            Platform Service Charges & Revenue
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Configure global citizen service charges for Preferred Attorneys and Bail Bondsmen, and monitor subscription revenue.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <a
            href="https://dashboard.stripe.com/test/payments"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold bg-[#635BFF] text-white hover:bg-[#5349e0] transition-colors shadow-sm"
          >
            <span>Stripe Payments</span>
            <ExternalLink className="h-4 w-4" />
          </a>
          <button
            onClick={() => {
              fetchServiceCharges();
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
              Attorney Service Fee
            </span>
            <div className="p-2 rounded-xl bg-blue-50 text-[#1554ad]">
              <Scale className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-extrabold text-slate-900">
              ${attorneyFee.toFixed(2)}
            </span>
            <span className="text-xs text-slate-500 font-medium">/ month</span>
          </div>
          <p className="text-xs text-slate-500 mt-1">Legal defense coverage fee</p>
        </div>

        <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Bondsman Service Fee
            </span>
            <div className="p-2 rounded-xl bg-teal-50 text-teal-600">
              <FileText className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-extrabold text-slate-900">
              ${bondsmanFee.toFixed(2)}
            </span>
            <span className="text-xs text-slate-500 font-medium">/ month</span>
          </div>
          <p className="text-xs text-slate-500 mt-1">24/7 bail release coverage fee</p>
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
              ${totalRevenue.toFixed(2)}
            </span>
          </div>
          <p className="text-xs text-slate-500 mt-1">Total service fees collected</p>
        </div>

        <div className="p-5 rounded-2xl bg-white border border-slate-200/80 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              Total Subscriptions
            </span>
            <div className="p-2 rounded-xl bg-amber-50 text-amber-600">
              <ShieldCheck className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-3 flex items-baseline gap-2">
            <span className="text-3xl font-extrabold text-slate-900">
              {completedTransactions.length}
            </span>
            <span className="text-xs text-slate-500">
              ({transactions.length} total)
            </span>
          </div>
          <p className="text-xs text-slate-500 mt-1">Protected citizen activations</p>
        </div>
      </div>

      {/* Service Charges Configuration Card */}
      <div className="p-6 rounded-2xl bg-white border border-slate-200 shadow-xs">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-5 border-b border-slate-100">
          <div>
            <h2 className="text-lg font-bold text-slate-900">
              Global Platform Service Charges
            </h2>
            <p className="text-sm text-slate-500 mt-0.5">
              Set the monthly service charges that Citizens pay via Stripe Checkout to activate 30-day emergency protection coverage and select their preferred providers.
            </p>
          </div>
          {saveSuccessMsg && (
            <div className="flex items-center gap-2 text-xs font-semibold text-emerald-700 bg-emerald-50 px-3 py-1.5 rounded-lg border border-emerald-200">
              <CheckCircle2 className="h-4 w-4" />
              <span>{saveSuccessMsg}</span>
            </div>
          )}
        </div>

        <div className="mt-6 max-w-3xl space-y-6">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
            {/* Preferred Attorney Fee */}
            <div className="p-5 rounded-xl border border-slate-200 bg-slate-50/50 space-y-3">
              <div className="flex items-center gap-2 text-slate-900 font-bold text-sm">
                <Scale className="h-4 w-4 text-[#1554ad]" />
                <span>Preferred Attorney Service Charge</span>
              </div>
              <p className="text-xs text-slate-500 leading-relaxed">
                Monthly service fee paid by citizens to retain a designated Preferred Attorney on their profile for 24/7 priority emergency dispatch.
              </p>
              <div className="relative pt-1">
                <span className="absolute left-3.5 top-3.5 text-slate-400 font-semibold text-sm">
                  $
                </span>
                <input
                  type="number"
                  min="0"
                  step="1"
                  value={attorneyFee}
                  onChange={(e) => setAttorneyFee(Math.max(0, Number(e.target.value)))}
                  className="w-full pl-8 pr-4 py-2.5 rounded-xl border border-slate-200 bg-white font-bold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-[#1554ad] text-base"
                />
              </div>
              <div className="flex items-center gap-2 pt-1 text-xs">
                <span className="text-slate-400 font-medium">Quick presets:</span>
                {[29, 49, 79, 99].map((p) => (
                  <button
                    key={p}
                    type="button"
                    onClick={() => setAttorneyFee(p)}
                    className={`px-2 py-0.5 rounded-md border text-xs font-semibold transition-colors ${
                      attorneyFee === p
                        ? "bg-[#1554ad] text-white border-[#1554ad]"
                        : "bg-white text-slate-600 border-slate-200 hover:bg-slate-100"
                    }`}
                  >
                    ${p}
                  </button>
                ))}
              </div>
            </div>

            {/* Preferred Bail Bondsman Fee */}
            <div className="p-5 rounded-xl border border-slate-200 bg-slate-50/50 space-y-3">
              <div className="flex items-center gap-2 text-slate-900 font-bold text-sm">
                <FileText className="h-4 w-4 text-teal-600" />
                <span>Preferred Bail Bondsman Service Charge</span>
              </div>
              <p className="text-xs text-slate-500 leading-relaxed">
                Monthly service fee paid by citizens to retain a licensed Bail Bondsman on their profile for immediate custody release assistance.
              </p>
              <div className="relative pt-1">
                <span className="absolute left-3.5 top-3.5 text-slate-400 font-semibold text-sm">
                  $
                </span>
                <input
                  type="number"
                  min="0"
                  step="1"
                  value={bondsmanFee}
                  onChange={(e) => setBondsmanFee(Math.max(0, Number(e.target.value)))}
                  className="w-full pl-8 pr-4 py-2.5 rounded-xl border border-slate-200 bg-white font-bold text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-teal-600 text-base"
                />
              </div>
              <div className="flex items-center gap-2 pt-1 text-xs">
                <span className="text-slate-400 font-medium">Quick presets:</span>
                {[19, 29, 49, 69].map((p) => (
                  <button
                    key={p}
                    type="button"
                    onClick={() => setBondsmanFee(p)}
                    className={`px-2 py-0.5 rounded-md border text-xs font-semibold transition-colors ${
                      bondsmanFee === p
                        ? "bg-teal-600 text-white border-teal-600"
                        : "bg-white text-slate-600 border-slate-200 hover:bg-slate-100"
                    }`}
                  >
                    ${p}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <div className="flex items-center gap-3 pt-2">
            <button
              onClick={handleSaveServiceCharges}
              disabled={isSavingFees || !hasChanges}
              className={`inline-flex items-center gap-2 px-5 py-2.5 rounded-xl text-sm font-bold text-white transition-all ${
                !hasChanges
                  ? "bg-slate-300 cursor-not-allowed"
                  : "bg-[#1554ad] hover:bg-[#11448b] shadow-sm cursor-pointer"
              }`}
            >
              <Save className="h-4 w-4" />
              <span>{isSavingFees ? "Saving Charges..." : "Save Service Charges"}</span>
            </button>
            {hasChanges && (
              <button
                onClick={() => {
                  setAttorneyFee(initialAttorneyFee);
                  setBondsmanFee(initialBondsmanFee);
                }}
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
              Service Fee Payment Transactions
            </h2>
            <p className="text-sm text-slate-500 mt-0.5">
              Live audit record of citizen payments for Preferred Attorney and Bail Bondsman protection coverage.
            </p>
          </div>

          {/* Filters & Search */}
          <div className="flex flex-wrap items-center gap-3">
            <div className="relative">
              <Search className="absolute left-3 top-2.5 h-4 w-4 text-slate-400" />
              <input
                type="text"
                placeholder="Search citizen or transaction..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9 pr-3 py-1.5 rounded-xl border border-slate-200 text-sm focus:outline-hidden focus:ring-2 focus:ring-blue-500 w-56"
              />
            </div>

            <select
              value={filterRole}
              onChange={(e) => setFilterRole(e.target.value)}
              className="py-1.5 px-3 rounded-xl border border-slate-200 text-sm font-medium text-slate-700 bg-white"
            >
              <option value="ALL">All Services</option>
              <option value="ATTORNEY">Attorney Protection</option>
              <option value="BAIL_BONDSMAN">Bail Bondsman Coverage</option>
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
                When citizens pay service charges, payments will appear here.
              </p>
            </div>
          ) : (
            <table className="w-full text-left border-collapse text-sm">
              <thead>
                <tr className="border-b border-slate-100 bg-slate-50/70 text-slate-500 text-xs font-semibold uppercase tracking-wider">
                  <th className="py-3 px-4">Date</th>
                  <th className="py-3 px-4">Transaction ID</th>
                  <th className="py-3 px-4">Service</th>
                  <th className="py-3 px-4">Citizen</th>
                  <th className="py-3 px-4">Selected Provider</th>
                  <th className="py-3 px-4">Amount Paid</th>
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
                      {tx.role === "ATTORNEY" ? (
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-blue-50 text-blue-700 border border-blue-200">
                          <Scale className="h-3 w-3" />
                          <span>Attorney Protection</span>
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-teal-50 text-teal-700 border border-teal-200">
                          <FileText className="h-3 w-3" />
                          <span>Bail Bondsman</span>
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
                      {tx.providerId ? (
                        <div>
                          <div className="font-semibold text-slate-800">
                            {tx.providerId.name}
                          </div>
                          <div className="text-xs text-slate-400">
                            {tx.providerId.lawFirmName ||
                              tx.providerId.companyName ||
                              tx.role}
                          </div>
                        </div>
                      ) : (
                        <span className="text-xs text-slate-400 italic">
                          Selected later by citizen
                        </span>
                      )}
                    </td>
                    <td className="py-3.5 px-4 font-bold text-slate-900 whitespace-nowrap">
                      ${tx.grossAmount.toFixed(2)}
                    </td>
                    <td className="py-3.5 px-4">
                      {tx.status === "COMPLETED" ? (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700">
                          <CheckCircle2 className="h-3.5 w-3.5" />
                          <span>Paid</span>
                        </span>
                      ) : tx.status === "PENDING" ? (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-50 text-amber-700">
                          <Clock className="h-3.5 w-3.5" />
                          <span>Pending</span>
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-rose-50 text-rose-700">
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
