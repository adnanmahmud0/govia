"use client";

import React from "react";
import { Badge } from "@/components/ui/badge";
import UserManagementPage, { FieldDef } from "@/components/tables/UserManagementPage";
import { User } from "@/hooks/useUsers";
import { ColumnDef } from "@/components/tables/DataTable";

const roleBadgeColors: Record<string, string> = {
  CITIZEN: "bg-blue-100 text-blue-700",
  POLICE: "bg-indigo-100 text-indigo-700",
  ATTORNEY: "bg-purple-100 text-purple-700",
  MENTAL_HEALTH_PROFESSIONAL: "bg-emerald-100 text-emerald-700",
  BAIL_BONDSMAN: "bg-amber-100 text-amber-700",
  ADMIN: "bg-rose-100 text-rose-700",
  SUPER_ADMIN: "bg-red-100 text-red-700",
};

const columns: ColumnDef<User>[] = [
  { header: "Name", accessorKey: "name" },
  { header: "Email", accessorKey: "email" },
  {
    header: "Role",
    cell: (u: User) => (
      <Badge className={`${roleBadgeColors[u.role] || "bg-slate-100 text-slate-700"} border-0 font-medium`}>
        {u.role ? u.role.replace(/_/g, " ") : "USER"}
      </Badge>
    ),
  },
  {
    header: "Phone",
    cell: (u: User) => u.phoneNumber || "—",
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
  { key: "name", label: "Full Name", placeholder: "Jane Doe", required: true },
  { key: "email", label: "Email", placeholder: "jane@example.com", type: "email", required: true },
  {
    key: "role",
    label: "Role",
    type: "select",
    required: true,
    options: [
      { label: "Citizen", value: "CITIZEN" },
      { label: "Police Officer", value: "POLICE" },
      { label: "Attorney", value: "ATTORNEY" },
      { label: "Mental Health Professional", value: "MENTAL_HEALTH_PROFESSIONAL" },
      { label: "Bail Bondsman", value: "BAIL_BONDSMAN" },
      { label: "Admin", value: "ADMIN" },
    ],
  },
  { key: "phoneNumber", label: "Phone Number", placeholder: "+1 (555) 000-0000", type: "tel" },
  { key: "password", label: "Password", placeholder: "Min 8 characters", type: "password", required: true },
];

export default function UsersPage() {
  return (
    <UserManagementPage
      title="User Management"
      description="Manage all system accounts across all roles, permissions, and access status."
      allowRoleFilter={true}
      fields={fields}
      columns={columns}
    />
  );
}
