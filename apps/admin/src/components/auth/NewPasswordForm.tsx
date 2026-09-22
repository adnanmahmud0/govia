"use client";

import { useRouter } from "next/navigation";
import { useState, useEffect } from "react";
import Link from "next/link";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import { Eye, EyeOff, AlertCircle, ArrowLeft, Loader2, CheckCircle2 } from "lucide-react";

export default function NewPasswordForm() {
  const router = useRouter();
  const [resetToken, setResetToken] = useState<string | null>(null);
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  useEffect(() => {
    if (typeof window !== "undefined") {
      const token = sessionStorage.getItem("govia_reset_token");
      if (token) {
        setResetToken(token);
      } else {
        setError("Reset session not found or expired. Please start over from Forgot Password.");
      }
    }
  }, []);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();

    if (!resetToken) {
      setError("No valid reset token found. Please start over.");
      return;
    }

    if (newPassword.length < 6) {
      setError("Password must be at least 6 characters long.");
      return;
    }

    if (newPassword !== confirmPassword) {
      setError("Passwords do not match!");
      return;
    }

    setLoading(true);
    setError(null);

    try {
      await api.post(
        "/auth/reset-password",
        {
          newPassword,
          confirmPassword,
        },
        {
          requiresAuth: false,
          headers: {
            Authorization: `Bearer ${resetToken}`,
          },
        }
      );

      // Clean up session storage
      if (typeof window !== "undefined") {
        sessionStorage.removeItem("govia_reset_token");
        sessionStorage.removeItem("govia_reset_email");
      }

      setSuccess(true);
      setTimeout(() => {
        router.push("/login?reset=success");
      }, 1500);
    } catch (err: any) {
      setError(err.message || "Failed to set new password. Please try again.");
      setLoading(false);
    }
  }

  return (
    <div className="w-full">
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold mb-2 text-slate-900 tracking-tight">Set New Password</h1>
        <p className="text-slate-500 text-sm">
          Create a new secure password for your administrator account.
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
          <span>Password updated successfully! Redirecting to login...</span>
        </div>
      )}

      <form onSubmit={onSubmit} className="space-y-6">
        <div className="space-y-2 text-left">
          <label className="text-sm font-medium text-slate-700">New Password</label>
          <div className="relative">
            <Input
              type={showNewPassword ? "text" : "password"}
              required
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              placeholder="Minimum 6 characters"
              disabled={loading || success || !resetToken}
              className="h-12 bg-slate-50 border-slate-200 text-slate-900 placeholder:text-slate-400 focus-visible:ring-blue-500/20 pr-12"
            />
            <button
              type="button"
              onClick={() => setShowNewPassword(!showNewPassword)}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors"
            >
              {showNewPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
            </button>
          </div>
        </div>

        <div className="space-y-2 text-left">
          <label className="text-sm font-medium text-slate-700">Confirm Password</label>
          <div className="relative">
            <Input
              type={showConfirmPassword ? "text" : "password"}
              required
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="Re-enter password"
              disabled={loading || success || !resetToken}
              className="h-12 bg-slate-50 border-slate-200 text-slate-900 placeholder:text-slate-400 focus-visible:ring-blue-500/20 pr-12"
            />
            <button
              type="button"
              onClick={() => setShowConfirmPassword(!showConfirmPassword)}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors"
            >
              {showConfirmPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
            </button>
          </div>
        </div>

        <Button
          variant="brand"
          type="submit"
          className="w-full h-12 text-base font-semibold"
          disabled={loading || success || !resetToken || !newPassword || !confirmPassword}
        >
          {loading ? (
            <span className="flex items-center gap-2">
              <Loader2 className="w-4 h-4 animate-spin" />
              Saving Password...
            </span>
          ) : (
            "Set New Password"
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
