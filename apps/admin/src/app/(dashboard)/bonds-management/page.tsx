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
    header: "Agency / Company",
    cell: (u: User) => u.companyName || "—",
  },
  {
    header: "License ID",
    cell: (u: User) => u.licenseNumber || "—",
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
  { key: "name", label: "Full Name", placeholder: "Mike Ehrmantraut", required: true },
  { key: "email", label: "Email", placeholder: "mike@quickbail.com", type: "email", required: true },
  { key: "companyName", label: "Agency Name", placeholder: "Quick Bail Bonds" },
  { key: "licenseNumber", label: "License ID", placeholder: "e.g. L-99821" },
  { key: "businessAddress", label: "Business Address", placeholder: "123 State St, Suite 400" },
  { key: "phoneNumber", label: "Phone Number", placeholder: "+1 (555) 000-0000", type: "tel" },
  { key: "password", label: "Password", placeholder: "Min 8 characters", type: "password", required: true },
];

export default function BailBondsmanManagementPage() {
  return (
    <UserManagementPage
      title="Bail Bondsman Management"
      description="Monitor bail bondsmen and their active registrations."
      role="BAIL_BONDSMAN"
      fields={fields}
      columns={columns}
    />
  );
}
