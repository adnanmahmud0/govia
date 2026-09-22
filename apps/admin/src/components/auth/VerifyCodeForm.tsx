"use client";

import { useRouter } from "next/navigation";
import { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api";
import { AlertCircle, ArrowLeft, Loader2, CheckCircle2, RotateCw } from "lucide-react";

export default function VerifyCodeForm() {
  const router = useRouter();
  const [email, setEmail] = useState<string>("");
  const [digits, setDigits] = useState<string[]>(["", "", "", ""]);
  const [loading, setLoading] = useState(false);
  const [resending, setResending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [resendCooldown, setResendCooldown] = useState(0);

  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

  useEffect(() => {
    if (typeof window !== "undefined") {
      const stored = sessionStorage.getItem("govia_reset_email");
      if (stored) {
        setEmail(stored);
      }
    }
  }, []);

  // Cooldown countdown timer
  useEffect(() => {
    if (resendCooldown > 0) {
      const timer = setTimeout(() => setResendCooldown((prev) => prev - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [resendCooldown]);

  const handleChange = (index: number, val: string) => {
    // Only accept numbers
    const clean = val.replace(/\D/g, "");
    if (!clean && val !== "") return;

    const char = clean.slice(-1);
    const newDigits = [...digits];
    newDigits[index] = char;
    setDigits(newDigits);

    // Auto-focus next input
    if (char && index < 3) {
      inputRefs.current[index + 1]?.focus();
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Backspace" && !digits[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  };

  const handlePaste = (e: React.ClipboardEvent<HTMLInputElement>) => {
    e.preventDefault();
    const pasteData = e.clipboardData.getData("text").replace(/\D/g, "").slice(0, 4);
    if (!pasteData) return;

    const newDigits = [...digits];
    for (let i = 0; i < pasteData.length; i++) {
      newDigits[i] = pasteData[i];
    }
    setDigits(newDigits);

    const targetIndex = Math.min(pasteData.length, 3);
    inputRefs.current[targetIndex]?.focus();
  };

  const handleResend = async () => {
    if (!email || resendCooldown > 0 || resending) return;

    setResending(true);
    setError(null);

    try {
      await api.post("/auth/forget-password", { email }, { requiresAuth: false });
      setResendCooldown(60);
    } catch (err: any) {
      setError(err.message || "Failed to resend code. Please try again.");
    } finally {
      setResending(false);
    }
  };

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    const fullCode = digits.join("");
    if (fullCode.length < 4) {
      setError("Please enter the complete 4-digit verification code.");
      return;
    }

    if (!email) {
      setError("Email address missing. Please return to forgot password step.");
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await api.post<any>(
        "/auth/verify-email",
        {
          email,
          oneTimeCode: Number(fullCode),
        },
        { requiresAuth: false }
      );

      // Backend returns reset token in `data`
      const resetToken = response?.data || response;
      if (typeof window !== "undefined" && resetToken) {
        sessionStorage.setItem("govia_reset_token", typeof resetToken === "string" ? resetToken : String(resetToken));
      }

      setSuccess(true);
      setTimeout(() => {
        router.push("/new-password");
      }, 1000);
    } catch (err: any) {
      setError(err.message || "Invalid or expired verification code. Please check and try again.");
      setLoading(false);
    }
  }

  return (
    <div className="w-full">
      <div className="text-center mb-8">
        <h1 className="text-3xl font-bold mb-2 text-slate-900 tracking-tight">Verify Reset Code</h1>
        <p className="text-slate-500 text-sm">
          Enter the 4-digit code sent to{" "}
          <span className="font-semibold text-slate-700">{email || "your email"}</span>
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
          <span>Code verified! Redirecting to set new password...</span>
        </div>
      )}

      <form onSubmit={onSubmit} className="space-y-7">
        <div className="flex justify-center gap-3">
          {digits.map((digit, index) => (
            <input
              key={index}
              ref={(el) => {
                inputRefs.current[index] = el;
              }}
              id={`code-${index}`}
              type="text"
              inputMode="numeric"
              maxLength={1}
              value={digit}
              disabled={loading || success}
              onChange={(e) => handleChange(index, e.target.value)}
              onKeyDown={(e) => handleKeyDown(index, e)}
              onPaste={handlePaste}
              className="w-14 h-16 bg-slate-50 border border-slate-300 rounded-xl text-center text-2xl font-bold text-slate-900 focus:border-[#1554ad] focus:ring-2 focus:ring-[#1554ad]/20 outline-none transition-all disabled:opacity-50"
            />
          ))}
        </div>

        <div className="flex items-center justify-between text-xs text-slate-500 px-1">
          <span>Didn&apos;t receive code?</span>
          <button
            type="button"
            onClick={handleResend}
            disabled={resendCooldown > 0 || resending || loading}
            className="flex items-center gap-1 font-semibold text-[#1554ad] hover:text-[#11438a] disabled:text-slate-400 disabled:cursor-not-allowed transition-colors"
          >
            <RotateCw className={`w-3 h-3 ${resending ? "animate-spin" : ""}`} />
            {resendCooldown > 0 ? `Resend in ${resendCooldown}s` : "Resend Code"}
          </button>
        </div>

        <Button
          type="submit"
          variant="brand"
          className="w-full h-12 text-base font-semibold"
          disabled={loading || success || digits.some((d) => !d)}
        >
          {loading ? (
            <span className="flex items-center gap-2">
              <Loader2 className="w-4 h-4 animate-spin" />
              Verifying Code...
            </span>
          ) : (
            "Verify Code"
          )}
        </Button>

        <div className="text-center pt-2">
          <Link
            href="/reset"
            className="inline-flex items-center gap-1.5 text-sm font-medium text-slate-500 hover:text-slate-800 transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            Change Email
          </Link>
        </div>
      </form>
    </div>
  );
}
