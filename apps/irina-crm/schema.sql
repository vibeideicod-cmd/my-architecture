CREATE TABLE IF NOT EXISTS leads (
  id TEXT PRIMARY KEY,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  source TEXT NOT NULL,
  status TEXT NOT NULL,
  name TEXT NOT NULL,
  channel TEXT NOT NULL,
  contact TEXT NOT NULL,
  context_note TEXT,
  main_growth_point TEXT,
  interested_offer_format TEXT,
  notification_channel TEXT,
  notification_status TEXT,
  consent_given_at TEXT,
  consent_text_version TEXT,
  niche TEXT,
  business_age TEXT,
  team_size TEXT,
  workload TEXT,
  main_pains TEXT,
  automation_now TEXT,
  ai_experience TEXT,
  ai_blockers TEXT,
  result_summary TEXT,
  next_step TEXT,
  followup_owner TEXT,
  followup_due_at TEXT,
  notes TEXT,
  partner TEXT,
  target TEXT,
  raw_payload TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_leads_created_at ON leads(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_source ON leads(source);
