-- Migration: Create CHIP Payment Tables and Update Existing Tables
-- Description: Add support for CHIP payment gateway with escrow functionality
-- Date: 2025-01-10

-- ============================================================================
-- 1. Create taskaway_chip_payments table
-- ============================================================================
CREATE TABLE IF NOT EXISTS taskaway_chip_payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Task and user references
  task_id UUID REFERENCES taskaway_tasks(id) ON DELETE CASCADE NOT NULL,
  poster_id UUID REFERENCES auth.users(id) ON DELETE RESTRICT NOT NULL,
  tasker_id UUID REFERENCES auth.users(id) ON DELETE RESTRICT,

  -- Payment amounts (in MYR)
  total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
  platform_fee DECIMAL(10,2) NOT NULL CHECK (platform_fee >= 0),
  tasker_amount DECIMAL(10,2) NOT NULL CHECK (tasker_amount >= 0),

  -- CHIP payment details
  chip_purchase_id VARCHAR(255) UNIQUE,
  chip_checkout_url TEXT,
  chip_checkout_id VARCHAR(255),
  payment_status VARCHAR(50) DEFAULT 'pending' CHECK (payment_status IN (
    'pending',
    'processing',
    'paid',
    'failed',
    'cancelled',
    'refunded'
  )),
  payment_method VARCHAR(50), -- 'fpx', 'card', 'grabpay', etc.
  paid_at TIMESTAMP WITH TIME ZONE,

  -- CHIP payout details (for escrow release)
  chip_payout_id VARCHAR(255),
  chip_budget_allocation_id VARCHAR(255),
  payout_status VARCHAR(50) DEFAULT 'pending' CHECK (payout_status IN (
    'pending',
    'processing',
    'completed',
    'failed',
    'cancelled'
  )),
  payout_requested_at TIMESTAMP WITH TIME ZONE,
  payout_completed_at TIMESTAMP WITH TIME ZONE,

  -- Settlement tracking
  settlement_status VARCHAR(50) DEFAULT 'held' CHECK (settlement_status IN (
    'held',
    'partially_settled',
    'fully_settled',
    'failed'
  )),
  platform_fee_settled BOOLEAN DEFAULT false,
  platform_fee_settled_at TIMESTAMP WITH TIME ZONE,
  settlement_date DATE,

  -- Metadata
  metadata JSONB DEFAULT '{}',
  error_message TEXT,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Constraints
  CONSTRAINT valid_amounts CHECK (total_amount = platform_fee + tasker_amount),
  CONSTRAINT valid_payout_timing CHECK (
    payout_requested_at IS NULL OR
    payout_requested_at >= paid_at
  ),
  CONSTRAINT valid_settlement CHECK (
    platform_fee_settled = false OR
    platform_fee_settled_at IS NOT NULL
  )
);

-- Indexes for performance
CREATE INDEX idx_chip_payments_task_id ON taskaway_chip_payments(task_id);
CREATE INDEX idx_chip_payments_poster_id ON taskaway_chip_payments(poster_id);
CREATE INDEX idx_chip_payments_tasker_id ON taskaway_chip_payments(tasker_id);
CREATE INDEX idx_chip_payments_payment_status ON taskaway_chip_payments(payment_status);
CREATE INDEX idx_chip_payments_payout_status ON taskaway_chip_payments(payout_status);
CREATE INDEX idx_chip_payments_settlement_status ON taskaway_chip_payments(settlement_status);
CREATE INDEX idx_chip_payments_chip_purchase_id ON taskaway_chip_payments(chip_purchase_id);
CREATE INDEX idx_chip_payments_created_at ON taskaway_chip_payments(created_at DESC);

-- Updated_at trigger
CREATE TRIGGER update_chip_payments_updated_at
  BEFORE UPDATE ON taskaway_chip_payments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 2. Create taskaway_platform_finances table
-- ============================================================================
CREATE TABLE IF NOT EXISTS taskaway_platform_finances (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Transaction details
  transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN (
    'platform_fee',
    'escrow_hold',
    'escrow_release',
    'refund',
    'chargeback'
  )),

  -- Reference IDs
  chip_payment_id UUID REFERENCES taskaway_chip_payments(id) ON DELETE RESTRICT,
  task_id UUID REFERENCES taskaway_tasks(id) ON DELETE RESTRICT NOT NULL,

  -- Amount tracking
  amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
  currency VARCHAR(3) DEFAULT 'MYR',

  -- Settlement details
  settled BOOLEAN DEFAULT false,
  settled_at TIMESTAMP WITH TIME ZONE,
  settlement_reference VARCHAR(255),

  -- Metadata
  description TEXT,
  metadata JSONB DEFAULT '{}',

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_platform_finances_transaction_type ON taskaway_platform_finances(transaction_type);
CREATE INDEX idx_platform_finances_chip_payment_id ON taskaway_platform_finances(chip_payment_id);
CREATE INDEX idx_platform_finances_task_id ON taskaway_platform_finances(task_id);
CREATE INDEX idx_platform_finances_settled ON taskaway_platform_finances(settled);
CREATE INDEX idx_platform_finances_created_at ON taskaway_platform_finances(created_at DESC);

-- Updated_at trigger
CREATE TRIGGER update_platform_finances_updated_at
  BEFORE UPDATE ON taskaway_platform_finances
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 3. Update taskaway_profiles table - Add bank account fields
-- ============================================================================
ALTER TABLE taskaway_profiles
  ADD COLUMN IF NOT EXISTS bank_name VARCHAR(255),
  ADD COLUMN IF NOT EXISTS bank_account_number VARCHAR(50),
  ADD COLUMN IF NOT EXISTS bank_account_holder_name VARCHAR(255),
  ADD COLUMN IF NOT EXISTS bank_verification_status VARCHAR(50) DEFAULT 'unverified'
    CHECK (bank_verification_status IN ('unverified', 'pending', 'verified', 'rejected')),
  ADD COLUMN IF NOT EXISTS bank_verified_at TIMESTAMP WITH TIME ZONE;

-- Index for bank verification lookups
CREATE INDEX IF NOT EXISTS idx_profiles_bank_verification_status
  ON taskaway_profiles(bank_verification_status);

-- ============================================================================
-- 4. Update taskaway_tasks table - Add payment and escrow fields
-- ============================================================================
ALTER TABLE taskaway_tasks
  ADD COLUMN IF NOT EXISTS chip_payment_id UUID REFERENCES taskaway_chip_payments(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS escrow_status VARCHAR(50) DEFAULT 'none'
    CHECK (escrow_status IN ('none', 'held', 'releasing', 'released', 'refunded')),
  ADD COLUMN IF NOT EXISTS escrow_held_at TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS escrow_released_at TIMESTAMP WITH TIME ZONE;

-- Index for escrow status lookups
CREATE INDEX IF NOT EXISTS idx_tasks_escrow_status ON taskaway_tasks(escrow_status);
CREATE INDEX IF NOT EXISTS idx_tasks_chip_payment_id ON taskaway_tasks(chip_payment_id);

-- ============================================================================
-- 5. Row Level Security (RLS) Policies
-- ============================================================================

-- Enable RLS on new tables
ALTER TABLE taskaway_chip_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE taskaway_platform_finances ENABLE ROW LEVEL SECURITY;

-- Policies for taskaway_chip_payments
-- Users can view their own payment records (as poster or tasker)
CREATE POLICY "Users can view their own chip payments"
  ON taskaway_chip_payments
  FOR SELECT
  USING (
    auth.uid() = poster_id OR
    auth.uid() = tasker_id
  );

-- Only authenticated users can insert (system will validate)
CREATE POLICY "Authenticated users can create chip payments"
  ON taskaway_chip_payments
  FOR INSERT
  WITH CHECK (auth.uid() = poster_id);

-- Only system/service role can update payment records
CREATE POLICY "Service role can update chip payments"
  ON taskaway_chip_payments
  FOR UPDATE
  USING (auth.role() = 'service_role');

-- Policies for taskaway_platform_finances
-- Only service role can access platform finances
CREATE POLICY "Service role can manage platform finances"
  ON taskaway_platform_finances
  FOR ALL
  USING (auth.role() = 'service_role');

-- Admin users can view platform finances (add admin check as needed)
CREATE POLICY "Admins can view platform finances"
  ON taskaway_platform_finances
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM taskaway_profiles
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );

-- ============================================================================
-- 6. Helper Functions
-- ============================================================================

-- Function to calculate platform fee (10%)
CREATE OR REPLACE FUNCTION calculate_platform_fee(total_amount DECIMAL)
RETURNS DECIMAL AS $$
BEGIN
  RETURN ROUND(total_amount * 0.10, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to calculate tasker amount (90%)
CREATE OR REPLACE FUNCTION calculate_tasker_amount(total_amount DECIMAL)
RETURNS DECIMAL AS $$
BEGIN
  RETURN total_amount - calculate_platform_fee(total_amount);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to check if tasker has verified bank account
CREATE OR REPLACE FUNCTION has_verified_bank_account(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM taskaway_profiles
    WHERE user_id = user_uuid
    AND bank_verification_status = 'verified'
    AND bank_account_number IS NOT NULL
  );
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- 7. Comments for documentation
-- ============================================================================

COMMENT ON TABLE taskaway_chip_payments IS 'Tracks all CHIP payment gateway transactions with escrow functionality';
COMMENT ON TABLE taskaway_platform_finances IS 'Platform financial tracking for fees, escrow, and settlements';

COMMENT ON COLUMN taskaway_chip_payments.chip_purchase_id IS 'CHIP Collect purchase ID from payment creation';
COMMENT ON COLUMN taskaway_chip_payments.chip_budget_allocation_id IS 'CHIP budget ID for held escrow funds';
COMMENT ON COLUMN taskaway_chip_payments.chip_payout_id IS 'CHIP Send payout ID when releasing to tasker';
COMMENT ON COLUMN taskaway_chip_payments.settlement_status IS 'Tracks whether funds have been settled from CHIP';

COMMENT ON COLUMN taskaway_tasks.chip_payment_id IS 'Reference to CHIP payment record for this task';
COMMENT ON COLUMN taskaway_tasks.escrow_status IS 'Current status of escrowed payment for this task';

COMMENT ON FUNCTION calculate_platform_fee IS 'Calculates 10% platform fee from total amount';
COMMENT ON FUNCTION calculate_tasker_amount IS 'Calculates 90% tasker amount from total amount';
COMMENT ON FUNCTION has_verified_bank_account IS 'Checks if user has verified bank account for payouts';
