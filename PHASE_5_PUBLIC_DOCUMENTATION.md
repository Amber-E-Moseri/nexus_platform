# Phase 5: Public Documentation — Engineering Portfolio Edition

**Status**: Planning (starts after Phase 4)

**Goal**: Separate private engineering docs from public engineering portfolio. Public docs explain **how you think**, not operational details.

## Current State

README links directly to:
- Maintainer Runbooks — ⚠️ Operational (private)
- Incident Log — ⚠️ Operational (private)
- Staging and Onboarding — ⚠️ Operational (private)
- Full Deployment Guide — ⚠️ Operational (private)

These are excellent internal docs. Recruiters don't need them, and they expose operational details that belong private.

## Solution: Public Engineering Docs

Create portfolio-grade documentation that showcases thinking without exposing operations:

### Public Docs (in `docs/public/`)

```
docs/public/
  ARCHITECTURE.md           # System design and module breakdown
  DATABASE_DESIGN.md        # Schema, RLS patterns, indexing strategy
  PERMISSIONS_MODEL.md      # Authorization architecture
  AI_ARCHITECTURE.md        # Nova's knowledge base and tool design
  INTEGRATION_PATTERN.md    # How providers work
  ENGINEERING_DECISIONS.md  # Design rationales (condensed from decision catalog)
  SECURITY_OVERVIEW.md      # Security principles and patterns
  CASE_STUDY.md             # How this solved a real problem (generic)
```

### Private Docs (in `docs/private/`)

These stay in the repo but are `.gitignore`'d or moved to private wiki:

```
docs/private/
  RUNBOOKS.md               # Incident response, deployments
  INCIDENT_LOG.md           # Production incidents and fixes
  STAGING_AND_ONBOARDING.md # Volunteer progression
  DEPLOYMENT_GUIDE.md       # Prod setup, secrets, integrations
  OPERATIONS_CHECKLIST.md   # Weekly/monthly maintenance
  TROUBLESHOOTING.md        # Known issues and fixes
```

## Document Specifications

### ARCHITECTURE.md

**Audience**: Technical recruiter / engineering team lead  
**Length**: 2,000-3,000 words

Topics:
- System overview (modules, data flow)
- Frontend architecture (React, routing, state management)
- Backend architecture (Supabase, RLS, edge functions)
- Real-time subscriptions
- Module dependencies
- Deployment topology

**Do**: Explain design choices, show code snippets, link to key files  
**Don't**: Reference production incidents, specific organizations, people

### DATABASE_DESIGN.md

**Audience**: Database architect / senior engineer  
**Length**: 2,500-4,000 words

Topics:
- Multi-tenant data model
- RLS enforcement strategy
- Index design and query patterns
- Foreign key constraints and data integrity
- Migration strategy (clean schema baseline approach)
- Scalability considerations

**Do**: Walk through schema design decisions, show policy examples  
**Don't**: Reference specific production issues or operational history

### PERMISSIONS_MODEL.md

**Audience**: Authorization engineer / security reviewer  
**Length**: 2,000-3,000 words

Topics:
- Role hierarchy (canonical Nexus roles, deployment mapping)
- Authorization requirements
- Deployment-agnostic permission matrix
- How role resolution works
- JWT claims and token structure
- Grant system for ad-hoc access

**Do**: Show role hierarchy diagram, permission matrix, code examples  
**Don't**: Hardcode BLW-specific roles, reference specific user grants

### AI_ARCHITECTURE.md

**Audience**: AI/ML engineer, product lead  
**Length**: 2,000-2,500 words

Topics:
- Nova assistant design (what problems it solves)
- Knowledge base structure and curation
- Tool design (live-data queries)
- Role-aware system prompts
- Model selection and token budgeting
- Guardrails and scope limitations

**Do**: Explain the two-job constraint, show KB schema, discuss prompt design  
**Don't**: Reference actual KB entries or specific user questions

### INTEGRATION_PATTERN.md

**Audience**: Backend engineer, integration specialist  
**Length**: 1,500-2,000 words

Topics:
- Provider interface design
- Adapter pattern (registry + implementations)
- Mock providers for testing/demo
- Adding new integrations
- Vendor-agnostic core design

**Do**: Show provider interfaces, explain adapter pattern with examples  
**Don't**: Reference specific vendors or deployment decisions

### ENGINEERING_DECISIONS.md

**Audience**: Engineering team, architecture review  
**Length**: 3,000-5,000 words

Topics (selected from decision catalog):
- Why RLS-first instead of application-layer permissions
- Why postgres_changes for realtime instead of polling
- Why Deno edge functions instead of serverless containers
- Why TanStack Query for server state instead of context
- Why modular feature structure
- Why JWT claims in token instead of permission lookups
- Why provider pattern for integrations

**Format**: Brief summaries with tradeoff discussion, not full decision documents

**Do**: Explain rationale, mention alternatives considered  
**Don't**: Deep dive into all 49+ decisions (that's for the private catalog)

### SECURITY_OVERVIEW.md

**Audience**: Security reviewer, compliance engineer  
**Length**: 2,000-3,000 words

Topics:
- Threat model
- RLS as the permission boundary
- Secret management (edge function secrets, API keys)
- Auth flow security (JWT, invite tokens)
- Audit logging considerations
- Data isolation model
- What's **not** in scope (enterprise features)

**Do**: Explain security principles, show code examples  
**Don't**: Disclose actual credentials, operational vulnerabilities, or fixes

### CASE_STUDY.md

**Audience**: Product hiring manager, engineering team  
**Length**: 2,500-4,000 words

Topics:
- Problem: "How do you build an internal operations platform for a distributed team?"
- Constraints: Limited budget, volunteer availability, bespoke integrations
- Solution approach: "Start with task management, add integrations incrementally"
- Key decisions made and why
- Learnings (what worked, what would be different)
- Results: "Reduced manual reporting by 80%, enabled real-time collaboration"

**Do**: Tell a compelling story, include specific metrics, explain tradeoffs  
**Don't**: Name the organization, reference specific people, include incidents

## Update README

Replace:

```markdown
## Quick Links

- **[Maintainer Runbooks](docs/RUNBOOKS.md)** — deployments, incidents, emergency access, and recovery
- **[Incident Log](docs/INCIDENTS.md)** — production incident record
- ...
```

With:

```markdown
## Engineering Documentation

### Public (Portfolio)
- **[Architecture](docs/public/ARCHITECTURE.md)** — System design, module breakdown, data flow
- **[Database Design](docs/public/DATABASE_DESIGN.md)** — Schema, RLS patterns, indexing strategy
- **[Permissions Model](docs/public/PERMISSIONS_MODEL.md)** — Role hierarchy, authorization architecture
- **[AI Architecture](docs/public/AI_ARCHITECTURE.md)** — Nova assistant design and knowledge base
- **[Engineering Decisions](docs/public/ENGINEERING_DECISIONS.md)** — Key architectural choices and rationales
- **[Security Overview](docs/public/SECURITY_OVERVIEW.md)** — Security principles and threat model
- **[Case Study](docs/public/CASE_STUDY.md)** — How this solved a real operational problem

### Private
Private engineering documentation (incident logs, operational runbooks, deployment guides) is maintained separately.
```

Also update the license/portfolio statement:

```markdown
## Repository Status

This repository is a **sanitized portfolio edition** of Nexus. It contains:
- ✅ Clean database schema and RLS architecture
- ✅ Complete application code and design patterns
- ✅ Synthetic demonstration data
- ✅ Integration provider pattern showcase
- ✅ Engineering documentation

It does **not** contain:
- ❌ Production data
- ❌ Operational history (incidents, specific fixes)
- ❌ Organization-specific configuration
- ❌ Credentials or secrets
- ❌ Vendor-specific integration implementations (see provider pattern)

For recruiters: This is a genuine portfolio project. The schema and code are from the production system; the configuration and operational details are private.
```

## Migration Checklist

### Before Phase 5 Starts
- [ ] Phase 1-4 complete
- [ ] All organization-specific logic removed (Phase 2)
- [ ] All integrations use provider pattern (Phase 3)
- [ ] Clean schema baseline in place (Phase 4)

### Phase 5 Execution
- [ ] Create `docs/public/` and `docs/private/` directories
- [ ] Write 7 public engineering docs (outlined above)
- [ ] Archive existing operational docs to `docs/private/`
- [ ] Update README with new doc structure
- [ ] Update license/portfolio statement
- [ ] Add `.gitignore` rule: `docs/private/` (if it lives in repo)
- [ ] Final audit: run SANITIZATION_CHECKLIST.md

## Success Criteria

After Phase 5:
- ✅ README is clean and links to portfolio docs only
- ✅ All 7 public engineering docs written and reviewed
- ✅ Docs explain architectural thinking without exposing operations
- ✅ Docs are specific enough to be impressive, generic enough to be reusable
- ✅ No hardcoded organization names, people, or incidents in public docs
- ✅ Case study tells a compelling story without naming the organization
- ✅ Private docs (runbooks, incident logs) are not linked from README
- ✅ Portfolio statement clearly explains what's included/excluded

## Template Examples

### Good (Portable)
```markdown
# RLS Pattern: Department Isolation

Users should only see data from their home department, with exceptions for:
1. Shared lists (explicit sharing via junction table)
2. Cross-department sprints (temporary membership via sprint_members)
3. Org-wide announcements (department_id IS NULL)

Policy example:
```sql
CREATE POLICY "tasks_users_see_own_dept" ON public.tasks
  FOR SELECT USING (
    department_id = current_user_department()
  );
```

Why this pattern:
- Avoids per-user permission tables (scales better)
- Maintains cross-department collaboration capability
- Clear audit trail via junction tables
```

### Bad (Organization-Specific)
```markdown
# RLS Policy for Pastors

Pastors should see meetings in their subgroup plus all regional meetings.
This is because Pastor John complained that... [specific incident]
```

## Notes

- Public docs are **not** a technical spec for recruiting. They're engineering thinking.
- A reader finishing these docs should understand **how you approach systems design**, not just what Nexus does.
- These docs become your teaching artifacts — they prove you can explain architecture clearly.
