/**
 * Authorization requirements — semantic capabilities that features need.
 *
 * Features request capabilities (e.g., can_administer_org) rather than specific roles.
 * Deployments map these requirements to their role hierarchy via requirementMap.
 * Core Nexus only knows these requirements, never actual role names.
 *
 * This is the single source of truth for what permissions exist in the system.
 */

export const AUTH_REQUIREMENTS = {
  // Platform administration
  can_administer_platform: 'can_administer_platform',
  can_manage_users: 'can_manage_users',
  can_manage_settings: 'can_manage_settings',

  // Organization administration
  can_administer_org: 'can_administer_org',
  can_manage_departments: 'can_manage_departments',
  can_manage_integrations: 'can_manage_integrations',
  can_access_org_reporting: 'can_access_org_reporting',

  // Team leadership
  can_lead_team: 'can_lead_team',
  can_manage_team_sprint: 'can_manage_team_sprint',
  can_assign_tasks: 'can_assign_tasks',
  can_view_team_analytics: 'can_view_team_analytics',

  // Group/sub-team leadership
  can_lead_group: 'can_lead_group',
  can_manage_group_members: 'can_manage_group_members',

  // Member capabilities
  can_read_org_data: 'can_read_org_data',
  can_view_calendar: 'can_view_calendar',
  can_view_meetings: 'can_view_meetings',
  can_create_meetings: 'can_create_meetings',
  can_view_crm: 'can_view_crm',
  can_manage_contacts: 'can_manage_contacts',
  can_access_email_campaigns: 'can_access_email_campaigns',
  can_send_campaigns: 'can_send_campaigns',

  // Blocking requirements (for denylist)
  cannot_access_if_group_member: 'cannot_access_if_group_member',
  cannot_access_if_member: 'cannot_access_if_member',
  cannot_access_if_temporary: 'cannot_access_if_temporary',
} as const

export type AuthRequirement = (typeof AUTH_REQUIREMENTS)[keyof typeof AUTH_REQUIREMENTS]

// For documentation: list all requirements
export const ALL_REQUIREMENTS = Object.values(AUTH_REQUIREMENTS)
