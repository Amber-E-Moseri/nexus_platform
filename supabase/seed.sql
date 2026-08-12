-- ============================================================================
-- Nexus Demo: Virtual Launch Organization
-- ============================================================================
-- Realistic example showing how a startup team uses Nexus for:
-- 1. Product launch coordination (Social Media, Branding, Content, Marketing)
-- 2. Internal restructuring (Operations)
-- 3. Cross-functional sprints and collaboration

-- Disable RLS temporarily for seeding (re-enabled by migrations)
SET session_replication_role = REPLICA;

-- ============================================================================
-- USERS (created in auth schema via seed setup script)
-- These UUIDs must match the auth.users records created separately
-- ============================================================================

-- Demo Admin
INSERT INTO public.users (id, name, email, role, department_id, status, activated_at, last_active_at)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'Maya', 'maya@virtualllaunch.app', 'super_admin', NULL, 'active', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Social Media Team
INSERT INTO public.users (id, name, email, role, department_id, status, activated_at, last_active_at)
SELECT * FROM (
  VALUES
    ('22222222-2222-2222-2222-222222222222', 'Alex Chen', 'alex@virtualllaunch.app', 'dept_lead', (SELECT id FROM public.departments WHERE name = 'Admin' LIMIT 1), 'active', NOW(), NOW()),
    ('33333333-3333-3333-3333-333333333333', 'Jordan Smith', 'jordan@virtualllaunch.app', 'member', (SELECT id FROM public.departments WHERE name = 'Admin' LIMIT 1), 'active', NOW(), NOW()),
    ('44444444-4444-4444-4444-444444444444', 'Casey Lee', 'casey@virtualllaunch.app', 'member', (SELECT id FROM public.departments WHERE name = 'Admin' LIMIT 1), 'active', NOW(), NOW()),
    ('55555555-5555-5555-5555-555555555555', 'Sam Rodriguez', 'sam@virtualllaunch.app', 'member', (SELECT id FROM public.departments WHERE name = 'Admin' LIMIT 1), 'active', NOW(), NOW())
) AS t(id, name, email, role, department_id, status, activated_at, last_active_at)
ON CONFLICT (id) DO NOTHING;

-- Brand & Design Team
INSERT INTO public.users (id, name, email, role, department_id, status, activated_at, last_active_at)
SELECT * FROM (
  VALUES
    ('66666666-6666-6666-6666-666666666666', 'Aria Patel', 'aria@virtualllaunch.app', 'dept_lead', (SELECT id FROM public.departments WHERE name = 'Media' LIMIT 1), 'active', NOW(), NOW()),
    ('77777777-7777-7777-7777-777777777777', 'Morgan Davis', 'morgan@virtualllaunch.app', 'member', (SELECT id FROM public.departments WHERE name = 'Media' LIMIT 1), 'active', NOW(), NOW()),
    ('88888888-8888-8888-8888-888888888888', 'Blake Taylor', 'blake@virtualllaunch.app', 'member', (SELECT id FROM public.departments WHERE name = 'Media' LIMIT 1), 'active', NOW(), NOW())
) AS t(id, name, email, role, department_id, status, activated_at, last_active_at)
ON CONFLICT (id) DO NOTHING;

-- Content Team
INSERT INTO public.users (id, name, email, role, department_id, status, activated_at, last_active_at)
SELECT * FROM (
  VALUES
    ('99999999-9999-9999-9999-999999999999', 'Quinn Adams', 'quinn@virtualllaunch.app', 'dept_lead', (SELECT id FROM public.departments WHERE name = 'ORS' LIMIT 1), 'active', NOW(), NOW()),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Reese Mitchell', 'reese@virtualllaunch.app', 'member', (SELECT id FROM public.departments WHERE name = 'ORS' LIMIT 1), 'active', NOW(), NOW())
) AS t(id, name, email, role, department_id, status, activated_at, last_active_at)
ON CONFLICT (id) DO NOTHING;

-- Marketing Team
INSERT INTO public.users (id, name, email, role, department_id, status, activated_at, last_active_at)
SELECT * FROM (
  VALUES
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Tori Williamson', 'tori@virtualllaunch.app', 'dept_lead', (SELECT id FROM public.departments WHERE name = 'PFCC' LIMIT 1), 'active', NOW(), NOW()),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Vance Thompson', 'vance@virtualllaunch.app', 'member', (SELECT id FROM public.departments WHERE name = 'PFCC' LIMIT 1), 'active', NOW(), NOW())
) AS t(id, name, email, role, department_id, status, activated_at, last_active_at)
ON CONFLICT (id) DO NOTHING;

-- Operations Team
INSERT INTO public.users (id, name, email, role, department_id, status, activated_at, last_active_at)
SELECT * FROM (
  VALUES
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Yuki Tanaka', 'yuki@virtualllaunch.app', 'dept_lead', (SELECT id FROM public.departments WHERE name = 'Pastors' LIMIT 1), 'active', NOW(), NOW()),
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Zara Hassan', 'zara@virtualllaunch.app', 'member', (SELECT id FROM public.departments WHERE name = 'Pastors' LIMIT 1), 'active', NOW(), NOW())
) AS t(id, name, email, role, department_id, status, activated_at, last_active_at)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- TASK STATUS DEFINITIONS (Org-wide canonical statuses)
-- ============================================================================

INSERT INTO public.task_status_definitions (name, color, category, department_id, sort_order, is_default, active, legacy_key)
VALUES
  ('To Do', '#378ADD', 'open', NULL, 0, true, true, 'to_do'),
  ('In Progress', '#F59E0B', 'in_progress', NULL, 1, false, true, 'in_progress'),
  ('In Review', '#8B5CF6', 'in_progress', NULL, 2, false, true, 'in_review'),
  ('Done', '#10B981', 'completed', NULL, 3, false, true, 'done'),
  ('Blocked', '#EF4444', 'cancelled', NULL, 4, false, true, 'blocked')
ON CONFLICT (lower(name)) WHERE department_id IS NULL DO NOTHING;

-- ============================================================================
-- SPRINTS
-- ============================================================================

INSERT INTO public.sprints (name, description, goal, status, start_date, end_date, created_by, is_archived)
SELECT * FROM (
  VALUES
    ('Q1 Product Launch Sprint', 'Coordinated launch across all teams. Target: Feb 15 launch with full marketing push, social coordination, and brand rollout.', 'Launch our product successfully', 'active', '2025-02-01'::date, '2025-02-15'::date, '11111111-1111-1111-1111-111111111111', false),
    ('Social Media Q1 Planning', 'Content calendar, TikTok strategy, community management', 'Execute social media strategy', 'active', '2025-01-15'::date, '2025-02-15'::date, '22222222-2222-2222-2222-222222222222', false),
    ('Brand Refresh Initiative', 'Logo refinement, color palette, style guide updates', 'Finalize brand identity', 'active', '2025-01-20'::date, '2025-02-20'::date, '66666666-6666-6666-6666-666666666666', false),
    ('Org Structure Sprint', 'Define roles, reporting lines, decision rights', 'Clarify organizational structure', 'planning', '2025-02-01'::date, '2025-03-01'::date, '11111111-1111-1111-1111-111111111111', false),
    ('Launch Marketing Campaign', 'Paid ads, email campaigns, press kit, early access', 'Drive launch awareness', 'active', '2025-02-01'::date, '2025-02-15'::date, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', false)
) AS t(name, description, goal, status, start_date, end_date, created_by, is_archived)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SPRINT TEAMS
-- ============================================================================

INSERT INTO public.sprint_teams (sprint_id, name, description)
SELECT
  s.id, t.name, t.description
FROM (
  VALUES
    ('Q1 Product Launch Sprint', 'Social Media Blitz', 'Daily posts, community response, influencer outreach'),
    ('Q1 Product Launch Sprint', 'Brand Launch', 'Visual assets, brand announcement, style guide rollout'),
    ('Q1 Product Launch Sprint', 'Content Release', 'Launch blog post, launch video, case studies'),
    ('Q1 Product Launch Sprint', 'Marketing Blitz', 'Paid campaigns, email sequence, partnerships')
) AS t(sprint_name, name, description)
JOIN public.sprints s ON s.name = t.sprint_name
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SPRINT MEMBERS
-- ============================================================================

INSERT INTO public.sprint_members (sprint_id, user_id, sprint_team_id, role, joined_at)
SELECT
  s.id, u.id, st.id, m.role, NOW()
FROM (
  VALUES
    ('Q1 Product Launch Sprint', 'Social Media Blitz', '22222222-2222-2222-2222-222222222222', 'lead'),
    ('Q1 Product Launch Sprint', 'Social Media Blitz', '33333333-3333-3333-3333-333333333333', 'member'),
    ('Q1 Product Launch Sprint', 'Social Media Blitz', '44444444-4444-4444-4444-444444444444', 'member'),
    ('Q1 Product Launch Sprint', 'Brand Launch', '66666666-6666-6666-6666-666666666666', 'lead'),
    ('Q1 Product Launch Sprint', 'Brand Launch', '77777777-7777-7777-7777-777777777777', 'member'),
    ('Q1 Product Launch Sprint', 'Content Release', '99999999-9999-9999-9999-999999999999', 'lead'),
    ('Q1 Product Launch Sprint', 'Content Release', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'member'),
    ('Q1 Product Launch Sprint', 'Marketing Blitz', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'lead'),
    ('Q1 Product Launch Sprint', 'Marketing Blitz', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'member')
) AS m(sprint_name, team_name, user_id, role)
JOIN public.sprints s ON s.name = m.sprint_name
JOIN public.sprint_teams st ON st.sprint_id = s.id AND st.name = m.team_name
JOIN public.users u ON u.id = m.user_id
ON CONFLICT DO NOTHING;

-- ============================================================================
-- FOLDERS & LISTS (Workspace hierarchy)
-- ============================================================================

INSERT INTO public.folders (name, department_id, sort_order, created_by)
SELECT * FROM (
  VALUES
    ('Launch Campaign Hub', (SELECT id FROM public.departments WHERE name = 'Admin' LIMIT 1), 0, '11111111-1111-1111-1111-111111111111'),
    ('Social Media Tasks', (SELECT id FROM public.departments WHERE name = 'Admin' LIMIT 1), 1, '22222222-2222-2222-2222-222222222222'),
    ('Brand Tasks', (SELECT id FROM public.departments WHERE name = 'Media' LIMIT 1), 0, '66666666-6666-6666-6666-666666666666'),
    ('Content Tasks', (SELECT id FROM public.departments WHERE name = 'ORS' LIMIT 1), 0, '99999999-9999-9999-9999-999999999999'),
    ('Org Restructuring', (SELECT id FROM public.departments WHERE name = 'Pastors' LIMIT 1), 0, '11111111-1111-1111-1111-111111111111')
) AS t(name, department_id, sort_order, created_by)
ON CONFLICT DO NOTHING;

INSERT INTO public.lists (name, folder_id, department_id, sort_order, created_by)
SELECT
  l.name, f.id, f.department_id, l.sort_order, l.created_by
FROM (
  VALUES
    ('Launch Campaign Hub', 'Launch Coordination', 0, '11111111-1111-1111-1111-111111111111'),
    ('Launch Campaign Hub', 'Cross-Team Blockers', 1, '11111111-1111-1111-1111-111111111111'),
    ('Social Media Tasks', 'TikTok Content', 0, '22222222-2222-2222-2222-222222222222'),
    ('Social Media Tasks', 'Instagram Reels', 1, '22222222-2222-2222-2222-222222222222'),
    ('Brand Tasks', 'Logo & Colors', 0, '66666666-6666-6666-6666-666666666666'),
    ('Brand Tasks', 'Style Guide', 1, '66666666-6666-6666-6666-666666666666'),
    ('Content Tasks', 'Blog & Video', 0, '99999999-9999-9999-9999-999999999999'),
    ('Org Restructuring', 'Structure & Roles', 0, '11111111-1111-1111-1111-111111111111'),
    ('Org Restructuring', 'Team Assignments', 1, '11111111-1111-1111-1111-111111111111')
) AS l(folder_name, name, sort_order, created_by)
JOIN public.folders f ON f.name = l.folder_name
ON CONFLICT DO NOTHING;

-- ============================================================================
-- TASKS (Detailed work items with status)
-- ============================================================================

INSERT INTO public.tasks (
  title, description, list_id, sprint_id, created_by,
  status_id, priority, due_date, department_id, is_personal, created_at
)
SELECT
  t.title, t.description, l.id, s.id, t.created_by,
  (SELECT id FROM public.task_status_definitions WHERE legacy_key = t.status_key AND department_id IS NULL LIMIT 1),
  t.priority, t.due_date, t.department_id, t.is_personal, NOW()
FROM (
  VALUES
    ('Launch Coordination Kickoff', 'All teams sync on timeline, deliverables, handoffs. Alex (Social), Aria (Brand), Quinn (Content), Tori (Marketing) present alignment.', 'Launch Coordination', 'Q1 Product Launch Sprint', '11111111-1111-1111-1111-111111111111', 'in_progress', 'high', '2025-02-05'::date, (SELECT id FROM public.departments WHERE name = 'Admin' LIMIT 1), false),
    ('TikTok Launch Content Calendar', 'Plan 30 TikToks for launch week. Mix of behind-the-scenes, feature demos, user testimonials. Coordinate with Jordan and Casey for posting.', 'TikTok Content', 'Social Media Q1 Planning', '22222222-2222-2222-2222-222222222222', 'in_progress', 'high', '2025-02-10'::date, (SELECT id FROM public.departments WHERE name = 'Admin' LIMIT 1), false),
    ('Instagram Reels: Product Feature Breakdown', '4 reels showing product features. Quick cuts, music, text overlay. Aria to provide brand assets. Quinn to provide product copy.', 'Instagram Reels', 'Social Media Q1 Planning', '33333333-3333-3333-3333-333333333333', 'in_progress', 'high', '2025-02-12'::date, (SELECT id FROM public.departments WHERE name = 'Admin' LIMIT 1), false),
    ('Brand Logo & Color Palette Finalization', 'Refine based on feedback from Maya. Deliver final Figma file with all variations, spacing, usage guidelines.', 'Logo & Colors', 'Brand Refresh Initiative', '77777777-7777-7777-7777-777777777777', 'done', 'high', '2025-02-08'::date, (SELECT id FROM public.departments WHERE name = 'Media' LIMIT 1), false),
    ('Style Guide Documentation', 'Write comprehensive style guide including: typography, colors, icons, photography style, tone of voice.', 'Style Guide', 'Brand Refresh Initiative', '88888888-8888-8888-8888-888888888888', 'in_progress', 'medium', '2025-02-15'::date, (SELECT id FROM public.departments WHERE name = 'Media' LIMIT 1), false),
    ('Launch Announcement Email Sequence', '5-email sequence: Announcement → Feature deep-dive → Success stories → Special offer → Post-launch follow-up.', 'Cross-Team Blockers', 'Launch Marketing Campaign', '11111111-1111-1111-1111-111111111111', 'in_progress', 'high', '2025-02-14'::date, (SELECT id FROM public.departments WHERE name = 'PFCC' LIMIT 1), false),
    ('Influencer Outreach & Partnerships', 'List of 20 micro-influencers in our space. Draft partnership offer, send outreach, track responses.', 'Cross-Team Blockers', 'Launch Marketing Campaign', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'in_progress', 'medium', '2025-02-10'::date, (SELECT id FROM public.departments WHERE name = 'PFCC' LIMIT 1), false),
    ('Define Department Structures & Reporting Lines', 'Map out: Who reports to whom, cross-functional dependencies, communication channels. Yuki to draft, review with Maya.', 'Structure & Roles', 'Org Structure Sprint', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'in_progress', 'high', '2025-02-20'::date, (SELECT id FROM public.departments WHERE name = 'Pastors' LIMIT 1), false),
    ('Role Clarity & Competency Mapping', 'Document each role: responsibilities, required skills, success metrics. Involve each dept lead.', 'Structure & Roles', 'Org Structure Sprint', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'to_do', 'medium', '2025-02-28'::date, (SELECT id FROM public.departments WHERE name = 'Pastors' LIMIT 1), false),
    ('All-Hands: Org Structure Announcement', 'Present new structure, roles, expectations. Q&A. Video recording for those who miss it.', 'Team Assignments', 'Org Structure Sprint', '11111111-1111-1111-1111-111111111111', 'to_do', 'high', '2025-03-01'::date, (SELECT id FROM public.departments WHERE name = 'Pastors' LIMIT 1), false)
) AS t(title, description, list_name, sprint_name, created_by, status_key, priority, due_date, department_id, is_personal)
JOIN public.lists l ON l.name = t.list_name
JOIN public.sprints s ON s.name = t.sprint_name
ON CONFLICT DO NOTHING;

-- ============================================================================
-- PERSONAL TASKS (Individual work across all departments)
-- ============================================================================

INSERT INTO public.tasks (
  title, description, created_by,
  status_id, priority, due_date, is_personal, created_at
)
SELECT
  t.title, t.description, t.created_by,
  (SELECT id FROM public.task_status_definitions WHERE legacy_key = t.status_key LIMIT 1),
  t.priority, t.due_date, true, NOW()
FROM (
  VALUES
    ('Prepare TikTok Trend Report', 'Analysis of trending sounds, formats for Feb launch window. For team reference and content planning.', '33333333-3333-3333-3333-333333333333', 'in_progress', 'medium', '2025-02-08'::date),
    ('Create Brand Assets Kit', 'Export all logos, icons, color swatches as accessible files for team download. Coordinate with Blake.', '77777777-7777-7777-7777-777777777777', 'in_progress', 'high', '2025-02-12'::date),
    ('Write Blog Post: Product Launch Story', 'Behind-the-scenes narrative of product building. 2000 words. Include team quotes.', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'in_progress', 'high', '2025-02-13'::date),
    ('Finalize PR Pitch & Media List', '30 journalists to reach out to. Personalized pitches ready. Follow-up schedule planned.', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'in_progress', 'high', '2025-02-11'::date),
    ('People Team: Interview Process Documentation', 'Document how we hire, onboard, evaluate performance. Link to new org structure.', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'to_do', 'medium', '2025-03-05'::date)
) AS t(title, description, created_by, status_key, priority, due_date)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- TASK ASSIGNEES
-- ============================================================================

INSERT INTO public.task_assignees (task_id, user_id)
SELECT t.id, u.id
FROM public.tasks t
JOIN public.users u ON true
WHERE
  t.title IN ('TikTok Launch Content Calendar', 'Instagram Reels: Product Feature Breakdown', 'Brand Logo & Color Palette Finalization', 'Style Guide Documentation')
  AND u.id IN ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444444', '66666666-6666-6666-6666-666666666666', '77777777-7777-7777-7777-777777777777')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- MEETINGS
-- ============================================================================

INSERT INTO public.meetings (title, description, date, meeting_type, department_id, created_by, created_at)
VALUES
  ('Launch Coordination Sync - All Teams', 'Weekly sync on launch readiness. Social calendar, brand assets, content pipeline, marketing spend. Alex, Aria, Quinn, Tori presenting status.', NOW() + INTERVAL '2 days', 'general', (SELECT id FROM public.departments WHERE name = 'Admin' LIMIT 1), '11111111-1111-1111-1111-111111111111', NOW()),
  ('Social Media Team Daily Standup', 'Jordan: TikTok uploads. Casey: Instagram edits. Sam: Community management & comments.', NOW() + INTERVAL '1 day', 'general', (SELECT id FROM public.departments WHERE name = 'Admin' LIMIT 1), '22222222-2222-2222-2222-222222222222', NOW()),
  ('Design System Review', 'Blake presents updated style guide. Aria provides feedback. Export process discussion.', NOW() + INTERVAL '3 days', 'general', (SELECT id FROM public.departments WHERE name = 'Media' LIMIT 1), '66666666-6666-6666-6666-666666666666', NOW()),
  ('Content Deep Dive: Blog & Video', 'Reese presenting draft blog post. Discuss angles, messaging, publishing timeline.', NOW() + INTERVAL '4 days', 'general', (SELECT id FROM public.departments WHERE name = 'ORS' LIMIT 1), '99999999-9999-9999-9999-999999999999', NOW())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- MEETING ATTENDANCE
-- ============================================================================

INSERT INTO public.meeting_attendance (meeting_id, user_id, status)
SELECT m.id, u.id, 'present'
FROM public.meetings m
CROSS JOIN public.users u
WHERE
  m.title = 'Launch Coordination Sync - All Teams'
  AND u.id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '66666666-6666-6666-6666-666666666666', '99999999-9999-9999-9999-999999999999', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb')
ON CONFLICT DO NOTHING;

INSERT INTO public.meeting_attendance (meeting_id, user_id, status)
SELECT m.id, u.id, 'present'
FROM public.meetings m
CROSS JOIN public.users u
WHERE
  m.title = 'Social Media Team Daily Standup'
  AND u.id IN ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', '44444444-4444-4444-4444-444444444444', '55555555-5555-5555-5555-555555555555')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- TASK COMMENTS
-- ============================================================================

INSERT INTO public.task_comments (task_id, author_id, body, created_at)
SELECT t.id, u.id, c.body, NOW() + (ROW_NUMBER() OVER (ORDER BY t.id) * INTERVAL '1 hour')
FROM public.tasks t
CROSS JOIN (
  VALUES
    ('33333333-3333-3333-3333-333333333333', 'Jordan has the first batch of 10 TikToks ready for review. Need brand team sign-off ASAP.'),
    ('44444444-4444-4444-4444-444444444444', 'Reviewed—looks great! One small note on color usage in video 3. Should we add captions for accessibility?'),
    ('99999999-9999-9999-9999-999999999999', 'Can we try a different music track for the second reel? Current one feels flat for launch energy.'),
    ('77777777-7777-7777-7777-777777777777', 'Finalized the logo—delivered to Figma. Blake is building out color variations now.')
) AS c(user_id, body)
JOIN public.users u ON u.id = c.user_id
WHERE t.title IN ('Instagram Reels: Product Feature Breakdown', 'Brand Logo & Color Palette Finalization')
LIMIT 4
ON CONFLICT DO NOTHING;

-- Re-enable RLS
SET session_replication_role = DEFAULT;
