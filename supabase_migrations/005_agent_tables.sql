-- ============================================================
-- PHASE 3: PROACTIVE AGENT SYSTEM
-- Agent recommendations and monitoring tables
-- ============================================================

-- ============================================================
-- AGENT RECOMMENDATIONS
-- Stores AI-generated recommendations for user action
-- ============================================================

CREATE TABLE agent_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  agent_type TEXT NOT NULL CHECK (agent_type IN ('cash_flow', 'revenue', 'inventory', 'customer')),
  priority TEXT NOT NULL CHECK (priority IN ('critical', 'high', 'medium', 'low')),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  suggested_action TEXT,
  action_type TEXT CHECK (action_type IN ('navigate', 'approve', 'dismiss', 'external')),
  action_data JSONB DEFAULT '{}',
  data JSONB DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'dismissed', 'snoozed', 'expired', 'auto_resolved')),
  snoozed_until TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fetching active recommendations
CREATE INDEX idx_recommendations_user_status ON agent_recommendations(user_id, status);
CREATE INDEX idx_recommendations_priority ON agent_recommendations(user_id, priority, created_at DESC);
CREATE INDEX idx_recommendations_agent ON agent_recommendations(user_id, agent_type, created_at DESC);

-- ============================================================
-- AGENT RUN LOGS
-- Tracks when agents run and what they produce
-- ============================================================

CREATE TABLE agent_run_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  agent_type TEXT NOT NULL,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  duration_ms INT,
  recommendations_generated INT DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'success', 'failed', 'timeout')),
  error_message TEXT,
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_agent_runs_user ON agent_run_logs(user_id, agent_type, started_at DESC);

-- ============================================================
-- CASH FLOW PROJECTIONS
-- Stores predicted cash flow for forecasting
-- ============================================================

CREATE TABLE cash_flow_projections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  projection_date DATE NOT NULL,
  projected_inflow DECIMAL(12,2) DEFAULT 0,
  projected_outflow DECIMAL(12,2) DEFAULT 0,
  projected_balance DECIMAL(12,2) DEFAULT 0,
  confidence_score DECIMAL(3,2) DEFAULT 0.8,
  inflow_sources JSONB DEFAULT '[]',
  outflow_sources JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, projection_date)
);

CREATE INDEX idx_projections_user_date ON cash_flow_projections(user_id, projection_date);

-- ============================================================
-- REVENUE OPPORTUNITIES
-- Stores identified upsell and optimization opportunities
-- ============================================================

CREATE TABLE revenue_opportunities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  opportunity_type TEXT NOT NULL CHECK (opportunity_type IN ('upsell', 'cross_sell', 'price_optimization', 'promotion', 'bundle')),
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  estimated_revenue DECIMAL(12,2),
  confidence_score DECIMAL(3,2) DEFAULT 0.7,
  data JSONB DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'actioned', 'dismissed', 'expired')),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  actioned_at TIMESTAMPTZ
);

CREATE INDEX idx_opportunities_user_status ON revenue_opportunities(user_id, status, created_at DESC);
CREATE INDEX idx_opportunities_customer ON revenue_opportunities(customer_id) WHERE customer_id IS NOT NULL;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE agent_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_run_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE cash_flow_projections ENABLE ROW LEVEL SECURITY;
ALTER TABLE revenue_opportunities ENABLE ROW LEVEL SECURITY;

-- Policies for agent_recommendations
CREATE POLICY "Users can view own recommendations"
  ON agent_recommendations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own recommendations"
  ON agent_recommendations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own recommendations"
  ON agent_recommendations FOR UPDATE
  USING (auth.uid() = user_id);

-- Policies for agent_run_logs
CREATE POLICY "Users can view own run logs"
  ON agent_run_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own run logs"
  ON agent_run_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policies for cash_flow_projections
CREATE POLICY "Users can view own projections"
  ON cash_flow_projections FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own projections"
  ON cash_flow_projections FOR ALL
  USING (auth.uid() = user_id);

-- Policies for revenue_opportunities
CREATE POLICY "Users can view own opportunities"
  ON revenue_opportunities FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own opportunities"
  ON revenue_opportunities FOR ALL
  USING (auth.uid() = user_id);

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Function to auto-expire old recommendations
CREATE OR REPLACE FUNCTION expire_old_recommendations()
RETURNS void AS $$
BEGIN
  UPDATE agent_recommendations
  SET status = 'expired', updated_at = NOW()
  WHERE status = 'pending'
    AND expires_at IS NOT NULL
    AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check snoozed recommendations
CREATE OR REPLACE FUNCTION unsnooze_recommendations()
RETURNS void AS $$
BEGIN
  UPDATE agent_recommendations
  SET status = 'pending', snoozed_until = NULL, updated_at = NOW()
  WHERE status = 'snoozed'
    AND snoozed_until IS NOT NULL
    AND snoozed_until < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
