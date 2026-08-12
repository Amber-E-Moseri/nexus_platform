# Phase 1 Tier 2b — Route Requirements Mapping

**Purpose**: Map all 30+ hardcoded role arrays in `src/App.jsx` to semantic authorization requirements.

**Status**: This is a reference document for implementing Tier 2b refactoring.

---

## Route Mapping Table

| Line | Current `roles={...}` | Route/Feature | Mapped Requirement | Notes |
|------|----------------------|---------------|--------------------|-------|
| 168 | `['super_admin']` | Admin → Users | `can_manage_users` | Platform admins manage users |
| 181 | `['super_admin', 'regional_secretary', 'dept_lead']` | ORS Reporting | `can_access_org_reporting` | Org reporting access (with grant override) |
| 189 | `['super_admin', 'regional_secretary', 'dept_lead']` | Programs | `can_access_org_reporting` | Programs reporting (org-level) |
| 207 | `['super_admin', 'regional_secretary', 'dept_lead']` | Settings | `can_manage_settings` | Org-wide settings (with grant override) |
| 215 | `['super_admin', 'regional_secretary', 'dept_lead']` | Integration Requests | `can_manage_integrations` | Org-level integrations (with grant override) |
| 223 | `['super_admin', 'regional_secretary', 'dept_lead']` | Support Tickets | `can_manage_integrations` | Support as org feature |
| 231 | `['super_admin', 'regional_secretary', 'ors']` | ORS Management | `can_administer_org` | Core org admin (allowGrant for escalation) |
| 239 | `['super_admin', 'ors']` | ORS Admin | `can_administer_org` | Org admin only |
| 247 | `['super_admin']` | Admin → Settings | `can_administer_platform` | Platform-level settings |
| 255 | `['super_admin']` | Admin → Email | `can_administer_platform` | Platform email config |
| 263 | `['super_admin', 'regional_secretary']` | Admin → Invitations | `can_manage_users` | User lifecycle management |
| 273 | `blockRoles={['group_member']}` | Dashboard | (none - block denylist) | Keep as-is; members can access |
| 283 | `['regional_secretary', 'pastor', 'super_admin']` | Flock CRM | `can_view_crm` | CRM access for leadership + group leads |
| 291 | `['pastor', 'regional_secretary', 'super_admin']` + grant | Flock Admin | `can_manage_contacts` | CRM management (with grant override) |
| 304 | `blockRoles={['group_member', 'member']}` | Sprints | `cannot_access_if_member` | Leadership-only feature |
| 314 | `blockRoles={['group_member', 'member']}` + temp | Agenda | (block denylist) | Keep as-is; temp members OK |
| 322 | `blockRoles={['group_member']}` + temp | Meetings | (block denylist) | Keep as-is; members can view |
| 330 | `['super_admin', 'regional_secretary', 'dept_lead', 'ors']` | Reports Suite | `can_access_org_reporting` | Org reporting (with grant) |
| 338 | `['super_admin', 'regional_secretary', 'dept_lead']` | Analytics | `can_access_org_reporting` | Analytics dashboard (with grant) |
| 346 | `['super_admin', 'regional_secretary', 'dept_lead', 'pastor']` | Events Admin | `can_lead_team` | Event management (team-lead+) |
| 354 | `blockRoles={['member', 'group_member']}` | Registration | (block denylist) | Leadership-only feature |
| 362 | `['super_admin', 'dept_lead', 'regional_secretary', 'pastor']` | Growth Tracking | `can_view_team_analytics` | Team analytics for leads/group leads |
| 370 | `['super_admin', 'dept_lead', 'regional_secretary', 'pastor']` | MI Sync | `can_access_org_reporting` | Ministry integration reporting |
| 378 | `['super_admin', 'dept_lead', 'regional_secretary']` | Automations | `can_manage_integrations` | Automation setup (with grant) |
| 386 | `['super_admin', 'dept_lead', 'regional_secretary', 'pastor']` | Comms | `can_access_email_campaigns` | Email campaign access |
| 394 | `['super_admin', 'dept_lead', 'regional_secretary', 'pastor']` | Broadcast | `can_send_campaigns` | Campaign sending (refined to org_admin) |
| 402 | `['super_admin']` | Admin → Logs | `can_administer_platform` | Platform audit logs |
| 410 | `['super_admin', 'regional_secretary', 'dept_lead']` | Workflows | `can_manage_integrations` | Workflow automation (with grant) |
| 418 | `['super_admin', 'regional_secretary', 'ors', 'dept_lead', 'programs']` | GrowthReports | `can_access_org_reporting` | Growth reporting (with grant) |
| 441 | `['super_admin']` | Admin → Finance | `can_administer_platform` | Platform finance config |
| 454 | `['super_admin']` | Admin → Communications | `can_administer_platform` | Platform comms config |
| 462 | `['super_admin']` | Admin → Tasks | `can_administer_platform` | Platform tasks config |
| 470 | `['super_admin']` | Admin → Meetings | `can_administer_platform` | Platform meetings config |
| 478 | `['super_admin']` | Admin → People | `can_administer_platform` | Platform people config |
| 490 | `['super_admin', 'regional_secretary', 'media']` | Media Integration | `can_manage_integrations` | Media vendor integration |

---

## Semantic Grouping

### Platform Admin Only (`can_administer_platform`)
- User management admin
- Platform-level settings
- Email configuration
- Invitation management (escalated to platform)
- Audit logs
- Finance/Communications/Tasks/Meetings/People config

### Org Admin (`can_administer_org` / `can_manage_integrations`)
- ORS management (core)
- Integration request handling
- Automation setup
- Media integration
- Workflow configuration

### Org Reporting (`can_access_org_reporting`)
- ORS Reporting
- Programs reporting
- Settings (org-level)
- Reports suite
- Analytics dashboard
- MI Sync
- Growth reports

### Team Leadership (`can_lead_team` / `can_view_team_analytics`)
- Event admin
- Growth tracking
- Team analytics

### CRM Access (`can_view_crm` / `can_manage_contacts`)
- Flock CRM (read)
- Flock admin (manage)

### Campaign Access (`can_access_email_campaigns` / `can_send_campaigns`)
- Comms (view campaigns)
- Broadcast (send campaigns — refined to `org_admin` only)

### Block Denylists (keep as-is)
- `blockRoles={['group_member']}` → Sprints, Dashboard
- `blockRoles={['group_member', 'member']}` → Sprints, Agenda, Registration
- `blockRoles={['group_member']} blockTemporary` → Meetings

---

## Implementation Strategy

### Tier 2b Steps

1. **Import requirements** at top of App.jsx:
   ```javascript
   import { AUTH_REQUIREMENTS } from '@/config/authz-requirements'
   ```

2. **Replace 33 instances** following this template:
   
   **Before:**
   ```jsx
   <ProtectedRoute roles={['super_admin', 'regional_secretary', 'dept_lead']} allowGrant="regional_secretary_access">
   ```
   
   **After:**
   ```jsx
   <ProtectedRoute requires={AUTH_REQUIREMENTS.can_access_org_reporting} allowGrant="regional_secretary_access">
   ```

3. **Keep allowGrant unchanged** (Phase 2 will refactor grant system)

4. **Keep blockRoles as-is** (legacy denylist, works fine)

5. **Test each route** with demo users before committing

---

## Questions for Review

1. **Broadcast campaign sending** (line 394)
   - Currently: `['super_admin', 'dept_lead', 'regional_secretary', 'pastor']`
   - Mapped to: `can_send_campaigns: ['org_admin']` in demo config
   - Should `team_lead` be able to send? Or is this org-admin only?
   - **Decision needed**: Keep restrictive or broaden?

2. **Grant overrides**
   - Currently: `allowGrant="regional_secretary_access"`
   - This lets `pastor` with a grant access `regional_secretary` features
   - Should this pattern change in Phase 2?
   - **Decision needed**: Keep or refactor in Phase 2?

3. **Space roles** (ors, programs, media)
   - Lines 231, 239, 418, 490 reference space-specific roles
   - These are Phase 3 (space-scoped roles)
   - Should we map them now or defer?
   - **Decision needed**: Phase 1 vs Phase 3 scope?

---

## Verification Checklist (Tier 2b)

- [ ] All 33 routes updated to use semantic requirements
- [ ] No `roles={['super_admin', ...]}` left in App.jsx (except comments)
- [ ] Build passes (`npm run build`)
- [ ] Login as `member` — no admin pages visible
- [ ] Login as `team_lead` — can see reports, but not user management
- [ ] Login as `org_admin` — can see all org features
- [ ] Login as `platform_admin` — can see all features
- [ ] BlockRoles still work (members can't see Sprints)
- [ ] AllowGrant still works (pastors with grant can access regional_secretary features)

---

## Notes

- This is a **pure refactoring** — no behavior changes, only role names → semantic requirements
- `allowGrant` stays unchanged (it's Phase 2 work to refactor the grant system)
- Block denylists stay unchanged (they work fine)
- Space roles are **deferred to Phase 3** (they're not in the canonical Nexus role set)

**Next commit message** will reference this mapping document and list all 33 route updates.
