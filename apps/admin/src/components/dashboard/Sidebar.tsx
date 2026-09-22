"use client";
import React from "react";
import Link from "next/link";
import Image from "next/image";
import { cn } from "@/lib/utils";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  Users,
  ChevronLeft,
  LucideIcon,
  Shield,
  Scale,
  HeartPulse,
  FileText,
  Activity,
  History,
  Star,
  Map,
  Gift,
  CreditCard,
  FileSignature,
  User,
  Bell,
  LogOut,
  Crown,
  BookOpen,
  UserCheck,
  Video,
} from "lucide-react";
import {
  Sheet,
  SheetContent,
  SheetClose,
} from "@/components/ui/sheet";
import { useAuth } from "@/context/AuthContext";
import { useNotifications } from "@/hooks/useNotifications";
import { useMeetings } from "@/hooks/useMeetings";

type IconType = LucideIcon;

const items: Array<{
  href: string;
  label: string;
  Icon: IconType;
}> = [
  { href: "/overview", label: "Overview", Icon: LayoutDashboard },
  { href: "/users", label: "All Users", Icon: Users },
  { href: "/citizen-management", label: "Citizen Management", Icon: UserCheck },
  { href: "/police-management", label: "Police Management", Icon: Shield },
  { href: "/attorney-management", label: "Attorney Management", Icon: Scale },
  { href: "/mhp-management", label: "MHP Management", Icon: HeartPulse },
  { href: "/bonds-management", label: "Bonds Management", Icon: FileText },
  { href: "/patients", label: "Patients & Clients", Icon: HeartPulse },
  { href: "/live-call-monitoring", label: "Live Call Monitoring", Icon: Activity },
  { href: "/call-history", label: "Call History", Icon: History },
  { href: "/recordings", label: "Meeting Recordings", Icon: Video },
  { href: "/hero-highlight", label: "Hero Highlight", Icon: Star },
  { href: "/formularies", label: "Community Resources", Icon: BookOpen },
  { href: "/notification", label: "Notification", Icon: Bell },
  { href: "/risk-map", label: "Risk Map", Icon: Map },
  { href: "/gift-code", label: "Gift Code", Icon: Gift },
  { href: "/subscription", label: "Subscription", Icon: CreditCard },
  { href: "/subpoena", label: "Subpoena", Icon: FileSignature },
  { href: "/profile", label: "Profile", Icon: User },
];

interface SidebarProps {
  active?: string;
  isOpen?: boolean;
  onClose?: () => void;
}

export default function Sidebar({ active, isOpen, onClose }: SidebarProps) {
  const pathname = usePathname();
  const current = active ?? pathname ?? "";
  const { user, isSuperAdmin, logout } = useAuth();
  const { unreadCount } = useNotifications();
  const { activeMeetings } = useMeetings();

  const SidebarContent = () => (
    <div className="h-full bg-white text-slate-600 flex flex-col">
      <div className="p-6 pb-3 border-b border-slate-100">
        <div className="flex flex-col items-center justify-center w-full">
          <Image
            src="/image 1 (1).png"
            alt="Govia Logo"
            width={80}
            height={80}
            className="w-auto h-20 object-contain"
            priority
          />
          {user && (
            <div
              className={`mt-2 px-3 py-1 rounded-full text-[11px] font-bold tracking-wide flex items-center gap-1.5 shadow-2xs ${
                isSuperAdmin
                  ? "bg-amber-50 text-amber-900 border border-amber-200"
                  : "bg-blue-50 text-blue-900 border border-blue-200"
              }`}
            >
              {isSuperAdmin ? (
                <Crown className="w-3 h-3 text-amber-600" />
              ) : (
                <Shield className="w-3 h-3 text-blue-600" />
              )}
              <span>{isSuperAdmin ? "SUPER ADMIN" : "ADMIN"}</span>
            </div>
          )}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-4 py-4 scrollbar-thin scrollbar-thumb-slate-200">
        <nav className="space-y-1">
          {items.map((item) => {
            const isActive = current === item.href || current.startsWith(`${item.href}/`);
            const isLiveMonitoring = item.href === "/live-call-monitoring";
            const isNotification = item.href === "/notification";

            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={onClose}
                className={cn(
                  "flex items-center justify-between px-4 py-2.5 text-sm transition-colors rounded-xl",
                  isActive
                    ? "bg-[#1554ad] text-white font-medium shadow-xs"
                    : "text-slate-700 font-semibold hover:bg-slate-50 hover:text-slate-900"
                )}
              >
                <div className="flex items-center gap-3">
                  <item.Icon className={cn("h-4 w-4", isActive ? "text-white" : "text-slate-600")} />
                  <span>{item.label}</span>
                </div>

                {/* Badge indicators */}
                {isNotification && unreadCount > 0 && (
                  <span
                    className={cn(
                      "text-[10px] font-bold px-1.5 py-0.5 rounded-full",
                      isActive ? "bg-white text-[#1554ad]" : "bg-red-500 text-white"
                    )}
                  >
                    {unreadCount > 9 ? "9+" : unreadCount}
                  </span>
                )}

                {isLiveMonitoring && activeMeetings.length > 0 && (
                  <span
                    className={cn(
                      "flex items-center gap-1 text-[10px] font-bold px-1.5 py-0.5 rounded-full animate-pulse",
                      isActive ? "bg-white text-[#1554ad]" : "bg-emerald-500 text-white"
                    )}
                  >
                    <span className="w-1.5 h-1.5 rounded-full bg-white" />
                    {activeMeetings.length}
                  </span>
                )}
              </Link>
            );
          })}
        </nav>
      </div>

      <div className="p-4 border-t border-slate-100">
        <button
          onClick={() => logout()}
          className="flex items-center gap-3 w-full px-4 py-2 text-sm font-semibold text-red-600 hover:bg-red-50 rounded-xl transition-colors cursor-pointer"
        >
          <LogOut className="h-4 w-4" />
          <span>Sign Out</span>
        </button>
      </div>
    </div>
  );

  return (
    <>
      <aside className="hidden lg:flex h-screen w-64 bg-white text-slate-600 border-r border-slate-200 fixed left-0 top-0 flex flex-col">
        <SidebarContent />
      </aside>

      <Sheet open={isOpen} onOpenChange={(open) => !open && onClose?.()}>
        <SheetContent side="left" className="p-0 w-64" showCloseButton={false}>
          <div className="absolute top-4 right-4">
            <SheetClose className="rounded-sm opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2">
              <ChevronLeft className="h-6 w-6" />
              <span className="sr-only">Close</span>
            </SheetClose>
          </div>
          <SidebarContent />
        </SheetContent>
      </Sheet>
    </>
  );
}
