// Payment Return Handler Edge Function
// Purpose: Handle HTTPS redirects from CHIP and redirect to app deep link
// Endpoint: /payment-return-handler

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  try {
    // Parse URL parameters
    const url = new URL(req.url)
    const taskId = url.searchParams.get('task_id')
    const source = url.searchParams.get('source')
    const status = url.searchParams.get('status')

    console.log(`[Payment Return] Redirecting: task=${taskId}, source=${source}, status=${status}`)

    // Build deep link URL for the app
    const deepLink = `taskaway://payment-return?task_id=${taskId}&source=${source}&status=${status}`

    // Try direct redirect first (works better on iOS)
    // If it fails, show HTML fallback
    return new Response(null, {
      status: 302,
      headers: {
        'Location': deepLink,
      },
    })

    // Fallback HTML (not reached, kept for reference)
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Redirecting to Taskaway...</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
          }
          .container {
            text-align: center;
            padding: 2rem;
          }
          .spinner {
            border: 4px solid rgba(255, 255, 255, 0.3);
            border-top: 4px solid white;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 2rem auto;
          }
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
          .message {
            font-size: 1.2rem;
            margin-bottom: 1rem;
          }
          .sub-message {
            font-size: 0.9rem;
            opacity: 0.8;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="spinner"></div>
          <div class="message">Returning to Taskaway...</div>
          <div class="sub-message">Please wait while we redirect you</div>
        </div>
        <script>
          // Attempt to open deep link
          window.location.href = '${deepLink}';

          // Fallback: If deep link doesn't work after 2 seconds, show manual link
          setTimeout(function() {
            document.querySelector('.sub-message').innerHTML =
              'If the app doesn\\'t open automatically, <a href="${deepLink}" style="color: white; text-decoration: underline;">click here</a>';
          }, 2000);
        </script>
      </body>
      </html>
    `

    return new Response(html, {
      status: 200,
      headers: {
        'Content-Type': 'text/html; charset=utf-8',
      },
    })
  } catch (error) {
    console.error('[Payment Return] Error:', error)

    return new Response(
      `<!DOCTYPE html>
      <html>
      <head><title>Error</title></head>
      <body>
        <h1>Payment Return Error</h1>
        <p>An error occurred while processing your payment return. Please open the Taskaway app manually.</p>
      </body>
      </html>`,
      {
        status: 500,
        headers: {
          'Content-Type': 'text/html; charset=utf-8',
        },
      }
    )
  }
})
