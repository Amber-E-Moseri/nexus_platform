# Phase 2: Configuration Abstraction — Remove Hardcoded Organization Logic

**Status**: Planning (starts after Phase 1 is complete)

**Principle**: Nexus core should never hardcode organization-specific logic. All organizational assumptions belong in deployment config.

## Anti-Pattern Examples (Currently in Codebase)

These **must be removed** in Phase 2:

### 1. Hardcoded Role Names (Addressed in Phase 1)
```javascript
// ❌ BAD
if (role === 'pastor') { /* pastoral view */ }
if (role === 'regional_secretary') { /* reporting view */ }

// ✅ GOOD (Phase 1)
if (canUserSatisfy(role, AUTH_REQUIREMENTS.can_lead_group)) { /* group leadership view */ }
```

### 2. Hardcoded Organizational Units
```javascript
// ❌ BAD
if (dept.name === 'Pastors') { /* special logic */ }
if (dept.id === KNOWN_ADMIN_DEPT_UUID) { /* special logic */ }

// ✅ GOOD (Phase 2)
if (profile.department_id === profile.primary_department?.id) { /* primary department */ }
// Department roles/types determined by config, not by name matching
```

### 3. Hardcoded Meeting Types
```javascript
// ❌ BAD
const MEETING_TYPES = ['sunday_service', 'midweek', 'planning_session', 'regional_monthly']
if (meetingType === 'sunday_service') { /* special tracking */ }

// ✅ GOOD (Phase 2)
// Meeting types defined in deployment config; core only knows: user_defined, system_generated, etc.
const meetingTypeConfig = deployment.getMeetingTypeConfig(meetingType)
if (meetingTypeConfig.requiresSpecialTracking) { /* ... */ }
```

### 4. Hardcoded Organizational Structures
```javascript
// ❌ BAD
const REGIONS = ['Central', 'North', 'East', 'West']
const SUBGROUPS = ['Central East', 'Central West', 'North Central', ...]
if (subgroup === 'Central East Subgroup B') { /* hardcoded logic */ }

// ✅ GOOD (Phase 2)
// Organizational hierarchies come from config or database
const orgHierarchy = deployment.getOrganizationalStructure()
// Query-based, not enum-based
```

### 5. Hardcoded Features/Integrations
```javascript
// ❌ BAD
const HAS_FLOCK_CRM = true
const HAS_GOOGLE_SYNC = true
const ENABLE_TTS_CACHE = true

if (HAS_FLOCK_CRM) { <FlockModule /> }

// ✅ GOOD (Phase 2)
const features = deployment.getEnabledFeatures()
if (features.includes('flock_crm')) { <FlockModule /> }
```

### 6. Hardcoded Business Rules
```javascript
// ❌ BAD
const MIN_TEAM_SIZE = 3
const SPRINT_VELOCITY_THRESHOLD = 15
const ABSENCE_AUTO_ESCALATE_AFTER_DAYS = 7

// ✅ GOOD (Phase 2)
const config = deployment.getBusinessRules()
if (absenceDays > config.escalateAfterDays) { /* escalate */ }
```

### 7. Hardcoded People/Events
```javascript
// ❌ BAD
const FOUNDING_MEMBERS = [uuid1, uuid2, uuid3]
const SPECIAL_EVENTS = ['This Is It 2.0', 'Conference 2026']
if (specialEventId === TII2_EVENT_UUID) { /* special access */ }

// ✅ GOOD (Phase 2)
// Reference by semantic role/tag, not by specific person/event UUID
const isFounder = user.tags?.includes('founding_member')
const isSpecialEvent = event.tags?.includes('special_event')
```

## Phase 2 Deliverables

### 1. Extend DeploymentConfig
```typescript
export interface DeploymentConfig extends DeploymentRoleConfig {
  // Organization structure
  organizationalStructure: {
    departmentTypes: Record<string, DepartmentConfig>
    hierarchyLevels: string[]  // e.g. ['region', 'subgroup', 'team']
  }

  // Feature flags
  enabledFeatures: ('flock_crm' | 'tts_cache' | 'google_calendar_sync' | ...)[]

  // Meeting types
  meetingTypes: Record<string, MeetingTypeConfig>

  // Business rules (organization-agnostic values)
  businessRules: {
    minTeamSize: number
    sprintVelocityThreshold: number
    absenceEscalationDays: number
    // ...
  }

  // Organizational tags/metadata
  organizationalTags: Record<string, TagConfig>
}
```

### 2. Migrate Hardcoded Enums to Config
- Meeting types → `deployment.getMeetingTypes()`
- Department structure → `deployment.getOrganizationalStructure()`
- Feature toggles → `deployment.getEnabledFeatures()`
- Business rule thresholds → `deployment.getBusinessRules()`

### 3. Remove Specific Person/Event References
- Replace UUID-based special logic with tag-based logic
- Example: instead of `if (userId === PASTOR_UUID)`, use `if (user.roles.includes('group_lead'))`
- Replace event-name matching with event-tagging system

### 4. Create Semantic Constants
Instead of:
```javascript
const SUNDAY_SERVICE_MEETING_TYPE = 'sunday_service'
```

Use:
```javascript
export const MEETING_TYPE_TAGS = {
  CORPORATE_WORSHIP: 'corporate_worship',  // Semantic (org-agnostic)
  ADMIN_PLANNING: 'admin_planning',
  MEMBER_GATHERING: 'member_gathering',
}
// Deployment maps these to actual meeting type names
```

## Benefits

1. **Portability**: A different organization can deploy Nexus by providing only a config file
2. **Flexibility**: BLW can add new departments, meeting types, or features without code changes
3. **Clarity**: Business logic is testable and auditable via config
4. **Maintainability**: Organizational changes don't require code review/deployment
5. **Scale**: Works for organizations of any size/structure

## Timeline

- **Phase 1 (now)**: Role abstraction infrastructure
- **Phase 2 (after Phase 1)**: Extract organizational logic to config
- **Phase 3+**: Realtime config hot-loading, multi-tenant config isolation

## Audit Checklist for Phase 2

Before shipping Phase 2, run:
```bash
# Find any hardcoded organizational names/IDs
grep -rn "Foundation School\|service center\|pastor\|regional" src/ --include="*.ts" --include="*.tsx" --include="*.jsx" | grep -v "AUTH_REQUIREMENTS\|comment\|doc"

# Find hardcoded UUIDs in business logic (not migrations)
grep -rn "[0-9a-f]\{8\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}" src/ --include="*.ts" --include="*.tsx" --include="*.jsx" | grep -v "auth\|seed\|test"

# Find feature flags hardcoded as `const ENABLE_*`
grep -rn "const ENABLE_\|const HAS_\|const USE_" src/ --include="*.ts" --include="*.tsx" --include="*.jsx"

# Find hardcoded arrays/enums of org-specific values
grep -rn "const.*=.*\[\s*['\"].*['\"],\s*['\"]" src/ --include="*.ts" --include="*.tsx" --include="*.jsx"
```

All results should be explained in a Phase 2 audit report before code reaches production.
