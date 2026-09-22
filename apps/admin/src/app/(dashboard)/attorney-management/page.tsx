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
    header: "Bar # / License",
    cell: (u: User) => u.barAssociationNumber || "—",
  },
  {
    header: "Law Firm",
    cell: (u: User) => u.lawFirmName || "—",
  },
  {
    header: "Licensed States",
    cell: (u: User) => (
      <span className="truncate max-w-[150px] block">{u.licensedStatesToPractice || "—"}</span>
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
  { key: "name", label: "Full Name", placeholder: "Attorney Jane Smith", required: true },
  { key: "email", label: "Email", placeholder: "j.smith@lawfirm.com", type: "email", required: true },
  { key: "barAssociationNumber", label: "Bar Association Number", placeholder: "NY-44021" },
  { key: "lawFirmName", label: "Law Firm Name", placeholder: "Smith & Associates" },
  { key: "licensedStatesToPractice", label: "Licensed States", placeholder: "NY, CA" },
  { key: "datePassedTheBar", label: "Date Passed the Bar", placeholder: "2010-06-15" },
  { key: "password", label: "Password", placeholder: "Min 8 characters", type: "password", required: true },
];

export default function AttorneyManagementPage() {
  return (
    <UserManagementPage
      title="Attorney Management"
      description="Manage registered attorneys and their credentials."
      role="ATTORNEY"
      fields={fields}
      columns={columns}
    />
  );
}
