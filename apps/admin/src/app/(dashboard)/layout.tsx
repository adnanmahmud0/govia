"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Sidebar from "@/components/dashboard/Sidebar";
import TopBar from "@/components/dashboard/TopBar";
import { useAuth } from "@/context/AuthContext";
import { ShieldAlert } from "lucide-react";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const { user, loading, isAuthenticated } = useAuth();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  useEffect(() => {
    if (!loading && !isAuthenticated) {
      router.replace("/login");
    }
  }, [loading, isAuthenticated, router]);

  // Loading skeleton while checking session
  if (loading) {
    return (
      <div className="min-h-screen bg-slate-50 flex flex-col items-center justify-center p-4">
        <div className="flex flex-col items-center gap-4">
          <div className="h-12 w-12 rounded-2xl bg-[#1554ad] flex items-center justify-center shadow-lg shadow-blue-500/20 animate-pulse">
            <span className="text-white font-black text-xl">G</span>
          </div>
          <div className="flex items-center gap-2 text-slate-500 text-sm font-medium">
            <div className="h-2 w-2 rounded-full bg-[#1554ad] animate-ping" />
            <span>Authenticating Govia Admin Portal...</span>
          </div>
        </div>
      </div>
    );
  }

  // If not authenticated and redirecting
  if (!isAuthenticated || !user) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4">
        <div className="text-center space-y-3">
          <ShieldAlert className="h-10 w-10 text-amber-500 mx-auto" />
          <p className="text-slate-700 font-medium">Redirecting to login...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-white text-black">
      <Sidebar
        isOpen={sidebarOpen}
        onClose={() => setSidebarOpen(false)}
      />
      <div className="lg:ml-64 flex flex-col min-h-screen">
        <TopBar
          onMenuToggle={() => setSidebarOpen(!sidebarOpen)}
        />
        <main className="p-4 md:p-6 flex-1 bg-white">{children}</main>
      </div>
    </div>
  );
}
