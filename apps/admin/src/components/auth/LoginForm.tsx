"use client";

import { useRouter } from "next/navigation";
import { useState, useEffect } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import Link from "next/link";
import { Eye, EyeOff, AlertCircle, Shield, Crown, CheckCircle2 } from "lucide-react";
import { useAuth } from "@/context/AuthContext";

export default function LoginForm() {
  const router = useRouter();
  const { login, isAuthenticated } = useAuth();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [rememberMe, setRememberMe] = useState(true);
  const [resetSuccess, setResetSuccess] = useState(false);

  // If already logged in, redirect to overview
  useEffect(() => {
    if (isAuthenticated) {
      router.replace("/overview");
    }
  }, [isAuthenticated, router]);

  useEffect(() => {
    if (typeof window !== "undefined") {
      const params = new URLSearchParams(window.location.search);
      if (params.get("reset") === "success") {
        setResetSuccess(true);
      }
    }
  }, []);

  const handleFillCredentials = (demoEmail: string, demoPass: string) => {
    setEmail(demoEmail);
    setPassword(demoPass);
    setError(null);
  };

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!email || !password) return;

    setError(null);
    setLoading(true);

    try {
      await login(email, password);
      router.push("/overview");
    } catch (err: any) {
      setError(err?.message || "Failed to log in. Please check your credentials.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="w-full max-w-md mx-auto">
      <div className="text-center mb-8">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-50 border border-blue-100 text-blue-700 text-xs font-semibold mb-3">
          <Shield className="w-3.5 h-3.5 text-blue-600" />
          <span>Govia Administrative Portal</span>
        </div>
        <h1 className="text-3xl font-bold text-slate-900 tracking-tight">
          Welcome Back
        </h1>
        <p className="text-slate-500 text-sm mt-1">
          Authorized Administrator & Super Admin Access
        </p>
      </div>

      {resetSuccess && (
        <div className="mb-6 p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm flex items-start gap-3 shadow-sm">
          <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />
          <div className="flex-1 font-medium">
            Your password has been successfully reset! You may now sign in with your new password.
          </div>
        </div>
      )}

      {error && (
        <div className="mb-6 p-4 rounded-xl bg-red-50 border border-red-200 text-red-700 text-sm flex items-start gap-3 shadow-sm">
          <AlertCircle className="w-5 h-5 text-red-500 shrink-0 mt-0.5" />
          <div className="flex-1 font-medium">{error}</div>
        </div>
      )}

      {/* Quick Demo Credentials Selection */}
      <div className="mb-6 p-3.5 rounded-xl bg-slate-50 border border-slate-200/80">
        <div className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2 text-center">
          Quick Sign-In Credentials
        </div>
        <div className="grid grid-cols-2 gap-2">
          <button
            type="button"
            onClick={() => handleFillCredentials("admin@govia.com", "Password123!")}
            className="flex flex-col items-start p-2.5 rounded-lg border border-amber-200 bg-amber-50/60 hover:bg-amber-100/70 text-left transition-all group cursor-pointer"
          >
            <div className="flex items-center gap-1.5 text-xs font-bold text-amber-900">
              <Crown className="w-3.5 h-3.5 text-amber-600" />
              <span>Super Admin</span>
            </div>
            <span className="text-[11px] text-amber-700/80 truncate w-full mt-0.5">
              admin@govia.com
            </span>
          </button>

          <button
            type="button"
            onClick={() => handleFillCredentials("ops.admin@govia.com", "Password123!")}
            className="flex flex-col items-start p-2.5 rounded-lg border border-blue-200 bg-blue-50/60 hover:bg-blue-100/70 text-left transition-all group cursor-pointer"
          >
            <div className="flex items-center gap-1.5 text-xs font-bold text-blue-900">
              <Shield className="w-3.5 h-3.5 text-blue-600" />
              <span>Admin (Ops)</span>
            </div>
            <span className="text-[11px] text-blue-700/80 truncate w-full mt-0.5">
              ops.admin@govia.com
            </span>
          </button>
        </div>
      </div>

      <form onSubmit={onSubmit} className="space-y-5">
        <div className="space-y-1.5 text-left">
          <label className="text-sm font-medium text-slate-700">Email Address</label>
          <Input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="admin@govia.com"
            className="h-12 bg-slate-50 border-slate-200 text-slate-900 placeholder:text-slate-400 focus-visible:ring-blue-500/20"
          />
        </div>

        <div className="space-y-1.5 text-left">
          <label className="text-sm font-medium text-slate-700">Password</label>
          <div className="relative">
            <Input
              type={showPassword ? "text" : "password"}
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              className="h-12 bg-slate-50 border-slate-200 text-slate-900 placeholder:text-slate-400 focus-visible:ring-blue-500/20 pr-12"
            />
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors p-1"
            >
              {showPassword ? (
                <EyeOff className="h-5 w-5" />
              ) : (
                <Eye className="h-5 w-5" />
              )}
            </button>
          </div>
        </div>

        <div className="flex items-center justify-between pt-1">
          <label
            onClick={() => setRememberMe(!rememberMe)}
            className="flex items-center space-x-2 cursor-pointer select-none"
          >
            <div
              className={`h-4 w-4 rounded border flex items-center justify-center transition-colors ${
                rememberMe
                  ? "bg-[#1554ad] border-[#1554ad] text-white"
                  : "border-slate-300 bg-slate-50"
              }`}
            >
              {rememberMe && <CheckCircle2 className="w-3.5 h-3.5" />}
            </div>
            <span className="text-sm text-slate-600 font-medium">Remember me</span>
          </label>
          <Link
            href="/reset"
            className="text-sm text-slate-900 font-medium underline hover:text-blue-600 transition-colors"
          >
            Forgot Password?
          </Link>
        </div>

        <Button
          type="submit"
          variant="brand"
          className="w-full h-12 text-base font-semibold shadow-md shadow-blue-500/10 cursor-pointer"
          disabled={loading}
        >
          {loading ? (
            <div className="flex items-center gap-2">
              <div className="h-4 w-4 rounded-full border-2 border-white/30 border-t-white animate-spin" />
              <span>Verifying Credentials...</span>
            </div>
          ) : (
            "Sign In to Admin Portal"
          )}
        </Button>
      </form>
    </div>
  );
}
