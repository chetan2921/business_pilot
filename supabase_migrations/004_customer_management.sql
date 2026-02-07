-- Migration: Customer Management Enhancement
-- Description: Add communication logs, reminders, and customer segmentation

-- ============================================================
-- Update customers table with segmentation fields
-- ============================================================

ALTER TABLE customers ADD COLUMN IF NOT EXISTS segment TEXT DEFAULT 'new';
ALTER TABLE customers ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
ALTER TABLE customers ADD COLUMN IF NOT EXISTS total_spent DECIMAL(12,2) DEFAULT 0;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS last_purchase_date DATE;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS company_name TEXT;

-- Add constraint for segment values
ALTER TABLE customers DROP CONSTRAINT IF EXISTS customers_segment_check;
ALTER TABLE customers ADD CONSTRAINT customers_segment_check 
  CHECK (segment IN ('gold', 'silver', 'bronze', 'new'));

-- ============================================================
-- Communication Logs Table
-- ============================================================

CREATE TABLE IF NOT EXISTS communication_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('call', 'email', 'sms', 'meeting', 'note')),
  subject TEXT,
  content TEXT NOT NULL,
  direction TEXT DEFAULT 'outbound' CHECK (direction IN ('inbound', 'outbound')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for communication_logs
CREATE INDEX IF NOT EXISTS idx_communication_logs_customer_id ON communication_logs(customer_id);
CREATE INDEX IF NOT EXISTS idx_communication_logs_user_id ON communication_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_communication_logs_created_at ON communication_logs(created_at DESC);

-- RLS policies for communication_logs
ALTER TABLE communication_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own communication logs" ON communication_logs;
CREATE POLICY "Users can view own communication logs" ON communication_logs
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own communication logs" ON communication_logs;
CREATE POLICY "Users can insert own communication logs" ON communication_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own communication logs" ON communication_logs;
CREATE POLICY "Users can update own communication logs" ON communication_logs
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own communication logs" ON communication_logs;
CREATE POLICY "Users can delete own communication logs" ON communication_logs
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- Customer Reminders Table
-- ============================================================

CREATE TABLE IF NOT EXISTS customer_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  reminder_date TIMESTAMPTZ NOT NULL,
  reminder_type TEXT NOT NULL DEFAULT 'follow_up' 
    CHECK (reminder_type IN ('follow_up', 'payment', 'birthday', 'anniversary', 'custom')),
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for customer_reminders
CREATE INDEX IF NOT EXISTS idx_customer_reminders_customer_id ON customer_reminders(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_reminders_user_id ON customer_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_customer_reminders_date ON customer_reminders(reminder_date);
CREATE INDEX IF NOT EXISTS idx_customer_reminders_pending ON customer_reminders(reminder_date) 
  WHERE is_completed = FALSE;

-- RLS policies for customer_reminders
ALTER TABLE customer_reminders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own reminders" ON customer_reminders;
CREATE POLICY "Users can view own reminders" ON customer_reminders
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own reminders" ON customer_reminders;
CREATE POLICY "Users can insert own reminders" ON customer_reminders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own reminders" ON customer_reminders;
CREATE POLICY "Users can update own reminders" ON customer_reminders
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own reminders" ON customer_reminders;
CREATE POLICY "Users can delete own reminders" ON customer_reminders
  FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- Trigger to update customer total_spent from invoices
-- ============================================================

CREATE OR REPLACE FUNCTION update_customer_total_spent()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE customers
  SET 
    total_spent = (
      SELECT COALESCE(SUM(total), 0)
      FROM invoices
      WHERE customer_id = COALESCE(NEW.customer_id, OLD.customer_id)
        AND status = 'paid'
    ),
    last_purchase_date = (
      SELECT MAX(issue_date)
      FROM invoices
      WHERE customer_id = COALESCE(NEW.customer_id, OLD.customer_id)
        AND status = 'paid'
    )
  WHERE id = COALESCE(NEW.customer_id, OLD.customer_id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_customer_total_spent ON invoices;
CREATE TRIGGER trigger_update_customer_total_spent
  AFTER INSERT OR UPDATE OR DELETE ON invoices
  FOR EACH ROW
  EXECUTE FUNCTION update_customer_total_spent();
