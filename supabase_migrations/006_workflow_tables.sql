-- Week 15-16: Advanced AI Features
-- Workflow and Conversation Tables

-- ============================================================
-- CONVERSATION HISTORY
-- ============================================================

-- Store conversation sessions
CREATE TABLE IF NOT EXISTS conversation_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT,
  messages JSONB NOT NULL DEFAULT '[]',
  context JSONB DEFAULT '{}',
  is_archived BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for efficient user queries
CREATE INDEX IF NOT EXISTS idx_conversation_history_user_id 
  ON conversation_history(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_history_updated 
  ON conversation_history(updated_at DESC);

-- ============================================================
-- WORKFLOW RUNS
-- ============================================================

-- Track automated workflow executions
CREATE TABLE IF NOT EXISTS workflow_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workflow_type TEXT NOT NULL,
  trigger_type TEXT NOT NULL DEFAULT 'manual', -- 'manual', 'scheduled', 'event'
  status TEXT DEFAULT 'pending', -- 'pending', 'running', 'completed', 'failed'
  input_data JSONB DEFAULT '{}',
  result JSONB,
  error_message TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- Index for workflow queries
CREATE INDEX IF NOT EXISTS idx_workflow_runs_user_id 
  ON workflow_runs(user_id);
CREATE INDEX IF NOT EXISTS idx_workflow_runs_status 
  ON workflow_runs(status);

-- ============================================================
-- WORKFLOW SETTINGS
-- ============================================================

-- User preferences for automated workflows
CREATE TABLE IF NOT EXISTS workflow_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workflow_type TEXT NOT NULL,
  is_enabled BOOLEAN DEFAULT TRUE,
  schedule_cron TEXT, -- For scheduled workflows
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, workflow_type)
);

-- ============================================================
-- DOCUMENT TEMPLATES
-- ============================================================

-- Custom document templates
CREATE TABLE IF NOT EXISTS document_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  template_type TEXT NOT NULL, -- 'invoice', 'report', 'quotation', 'expense_report'
  name TEXT NOT NULL,
  content JSONB NOT NULL, -- Template structure
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for template queries
CREATE INDEX IF NOT EXISTS idx_document_templates_user_id 
  ON document_templates(user_id);

-- ============================================================
-- GENERATED DOCUMENTS
-- ============================================================

-- Track generated documents
CREATE TABLE IF NOT EXISTS generated_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  template_id UUID REFERENCES document_templates(id),
  document_type TEXT NOT NULL,
  title TEXT NOT NULL,
  file_path TEXT, -- Storage path
  data JSONB DEFAULT '{}', -- Document data
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE conversation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE workflow_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE workflow_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE generated_documents ENABLE ROW LEVEL SECURITY;

-- Conversation history policies
CREATE POLICY "Users can manage own conversations"
  ON conversation_history FOR ALL
  USING (auth.uid() = user_id);

-- Workflow runs policies
CREATE POLICY "Users can view own workflow runs"
  ON workflow_runs FOR ALL
  USING (auth.uid() = user_id);

-- Workflow settings policies
CREATE POLICY "Users can manage own workflow settings"
  ON workflow_settings FOR ALL
  USING (auth.uid() = user_id);

-- Document templates policies
CREATE POLICY "Users can manage own templates"
  ON document_templates FOR ALL
  USING (auth.uid() = user_id);

-- Generated documents policies
CREATE POLICY "Users can manage own documents"
  ON generated_documents FOR ALL
  USING (auth.uid() = user_id);

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_conversation_history_updated_at
  BEFORE UPDATE ON conversation_history
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workflow_settings_updated_at
  BEFORE UPDATE ON workflow_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_document_templates_updated_at
  BEFORE UPDATE ON document_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
