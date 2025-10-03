// CHIP Webhook Handler Edge Function
// Purpose: Handle payment status webhooks from CHIP
// Endpoint: /chip-webhook

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'
import { createHmac } from 'https://deno.land/std@0.168.0/node/crypto.ts'

const CHIP_SECRET_KEY = Deno.env.get('CHIP_SECRET_KEY') || ''
const CHIP_WEBHOOK_SECRET = Deno.env.get('CHIP_WEBHOOK_SECRET') || ''

interface ChipWebhookPayload {
  id: string // purchase_id
  status: string // 'paid', 'cancelled', 'failed'
  payment_method?: string
  paid_at?: string
  budget_allocation_id?: string
  split?: {
    modules?: Array<{
      budget_allocation_id?: string
      amount: number
      description: string
    }>
  }
  client?: {
    email: string
    full_name?: string
  }
  purchase?: {
    total: number
    currency: string
    notes?: string
  }
}

// Verify CHIP webhook signature
function verifyWebhookSignature(
  payload: string,
  signature: string,
  secret: string
): boolean {
  try {
    const hmac = createHmac('sha256', secret)
    hmac.update(payload)
    const computedSignature = hmac.digest('hex')
    return computedSignature === signature
  } catch (error) {
    console.error('[CHIP Webhook] Signature verification error:', error)
    return false
  }
}

serve(async (req) => {
  // CORS handling
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-chip-signature',
      },
    })
  }

  try {
    // Verify request method
    if (req.method !== 'POST') {
      throw new Error('Method not allowed')
    }

    // Get request body as text for signature verification
    const rawBody = await req.text()
    console.log('[CHIP Webhook] Received webhook:', rawBody)

    // Verify webhook signature if secret is configured
    if (CHIP_WEBHOOK_SECRET) {
      const signature = req.headers.get('x-chip-signature') || ''
      if (!signature) {
        console.error('[CHIP Webhook] Missing signature header')
        throw new Error('Missing webhook signature')
      }

      if (!verifyWebhookSignature(rawBody, signature, CHIP_WEBHOOK_SECRET)) {
        console.error('[CHIP Webhook] Invalid signature')
        throw new Error('Invalid webhook signature')
      }
      console.log('[CHIP Webhook] Signature verified')
    }

    // Parse webhook payload
    const webhookData: ChipWebhookPayload = JSON.parse(rawBody)
    const { id: purchaseId, status, payment_method, paid_at, split } = webhookData

    console.log(`[CHIP Webhook] Purchase ${purchaseId} status: ${status}`)

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Find payment record by CHIP purchase ID
    const { data: payment, error: paymentError } = await supabase
      .from('taskaway_chip_payments')
      .select('*, taskaway_tasks!inner(*)')
      .eq('chip_purchase_id', purchaseId)
      .single()

    if (paymentError || !payment) {
      console.error('[CHIP Webhook] Payment not found:', purchaseId)
      throw new Error(`Payment record not found for purchase ${purchaseId}`)
    }

    console.log(`[CHIP Webhook] Found payment record: ${payment.id}`)

    // Extract budget allocation ID from split payment if available
    let budgetAllocationId = null
    if (split?.modules && split.modules.length > 0) {
      // Find the escrow module (should be the first/only module)
      const escrowModule = split.modules.find((m) =>
        m.description.includes('Escrow')
      )
      if (escrowModule?.budget_allocation_id) {
        budgetAllocationId = escrowModule.budget_allocation_id
        console.log(`[CHIP Webhook] Budget allocation ID: ${budgetAllocationId}`)
      }
    }

    // Update payment record based on status
    const updateData: Record<string, any> = {
      payment_status: status === 'paid' ? 'paid' : status,
      payment_method: payment_method,
      updated_at: new Date().toISOString(),
    }

    if (status === 'paid') {
      updateData.paid_at = paid_at || new Date().toISOString()

      // Store budget allocation ID for later payout
      if (budgetAllocationId) {
        updateData.chip_budget_allocation_id = budgetAllocationId
      }

      // Platform fee settlement happens automatically via split payment
      // Mark platform fee as settled
      updateData.platform_fee_settled = true
      updateData.platform_fee_settled_at = new Date().toISOString()
      updateData.settlement_status = 'partially_settled' // Platform fee settled, tasker amount held

      console.log('[CHIP Webhook] Payment successful, platform fee settled, escrow held')
    } else if (status === 'cancelled' || status === 'failed') {
      updateData.settlement_status = 'failed'
      updateData.error_message = `Payment ${status}`
      console.log(`[CHIP Webhook] Payment ${status}`)
    }

    // Update payment record
    const { error: updateError } = await supabase
      .from('taskaway_chip_payments')
      .update(updateData)
      .eq('id', payment.id)

    if (updateError) {
      console.error('[CHIP Webhook] Update error:', updateError)
      throw new Error(`Failed to update payment: ${updateError.message}`)
    }

    // Update task escrow status if payment successful
    if (status === 'paid') {
      const { error: taskUpdateError } = await supabase
        .from('taskaway_tasks')
        .update({
          chip_payment_id: payment.id,
          escrow_status: 'held',
          escrow_held_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq('id', payment.task_id)

      if (taskUpdateError) {
        console.error('[CHIP Webhook] Task update error:', taskUpdateError)
        // Don't throw - payment update succeeded, this is secondary
      } else {
        console.log('[CHIP Webhook] Task escrow status updated to held')
      }

      // Update platform finance records
      await supabase
        .from('taskaway_platform_finances')
        .update({
          settled: true,
          settled_at: new Date().toISOString(),
          settlement_reference: purchaseId,
        })
        .eq('chip_payment_id', payment.id)
        .eq('transaction_type', 'platform_fee')

      console.log('[CHIP Webhook] Platform finance records updated')
    } else if (status === 'cancelled' || status === 'failed') {
      // Update task escrow status to none if payment failed
      await supabase
        .from('taskaway_tasks')
        .update({
          escrow_status: 'none',
          updated_at: new Date().toISOString(),
        })
        .eq('id', payment.task_id)

      console.log('[CHIP Webhook] Task escrow status reset due to payment failure')
    }

    console.log('[CHIP Webhook] Webhook processed successfully')

    // Return success response to CHIP
    return new Response(
      JSON.stringify({
        success: true,
        message: 'Webhook processed',
        payment_id: payment.id,
        status: status,
      }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
        },
      }
    )
  } catch (error) {
    console.error('[CHIP Webhook] Error:', error)

    // Still return 200 to CHIP to prevent retries for invalid webhooks
    // But log the error for debugging
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Internal server error',
      }),
      {
        status: 200, // Return 200 to prevent CHIP from retrying
        headers: {
          'Content-Type': 'application/json',
        },
      }
    )
  }
})
