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
    header: "Medical License #",
    cell: (u: User) => u.medicalLicenseNumber || "—",
  },
  {
    header: "Specialization",
    cell: (u: User) => u.specialization || "General / Crisis Intervention",
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
  { key: "name", label: "Full Name", placeholder: "Dr. Sarah Jenkins", required: true },
  { key: "email", label: "Email", placeholder: "s.jenkins@mhp.org", type: "email", required: true },
  { key: "phoneNumber", label: "Phone Number", placeholder: "+1 (555) 000-0000", type: "tel" },
  { key: "medicalLicenseNumber", label: "Medical License / HIPAA ID", placeholder: "e.g. H-88219" },
  { key: "specialization", label: "Specialization", placeholder: "e.g. Crisis Intervention, Trauma" },
  { key: "password", label: "Password", placeholder: "Min 8 characters", type: "password", required: true },
];

export default function MHPManagementPage() {
  return (
    <UserManagementPage
      title="MHP Management"
      description="Monitor Mental Health Professionals and their credentials."
      role="MENTAL_HEALTH_PROFESSIONAL"
      fields={fields}
      columns={columns}
    />
  );
}
