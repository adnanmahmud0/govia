"use client";

import React from "react";
import { Badge } from "@/components/ui/badge";
import UserManagementPage, { FieldDef } from "@/components/tables/UserManagementPage";
import { User } from "@/hooks/useUsers";
import { ColumnDef } from "@/components/tables/DataTable";

const columns: ColumnDef<User>[] = [
  { header: "Citizen / Patient Name", accessorKey: "name" },
  { header: "Email", accessorKey: "email" },
  {
    header: "Phone Number",
    cell: (u: User) => u.phoneNumber || "—",
  },
  {
    header: "Preferred Attorney",
    cell: (u: User) => (
      <span className="text-slate-600 text-xs">
        {u.preferredAttorney || <span className="text-slate-300">Not assigned</span>}
      </span>
    ),
  },
  {
    header: "Preferred Bondsman",
    cell: (u: User) => (
      <span className="text-slate-600 text-xs">
        {u.preferredBailBondsman || <span className="text-slate-300">Not assigned</span>}
      </span>
    ),
  },
  {
    header: "Status",
    cell: (u: User) => (
      <Badge
        className={
          u.status === "active"
            ? "bg-emerald-100 text-emerald-700 border-0"
            : "bg-red-100 text-red-700 border-0"
        }
      >
        {u.status === "active" ? "Active" : "Inactive"}
      </Badge>
    ),
  },
];

const fields: FieldDef[] = [
  { key: "name", label: "Full Name", placeholder: "Marcus Allen", required: true },
  { key: "email", label: "Email", placeholder: "marcus@example.com", type: "email", required: true },
  { key: "phoneNumber", label: "Emergency Phone", placeholder: "+1 (555) 000-0000", type: "tel" },
  { key: "preferredAttorney", label: "Preferred Attorney Name", placeholder: "e.g. Attorney Sarah Jenkins" },
  { key: "preferredBailBondsman", label: "Preferred Bail Bondsman", placeholder: "e.g. Quick Bail Bonds" },
  { key: "password", label: "Password", placeholder: "Min 8 characters", type: "password", required: true },
];

export default function PatientsPage() {
  return (
    <UserManagementPage
      title="Patients & Citizens Directory"
      description="Monitor registered citizens, mental health clients, emergency contacts, and assigned support providers."
      role="CITIZEN"
      fields={fields}
      columns={columns}
    />
  );
}
