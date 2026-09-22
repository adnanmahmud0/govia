"use client";

import React, { useState } from "react";
import {
  Plus,
  Search,
  Pencil,
  Trash2,
  ExternalLink,
  Phone,
  Mail,
  Building2,
  Loader2,
  AlertCircle,
  X,
  RefreshCw,
  Download,
} from "lucide-react";
import { DataTable, ColumnDef } from "@/components/tables/DataTable";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  useCommunityResources,
  CommunityResource,
} from "@/hooks/useCommunityResources";
import { useToast } from "@/context/ToastContext";

export default function FormularyPage() {
  const {
    resources,
    loading,
    error,
    refetch,
    createResource,
    updateResource,
    deleteResource,
  } = useCommunityResources();

  const { toast } = useToast();
  const [searchTerm, setSearchTerm] = useState("");
  const [addOpen, setAddOpen] = useState(false);
  const [editItem, setEditItem] = useState<CommunityResource | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<CommunityResource | null>(null);
  const [saving, setSaving] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  // Form state
  const [form, setForm] = useState({
    name: "",
    shortName: "",
    email: "",
    phone: "",
    websiteUrl: "",
  });

  const openCreateDialog = () => {
    setForm({ name: "", shortName: "", email: "", phone: "", websiteUrl: "" });
    setActionError(null);
    setAddOpen(true);
  };

  const openEditDialog = (item: CommunityResource) => {
    setEditItem(item);
    setForm({
      name: item.name || "",
      shortName: item.shortName || "",
      email: item.email || "",
      phone: item.phone || "",
      websiteUrl: item.websiteUrl || "",
    });
    setActionError(null);
  };

  const handleSave = async () => {
    if (!form.name.trim()) {
      setActionError("Resource name is required");
      return;
    }
    setSaving(true);
    setActionError(null);
    try {
      if (editItem) {
        await updateResource(editItem._id, form);
        setEditItem(null);
        toast.success("Resource updated successfully");
      } else {
        await createResource(form);
        setAddOpen(false);
        toast.success("Community resource added");
      }
    } catch (err: any) {
      setActionError(err?.message || "Failed to save resource");
      toast.error("Failed to save resource", err?.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    setSaving(true);
    try {
      await deleteResource(deleteTarget._id);
      setDeleteTarget(null);
      toast.success("Resource deleted successfully");
    } catch (err: any) {
      setActionError(err?.message || "Failed to delete resource");
      toast.error("Failed to delete resource", err?.message);
    } finally {
      setSaving(false);
    }
  };

  const handleExportCSV = () => {
    if (resources.length === 0) {
      toast.info("No records to export");
      return;
    }
    const headers = ["Organization Name", "Short Code", "Contact Email", "Phone", "Website URL"];
    const rows = resources.map((r) => [
      `"${r.name || ""}"`,
      `"${r.shortName || ""}"`,
      `"${r.email || ""}"`,
      `"${r.phone || ""}"`,
      `"${r.websiteUrl || ""}"`,
    ]);
    const csvContent =
      "data:text/csv;charset=utf-8," + [headers.join(","), ...rows.map((r) => r.join(","))].join("\n");
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `community_resources_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    toast.success("Community resources exported to CSV");
  };

  const filtered = resources.filter((r) => {
    if (!searchTerm.trim()) return true;
    const term = searchTerm.toLowerCase();
    return (
      (r.name || "").toLowerCase().includes(term) ||
      (r.shortName || "").toLowerCase().includes(term) ||
      (r.email || "").toLowerCase().includes(term) ||
      (r.phone || "").toLowerCase().includes(term)
    );
  });

  const columns: ColumnDef<CommunityResource>[] = [
    {
      header: "Resource / Organization",
      cell: (r) => (
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-blue-50 text-[#1554ad] flex items-center justify-center font-bold text-sm shrink-0">
            {r.shortName ? r.shortName.slice(0, 3).toUpperCase() : (r.name || "R").slice(0, 2).toUpperCase()}
          </div>
          <div>
            <p className="font-semibold text-slate-800 text-sm">{r.name}</p>
            {r.shortName && <p className="text-xs text-slate-400">{r.shortName}</p>}
          </div>
        </div>
      ),
    },
    {
      header: "Contact",
      cell: (r) => (
        <div className="space-y-0.5 text-xs">
          {r.email && (
            <div className="flex items-center gap-1.5 text-slate-600">
              <Mail className="w-3.5 h-3.5 text-slate-400" />
              <span>{r.email}</span>
            </div>
          )}
          {r.phone && (
            <div className="flex items-center gap-1.5 text-slate-600">
              <Phone className="w-3.5 h-3.5 text-slate-400" />
              <span>{r.phone}</span>
            </div>
          )}
          {!r.email && !r.phone && <span className="text-slate-300">—</span>}
        </div>
      ),
    },
    {
      header: "Website",
      cell: (r) =>
        r.websiteUrl ? (
          <a
            href={r.websiteUrl}
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center gap-1 text-xs text-[#1554ad] hover:underline font-medium"
          >
            Visit Site
            <ExternalLink className="w-3 h-3" />
          </a>
        ) : (
          <span className="text-slate-300 text-xs">—</span>
        ),
    },
    {
      header: "Created",
      cell: (r) => (
        <span className="text-slate-400 text-xs">
          {r.createdAt ? new Date(r.createdAt).toLocaleDateString() : "—"}
        </span>
      ),
    },
    {
      header: "Actions",
      cell: (r) => (
        <div className="flex items-center gap-1 justify-end">
          <button
            onClick={() => openEditDialog(r)}
            className="p-1.5 hover:bg-slate-100 rounded-lg text-slate-500 hover:text-[#1554ad] transition-colors"
            title="Edit resource"
          >
            <Pencil className="w-4 h-4" />
          </button>
          <button
            onClick={() => setDeleteTarget(r)}
            className="p-1.5 hover:bg-red-50 rounded-lg text-slate-400 hover:text-red-500 transition-colors"
            title="Delete resource"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      ),
      className: "text-right",
    },
  ];

  return (
    <div className="container mx-auto py-6 px-4 space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-slate-800">Community Resources & Formularies</h1>
          <p className="text-slate-500 text-sm mt-0.5">
            Manage public health directories, legal aid organizations, crisis clinics, and helpline resources.
          </p>
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
            variant="outline"
            size="sm"
            onClick={refetch}
            disabled={loading}
            className="rounded-xl gap-2 text-xs"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? "animate-spin" : ""}`} />
            Refresh
          </Button>
          <Button
            onClick={openCreateDialog}
            className="rounded-xl bg-[#1554ad] hover:bg-[#1554ad]/90 text-white gap-2 shadow-sm text-xs"
            size="sm"
          >
            <Plus className="w-4 h-4" />
            Add Resource
          </Button>
        </div>
      </div>

      {/* Error alert */}
      {(error || actionError) && (
        <div className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 text-sm">
          <AlertCircle className="w-4 h-4 flex-shrink-0" />
          {error || actionError}
        </div>
      )}

      {/* Stats summary */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-blue-50 flex items-center justify-center text-[#1554ad]">
            <Building2 className="w-5 h-5" />
          </div>
          <div>
            <p className="text-xl font-bold text-slate-800">{resources.length}</p>
            <p className="text-xs text-slate-500">Total Directory Resources</p>
          </div>
        </div>
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-emerald-50 flex items-center justify-center text-emerald-600">
            <ExternalLink className="w-5 h-5" />
          </div>
          <div>
            <p className="text-xl font-bold text-slate-800">
              {resources.filter((r) => r.websiteUrl).length}
            </p>
            <p className="text-xs text-slate-500">Online Portals & Links</p>
          </div>
        </div>
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-purple-50 flex items-center justify-center text-purple-600">
            <Phone className="w-5 h-5" />
          </div>
          <div>
            <p className="text-xl font-bold text-slate-800">
              {resources.filter((r) => r.phone).length}
            </p>
            <p className="text-xs text-slate-500">Direct Helplines</p>
          </div>
        </div>
      </div>

      {/* Table section */}
      <div className="bg-white border border-slate-100 rounded-2xl shadow-sm p-4 space-y-4">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <Input
            placeholder="Search resources by name, shortcode, email, or phone..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-9 rounded-xl border-slate-200"
          />
        </div>

        {loading && resources.length === 0 ? (
          <div className="flex items-center justify-center py-20 gap-3 text-slate-400">
            <Loader2 className="w-5 h-5 animate-spin" />
            <span className="font-medium">Loading resources...</span>
          </div>
        ) : filtered.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 text-slate-400 gap-2">
            <Building2 className="w-8 h-8 opacity-40" />
            <p className="font-medium">No community resources found</p>
            <p className="text-sm">Add directory organizations to make them accessible across the system.</p>
          </div>
        ) : (
          <DataTable columns={columns} data={filtered} />
        )}
      </div>

      {/* Add / Edit Dialog */}
      {(addOpen || !!editItem) && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div
            className="absolute inset-0 bg-black/40 backdrop-blur-sm"
            onClick={() => {
              setAddOpen(false);
              setEditItem(null);
            }}
          />
          <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-md p-6 space-y-4 z-10">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold text-slate-800">
                {editItem ? "Edit Resource" : "Add Community Resource"}
              </h3>
              <button
                onClick={() => {
                  setAddOpen(false);
                  setEditItem(null);
                }}
                className="text-slate-400 hover:text-slate-600 rounded-lg p-1"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  Organization / Resource Name <span className="text-red-500">*</span>
                </label>
                <Input
                  placeholder="e.g. Legal Aid Society of New York"
                  value={form.name}
                  onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))}
                  className="rounded-xl border-slate-200"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Short Name / Code</label>
                <Input
                  placeholder="e.g. LAS-NY"
                  value={form.shortName}
                  onChange={(e) => setForm((p) => ({ ...p, shortName: e.target.value }))}
                  className="rounded-xl border-slate-200"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Contact Email</label>
                <Input
                  type="email"
                  placeholder="contact@legalaid.org"
                  value={form.email}
                  onChange={(e) => setForm((p) => ({ ...p, email: e.target.value }))}
                  className="rounded-xl border-slate-200"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Helpline / Phone</label>
                <Input
                  type="tel"
                  placeholder="+1 (800) 555-0199"
                  value={form.phone}
                  onChange={(e) => setForm((p) => ({ ...p, phone: e.target.value }))}
                  className="rounded-xl border-slate-200"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Website URL</label>
                <Input
                  type="url"
                  placeholder="https://www.legalaid.org"
                  value={form.websiteUrl}
                  onChange={(e) => setForm((p) => ({ ...p, websiteUrl: e.target.value }))}
                  className="rounded-xl border-slate-200"
                />
              </div>
            </div>

            <div className="flex gap-3 pt-2">
              <Button
                variant="outline"
                onClick={() => {
                  setAddOpen(false);
                  setEditItem(null);
                }}
                className="flex-1 rounded-xl"
              >
                Cancel
              </Button>
              <Button
                onClick={handleSave}
                disabled={saving}
                className="flex-1 rounded-xl bg-[#1554ad] hover:bg-[#1554ad]/90 text-white"
              >
                {saving ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : null}
                Save Resource
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation */}
      {deleteTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={() => setDeleteTarget(null)} />
          <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-sm p-6 z-10 space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-red-100 rounded-full flex items-center justify-center">
                <AlertCircle className="w-5 h-5 text-red-500" />
              </div>
              <div>
                <h3 className="font-bold text-slate-800">Delete Resource</h3>
                <p className="text-sm text-slate-500">Remove <span className="font-medium">{deleteTarget.name}</span>?</p>
              </div>
            </div>
            <p className="text-sm text-slate-600">This will remove this resource from the public directory.</p>
            <div className="flex gap-3">
              <Button variant="outline" onClick={() => setDeleteTarget(null)} className="flex-1 rounded-xl">
                Cancel
              </Button>
              <Button
                onClick={handleDelete}
                disabled={saving}
                className="flex-1 rounded-xl bg-red-500 hover:bg-red-600 text-white"
              >
                {saving ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : null}
                Delete
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
