"use client";

import React from "react";
import { Badge } from "@/components/ui/badge";
import UserManagementPage, { FieldDef } from "@/components/tables/UserManagementPage";
import { User } from "@/hooks/useUsers";
import { ColumnDef } from "@/components/tables/DataTable";

const columns: ColumnDef<User>[] = [
  {
    header: "Name",
    accessorKey: "name",
  },
  {
    header: "Email",
    accessorKey: "email",
  },
  {
    header: "Phone",
    accessorKey: "phoneNumber",
    cell: (u: User) => u.phoneNumber || "—",
  },
  {
    header: "Verified",
    cell: (u: User) => (
      <Badge className={u.verified ? "bg-emerald-100 text-emerald-700 border-0" : "bg-slate-100 text-slate-500 border-0"}>
        {u.verified ? "Verified" : "Pending"}
      </Badge>
    ),
  },
  {
    header: "Status",
    cell: (u: User) => (
      <Badge className={u.status === "active" ? "bg-emerald-100 text-emerald-700 border-0" : "bg-red-100 text-red-700 border-0"}>
        {u.status === "active" ? "Active" : "Inactive"}
      </Badge>
    ),
  },
];

const fields: FieldDef[] = [
  { key: "name", label: "Full Name", placeholder: "Jane Doe", required: true },
  { key: "email", label: "Email", placeholder: "jane@example.com", type: "email", required: true },
  { key: "phoneNumber", label: "Phone Number", placeholder: "+1 555 000 0000", type: "tel" },
  { key: "password", label: "Password", placeholder: "Min 8 characters", type: "password", required: true },
];

export default function CitizenManagementPage() {
  return (
    <UserManagementPage
      title="Citizen Management"
      description="Manage registered citizens and their accounts."
      role="CITIZEN"
      fields={fields}
      columns={columns}
    />
  );
}
