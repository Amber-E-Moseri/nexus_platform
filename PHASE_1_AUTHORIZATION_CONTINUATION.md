# Phase 1 Authorization Abstraction — Continuation Plan

## Current State

✅ Infrastructure in place:
- `src/config/roles.ts` — canonical Nexus roles (platform_admin, org_admin, team_lead, group_lead, member)
- `src/config/deployment.ts` — `DeploymentRoleConfig` interface + `resolveNexusRole()` authority
- `src/config/deployments/demo.ts` — demo deployment (identity mapping)
- `supabase/functions/_shared/novaAuth.ts` — boundary comment noting the split

❌ Boundary violations (still hardcoding BLW roles in app code):
- `src/App.jsx` — 40+ `<ProtectedRoute roles={['super_admin', 'regional_secretary', 'dept_lead', ...]}>`
- `src/components/layout/ProtectedRoute.jsx` — checks `effectiveRole` against hardcoded strings
- `src/features/dashboard/lib/roleDefaults.ts` — hardcoded role string keys
- Various components checking `role === 'super_admin'` or `role === 'pastor'`

## The Problem

Right now, the app has **two separate role systems**:

```
Deployment layer (BLW-specific):
  users.role = 'super_admin' | 'regional_secretary' | 'dept_lead' | 'pastor' | 'member'
         ↓
  resolveNexusRole() [edge function, seed]
         ↓
Canonical layer (core Nexus):
  platform_admin | org_admin | team_lead | group_lead | member

         ↓ (violation here)
         
App code layer (should use canonical, but still uses BLW):
  ProtectedRoute roles={['super_admin', 'regional_secretary', ...]}  ← BLW names leak here
  if (role === 'pastor') { ... }                                     ← BLW names leak here
```

This means:
1. Core Nexus logic is still tightly coupled to BLW's role vocabulary
2. A different deployment (e.g., a church that uses `minister`, `elder`, `deacon`) would need to rewrite all component logic
3. Nova, dashboard, and auth guards all know BLW-specific role names

## Solution: Authorization Requirements

Instead of components checking specific role names, define **authorization requirements** (semantic capabilities) and let deployments map those requirements to their role hierarchy.

### Step 1: Define Authorization Requirements

Create `src/config/authz-requirements.ts`:

```typescript
/**
 * Authorization requirements — semantic capabilities that features need.
 * 
 * Deployments map these to their role hierarchy via requirementMap.
 * Core Nexus only knows these requirements, never actual role names.
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
  
  // Group/sub-team leadership
  can_lead_group: 'can_lead_group',
  can_manage_pastoral_assignments: 'can_manage_pastoral_assignments',
  
  // Member capabilities
  can_read_org_data: 'can_read_org_data',
  can_view_flock_crm: 'can_view_flock_crm',
  can_view_ministry_calendar: 'can_view_ministry_calendar',
  
  // Block lower roles from features
  cannot_access_if_group_member: 'cannot_access_if_group_member',
  cannot_access_if_member: 'cannot_access_if_member',
  cannot_access_if_temporary: 'cannot_access_if_temporary',
} as const

export type AuthRequirement = (typeof AUTH_REQUIREMENTS)[keyof typeof AUTH_REQUIREMENTS]
```

### Step 2: Extend DeploymentRoleConfig

Update `src/config/deployment.ts`:

```typescript
import { type AuthRequirement } from '@/config/authz-requirements'

export interface DeploymentRoleConfig {
  resolveRole(role: string): NexusRole | null
  getRoleLabel(role: string): string
  
  // NEW: Map authorization requirements to canonical roles that satisfy them
  requirementMap: Record<AuthRequirement, NexusRole[]>
  
  // NEW: Define which roles are "lower tier" for blocking
  blockedRoles: {
    group_member?: NexusRole[]        // Roles that should be blocked from sensitive features
    temporary_member?: NexusRole[]    // Temporary/external members
  }
}

export function canUserSatisfy(
  userRole: NexusRole | null,
  requirement: AuthRequirement
): boolean {
  if (!userRole || !_config) return false
  return _config.requirementMap[requirement]?.includes(userRole) ?? false
}

export function isBlockedRole(
  userRole: NexusRole,
  blockType: keyof DeploymentRoleConfig['blockedRoles']
): boolean {
  if (!_config) return false
  return _config.blockedRoles[blockType]?.includes(userRole) ?? false
}
```

### Step 3: Implement Demo Deployment Mapping

Update `src/config/deployments/demo.ts`:

```typescript
import { type DeploymentRoleConfig } from '@/config/deployment'
import { AUTH_REQUIREMENTS } from '@/config/authz-requirements'

const demoConfig: DeploymentRoleConfig = {
  resolveRole(role: string): NexusRole | null {
    return isNexusRole(role) ? role : null
  },
  getRoleLabel(role: string): string {
    return isNexusRole(role) ? NEXUS_ROLE_LABELS[role] : role
  },
  
  // NEW: Map authorization requirements to canonical roles
  requirementMap: {
    [AUTH_REQUIREMENTS.can_administer_platform]: ['platform_admin'],
    [AUTH_REQUIREMENTS.can_manage_users]: ['platform_admin', 'org_admin'],
    [AUTH_REQUIREMENTS.can_manage_settings]: ['platform_admin', 'org_admin'],
    [AUTH_REQUIREMENTS.can_administer_org]: ['org_admin'],
    [AUTH_REQUIREMENTS.can_manage_departments]: ['org_admin', 'team_lead'],
    [AUTH_REQUIREMENTS.can_manage_integrations]: ['org_admin'],
    [AUTH_REQUIREMENTS.can_access_org_reporting]: ['org_admin', 'team_lead'],
    [AUTH_REQUIREMENTS.can_lead_team]: ['team_lead'],
    [AUTH_REQUIREMENTS.can_manage_team_sprint]: ['team_lead'],
    [AUTH_REQUIREMENTS.can_assign_tasks]: ['team_lead', 'group_lead'],
    [AUTH_REQUIREMENTS.can_lead_group]: ['group_lead'],
    [AUTH_REQUIREMENTS.can_manage_pastoral_assignments]: ['group_lead', 'team_lead'],
    [AUTH_REQUIREMENTS.can_read_org_data]: ['platform_admin', 'org_admin', 'team_lead', 'group_lead', 'member'],
    [AUTH_REQUIREMENTS.can_view_flock_crm]: ['team_lead', 'group_lead'],
    [AUTH_REQUIREMENTS.can_view_ministry_calendar]: ['platform_admin', 'org_admin', 'team_lead', 'group_lead', 'member'],
  },
  
  blockedRoles: {
    group_member: [],  // No lower-tier roles in demo
    temporary_member: [],
  },
}
```

### Step 4: Wire into ProtectedRoute

Update `src/components/layout/ProtectedRoute.jsx`:

```jsx
import { canUserSatisfy, isBlockedRole } from '@/config/deployment'
import { AUTH_REQUIREMENTS } from '@/config/authz-requirements'

export default function ProtectedRoute({ 
  children, 
  requires,           // NEW: semantic requirements instead of role array
  requiresAny,        // NEW: at least one of these requirements
  blockRoles,         // unchanged (backward compat, deprecated)
  ...props 
}) {
  const { user, profile, effectiveRole } = useAuth()

  // NEW: Check semantic requirements
  if (requires && !canUserSatisfy(effectiveRole, requires)) {
    return <Navigate to="/dashboard" state={{ authError: 'Insufficient permissions.' }} />
  }

  if (requiresAny && !requiresAny.some(req => canUserSatisfy(effectiveRole, req))) {
    return <Navigate to="/dashboard" state={{ authError: 'Insufficient permissions.' }} />
  }

  // ... rest of logic
}
```

### Step 5: Update App.jsx Routes

Before (BLW-specific):
```jsx
<ProtectedRoute roles={['super_admin', 'regional_secretary', 'dept_lead']}>
  <AdminUsersPage />
</ProtectedRoute>
```

After (canonical):
```jsx
<ProtectedRoute requires={AUTH_REQUIREMENTS.can_manage_users}>
  <AdminUsersPage />
</ProtectedRoute>
```

Or for "any of these":
```jsx
<ProtectedRoute requiresAny={[
  AUTH_REQUIREMENTS.can_administer_org,
  AUTH_REQUIREMENTS.can_manage_integrations
]}>
  <IntegrationsPage />
</ProtectedRoute>
```

### Step 6: Update Component Logic

Before:
```javascript
if (effectiveRole === 'super_admin' || effectiveRole === 'regional_secretary') {
  // show admin controls
}
```

After:
```javascript
import { canUserSatisfy } from '@/config/deployment'

if (canUserSatisfy(effectiveRole, AUTH_REQUIREMENTS.can_administer_org)) {
  // show admin controls
}
```

## Implementation Roadmap

### Tier 1 (Core Foundation)
- [ ] Create `src/config/authz-requirements.ts` with semantic requirements
- [ ] Extend `DeploymentRoleConfig` with `requirementMap` + `blockedRoles`
- [ ] Implement `canUserSatisfy()` and `isBlockedRole()` in `deployment.ts`
- [ ] Update demo deployment to define full `requirementMap`
- [ ] Build comprehensive test suite for authorization matrix

### Tier 2 (Route Protection)
- [ ] Update `ProtectedRoute` to accept `requires` and `requiresAny` props
- [ ] Audit all 40+ routes in `App.jsx`
- [ ] Replace `roles={[...]}` with `requires={AUTH_REQUIREMENTS.xxx}`
- [ ] Update fallback routes and error messages
- [ ] Test all routes with demo user

### Tier 3 (Component Authorization)
- [ ] Audit all component logic checking `effectiveRole` directly
- [ ] Replace hardcoded role checks with `canUserSatisfy()` calls
- [ ] Update dashboard widgets to use requirements instead of roles
- [ ] Update Nova's role-aware logic to use canonical roles
- [ ] Update role-based UI rendering (show/hide admin controls)

### Tier 4 (Dashboard & Preferences)
- [ ] Update `src/features/dashboard/lib/roleDefaults.ts` to use canonical roles
- [ ] Update `src/lib/permissions.js` to understand canonical roles
- [ ] Wire `resolveNexusRole` into dashboard preference loading
- [ ] Update Nova KB filtering to use canonical roles

### Tier 5 (Edge Functions & Auth)
- [ ] Verify `resolveNexusRole` is called in all auth paths
- [ ] Update RPC permission checks if any still hardcode BLW roles
- [ ] Audit all edge functions for hardcoded role strings
- [ ] Document auth boundary in each edge function

## Deployment Adapter Pattern (for private BLW repo)

Private deployment repo would define:

```typescript
// private-deployment/config/deployments/blw.ts
const blwConfig: DeploymentRoleConfig = {
  resolveRole(role: string): NexusRole | null {
    const map = {
      'super_admin': 'platform_admin',
      'regional_secretary': 'org_admin',
      'dept_lead': 'team_lead',
      'pastor': 'group_lead',
      'member': 'member',
    }
    return map[role] || null
  },

  getRoleLabel(role: string): string {
    const labels = {
      'super_admin': 'Super Admin',
      'regional_secretary': 'Regional Secretary',
      'dept_lead': 'Department Lead',
      'pastor': 'Pastor',
      'member': 'Member',
    }
    return labels[role] || role
  },

  // Same requirementMap as demo (canonical roles are org-agnostic)
  requirementMap: {
    ...identicalToDemoMapping,
  },

  blockedRoles: {
    group_member: ['group_member'],  // BLW has a lower 'group_member' role
    temporary_member: [],
  },
}
```

This way, the private BLW deployment only needs to define role mapping; the authorization requirements stay the same across deployments.

## Success Criteria

After Phase 1 completion, the codebase should:

1. ✅ Core Nexus (`src/`) knows **only** `NEXUS_ROLES` and `AUTH_REQUIREMENTS`
2. ✅ All role comparisons use `canUserSatisfy(role, requirement)`, not `role === 'super_admin'`
3. ✅ All `<ProtectedRoute>` use semantic requirements, not hardcoded role arrays
4. ✅ `resolveNexusRole()` is the single normalization point for all incoming role strings
5. ✅ Deployment adapters (demo, BLW) define role mapping + requirement matrix
6. ✅ A different deployment can change all BLW role names by updating one file
7. ✅ Nova system prompt generation is canonical-role-aware
8. ✅ Dashboard role defaults use canonical roles
9. ✅ Edge functions' RLS checks stay BLW-specific (they reference persisted roles)

## Notes

- **Edge functions remain BLW-specific**: Supabase RLS policies embed persisted `users.role` values (`super_admin`, `regional_secretary`, etc.). Phase 1 doesn't migrate the DB — only app code. Phase 5 will migrate persisted roles.
- **Backward compatibility**: Old `roles={[...]}` prop still works for a transition period, but deprecation warnings guide removal.
- **Authorization matrix as config**: `requirementMap` becomes the single source of truth for who can do what, making audit and changes straightforward.
