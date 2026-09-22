"use client";

import React from "react";
import { Badge } from "@/components/ui/badge";
import UserManagementPage, { FieldDef } from "@/components/tables/UserManagementPage";
import { User } from "@/hooks/useUsers";
import { ColumnDef } from "@/components/tables/DataTable";

const columns: ColumnDef<User>[] = [
  { header: "Name", accessorKey: "name" },
  { header: "Email", accessorKey: "email" },
  {
    header: "Badge #",
    cell: (u: User) => u.badgeNumber || "—",
  },
  {
    header: "Department",
    cell: (u: User) => u.departmentOrPrecinct || "—",
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
  { key: "name", label: "Full Name", placeholder: "Officer John Doe", required: true },
  { key: "email", label: "Email", placeholder: "j.doe@police.dept", type: "email", required: true },
  { key: "badgeNumber", label: "Badge Number", placeholder: "B-1045" },
  { key: "departmentOrPrecinct", label: "Department / Precinct", placeholder: "Metro District" },
  { key: "password", label: "Password", placeholder: "Min 8 characters", type: "password", required: true },
];

export default function PoliceManagementPage() {
  return (
    <UserManagementPage
      title="Police Management"
      description="Manage police officers and their records."
      role="POLICE"
      fields={fields}
      columns={columns}
    />
  );
}
