# Phase 3: Integration Abstraction — Pluggable Providers

**Status**: Planning (starts after Phase 2)

**Goal**: Move integration-specific code into replaceable provider modules. Core Nexus knows only about provider interfaces; deployments choose implementations.

## Current State (Anti-Pattern)

Integrations are embedded throughout the codebase with hardcoded references:

```
src/
  components/
    flock/FlockCRMPage.jsx        ← Elvanto-specific UI
  features/
    meetings/
      hooks/useAudioTranscription.ts   ← Deepgram-hardcoded
      lib/extractMeetingData.ts        ← Anthropic-hardcoded
    calendar/
      hooks/useGoogleCalendarSync.ts   ← Google-specific
  lib/
    google-calendar.ts            ← Google-specific helpers
    email/resendEmail.ts          ← Resend-hardcoded
```

Edge functions embed specific integrations:

```
supabase/functions/
  google-oauth-callback/          ← Google-specific
  google-calendar-sync/           ← Google-specific
  google-drive-upload/            ← Google-specific
  register-attendance/
    rocksolid-sync/               ← RockSolid-specific
  extract-meeting-data/
    deepgram-webhook/             ← Deepgram-specific
```

**Problem**: To use Nexus with different integrations (e.g., Microsoft Calendar instead of Google, or a different CRM), you'd have to fork and rewrite files across multiple directories.

## Solution: Provider Pattern

Create a provider abstraction layer. Core Nexus defines provider interfaces; deployments wire concrete implementations.

### Step 1: Define Provider Interfaces

Create `src/integrations/providers.ts`:

```typescript
/**
 * Provider interfaces — core Nexus integration contracts.
 * 
 * Deployments implement these interfaces and register them.
 * Core code uses providers, not hardcoded integrations.
 */

// Attendance/Roster
export interface RosterProvider {
  name: string
  syncRoster(organizationId: string): Promise<RosterSyncResult>
  getMemberDetails(memberId: string): Promise<MemberDetails | null>
  recordAttendance(eventId: string, memberId: string, attended: boolean): Promise<void>
}

// Calendar
export interface CalendarProvider {
  name: string
  getAuthUrl(): string
  handleAuthCallback(code: string, state: string): Promise<CalendarAccount>
  listCalendars(accountId: string): Promise<CalendarSource[]>
  syncEvents(accountId: string, calendarId: string): Promise<SyncResult>
  pushEvent(event: CalendarEvent): Promise<void>
}

// Email
export interface EmailProvider {
  name: string
  sendEmail(to: string, subject: string, html: string): Promise<SendResult>
  sendBatch(recipients: Recipient[], subject: string, html: string): Promise<SendResult>
  trackBounce(email: string): Promise<void>
}

// CRM/Contacts
export interface CRMProvider {
  name: string
  syncContacts(organizationId: string): Promise<SyncResult>
  getContact(externalId: string): Promise<Contact | null>
  logCall(contactId: string, notes: string, duration: number): Promise<void>
  addFollowUp(contactId: string, dueDate: date, notes: string): Promise<void>
}

// Transcription
export interface TranscriptionProvider {
  name: string
  transcribeAudio(audioUrl: string): Promise<TranscriptionResult>
  handleWebhook(payload: unknown): Promise<TranscriptionResult>
}

// Document Processing (for Immerse/e-reader)
export interface DocumentProvider {
  name: string
  uploadDocument(file: Buffer, metadata: DocumentMetadata): Promise<Document>
  getTextContent(documentId: string): Promise<string>
  getPageImage(documentId: string, pageNum: number): Promise<Buffer>
}

// Analytics/Reporting
export interface AnalyticsProvider {
  name: string
  trackEvent(eventName: string, properties: Record<string, unknown>): Promise<void>
  trackPageView(path: string): Promise<void>
}
```

### Step 2: Create Provider Registry

Create `src/integrations/registry.ts`:

```typescript
import { type RosterProvider, type CalendarProvider, /* ... */ } from './providers'

export interface ProviderRegistry {
  roster?: RosterProvider
  calendar?: CalendarProvider
  email?: EmailProvider
  crm?: CRMProvider
  transcription?: TranscriptionProvider
  document?: DocumentProvider
  analytics?: AnalyticsProvider
}

let _registry: ProviderRegistry = {}

export function registerProviders(providers: Partial<ProviderRegistry>) {
  _registry = { ..._registry, ...providers }
}

export function getProvider<K extends keyof ProviderRegistry>(
  name: K
): ProviderRegistry[K] {
  const provider = _registry[name]
  if (!provider) {
    throw new Error(`Provider '${String(name)}' not registered`)
  }
  return provider
}

export function getProviderOrNull<K extends keyof ProviderRegistry>(
  name: K
): ProviderRegistry[K] | null {
  return _registry[name] ?? null
}

export function isProviderAvailable(name: keyof ProviderRegistry): boolean {
  return _registry[name] !== undefined
}
```

### Step 3: Organize Integration Implementations

Create directory structure:

```
src/integrations/
  providers.ts                    # Interfaces
  registry.ts                     # Registration system
  
  roster/
    index.ts                      # Export interface
    rocksolid-adapter.ts          # RockSolid implementation
    csv-adapter.ts                # CSV import adapter
    mock-adapter.ts               # Demo implementation
  
  calendar/
    index.ts
    google-adapter.ts             # Google Calendar
    microsoft-adapter.ts          # Microsoft Outlook (future)
    mock-adapter.ts               # Demo implementation
  
  email/
    index.ts
    resend-adapter.ts             # Resend
    sendgrid-adapter.ts           # SendGrid (future)
    mock-adapter.ts               # Demo/test implementation
  
  crm/
    index.ts
    elvanto-adapter.ts            # Elvanto
    airtable-adapter.ts           # Airtable (future)
    mock-adapter.ts               # Demo implementation
  
  transcription/
    index.ts
    deepgram-adapter.ts           # Deepgram
    openai-adapter.ts             # OpenAI Whisper
    mock-adapter.ts               # Demo implementation
  
  document/
    index.ts
    pdf-adapter.ts                # PDF.js based
  
  analytics/
    index.ts
    posthog-adapter.ts            # PostHog (optional)
    mock-adapter.ts               # No-op demo
```

Each adapter exports its provider implementation:

```typescript
// src/integrations/roster/rocksolid-adapter.ts
import { type RosterProvider } from '../providers'

export const rocksolidRosterProvider: RosterProvider = {
  name: 'rocksolid',
  
  async syncRoster(organizationId: string) {
    // RockSolid-specific logic
    const client = new RockSolidClient(process.env.ROCKSOLID_API_KEY)
    // ...
  },
  
  async getMemberDetails(memberId: string) {
    // ...
  },
  
  async recordAttendance(eventId, memberId, attended) {
    // ...
  },
}
```

### Step 4: Wire Providers in Deployment Config

Update `src/config/deployments/demo.ts`:

```typescript
import { registerProviders } from '@/integrations/registry'
import { mockRosterProvider } from '@/integrations/roster/mock-adapter'
import { mockCalendarProvider } from '@/integrations/calendar/mock-adapter'
import { mockEmailProvider } from '@/integrations/email/mock-adapter'
import { mockCRMProvider } from '@/integrations/crm/mock-adapter'
import { mockTranscriptionProvider } from '@/integrations/transcription/mock-adapter'

// Demo deployment uses mock providers (no real API calls)
registerProviders({
  roster: mockRosterProvider,
  calendar: mockCalendarProvider,
  email: mockEmailProvider,
  crm: mockCRMProvider,
  transcription: mockTranscriptionProvider,
})

export const demoDeploymentConfig = {
  // ... existing config
}
```

For a private BLW deployment:

```typescript
// private-deployment/config/deployments/blw.ts
import { registerProviders } from '@/integrations/registry'
import { rocksolidRosterProvider } from '@/integrations/roster/rocksolid-adapter'
import { googleCalendarProvider } from '@/integrations/calendar/google-adapter'
import { resendEmailProvider } from '@/integrations/email/resend-adapter'
import { elvantoProvider } from '@/integrations/crm/elvanto-adapter'
import { deepgramTranscriptionProvider } from '@/integrations/transcription/deepgram-adapter'

registerProviders({
  roster: rocksolidRosterProvider,
  calendar: googleCalendarProvider,
  email: resendEmailProvider,
  crm: elvantoProvider,
  transcription: deepgramTranscriptionProvider,
})

export const blwDeploymentConfig = {
  // ... existing config
}
```

### Step 5: Update Components to Use Providers

Before (hardcoded):
```typescript
// src/components/flock/FlockCRMPage.jsx
import { syncElvantoContacts } from '@/lib/elvanto-api'

export default function FlockCRMPage() {
  const handleSync = async () => {
    await syncElvantoContacts()  // ← Hardcoded to Elvanto
  }
}
```

After (provider-based):
```typescript
// src/components/flock/FlockCRMPage.jsx
import { getProvider, isProviderAvailable } from '@/integrations/registry'

export default function FlockCRMPage() {
  const handleSync = async () => {
    if (!isProviderAvailable('crm')) {
      toast.error('CRM provider not configured')
      return
    }
    
    const crmProvider = getProvider('crm')
    await crmProvider.syncContacts(organizationId)  // ← Uses provider
  }
}
```

### Step 6: Update Edge Functions

Move integration logic into provider implementations, edge functions call providers:

Before:
```typescript
// supabase/functions/google-oauth-callback/index.ts
import { handleGoogleOAuthCallback } from '../_shared/google-auth'

export async function POST(req: Request) {
  const { code, state } = await req.json()
  const result = await handleGoogleOAuthCallback(code, state)  // ← Hardcoded
}
```

After:
```typescript
// supabase/functions/calendar-oauth-callback/index.ts
import { getProvider } from '../_shared/provider-registry'

export async function POST(req: Request) {
  const { code, state } = await req.json()
  const calendarProvider = getProvider('calendar')
  const result = await calendarProvider.handleAuthCallback(code, state)  // ← Provider-based
}
```

## Implementation Roadmap

### Tier 1: Foundation
- [ ] Create `src/integrations/providers.ts` with all interfaces
- [ ] Create `src/integrations/registry.ts` with registration system
- [ ] Build demo implementations of all providers (no-op/mock)
- [ ] Wire demo providers into demo deployment config

### Tier 2: Roster/Attendance
- [ ] Extract RockSolid logic into `rocksolid-adapter.ts`
- [ ] Remove hardcoded RockSolid imports from core components
- [ ] Update roster sync components to use `getProvider('roster')`
- [ ] Migrate `supabase/functions/register-attendance/rocksolid-sync/` to edge function wrapper

### Tier 3: Calendar
- [ ] Extract Google Calendar logic into `google-adapter.ts`
- [ ] Remove hardcoded Google imports from core components
- [ ] Consolidate `supabase/functions/google-*` into single edge function that calls provider
- [ ] Update calendar UI to check `isProviderAvailable('calendar')`

### Tier 4: Email
- [ ] Extract Resend logic into `resend-adapter.ts`
- [ ] Update email delivery functions to use provider
- [ ] Remove hardcoded Resend references from campaigns

### Tier 5: CRM
- [ ] Extract Elvanto logic into `elvanto-adapter.ts`
- [ ] Update FlockCRM components to use provider
- [ ] Remove hardcoded Elvanto references from Flock module

### Tier 6: Transcription & Others
- [ ] Extract Deepgram logic into `deepgram-adapter.ts`
- [ ] Extract Anthropic logic into separate provider (if not core)
- [ ] Update meeting transcription to use provider

## Benefits

1. **Portability**: Deploy Nexus with different vendors without forking
2. **Multi-vendor**: Mix and match (Google Calendar + SendGrid email + different CRM)
3. **Demo safety**: Public demo uses safe mock providers, zero API calls
4. **Testing**: Swap real providers for test doubles in test suites
5. **Future-proof**: Adding new vendor means adding one adapter, not touching core logic

## Success Criteria

After Phase 3:
- ✅ All integrations behind provider interfaces
- ✅ No hardcoded vendor names in component logic
- ✅ Demo deployment uses mock providers exclusively
- ✅ Private BLW deployment can choose which adapters to use
- ✅ New vendor can be added by creating one adapter file
- ✅ Core Nexus has zero dependency on specific vendors
