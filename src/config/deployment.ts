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
 * Deployments also define an authorization requirement map that connects
 * semantic capabilities (can_administer_org, can_lead_team) to role sets.
 * This lets features request capabilities rather than hardcoding role names.
 *
 * NOT YET WIRED into Nova (src/features/nova/lib/buildSystemPrompt.ts) or the
 * dashboard (src/features/dashboard/lib/roleDefaults.ts) — that file must stay
 * import-free so the Deno nova-chat edge function can load it via a relative
 * path. Wiring this adapter into Nova requires a Deno-safe design and is
 * deferred to a follow-up phase.
 */

import { type NexusRole, isNexusRole } from '@/config/roles'
import { type AuthRequirement } from '@/config/authz-requirements'

export interface DeploymentRoleConfig {
  /** Map a persisted deployment role string → canonical NexusRole, or null if invalid. */
  resolveRole(role: string): NexusRole | null
  /** Return the display label for a role string (deployment-specific title or fallback). */
  getRoleLabel(role: string): string
  /** Map semantic authorization requirements to the canonical roles that satisfy them. */
  requirementMap: Record<AuthRequirement, NexusRole[]>
  /** Roles that should be blocked from accessing certain features. */
  blockedRoles?: {
    /** Roles that represent a lower tier of access (e.g., temporary members). */
    group_member?: NexusRole[]
    /** Temporary or external members. */
    temporary_member?: NexusRole[]
  }
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

/**
 * Check if a user's role satisfies a specific authorization requirement.
 *
 * Returns false if:
 * - No deployment config is registered
 * - Role is null or invalid
 * - The role doesn't satisfy the requirement
 *
 * Example:
 *   if (canUserSatisfy(userRole, AUTH_REQUIREMENTS.can_administer_org)) {
 *     // show admin controls
 *   }
 */
export function canUserSatisfy(
  userRole: NexusRole | null,
  requirement: AuthRequirement
): boolean {
  if (!userRole || !_config) return false
  return _config.requirementMap[requirement]?.includes(userRole) ?? false
}

/**
 * Check if a role belongs to a blocked category.
 *
 * Used to denylist certain roles from features (e.g., prevent temporary members
 * from accessing sensitive areas).
 *
 * Example:
 *   if (isBlockedRole(userRole, 'temporary_member')) {
 *     return <Navigate to="/limited-access" />
 *   }
 */
export function isBlockedRole(
  userRole: NexusRole,
  blockType: keyof NonNullable<DeploymentRoleConfig['blockedRoles']>
): boolean {
  if (!_config?.blockedRoles) return false
  return _config.blockedRoles[blockType]?.includes(userRole) ?? false
}
