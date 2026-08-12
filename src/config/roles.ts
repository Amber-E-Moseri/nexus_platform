/**
 * Nexus canonical roles — generic authorization identifiers.
 *
 * These are the roles Nexus uses internally. Deployment-specific titles
 * (e.g. "Pastor", "Regional Secretary") are mapped to these roles at runtime
 * by the active DeploymentRoleConfig.
 *
 * IMPORTANT: Supabase Edge Functions (Deno) cannot import this file — see
 * the module-boundary note in src/features/nova/lib/buildSystemPrompt.ts.
 * Keep supabase/functions/_shared/novaAuth.ts in sync manually when roles change.
 * Search "source of truth: src/config/roles.ts" to find those copies.
 */

export const NEXUS_ROLES = [
  'platform_admin',
  'org_admin',
  'team_lead',
  'group_lead',
  'member',
] as const

export type NexusRole = (typeof NEXUS_ROLES)[number]

export const NEXUS_ROLE_LABELS: Record<NexusRole, string> = {
  platform_admin: 'Platform Admin',
  org_admin: 'Organization Admin',
  team_lead: 'Team Lead',
  group_lead: 'Group Lead',
  member: 'Member',
}

export function isNexusRole(value: unknown): value is NexusRole {
  return typeof value === 'string' && (NEXUS_ROLES as readonly string[]).includes(value)
}
