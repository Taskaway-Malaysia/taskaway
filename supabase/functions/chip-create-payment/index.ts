// CHIP Create Payment Edge Function
// Purpose: Create CHIP payment with split payment (platform fee + escrow)
// Endpoint: /chip-create-payment

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const CHIP_API_URL = 'https://gate.chip-in.asia/api/v1'
const CHIP_BRAND_ID = Deno.env.get('CHIP_BRAND_ID') || ''
const CHIP_SECRET_KEY = Deno.env.get('CHIP_SECRET_KEY') || ''
const PLATFORM_FEE_RATE = 0.10 // 10% platform fee

interface CreatePaymentRequest {
  taskId: string
  amount: number
  posterId: string
  posterEmail: string
  taskTitle: string
  posterName?: string
}

interface ChipPurchaseResponse {
  id: string
  status: string
  checkout_url: string
  payment_method?: string
  budget_allocation_id?: string
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
    const body: CreatePaymentRequest = await req.json()
    const { taskId, amount, posterId, posterEmail, taskTitle, posterName } = body

    // Validate required fields
    if (!taskId || !amount || !posterId || !posterEmail || !taskTitle) {
      throw new Error('Missing required fields: taskId, amount, posterId, posterEmail, taskTitle')
    }

    // Validate amount
    if (amount <= 0) {
      throw new Error('Amount must be greater than 0')
    }

    console.log(`[CHIP] Creating payment for task ${taskId}, amount: RM${amount}`)

    // Calculate platform fee and tasker amount
    const platformFee = Math.round(amount * PLATFORM_FEE_RATE * 100) / 100
    const taskerAmount = amount - platformFee

    console.log(`[CHIP] Platform fee: RM${platformFee}, Tasker amount: RM${taskerAmount}`)

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Verify task exists and is in correct status
    const { data: task, error: taskError } = await supabase
      .from('taskaway_tasks')
      .select('id, status, poster_id, tasker_id')
      .eq('id', taskId)
      .single()

    if (taskError || !task) {
      throw new Error(`Task not found: ${taskId}`)
    }

    if (task.poster_id !== posterId) {
      throw new Error('Unauthorized: You are not the poster of this task')
    }

    if (task.status !== 'open' && task.status !== 'pending') {
      throw new Error(`Cannot create payment for task in status: ${task.status}`)
    }

    // Get tasker details if task is assigned
    let taskerBankDetails = null
    if (task.tasker_id) {
      const { data: profile } = await supabase
        .from('taskaway_profiles')
        .select('bank_name, bank_account_number, bank_account_holder_name, bank_verification_status')
        .eq('id', task.tasker_id)
        .single()

      if (profile && profile.bank_verification_status === 'verified') {
        taskerBankDetails = profile
      }
    }

    // Prepare CHIP purchase payload with split payment
    const chipPayload = {
      brand_id: CHIP_BRAND_ID,
      client: {
        email: posterEmail,
        full_name: posterName || posterEmail,
      },
      purchase: {
        total: Math.round(amount * 100), // Convert to cents
        currency: 'MYR',
        products: [
          {
            name: taskTitle,
            price: Math.round(amount * 100),
            quantity: 1,
          },
        ],
        notes: `Task ID: ${taskId}`,
        platform: 'taskaway',
        send_receipt: true,
        skip_capture: false, // We want immediate settlement for FPX
        due_strict: false,
      },
      // Split payment configuration
      split: {
        // Platform fee settles to business bank account
        settle: [
          {
            amount: Math.round(platformFee * 100),
            description: 'Platform Fee',
          },
        ],
        // Tasker amount held in CHIP budget for escrow
        modules: [
          {
            amount: Math.round(taskerAmount * 100),
            description: `Escrow for Tasker - Task ${taskId}`,
            budget_type: 'internal', // Use CHIP's internal budget
          },
        ],
      },
      success_callback: `${supabaseUrl}/functions/v1/chip-webhook`,
      success_redirect: `${supabaseUrl}/functions/v1/payment-return-handler?task_id=${taskId}&source=chip&status=success`,
      failure_redirect: `${supabaseUrl}/functions/v1/payment-return-handler?task_id=${taskId}&source=chip&status=failed`,
      cancel_redirect: `${supabaseUrl}/functions/v1/payment-return-handler?task_id=${taskId}&source=chip&status=cancelled`,
      webhook_url: `${supabaseUrl}/functions/v1/chip-webhook`,
    }

    console.log('[CHIP] Creating purchase with split payment:', JSON.stringify(chipPayload, null, 2))

    // Call CHIP API to create purchase
    const chipResponse = await fetch(`${CHIP_API_URL}/purchases/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${CHIP_SECRET_KEY}`,
      },
      body: JSON.stringify(chipPayload),
    })

    if (!chipResponse.ok) {
      const errorText = await chipResponse.text()
      console.error('[CHIP] API Error Response:', errorText)
      console.error('[CHIP] API Status:', chipResponse.status)
      throw new Error(`CHIP API error: ${chipResponse.status} - ${errorText}`)
    }

    const chipData: ChipPurchaseResponse = await chipResponse.json()
    console.log('[CHIP] Purchase created successfully')
    console.log('[CHIP] Purchase ID:', chipData.id)
    console.log('[CHIP] Checkout URL:', chipData.checkout_url)

    // Insert payment record into database
    const { data: payment, error: paymentError } = await supabase
      .from('taskaway_chip_payments')
      .insert({
        task_id: taskId,
        poster_id: posterId,
        tasker_id: task.tasker_id,
        total_amount: amount,
        platform_fee: platformFee,
        tasker_amount: taskerAmount,
        chip_purchase_id: chipData.id,
        chip_checkout_url: chipData.checkout_url,
        payment_status: 'pending',
        settlement_status: 'held',
        metadata: {
          task_title: taskTitle,
          poster_email: posterEmail,
          chip_response: chipData,
        },
      })
      .select()
      .single()

    if (paymentError) {
      console.error('[CHIP] Database error:', paymentError)
      throw new Error(`Failed to create payment record: ${paymentError.message}`)
    }

    console.log('[CHIP] Payment record created:', payment.id)

    // Create platform finance record for platform fee
    await supabase
      .from('taskaway_platform_finances')
      .insert({
        transaction_type: 'platform_fee',
        chip_payment_id: payment.id,
        task_id: taskId,
        amount: platformFee,
        currency: 'MYR',
        description: `Platform fee for task ${taskId}`,
        metadata: {
          chip_purchase_id: chipData.id,
          task_title: taskTitle,
        },
      })

    // Create platform finance record for escrow hold
    await supabase
      .from('taskaway_platform_finances')
      .insert({
        transaction_type: 'escrow_hold',
        chip_payment_id: payment.id,
        task_id: taskId,
        amount: taskerAmount,
        currency: 'MYR',
        description: `Escrow hold for task ${taskId}`,
        metadata: {
          chip_purchase_id: chipData.id,
          task_title: taskTitle,
          tasker_id: task.tasker_id,
        },
      })

    console.log('[CHIP] Platform finance records created')

    // Return checkout URL and payment details
    return new Response(
      JSON.stringify({
        success: true,
        payment_id: payment.id,
        checkout_url: chipData.checkout_url,
        chip_purchase_id: chipData.id,
        amount: amount,
        platform_fee: platformFee,
        tasker_amount: taskerAmount,
        message: 'Payment created successfully. Redirect user to checkout URL.',
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )
  } catch (error) {
    console.error('[CHIP] Error:', error)
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
