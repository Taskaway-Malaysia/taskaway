// CHIP Payout Webhook Handler Edge Function
// Purpose: Handle payout completion webhooks from CHIP Send
// Endpoint: /chip-payout-webhook

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'
import { createHmac } from 'https://deno.land/std@0.168.0/node/crypto.ts'

const CHIP_WEBHOOK_SECRET = Deno.env.get('CHIP_WEBHOOK_SECRET') || ''

interface ChipPayoutWebhookPayload {
  id: string // payout_id
  status: string // 'completed', 'failed', 'cancelled'
  recipient: {
    bank_account_no: string
    bank_name: string
    account_holder_name?: string
  }
  amount: number
  currency: string
  reference?: string
  completed_at?: string
  failed_reason?: string
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
    console.error('[CHIP Payout Webhook] Signature verification error:', error)
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
    console.log('[CHIP Payout Webhook] Received webhook:', rawBody)

    // Verify webhook signature if secret is configured
    if (CHIP_WEBHOOK_SECRET) {
      const signature = req.headers.get('x-chip-signature') || ''
      if (!signature) {
        console.error('[CHIP Payout Webhook] Missing signature header')
        throw new Error('Missing webhook signature')
      }

      if (!verifyWebhookSignature(rawBody, signature, CHIP_WEBHOOK_SECRET)) {
        console.error('[CHIP Payout Webhook] Invalid signature')
        throw new Error('Invalid webhook signature')
      }
      console.log('[CHIP Payout Webhook] Signature verified')
    }

    // Parse webhook payload
    const webhookData: ChipPayoutWebhookPayload = JSON.parse(rawBody)
    const { id: payoutId, status, completed_at, failed_reason } = webhookData

    console.log(`[CHIP Payout Webhook] Payout ${payoutId} status: ${status}`)

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Find payment record by CHIP payout ID
    const { data: payment, error: paymentError } = await supabase
      .from('taskaway_chip_payments')
      .select('*, taskaway_tasks!inner(*)')
      .eq('chip_payout_id', payoutId)
      .single()

    if (paymentError || !payment) {
      console.error('[CHIP Payout Webhook] Payment not found for payout:', payoutId)
      throw new Error(`Payment record not found for payout ${payoutId}`)
    }

    console.log(`[CHIP Payout Webhook] Found payment record: ${payment.id}`)

    // Update payment record based on payout status
    const updateData: Record<string, any> = {
      payout_status: status,
      updated_at: new Date().toISOString(),
    }

    if (status === 'completed') {
      updateData.payout_completed_at = completed_at || new Date().toISOString()
      updateData.settlement_status = 'fully_settled' // Both platform fee and payout completed

      console.log('[CHIP Payout Webhook] Payout completed successfully')
    } else if (status === 'failed' || status === 'cancelled') {
      updateData.error_message = failed_reason || `Payout ${status}`
      updateData.settlement_status = 'failed'

      console.log(`[CHIP Payout Webhook] Payout ${status}: ${failed_reason || 'No reason provided'}`)
    }

    // Update payment record
    const { error: updateError } = await supabase
      .from('taskaway_chip_payments')
      .update(updateData)
      .eq('id', payment.id)

    if (updateError) {
      console.error('[CHIP Payout Webhook] Update error:', updateError)
      throw new Error(`Failed to update payment: ${updateError.message}`)
    }

    // Update task escrow status
    if (status === 'completed') {
      const { error: taskUpdateError } = await supabase
        .from('taskaway_tasks')
        .update({
          escrow_status: 'released',
          escrow_released_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq('id', payment.task_id)

      if (taskUpdateError) {
        console.error('[CHIP Payout Webhook] Task update error:', taskUpdateError)
        // Don't throw - payment update succeeded
      } else {
        console.log('[CHIP Payout Webhook] Task escrow status updated to released')
      }

      // Update platform finance record
      await supabase
        .from('taskaway_platform_finances')
        .update({
          settled: true,
          settled_at: new Date().toISOString(),
          settlement_reference: payoutId,
        })
        .eq('chip_payment_id', payment.id)
        .eq('transaction_type', 'escrow_release')

      console.log('[CHIP Payout Webhook] Platform finance record updated')
    } else if (status === 'failed' || status === 'cancelled') {
      // Revert task escrow status back to held if payout failed
      // This allows retry of payout
      const { error: taskUpdateError } = await supabase
        .from('taskaway_tasks')
        .update({
          escrow_status: 'held',
          updated_at: new Date().toISOString(),
        })
        .eq('id', payment.task_id)

      if (taskUpdateError) {
        console.error('[CHIP Payout Webhook] Task revert error:', taskUpdateError)
      } else {
        console.log('[CHIP Payout Webhook] Task escrow status reverted to held for retry')
      }

      // Create a finance record for the failed payout
      await supabase
        .from('taskaway_platform_finances')
        .insert({
          transaction_type: 'escrow_release',
          chip_payment_id: payment.id,
          task_id: payment.task_id,
          amount: payment.tasker_amount,
          currency: 'MYR',
          settled: false,
          description: `Failed payout for task ${payment.task_id}: ${failed_reason || status}`,
          metadata: {
            chip_payout_id: payoutId,
            failed_reason: failed_reason,
            original_payout_requested_at: payment.payout_requested_at,
          },
        })

      console.log('[CHIP Payout Webhook] Failed payout recorded in platform finances')
    }

    console.log('[CHIP Payout Webhook] Webhook processed successfully')

    // Return success response to CHIP
    return new Response(
      JSON.stringify({
        success: true,
        message: 'Payout webhook processed',
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
    console.error('[CHIP Payout Webhook] Error:', error)

    // Return 200 to CHIP to prevent retries for invalid webhooks
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Internal server error',
      }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
        },
      }
    )
  }
})
