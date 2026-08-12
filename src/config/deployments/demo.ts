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
import { AUTH_REQUIREMENTS, type AuthRequirement } from '@/config/authz-requirements'

const demoConfig: DeploymentRoleConfig = {
  resolveRole(role: string): NexusRole | null {
    // Demo: stored roles ARE canonical Nexus roles (identity mapping)
    return isNexusRole(role) ? role : null
  },
  getRoleLabel(role: string): string {
    return isNexusRole(role) ? NEXUS_ROLE_LABELS[role] : role
  },
  // Authorization requirement map: which roles can satisfy each requirement
  requirementMap: {
    // Platform administration
    [AUTH_REQUIREMENTS.can_administer_platform]: ['platform_admin'],
    [AUTH_REQUIREMENTS.can_manage_users]: ['platform_admin', 'org_admin'],
    [AUTH_REQUIREMENTS.can_manage_settings]: ['platform_admin', 'org_admin'],

    // Organization administration
    [AUTH_REQUIREMENTS.can_administer_org]: ['org_admin'],
    [AUTH_REQUIREMENTS.can_manage_departments]: ['org_admin', 'team_lead'],
    [AUTH_REQUIREMENTS.can_manage_integrations]: ['org_admin'],
    [AUTH_REQUIREMENTS.can_access_org_reporting]: ['org_admin', 'team_lead'],

    // Team leadership
    [AUTH_REQUIREMENTS.can_lead_team]: ['team_lead'],
    [AUTH_REQUIREMENTS.can_manage_team_sprint]: ['team_lead'],
    [AUTH_REQUIREMENTS.can_assign_tasks]: ['team_lead', 'group_lead'],
    [AUTH_REQUIREMENTS.can_view_team_analytics]: ['team_lead', 'org_admin'],

    // Group/sub-team leadership
    [AUTH_REQUIREMENTS.can_lead_group]: ['group_lead'],
    [AUTH_REQUIREMENTS.can_manage_group_members]: ['group_lead', 'team_lead'],

    // Member capabilities (everyone can do these, so all roles)
    [AUTH_REQUIREMENTS.can_read_org_data]: [
      'platform_admin',
      'org_admin',
      'team_lead',
      'group_lead',
      'member',
    ],
    [AUTH_REQUIREMENTS.can_view_calendar]: [
      'platform_admin',
      'org_admin',
      'team_lead',
      'group_lead',
      'member',
    ],
    [AUTH_REQUIREMENTS.can_view_meetings]: [
      'platform_admin',
      'org_admin',
      'team_lead',
      'group_lead',
      'member',
    ],
    [AUTH_REQUIREMENTS.can_create_meetings]: ['team_lead', 'group_lead', 'member'],
    [AUTH_REQUIREMENTS.can_view_crm]: ['team_lead', 'group_lead'],
    [AUTH_REQUIREMENTS.can_manage_contacts]: ['team_lead'],
    [AUTH_REQUIREMENTS.can_access_email_campaigns]: ['org_admin', 'team_lead'],
    [AUTH_REQUIREMENTS.can_send_campaigns]: ['org_admin'],

    // Blocking requirements (inverted logic — these are denylists)
    [AUTH_REQUIREMENTS.cannot_access_if_group_member]: [],
    [AUTH_REQUIREMENTS.cannot_access_if_member]: [],
    [AUTH_REQUIREMENTS.cannot_access_if_temporary]: [],
  },

  blockedRoles: {
    group_member: [],
    temporary_member: [],
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
