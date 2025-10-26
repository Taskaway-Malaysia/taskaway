# Notify Nearby Taskers Edge Function

This Supabase Edge Function sends push notifications to taskers within a 5km radius when a new task is created.

## Features

- Calculates distance using Haversine formula
- Filters taskers by:
  - Role (must be tasker, not poster)
  - Notifications enabled
  - Available/online status
  - Has FCM token
  - Within 5km radius
- Sends FCM push notifications
- Creates in-app notification records

## Setup

### 1. Set Environment Variables in Supabase

You need to add the following secrets in your Supabase project dashboard (Project Settings → Edge Functions → Manage secrets):

```bash
# Firebase Project ID
# Get this from: Firebase Console → Project Settings → General → Project ID
FIREBASE_PROJECT_ID=your-project-id

# Firebase Service Account JSON (entire JSON as a string)
# Get this from: Firebase Console → Project Settings → Service Accounts → Generate New Private Key
FIREBASE_SERVICE_ACCOUNT={"type":"service_account","project_id":"...","private_key_id":"...","private_key":"...","client_email":"...","client_id":"...","auth_uri":"...","token_uri":"...","auth_provider_x509_cert_url":"...","client_x509_cert_url":"..."}
```

**How to get Firebase Service Account:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click ⚙️ **Project Settings** → **Service Accounts** tab
4. Click **Generate New Private Key** button
5. Download the JSON file
6. Copy the entire contents of the JSON file as a single-line string

### 2. Deploy the Edge Function

```bash
# Deploy from the project root
supabase functions deploy notify-nearby-taskers
```

### 3. Create Database Trigger

You need to create a database trigger that calls this Edge Function when a new task is created.

#### Option A: Create via Supabase Dashboard

1. Go to Supabase Dashboard → Database → Functions
2. Create a new function or use SQL Editor to run the following:

```sql
-- Create a webhook trigger for new tasks
CREATE OR REPLACE FUNCTION notify_nearby_taskers_webhook()
RETURNS TRIGGER AS $$
DECLARE
  function_url TEXT;
BEGIN
  -- Get the Edge Function URL
  function_url := current_setting('app.settings.edge_function_url', TRUE) || '/notify-nearby-taskers';

  -- Call the Edge Function asynchronously using pg_net (Supabase extension)
  PERFORM
    net.http_post(
      url := function_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', TRUE)
      ),
      body := jsonb_build_object('record', row_to_json(NEW))
    );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER on_task_created
  AFTER INSERT ON taskaway_tasks
  FOR EACH ROW
  EXECUTE FUNCTION notify_nearby_taskers_webhook();
```

#### Option B: Use Supabase Webhooks (Recommended for simplicity)

1. Go to Supabase Dashboard → Database → Webhooks
2. Click "Create a new webhook"
3. Configure:
   - **Name**: Notify Nearby Taskers
   - **Table**: taskaway_tasks
   - **Events**: INSERT
   - **Type**: Edge Function
   - **Function**: notify-nearby-taskers
   - **HTTP Headers**: (leave default)

### 4. Test the Function

You can test the function manually:

```bash
# Test locally
supabase functions serve notify-nearby-taskers

# In another terminal, send a test request
curl -i --location --request POST 'http://localhost:54321/functions/v1/notify-nearby-taskers' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"record":{"id":"test-123","title":"Test Task","category":"cleaning","price":50,"latitude":3.1390,"longitude":101.6869,"poster_id":"test-poster-id"}}'
```

## How It Works

1. When a new task is created in `taskaway_tasks`, the trigger fires
2. The Edge Function receives the new task data
3. It queries all taskers who:
   - Have role = 'tasker'
   - Have notifications_enabled = true
   - Have is_available = true
   - Have a valid fcm_token
   - Are not the task poster
4. For each tasker, it calculates the distance from the task
5. Taskers within 5km receive:
   - FCM push notification
   - In-app notification record in `taskaway_notifications` table
6. The function returns a summary of notifications sent

## Monitoring

Check Edge Function logs in Supabase Dashboard → Edge Functions → notify-nearby-taskers → Logs

## Troubleshooting

**No notifications sent:**
- Verify FIREBASE_PROJECT_ID and FIREBASE_SERVICE_ACCOUNT are set correctly
- Check taskers have:
  - Valid FCM tokens
  - is_available = true
  - notifications_enabled = true
  - Valid latitude/longitude coordinates
- Verify the task has valid latitude/longitude coordinates

**FCM errors:**
- Verify your Firebase Service Account JSON is correct and properly formatted
- Ensure the service account has Firebase Cloud Messaging API enabled
- Check that FCM tokens are valid and not expired
- Verify the FIREBASE_PROJECT_ID matches your Firebase project

**Trigger not firing:**
- Check webhook configuration in Supabase Dashboard
- Verify the trigger exists: `SELECT * FROM pg_trigger WHERE tgname = 'on_task_created';`
- Check Edge Function logs for errors

## Configuration

You can modify these constants in `index.ts`:

- `RADIUS_KM`: Default is 5km, adjust as needed
- Notification title and body format
- Additional filters (e.g., category-based notifications)
