# Sanitization Checklist — Portfolio Edition

**Status**: Audit tool for ensuring sensitive data is removed before public publication.

**How to use**: Run before publishing. Address **every** item. Mark as ✅ (removed) or 📋 (N/A for this deployment).

---

## 1. Credentials & Secrets

Anything that could authenticate or authorize:

- [ ] ✅ API keys (Anthropic, Deepgram, Resend, Google, Slack, etc.)
- [ ] ✅ Supabase service role keys
- [ ] ✅ Database connection strings with passwords
- [ ] ✅ JWT signing secrets
- [ ] ✅ OAuth tokens or refresh tokens
- [ ] ✅ Email addresses used for OAuth (if production accounts)
- [ ] ✅ `.env.local` or `.env.production` files
- [ ] ✅ AWS/GCP/Azure credentials
- [ ] ✅ SSH keys or deploy keys
- [ ] ✅ Slack webhook URLs
- [ ] ✅ Stripe/payment keys
- [ ] ✅ Sentry DSN (contains org slug)

**Check**:
```bash
grep -rn "SUPABASE_SERVICE_KEY\|OPENAI_API_KEY\|crypt('\|SECRET\|PRIVATE" . \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.env*" \
  --exclude-dir=node_modules --exclude-dir=.git
```

---

## 2. Organization Names & Branding

Organization-specific terminology that ties this to a specific deployment:

- [ ] ✅ "BLW" anywhere in code/comments (except docs explaining the pattern)
- [ ] ✅ "BLW Canada"
- [ ] ✅ "Nexus" hardcoded as the org name (use "Demo Organization" in seed)
- [ ] ✅ Organization logo or branding files
- [ ] ✅ Specific regional names (e.g., "Manitoba", "Central Region")
- [ ] ✅ Department names from production (Admin, Media, ORS, Pastors, PFCC)
- [ ] ✅ Specific building/campus names
- [ ] ✅ Production ministry names or fellowship names

**Check**:
```bash
grep -rn "BLW\|Manitoba\|Central Region\|ORS\|PFCC\|Pastors\|Media" src/ \
  --include="*.ts" --include="*.tsx" | grep -v "demo\|example\|comment"
```

---

## 3. People & Personal Data

Names, emails, UUIDs, or identifying information about real people:

- [ ] ✅ Real people's names in code comments (except in commit history which is acceptable)
- [ ] ✅ Real people's email addresses (production email like `user@blw.ca`)
- [ ] ✅ Specific people referenced in git commit messages about incidents
- [ ] ✅ UUID values for specific real users (except generic demo UUIDs in seed)
- [ ] ✅ Phone numbers
- [ ] ✅ Personal URLs or social profiles
- [ ] ✅ GitHub usernames if they identify real people
- [ ] ✅ Slack user IDs or workspace URLs
- [ ] ✅ Google Drive folder links to real org folders

**Check**:
```bash
# Find person names (use git log audit too)
grep -rn "@blw\|@elvis\|@moser\|Amber\|Maya\|Pastor\|Toby\|Sharon" src/ --include="*.ts" --include="*.tsx"

# Find production email domains
grep -rn "@blw.ca\|@blacksheeptech\|@ministry" . --include="*.ts" --include="*.tsx" --include="*.md"
```

---

## 4. Database & Migration Artifacts

Operational history should be in schema baseline, not migration files:

- [ ] ✅ `supabase/migrations/` contains only recent, non-operational migrations
- [ ] ✅ Old 248 migrations replaced with clean schema baseline (`supabase/schema/`)
- [ ] ✅ No comments in schema files referencing specific people or incidents
- [ ] ✅ `supabase/seed.sql` uses synthetic demo data (not production exports)
- [ ] ✅ No hardcoded UUIDs for real users in migration logic
- [ ] ✅ No guards checking for specific real-person names (e.g., `WHERE name = 'Pastor X'`)
- [ ] ✅ `supabase/migration-log.md` removed or sanitized (if exists)

**Check**:
```bash
# Count migrations (should be <50 for a clean project)
ls -1 supabase/migrations/*.sql | wc -l

# Look for hardcoded UUIDs in recent migrations
grep -r "[0-9a-f]\{8\}-[0-9a-f]\{4\}" supabase/migrations/*.sql | grep -v "gen_random\|default" | head -20
```

---

## 5. Edge Functions & Server-Side

Supabase functions may contain specific business logic:

- [ ] ✅ No hardcoded org UUIDs in function logic
- [ ] ✅ No specific webhook URLs from production
- [ ] ✅ No Elvanto/RockSolid/specific-vendor API calls (should be abstracted to providers)
- [ ] ✅ No specific meeting types or business rules hardcoded
- [ ] ✅ No comments referencing production incidents
- [ ] ✅ No direct references to specific user roles (use auth requirements instead)
- [ ] ✅ All functions use demo/mock adapters when appropriate

**Check**:
```bash
grep -rn "elvanto\|rocksolid\|foundation school\|subgroup" supabase/functions/ --include="*.ts" | head -20
```

---

## 6. Configuration & Deployments

Private deployment config should not be visible:

- [ ] ✅ No `src/config/deployments/blw.ts` or similar in public repo
- [ ] ✅ `src/config/deployments/demo.ts` is generic and neutral
- [ ] ✅ No hardcoded vendor mappings in demo deployment
- [ ] ✅ `.env.demo.example` uses placeholder values (not real ANON_KEY)
- [ ] ✅ No references to production Supabase projects
- [ ] ✅ Demo Supabase project details are public-safe (can be shared)

---

## 7. Documentation

Docs should explain architecture, not operations:

- [ ] ✅ README doesn't link to runbooks, incident logs, or operational docs
- [ ] ✅ No .gitignore'd docs accidentally committed (check `git status`)
- [ ] ✅ Public docs don't reference real incidents or people
- [ ] ✅ Public docs don't name the organization
- [ ] ✅ No CLEANUP.md, RELEASE_1_SUMMARY.md, SESSION_COMPLETION_SUMMARY.md (removed)
- [ ] ✅ CASE_STUDY.md is generic ("how we solved a distributed team coordination problem")
- [ ] ✅ Example code in docs uses synthetic/demo data only
- [ ] ✅ No sensitive URLs in docs (Vercel, Supabase, AWS, etc.)

**Check**:
```bash
# Should only have Phase files and architecture/engineering docs
ls -1 *.md | grep -v README | grep -v PHASE | grep -v "LICENSE\|SANITIZATION"
```

---

## 8. Source Code Comments & Logs

Developers often leave breadcrumbs:

- [ ] ✅ No `// TODO: fix for Pastor X` or similar person-specific TODOs
- [ ] ✅ No `// Workaround for Toby's flight booking issue`
- [ ] ✅ No hardcoded test data with real names
- [ ] ✅ No console.log statements with production data
- [ ] ✅ No URLs with real org slugs in code comments
- [ ] ✅ No references to specific dates of incidents ("On July 15, we had to...")

**Check**:
```bash
grep -rn "TODO\|HACK\|FIXME\|XXX" src/ --include="*.ts" --include="*.tsx" | head -20
```

---

## 9. Git History

Commits that reference private information:

- [ ] ✅ Sensitive commits have been force-pushed (if needed)
- [ ] ✅ No commit messages naming specific people or incidents
- [ ] ✅ No commit messages referencing production problems
- [ ] ⚠️ Note: Some history is OK if it shows your thinking process

**Check**:
```bash
# Review recent commits
git log --oneline -50 | grep -i "pastor\|toby\|amber\|fix for user\|production bug"
```

---

## 10. Integration & Vendor References

Code shouldn't hardcode vendor choices:

- [ ] ✅ No hardcoded "use Elvanto" logic (wrapped in providers)
- [ ] ✅ No hardcoded "use RockSolid" logic (wrapped in providers)
- [ ] ✅ No hardcoded "use Google Calendar" (wrapped in providers)
- [ ] ✅ No hardcoded "use Resend" (wrapped in providers)
- [ ] ✅ No hardcoded "use Deepgram" (wrapped in providers)
- [ ] ✅ Demo deployment uses mock/stub implementations

**Check**:
```bash
grep -rn "if (PROVIDER === 'elvanto')\|new RockSolidClient\|new GoogleCalendar\|process.env.DEEPGRAM" src/ \
  --include="*.ts" --include="*.tsx" | head -20
```

---

## 11. Tests & Fixtures

Test data might leak production info:

- [ ] ✅ Test fixtures use synthetic data only
- [ ] ✅ No email addresses from production in tests
- [ ] ✅ No real user UUIDs in test setup
- [ ] ✅ Test data is clearly marked as synthetic
- [ ] ✅ No seeded production data in test databases

---

## 12. Build Artifacts & Logs

Generated files shouldn't be committed:

- [ ] ✅ No `.env.local` or `.env.production` files
- [ ] ✅ `dist/`, `build/`, `node_modules/` are .gitignored
- [ ] ✅ No build logs containing secrets
- [ ] ✅ No `*.log` files committed
- [ ] ✅ No `.DS_Store`, `Thumbs.db`, or editor config files

---

## 13. Package.json & Dependencies

Package metadata might leak info:

- [ ] ✅ No private npm registry URLs
- [ ] ✅ No org-specific git dependencies (use public URLs)
- [ ] ✅ Version numbers don't leak timeline info
- [ ] ✅ No private package.json scripts that reference org names

---

## 14. README & Public-Facing Copy

The README is the first impression:

- [ ] ✅ README describes **what** Nexus does, not **where** it's deployed
- [ ] ✅ Demo section has realistic but synthetic credentials
- [ ] ✅ No production Supabase project URL exposed in README
- [ ] ✅ License/portfolio statement is clear about what's included/excluded
- [ ] ✅ No links to private operational documents
- [ ] ✅ Demo organization name is generic ("Virtual Launch Inc." or similar)

---

## 15. GitHub Settings (If Applicable)

Repository-level configuration:

- [ ] ✅ Repository is public
- [ ] ✅ No sensitive branch protection rules exposed
- [ ] ✅ No organization/team-specific webhooks
- [ ] ✅ GitHub secrets are clean and don't relate to production
- [ ] ✅ Repository description is generic

---

## Final Audit Script

Run this before pushing to GitHub:

```bash
#!/bin/bash
set -e

echo "=== SANITIZATION AUDIT ==="
echo ""

echo "1. Checking for credentials..."
grep -r "OPENAI_API_KEY\|SUPABASE_SERVICE_KEY\|SECRET" . \
  --include="*.env*" --include="*.ts" --include="*.tsx" \
  --exclude-dir=node_modules --exclude-dir=.git && echo "⚠️ FOUND CREDENTIALS" || echo "✓ No credentials"

echo ""
echo "2. Checking for BLW references..."
grep -r "BLW\|blwcan" src/ --include="*.ts" --include="*.tsx" \
  --exclude-dir=node_modules && echo "⚠️ FOUND BLW REFS" || echo "✓ No BLW references"

echo ""
echo "3. Checking for people names..."
grep -r "@blw.ca\|@gmail\|Pastor\|Toby\|Amber\|Sharon" src/ --include="*.ts" --include="*.tsx" \
  --exclude-dir=node_modules && echo "⚠️ FOUND PEOPLE DATA" || echo "✓ No people data"

echo ""
echo "4. Checking migrations..."
ls -1 supabase/migrations/*.sql | wc -l | xargs echo "Migration files:"
grep -l "name = 'Pastor\|WHERE email LIKE" supabase/migrations/*.sql && echo "⚠️ FOUND PERSON-SPECIFIC LOGIC" || echo "✓ No person-specific migration logic"

echo ""
echo "5. Checking git log..."
git log --oneline -50 | grep -i "production\|fix for\|incident" && echo "⚠️ FOUND OPERATIONAL REFS IN GIT" || echo "✓ Clean git log"

echo ""
echo "6. Checking for .env files..."
git status --porcelain | grep ".env" && echo "⚠️ .ENV FILES NOT GITIGNORED" || echo "✓ .env files clean"

echo ""
echo "=== AUDIT COMPLETE ==="
```

---

## If Audit Fails

| Finding | Action |
|---------|--------|
| Credentials found | Remove and rotate immediately |
| BLW references | Replace with generic "deployment" / "organization" terminology |
| People names/emails | Remove or anonymize (use synthetic names in demo) |
| Hardcoded logic | Wrap in provider pattern or move to deployment config |
| Operational git log | Rewrite history with `git filter-branch` (if needed) |

---

## Notes

- This is not a one-time audit — run it before every public release
- Some history (commits showing your problem-solving) is actually good for a portfolio
- The goal is **transparency** — make it clear what's removed and why
- Update this checklist as new vulnerabilities are discovered
