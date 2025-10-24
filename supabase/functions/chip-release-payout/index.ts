// CHIP Release Payout Edge Function
// Purpose: Release escrowed funds to tasker when task is approved
// Endpoint: /chip-release-payout

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const CHIP_API_URL = 'https://gate.chip-in.asia/api/v1'
const CHIP_BRAND_ID = Deno.env.get('CHIP_BRAND_ID') || ''
const CHIP_SECRET_KEY = Deno.env.get('CHIP_SECRET_KEY') || ''

interface ReleasePayoutRequest {
  taskId: string
  approverId: string // poster_id who is approving
}

interface ChipPayoutResponse {
  id: string
  status: string
  recipient: {
    bank_account_no: string
    bank_name: string
  }
  amount: number
  currency: string
}

serve(async (req) => {
  // CORS handling
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    // Verify request method
    if (req.method !== 'POST') {
      throw new Error('Method not allowed')
    }

    // Parse request body
    const body: ReleasePayoutRequest = await req.json()
    const { taskId, approverId } = body

    // Validate required fields
    if (!taskId || !approverId) {
      throw new Error('Missing required fields: taskId, approverId')
    }

    console.log(`[CHIP Payout] Releasing escrow for task ${taskId}`)

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Get task and verify status
    const { data: task, error: taskError } = await supabase
      .from('taskaway_tasks')
      .select('id, status, poster_id, tasker_id, chip_payment_id, escrow_status')
      .eq('id', taskId)
      .single()

    if (taskError || !task) {
      throw new Error(`Task not found: ${taskId}`)
    }

    // Verify approver is the poster
    if (task.poster_id !== approverId) {
      throw new Error('Unauthorized: Only the task poster can approve completion')
    }

    // Verify task is in correct status
    if (task.status !== 'pending_approval') {
      throw new Error(`Cannot release payout for task in status: ${task.status}`)
    }

    // Verify escrow is held
    if (task.escrow_status !== 'held') {
      throw new Error(`Escrow is not held for this task. Current status: ${task.escrow_status}`)
    }

    // Get payment record
    const { data: payment, error: paymentError } = await supabase
      .from('taskaway_chip_payments')
      .select('*')
      .eq('task_id', taskId)
      .single()

    if (paymentError || !payment) {
      throw new Error(`Payment record not found for task: ${taskId}`)
    }

    // Verify payment is paid
    if (payment.payment_status !== 'paid') {
      throw new Error(`Payment is not in paid status: ${payment.payment_status}`)
    }

    // NOTE: Using immediate settlement approach (no CHIP budgets)
    // Funds already settled to business account
    // Manual payout will be processed via CHIP dashboard
    console.log('[CHIP Payout] Using manual payout approach (no budget allocation needed)')

    // Check if payout already requested/completed
    if (payment.payout_status !== 'pending') {
      throw new Error(`Payout already in status: ${payment.payout_status}`)
    }

    // Get tasker bank details
    const { data: taskerProfile, error: profileError } = await supabase
      .from('taskaway_profiles')
      .select('bank_name, bank_account_number, bank_account_holder_name, bank_verification_status')
      .eq('id', task.tasker_id)
      .single()

    if (profileError || !taskerProfile) {
      throw new Error('Tasker profile not found')
    }

    // Verify tasker has verified bank account
    if (taskerProfile.bank_verification_status !== 'verified') {
      throw new Error('Tasker bank account is not verified. Cannot process payout.')
    }

    if (!taskerProfile.bank_account_number || !taskerProfile.bank_name) {
      throw new Error('Tasker bank details are incomplete')
    }

    console.log(`[CHIP Payout] Tasker bank: ${taskerProfile.bank_name} - ${taskerProfile.bank_account_number}`)

    // Manual payout approach - no CHIP Send API call
    // Admin will process payout via CHIP dashboard using tasker's verified bank details
    console.log('[CHIP Payout] Preparing payout instructions for manual processing')

    const payoutInstructions = {
      amount: payment.tasker_amount,
      currency: 'MYR',
      bank_name: taskerProfile.bank_name,
      account_number: taskerProfile.bank_account_number,
      account_holder: taskerProfile.bank_account_holder_name,
      task_id: taskId,
      reference: `TASK-${taskId}`,
      chip_purchase_id: payment.chip_purchase_id,
    }

    console.log('[CHIP Payout] Payout instructions:', JSON.stringify(payoutInstructions, null, 2))

    // Update payment record for manual payout
    const { error: updateError } = await supabase
      .from('taskaway_chip_payments')
      .update({
        payout_status: 'pending',
        payout_requested_at: new Date().toISOString(),
        settlement_status: 'fully_settled', // All funds settled to platform account
        metadata: {
          ...payment.metadata,
          payout_instructions: payoutInstructions,
        },
        updated_at: new Date().toISOString(),
      })
      .eq('id', payment.id)

    if (updateError) {
      console.error('[CHIP Payout] Database update error:', updateError)
      throw new Error(`Failed to update payment record: ${updateError.message}`)
    }

    // Update task status to completed and escrow status
    const { error: taskUpdateError } = await supabase
      .from('taskaway_tasks')
      .update({
        status: 'completed',
        escrow_status: 'released',
        updated_at: new Date().toISOString(),
      })
      .eq('id', taskId)

    if (taskUpdateError) {
      console.error('[CHIP Payout] Task update error:', taskUpdateError)
      // Don't throw - payment record updated successfully
    }

    // Create platform finance record for manual payout request
    await supabase
      .from('taskaway_platform_finances')
      .insert({
        transaction_type: 'escrow_release',
        chip_payment_id: payment.id,
        task_id: taskId,
        amount: payment.tasker_amount,
        currency: 'MYR',
        description: `Manual payout request for task ${taskId}`,
        metadata: {
          tasker_id: task.tasker_id,
          bank_account: taskerProfile.bank_account_number,
          payout_instructions: payoutInstructions,
        },
      })

    console.log('[CHIP Payout] Manual payout request recorded successfully')

    // Return success response with payout instructions
    return new Response(
      JSON.stringify({
        success: true,
        status: 'pending_manual',
        amount: payment.tasker_amount,
        payout_instructions: payoutInstructions,
        message: 'Task approved. Process manual payout via CHIP dashboard using the provided bank details.',
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )
  } catch (error) {
    console.error('[CHIP Payout] Error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Internal server error',
      }),
      {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )
  }
})
