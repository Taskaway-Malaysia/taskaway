// CHIP Webhook Handler Edge Function
// Purpose: Handle payment status webhooks from CHIP
// Endpoint: /chip-webhook

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'
import { createHmac } from 'https://deno.land/std@0.168.0/node/crypto.ts'

const CHIP_API_URL = 'https://gate.chip-in.asia/api/v1'
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

    // Verify webhook signature if secret is configured AND signature is provided
    if (CHIP_WEBHOOK_SECRET) {
      const signature = req.headers.get('x-chip-signature') || ''
      if (signature) {
        // Only verify if signature is provided
        if (!verifyWebhookSignature(rawBody, signature, CHIP_WEBHOOK_SECRET)) {
          console.error('[CHIP Webhook] Invalid signature')
          throw new Error('Invalid webhook signature')
        }
        console.log('[CHIP Webhook] Signature verified')
      } else {
        console.log('[CHIP Webhook] No signature provided, skipping verification')
      }
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
      .select('*')
      .eq('chip_purchase_id', purchaseId)
      .single()

    if (paymentError || !payment) {
      console.error('[CHIP Webhook] Payment not found:', purchaseId)
      throw new Error(`Payment record not found for purchase ${purchaseId}`)
    }

    console.log(`[CHIP Webhook] Found payment record: ${payment.id}`)

    // NOTE: Using immediate settlement approach (no CHIP budgets)
    // Both platform fee and tasker amount settle directly to business account
    // No budget allocation ID needed for manual payout workflow
    console.log('[CHIP Webhook] Using immediate settlement - no budget extraction needed')

    // Update payment record based on status
    // Map CHIP status to our payment_status constraint values
    let mappedStatus: string
    if (status === 'paid') {
      mappedStatus = 'paid'
    } else if (status === 'cancelled') {
      mappedStatus = 'cancelled'
    } else if (status === 'failed') {
      mappedStatus = 'failed'
    } else {
      // For any other status (created, processing, etc.), map to 'processing'
      mappedStatus = 'processing'
    }

    const updateData: Record<string, any> = {
      payment_status: mappedStatus,
      payment_method: payment_method,
      updated_at: new Date().toISOString(),
    }

    if (status === 'paid') {
      updateData.paid_at = paid_at || new Date().toISOString()

      // Using immediate settlement - both platform fee and tasker amount settle to business account
      // Mark both as settled since funds are immediately available
      updateData.platform_fee_settled = true
      updateData.platform_fee_settled_at = new Date().toISOString()
      updateData.settlement_status = 'fully_settled' // All funds settled to platform account

      console.log('[CHIP Webhook] Payment successful, all funds settled to platform account')
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

    // Update task payment status if payment successful
    if (status === 'paid') {
      const { error: taskUpdateError } = await supabase
        .from('taskaway_tasks')
        .update({
          chip_payment_id: payment.id,
          escrow_status: 'held', // Funds held by platform until task completion
          escrow_held_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq('id', payment.task_id)

      if (taskUpdateError) {
        console.error('[CHIP Webhook] Task update error:', taskUpdateError)
        // Don't throw - payment update succeeded, this is secondary
      } else {
        console.log('[CHIP Webhook] Task payment status updated')
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
