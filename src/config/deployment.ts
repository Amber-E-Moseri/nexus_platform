/**
 * Deployment role resolution contract.
 *
 * Each deployment provides a DeploymentRoleConfig that maps its persisted
 * role IDs to canonical NexusRoles. Nexus core calls resolveNexusRole() and
 * never reads raw deployment role strings.
 *
 * The active config is registered at app startup via registerDeployment().
 * Only one deployment config is active at a time.
 *
 * NOT YET WIRED into Nova (src/features/nova/lib/buildSystemPrompt.ts) or the
 * dashboard (src/features/dashboard/lib/roleDefaults.ts) — that file must stay
 * import-free so the Deno nova-chat edge function can load it via a relative
 * path. Wiring this adapter into Nova requires a Deno-safe design and is
 * deferred to a follow-up phase.
 */

import { type NexusRole, isNexusRole } from '@/config/roles'

export interface DeploymentRoleConfig {
  /** Map a persisted deployment role string → canonical NexusRole, or null if invalid. */
  resolveRole(role: string): NexusRole | null
  /** Return the display label for a role string (deployment-specific title or fallback). */
  getRoleLabel(role: string): string
}

let _config: DeploymentRoleConfig | null = null

/** Called once at app startup by the active deployment module. */
export function registerDeployment(config: DeploymentRoleConfig): void {
  _config = config
}

/**
 * Resolve a raw deployment role to a canonical NexusRole.
 *
 * Accepts both persisted deployment roles ("regional_secretary") and canonical
 * Nexus roles ("org_admin") so the strangler migration works in both directions:
 * legacy DB values resolve via the adapter; already-migrated values pass through.
 *
 * Returns null for unrecognised values.
 */
export function resolveNexusRole(role: string): NexusRole | null {
  if (!_config) {
    // Fallback: accept canonical roles directly when no deployment is registered
    return isNexusRole(role) ? role : null
  }
  return _config.resolveRole(role)
}

export function getRoleLabel(role: string): string {
  return _config?.getRoleLabel(role) ?? role
}
