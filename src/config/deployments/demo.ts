/**
 * Neutral demo deployment for nexus-public-demo.
 * No organization-specific vocabulary — safe for the public repository.
 *
 * For private deployments (e.g. BLW Canada), create an equivalent file in
 * the private repo and call registerDeployment() with the BLW role mapping.
 *
 * Example private BLW mapping (NOT in this repo):
 *   super_admin        → platform_admin
 *   regional_secretary → org_admin
 *   dept_lead          → team_lead
 *   pastor             → group_lead
 *   group_member       → member
 *   member             → member
 */

import { registerDeployment, type DeploymentRoleConfig } from '@/config/deployment'
import { isNexusRole, NEXUS_ROLE_LABELS, type NexusRole } from '@/config/roles'

const demoConfig: DeploymentRoleConfig = {
  resolveRole(role: string): NexusRole | null {
    // Demo: stored roles ARE canonical Nexus roles (identity mapping)
    return isNexusRole(role) ? role : null
  },
  getRoleLabel(role: string): string {
    return isNexusRole(role) ? NEXUS_ROLE_LABELS[role] : role
  },
}

registerDeployment(demoConfig)

export const demoOrganizationConfig = {
  name: 'Nexus Demo Organization',
  terminology: {
    organization: 'Organization',
    region: 'Region',
    department: 'Department',
    team: 'Team',
    group: 'Group',
    subgroup: 'Subgroup',
  },
} as const
