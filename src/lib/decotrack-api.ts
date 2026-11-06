import { requireSupabase } from "./supabase";

export type ToolStatus = "available" | "assigned" | "maintenance" | "missing" | "retired";
export type ToolRecord = {
  id: string;
  asset_tag: string;
  name: string;
  category: string;
  status: ToolStatus;
  current_employee_id: string | null;
  current_project_id: string | null;
  qr_code_value: string;
  updated_at: string;
};

export async function signIn(email: string, password: string) {
  const { data, error } = await requireSupabase().auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

export async function signOut() {
  const { error } = await requireSupabase().auth.signOut();
  if (error) throw error;
}

export async function listTools(organizationId: string, search = "") {
  let query = requireSupabase()
    .from("tools")
    .select("id,asset_tag,name,category,status,current_employee_id,current_project_id,qr_code_value,updated_at")
    .eq("organization_id", organizationId)
    .order("name");
  if (search.trim()) query = query.or(`name.ilike.%${search.trim()}%,asset_tag.ilike.%${search.trim()}%`);
  const { data, error } = await query;
  if (error) throw error;
  return (data ?? []) as ToolRecord[];
}

export async function createTool(input: {
  organizationId: string;
  assetTag: string;
  name: string;
  category: string;
}) {
  const { data, error } = await requireSupabase()
    .from("tools")
    .insert({
      organization_id: input.organizationId,
      asset_tag: input.assetTag,
      name: input.name,
      category: input.category,
    })
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function completeTransfer(input: {
  organizationId: string;
  toolIds: string[];
  toEmployeeId: string | null;
  toProjectId: string | null;
  notes?: string;
}) {
  const { data, error } = await requireSupabase().rpc("complete_tool_transfer", {
    p_organization_id: input.organizationId,
    p_tool_ids: input.toolIds,
    p_to_employee_id: input.toEmployeeId,
    p_to_project_id: input.toProjectId,
    p_notes: input.notes ?? null,
  });
  if (error) throw error;
  return data as string;
}

export async function listProjects(organizationId: string) {
  const { data, error } = await requireSupabase()
    .from("projects")
    .select("id,code,name,city,status,manager_employee_id")
    .eq("organization_id", organizationId)
    .order("name");
  if (error) throw error;
  return data ?? [];
}

export async function listEmployees(organizationId: string) {
  const { data, error } = await requireSupabase()
    .from("employees")
    .select("id,full_name,email,phone,active")
    .eq("organization_id", organizationId)
    .eq("active", true)
    .order("full_name");
  if (error) throw error;
  return data ?? [];
}
