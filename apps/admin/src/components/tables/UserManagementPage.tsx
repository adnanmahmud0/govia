"use client";

import React, { useState } from "react";
import {
  MoreHorizontal,
  Plus,
  Search,
  Trash2,
  Pencil,
  X,
  AlertCircle,
  Loader2,
  Eye,
  Download,
  CheckCircle2,
  Ban,
  Shield,
  Phone,
  Mail,
  Calendar,
  Building,
  Scale,
  Award,
  UserCheck,
} from "lucide-react";
import { DataTable, ColumnDef } from "@/components/tables/DataTable";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { useUsers, User } from "@/hooks/useUsers";
import { useToast } from "@/context/ToastContext";

export interface FieldOption {
  label: string;
  value: string;
}

export interface FieldDef {
  key: keyof User | string;
  label: string;
  placeholder?: string;
  type?: "text" | "email" | "password" | "tel" | "select";
  options?: FieldOption[];
  required?: boolean;
}

interface UserManagementPageProps {
  title: string;
  description: string;
  role?: string;
  allowRoleFilter?: boolean;
  fields: FieldDef[];
  columns: ColumnDef<User>[];
  defaultPassword?: string;
}

// ─── Add/Edit Dialog ──────────────────────────────────────────────────────────
function UserDialog({
  open,
  onClose,
  onSave,
  title,
  fields,
  defaultValues,
  saving,
}: {
  open: boolean;
  onClose: () => void;
  onSave: (data: Record<string, string>) => Promise<void>;
  title: string;
  fields: FieldDef[];
  defaultValues?: Partial<Record<string, string>>;
  saving: boolean;
}) {
  const [form, setForm] = useState<Record<string, string>>(() =>
    Object.fromEntries(fields.map((f) => [f.key, defaultValues?.[f.key as string] ?? ""]))
  );
  const [errors, setErrors] = useState<Record<string, string>>({});

  React.useEffect(() => {
    if (open) {
      setForm(Object.fromEntries(fields.map((f) => [f.key, defaultValues?.[f.key as string] ?? ""])));
      setErrors({});
    }
  }, [open]);

  const validate = () => {
    const errs: Record<string, string> = {};
    fields.forEach((f) => {
      if (f.required && !form[f.key as string]?.trim()) {
        errs[f.key as string] = `${f.label} is required`;
      }
    });
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async () => {
    if (!validate()) return;
    await onSave(form);
  };

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-md p-6 space-y-4 z-10">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-bold text-slate-800">{title}</h3>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-600 rounded-lg p-1">
            <X className="w-5 h-5" />
          </button>
        </div>
        <div className="space-y-3 max-h-[70vh] overflow-y-auto pr-1">
          {fields.map((f) => (
            <div key={f.key as string}>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                {f.label} {f.required && <span className="text-red-500">*</span>}
              </label>
              {f.type === "select" ? (
                <Select
                  value={form[f.key as string] ?? ""}
                  onValueChange={(val) => setForm((prev) => ({ ...prev, [f.key as string]: val }))}
                >
                  <SelectTrigger className={`rounded-xl border-slate-200 ${errors[f.key as string] ? "border-red-400" : ""}`}>
                    <SelectValue placeholder={f.placeholder ?? `Select ${f.label}`} />
                  </SelectTrigger>
                  <SelectContent>
                    {(f.options || []).map((opt) => (
                      <SelectItem key={opt.value} value={opt.value}>
                        {opt.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              ) : (
                <Input
                  type={f.type ?? "text"}
                  placeholder={f.placeholder ?? f.label}
                  value={form[f.key as string] ?? ""}
                  onChange={(e) => setForm((prev) => ({ ...prev, [f.key as string]: e.target.value }))}
                  className={`rounded-xl border-slate-200 ${errors[f.key as string] ? "border-red-400" : ""}`}
                />
              )}
              {errors[f.key as string] && (
                <p className="text-xs text-red-500 mt-1">{errors[f.key as string]}</p>
              )}
            </div>
          ))}
        </div>
        <div className="flex gap-3 pt-2">
          <Button variant="outline" onClick={onClose} className="flex-1 rounded-xl">Cancel</Button>
          <Button
            onClick={handleSubmit}
            disabled={saving}
            className="flex-1 rounded-xl bg-[#1554ad] hover:bg-[#1554ad]/90 text-white"
          >
            {saving ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : null}
            Save
          </Button>
        </div>
      </div>
    </div>
  );
}

// ─── User Details Modal ───────────────────────────────────────────────────────
function UserDetailsModal({
  user,
  onClose,
  onEdit,
  onToggleStatus,
  updating,
}: {
  user: User | null;
  onClose: () => void;
  onEdit: () => void;
  onToggleStatus: () => Promise<void>;
  updating: boolean;
}) {
  if (!user) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-lg p-6 space-y-5 z-10 max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-blue-700 to-[#1554ad] text-white font-bold text-lg flex items-center justify-center shadow-md">
              {user.name.slice(0, 2).toUpperCase()}
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-xl font-bold text-slate-800">{user.name}</h3>
                {user.verified && (
                  <Badge className="bg-blue-100 text-[#1554ad] border-0 text-[10px] gap-1 py-0.5">
                    <UserCheck className="w-3 h-3" /> Verified
                  </Badge>
                )}
              </div>
              <p className="text-sm text-slate-500 mt-0.5">{user.email}</p>
            </div>
          </div>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-600 rounded-lg p-1">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Status & Role Badges */}
        <div className="flex items-center gap-2 pt-1">
          <Badge className="bg-slate-100 text-slate-700 border-0 font-medium text-xs">
            Role: {user.role?.replace(/_/g, " ")}
          </Badge>
          <Badge
            className={
              user.status === "active"
                ? "bg-emerald-100 text-emerald-700 border-0 text-xs"
                : "bg-red-100 text-red-700 border-0 text-xs"
            }
          >
            Status: {user.status === "active" ? "Active" : "Inactive"}
          </Badge>
        </div>

        {/* Information Grid */}
        <div className="bg-slate-50/80 rounded-xl p-4 space-y-3 border border-slate-100 text-sm">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <p className="text-xs text-slate-400 font-medium">Contact Phone</p>
              <p className="font-semibold text-slate-700 mt-0.5">{user.phoneNumber || "—"}</p>
            </div>
            <div>
              <p className="text-xs text-slate-400 font-medium">Account ID</p>
              <p className="font-mono text-xs text-slate-600 mt-0.5 truncate">{user._id}</p>
            </div>
          </div>

          {/* Role specific attributes */}
          {user.badgeNumber && (
            <div className="grid grid-cols-2 gap-3 pt-2 border-t border-slate-200/60">
              <div>
                <p className="text-xs text-slate-400 font-medium">Badge Number</p>
                <p className="font-semibold text-slate-700 mt-0.5">{user.badgeNumber}</p>
              </div>
              <div>
                <p className="text-xs text-slate-400 font-medium">Precinct / Dept</p>
                <p className="font-semibold text-slate-700 mt-0.5">{user.departmentOrPrecinct || "—"}</p>
              </div>
            </div>
          )}

          {user.barAssociationNumber && (
            <div className="grid grid-cols-2 gap-3 pt-2 border-t border-slate-200/60">
              <div>
                <p className="text-xs text-slate-400 font-medium">Bar Association #</p>
                <p className="font-semibold text-slate-700 mt-0.5">{user.barAssociationNumber}</p>
              </div>
              <div>
                <p className="text-xs text-slate-400 font-medium">Law Firm</p>
                <p className="font-semibold text-slate-700 mt-0.5">{user.lawFirmName || "—"}</p>
              </div>
              {user.licensedStatesToPractice && (
                <div className="col-span-2">
                  <p className="text-xs text-slate-400 font-medium">Licensed States</p>
                  <p className="font-semibold text-slate-700 mt-0.5">{user.licensedStatesToPractice}</p>
                </div>
              )}
            </div>
          )}

          {user.medicalLicenseNumber && (
            <div className="grid grid-cols-2 gap-3 pt-2 border-t border-slate-200/60">
              <div>
                <p className="text-xs text-slate-400 font-medium">Medical / HIPAA License</p>
                <p className="font-semibold text-slate-700 mt-0.5">{user.medicalLicenseNumber}</p>
              </div>
              <div>
                <p className="text-xs text-slate-400 font-medium">Specialization</p>
                <p className="font-semibold text-slate-700 mt-0.5">{user.specialization || "General"}</p>
              </div>
            </div>
          )}

          {user.companyName && (
            <div className="grid grid-cols-2 gap-3 pt-2 border-t border-slate-200/60">
              <div>
                <p className="text-xs text-slate-400 font-medium">Agency / Company</p>
                <p className="font-semibold text-slate-700 mt-0.5">{user.companyName}</p>
              </div>
              <div>
                <p className="text-xs text-slate-400 font-medium">License ID</p>
                <p className="font-semibold text-slate-700 mt-0.5">{user.licenseNumber || "—"}</p>
              </div>
            </div>
          )}

          {(user.preferredAttorney || user.preferredBailBondsman) && (
            <div className="grid grid-cols-2 gap-3 pt-2 border-t border-slate-200/60">
              <div>
                <p className="text-xs text-slate-400 font-medium">Preferred Attorney</p>
                <p className="font-semibold text-slate-700 mt-0.5">{user.preferredAttorney || "None"}</p>
              </div>
              <div>
                <p className="text-xs text-slate-400 font-medium">Preferred Bondsman</p>
                <p className="font-semibold text-slate-700 mt-0.5">{user.preferredBailBondsman || "None"}</p>
              </div>
            </div>
          )}

          {user.createdAt && (
            <div className="pt-2 border-t border-slate-200/60 flex items-center justify-between text-xs text-slate-500">
              <span>Member Since:</span>
              <span className="font-medium">{new Date(user.createdAt).toLocaleDateString()}</span>
            </div>
          )}
        </div>

        {/* Action Controls */}
        <div className="flex gap-3 pt-1">
          <Button
            variant="outline"
            onClick={onToggleStatus}
            disabled={updating}
            className={`flex-1 rounded-xl gap-2 ${
              user.status === "active"
                ? "text-amber-600 hover:text-amber-700 hover:bg-amber-50"
                : "text-emerald-600 hover:text-emerald-700 hover:bg-emerald-50"
            }`}
          >
            {updating ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : user.status === "active" ? (
              <Ban className="w-4 h-4" />
            ) : (
              <CheckCircle2 className="w-4 h-4" />
            )}
            {user.status === "active" ? "Deactivate Account" : "Activate Account"}
          </Button>
          <Button
            onClick={onEdit}
            className="rounded-xl bg-[#1554ad] hover:bg-[#1554ad]/90 text-white gap-2 px-5"
          >
            <Pencil className="w-4 h-4" />
            Edit Profile
          </Button>
        </div>
      </div>
    </div>
  );
}

// ─── Confirm Delete Dialog ────────────────────────────────────────────────────
function ConfirmDeleteDialog({
  open,
  onClose,
  onConfirm,
  name,
  deleting,
}: {
  open: boolean;
  onClose: () => void;
  onConfirm: () => Promise<void>;
  name: string;
  deleting: boolean;
}) {
  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6 z-10 space-y-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center">
            <AlertCircle className="w-5 h-5 text-red-500" />
          </div>
          <div>
            <h3 className="font-bold text-slate-800">Delete User</h3>
            <p className="text-sm text-slate-500">Remove <span className="font-medium">{name}</span>?</p>
          </div>
        </div>
        <p className="text-sm text-slate-600">This action cannot be undone.</p>
        <div className="flex gap-3">
          <Button variant="outline" onClick={onClose} className="flex-1 rounded-xl">Cancel</Button>
          <Button
            onClick={onConfirm}
            disabled={deleting}
            className="flex-1 rounded-xl bg-red-500 hover:bg-red-600 text-white"
          >
            {deleting ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : null}
            Delete
          </Button>
        </div>
      </div>
    </div>
  );
}

// ─── Main Component ───────────────────────────────────────────────────────────
export default function UserManagementPage({
  title,
  description,
  role,
  allowRoleFilter = false,
  fields,
  columns,
  defaultPassword = "GoVia@2024",
}: UserManagementPageProps) {
  const { toast } = useToast();
  const [selectedRole, setSelectedRole] = useState<string>(role || "");
  const activeRole = role || selectedRole;

  const {
    users,
    meta,
    loading,
    error,
    page,
    setPage,
    searchTerm,
    setSearchTerm,
    statusFilter,
    setStatusFilter,
    createUser,
    updateUser,
    deleteUser,
  } = useUsers({ role: activeRole });

  const [addOpen, setAddOpen] = useState(false);
  const [editUser, setEditUser] = useState<User | null>(null);
  const [detailsUser, setDetailsUser] = useState<User | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<User | null>(null);
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [statusUpdating, setStatusUpdating] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  const handleCreate = async (data: Record<string, string>) => {
    setSaving(true);
    setActionError(null);
    try {
      const assignedRole = role || data.role || (selectedRole && selectedRole !== "all" ? selectedRole : "CITIZEN");
      await createUser({ ...data, role: assignedRole, password: data.password || defaultPassword } as any);
      setAddOpen(false);
      toast.success("User created successfully", `${data.name} has been added.`);
    } catch (err: any) {
      setActionError(err?.message || "Failed to create user");
      toast.error("Failed to create user", err?.message);
    } finally {
      setSaving(false);
    }
  };

  const handleUpdate = async (data: Record<string, string>) => {
    if (!editUser) return;
    setSaving(true);
    setActionError(null);
    try {
      const updateData: Record<string, string> = {};
      Object.keys(data).forEach((k) => {
        if (k !== "password" && data[k] !== undefined) updateData[k] = data[k];
      });
      const updated = await updateUser(editUser._id, updateData);
      setEditUser(null);
      if (detailsUser && detailsUser._id === editUser._id) {
        setDetailsUser({ ...detailsUser, ...updateData });
      }
      toast.success("User updated successfully");
    } catch (err: any) {
      setActionError(err?.message || "Failed to update user");
      toast.error("Failed to update user", err?.message);
    } finally {
      setSaving(false);
    }
  };

  const handleToggleStatus = async (targetUser: User) => {
    setStatusUpdating(true);
    const nextStatus = targetUser.status === "active" ? "inactive" : "active";
    try {
      await updateUser(targetUser._id, { status: nextStatus });
      if (detailsUser && detailsUser._id === targetUser._id) {
        setDetailsUser({ ...detailsUser, status: nextStatus });
      }
      toast.success(`User status updated to ${nextStatus.toUpperCase()}`);
    } catch (err: any) {
      toast.error("Failed to change user status", err?.message);
    } finally {
      setStatusUpdating(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await deleteUser(deleteTarget._id);
      if (detailsUser && detailsUser._id === deleteTarget._id) {
        setDetailsUser(null);
      }
      setDeleteTarget(null);
      toast.success("User deleted successfully");
    } catch (err: any) {
      setActionError(err?.message || "Failed to delete user");
      toast.error("Failed to delete user", err?.message);
    } finally {
      setDeleting(false);
    }
  };

  const handleExportCSV = () => {
    if (users.length === 0) {
      toast.info("No records to export");
      return;
    }
    const headers = ["Name", "Email", "Role", "Status", "Phone", "Created Date"];
    const rows = users.map((u) => [
      `"${u.name || ""}"`,
      `"${u.email || ""}"`,
      `"${u.role || ""}"`,
      `"${u.status || ""}"`,
      `"${u.phoneNumber || ""}"`,
      `"${u.createdAt ? new Date(u.createdAt).toLocaleDateString() : ""}"`,
    ]);
    const csvContent =
      "data:text/csv;charset=utf-8," + [headers.join(","), ...rows.map((r) => r.join(","))].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute(
      "download",
      `${title.toLowerCase().replace(/\s+/g, "_")}_${new Date().toISOString().slice(0, 10)}.csv`
    );
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    toast.success("CSV file downloaded");
  };

  // Append action column with View Details, Edit, Toggle Status, Delete
  const allColumns: ColumnDef<User>[] = [
    ...columns,
    {
      header: "",
      cell: (user: User) => (
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <button className="p-1 hover:bg-slate-100 rounded-lg transition-colors">
              <MoreHorizontal className="w-4 h-4 text-slate-500" />
            </button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="rounded-xl shadow-lg border-slate-100 min-w-[150px]">
            <DropdownMenuItem
              onClick={() => setDetailsUser(user)}
              className="gap-2 cursor-pointer"
            >
              <Eye className="w-3.5 h-3.5 text-slate-600" /> View Details
            </DropdownMenuItem>
            <DropdownMenuItem
              onClick={() => setEditUser(user)}
              className="gap-2 cursor-pointer"
            >
              <Pencil className="w-3.5 h-3.5 text-slate-600" /> Edit
            </DropdownMenuItem>
            <DropdownMenuItem
              onClick={() => handleToggleStatus(user)}
              className="gap-2 cursor-pointer text-slate-700"
            >
              {user.status === "active" ? (
                <>
                  <Ban className="w-3.5 h-3.5 text-amber-600" /> Deactivate
                </>
              ) : (
                <>
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" /> Activate
                </>
              )}
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem
              onClick={() => setDeleteTarget(user)}
              className="gap-2 cursor-pointer text-red-600 focus:text-red-600"
            >
              <Trash2 className="w-3.5 h-3.5" /> Delete
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      ),
    },
  ];

  return (
    <div className="container mx-auto py-6 px-4 space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800">{title}</h1>
          <p className="text-slate-500 text-sm mt-0.5">{description}</p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={handleExportCSV}
            className="rounded-xl gap-2 text-xs border-slate-200"
          >
            <Download className="w-3.5 h-3.5" />
            Export CSV
          </Button>
          <Button
            onClick={() => setAddOpen(true)}
            size="sm"
            className="rounded-xl bg-[#1554ad] hover:bg-[#1554ad]/90 text-white gap-2 shadow-sm text-xs"
          >
            <Plus className="w-3.5 h-3.5" />
            Add {title.split(" ")[0]}
          </Button>
        </div>
      </div>

      {/* Error banner */}
      {(error || actionError) && (
        <div className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm">
          <AlertCircle className="w-4 h-4 flex-shrink-0" />
          {error || actionError}
        </div>
      )}

      {/* Filters */}
      <div className="bg-white border border-slate-100 rounded-2xl shadow-sm p-4">
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <Input
              placeholder="Search by name or email..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-9 rounded-xl border-slate-200"
            />
          </div>
          {(!role || allowRoleFilter) && (
            <Select
              value={selectedRole || "all"}
              onValueChange={(v) => setSelectedRole(v === "all" ? "" : v)}
            >
              <SelectTrigger className="w-[180px] rounded-xl border-slate-200">
                <SelectValue placeholder="All Roles" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Roles</SelectItem>
                <SelectItem value="CITIZEN">Citizen</SelectItem>
                <SelectItem value="POLICE">Police</SelectItem>
                <SelectItem value="ATTORNEY">Attorney</SelectItem>
                <SelectItem value="MENTAL_HEALTH_PROFESSIONAL">MHP</SelectItem>
                <SelectItem value="BAIL_BONDSMAN">Bail Bondsman</SelectItem>
                <SelectItem value="ADMIN">Admin</SelectItem>
              </SelectContent>
            </Select>
          )}
          <Select value={statusFilter || "all"} onValueChange={(v) => setStatusFilter(v === "all" ? "" : v)}>
            <SelectTrigger className="w-[160px] rounded-xl border-slate-200">
              <SelectValue placeholder="Status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Status</SelectItem>
              <SelectItem value="active">Active</SelectItem>
              <SelectItem value="inactive">Inactive</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white border border-slate-100 rounded-2xl shadow-sm overflow-hidden">
        {loading ? (
          <div className="flex items-center justify-center py-20 gap-3 text-slate-400">
            <Loader2 className="w-5 h-5 animate-spin" />
            <span className="font-medium">Loading...</span>
          </div>
        ) : users.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-20 text-slate-400 gap-2">
            <Search className="w-8 h-8 opacity-40" />
            <p className="font-medium">No records found</p>
            <p className="text-sm">Try adjusting your search or add a new entry.</p>
          </div>
        ) : (
          <DataTable columns={allColumns} data={users} />
        )}

        {/* Pagination */}
        {meta && meta.totalPage > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-slate-100">
            <p className="text-sm text-slate-500">
              Page {meta.page} of {meta.totalPage} ({meta.total} total)
            </p>
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage(Math.max(1, page - 1))}
                disabled={page <= 1}
                className="rounded-lg text-xs"
              >
                Previous
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setPage(Math.min(meta.totalPage, page + 1))}
                disabled={page >= meta.totalPage}
                className="rounded-lg text-xs"
              >
                Next
              </Button>
            </div>
          </div>
        )}
      </div>

      {/* Add Dialog */}
      <UserDialog
        open={addOpen}
        onClose={() => { setAddOpen(false); setActionError(null); }}
        onSave={handleCreate}
        title={`Add ${title.split(" ")[0]}`}
        fields={fields}
        saving={saving}
      />

      {/* Edit Dialog */}
      <UserDialog
        open={!!editUser}
        onClose={() => { setEditUser(null); setActionError(null); }}
        onSave={handleUpdate}
        title="Edit User"
        fields={fields.filter((f) => f.key !== "password")}
        defaultValues={editUser ? Object.fromEntries(Object.entries(editUser).map(([k, v]) => [k, String(v ?? "")])) : {}}
        saving={saving}
      />

      {/* User Details Modal */}
      <UserDetailsModal
        user={detailsUser}
        onClose={() => setDetailsUser(null)}
        onEdit={() => {
          if (detailsUser) {
            setEditUser(detailsUser);
            setDetailsUser(null);
          }
        }}
        onToggleStatus={async () => {
          if (detailsUser) await handleToggleStatus(detailsUser);
        }}
        updating={statusUpdating}
      />

      {/* Delete Confirm */}
      <ConfirmDeleteDialog
        open={!!deleteTarget}
        onClose={() => { setDeleteTarget(null); setActionError(null); }}
        onConfirm={handleDelete}
        name={deleteTarget?.name ?? ""}
        deleting={deleting}
      />
    </div>
  );
}
