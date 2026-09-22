"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import Link from "next/link";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import { AlertCircle, ArrowLeft, Loader2, CheckCircle2 } from "lucide-react";

export default function ResetEmailForm() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!email) return;

    setLoading(true);
    setError(null);

    try {
      const normalizedEmail = email.trim().toLowerCase();
      await api.post(
        "/auth/forget-password",
        { email: normalizedEmail },
        { requiresAuth: false }
      );

      if (typeof window !== "undefined") {
        sessionStorage.setItem("govia_reset_email", normalizedEmail);
      }

      setSuccess(true);
      setTimeout(() => {
        router.push("/verify");
      }, 1200);
    } catch (err: any) {
      setError(err.message || "Failed to send reset code. Please check your email address.");
      setLoading(false);
    }
  }

  return (
    <div className="w-full">
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold mb-2 text-slate-900 tracking-tight">Forgot Password</h1>
        <p className="text-slate-500 text-sm">
          Enter your admin email address to receive a 4-digit verification code.
        </p>
      </div>

      {error && (
        <div className="mb-6 flex items-start gap-2.5 p-3.5 rounded-xl bg-red-50 border border-red-200 text-red-700 text-sm font-medium">
          <AlertCircle className="w-5 h-5 shrink-0 text-red-500 mt-0.5" />
          <span>{error}</span>
        </div>
      )}

      {success && (
        <div className="mb-6 flex items-center gap-2.5 p-3.5 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm font-medium">
          <CheckCircle2 className="w-5 h-5 shrink-0 text-emerald-600" />
          <span>Reset code sent! Redirecting to verification...</span>
        </div>
      )}

      <form onSubmit={onSubmit} className="space-y-6">
        <div className="space-y-2 text-left">
          <label className="text-sm font-medium text-slate-700">Email Address</label>
          <Input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="admin@govia.com"
            disabled={loading || success}
            className="h-12 bg-slate-50 border-slate-200 text-slate-900 placeholder:text-slate-400 focus-visible:ring-blue-500/20"
          />
        </div>

        <Button
          variant="brand"
          type="submit"
          className="w-full h-12 text-base font-semibold"
          disabled={loading || success}
        >
          {loading ? (
            <span className="flex items-center gap-2">
              <Loader2 className="w-4 h-4 animate-spin" />
              Sending Code...
            </span>
          ) : (
            "Send Reset Code"
          )}
        </Button>

        <div className="text-center pt-2">
          <Link
            href="/login"
            className="inline-flex items-center gap-1.5 text-sm font-medium text-slate-500 hover:text-slate-800 transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            Back to Sign In
          </Link>
        </div>
      </form>
    </div>
  );
}
