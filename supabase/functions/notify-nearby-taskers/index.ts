// Supabase Edge Function to notify nearby taskers about new tasks
// This function is triggered when a new task is created
// It finds taskers within a 5km radius and sends them push notifications

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')!; // Firebase Project ID
const FIREBASE_SERVICE_ACCOUNT = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!; // Firebase Service Account JSON

const RADIUS_KM = 5; // 5 km radius
const EARTH_RADIUS_KM = 6371; // Earth's radius in kilometers

// Haversine formula to calculate distance between two points on Earth
function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = EARTH_RADIUS_KM * c;

  return distance;
}

function toRadians(degrees: number): number {
  return degrees * (Math.PI / 180);
}

// Generate OAuth 2.0 access token from service account
async function getAccessToken(): Promise<string> {
  const serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT);

  // JWT Header
  const header = {
    alg: 'RS256',
    typ: 'JWT',
  };

  // JWT Claims
  const now = Math.floor(Date.now() / 1000);
  const claims = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  };

  // Create JWT
  const encodedHeader = btoa(JSON.stringify(header));
  const encodedClaims = btoa(JSON.stringify(claims));
  const unsignedToken = `${encodedHeader}.${encodedClaims}`;

  // Sign JWT with private key
  const privateKey = serviceAccount.private_key;

  // Convert PEM private key to binary format
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = privateKey
    .replace(pemHeader, '')
    .replace(pemFooter, '')
    .replace(/\s/g, '');

  // Decode base64 to binary
  const binaryDer = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0));

  // Import the key
  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    binaryDer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  );

  // Sign the JWT
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(unsignedToken)
  );

  const jwt = `${unsignedToken}.${btoa(String.fromCharCode(...new Uint8Array(signature)))}`;

  // Exchange JWT for access token
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

// Send FCM notification to a device using FCM HTTP v1 API
async function sendFCMNotification(
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>
) {
  try {
    // Get OAuth access token
    const accessToken = await getAccessToken();

    // FCM v1 API endpoint
    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;

    // FCM v1 message payload
    const message = {
      message: {
        token: fcmToken,
        notification: {
          title,
          body,
        },
        data,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channel_id: 'taskaway_notifications',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      },
    };

    const response = await fetch(fcmUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`,
      },
      body: JSON.stringify(message),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error('FCM Error:', error);
      return false;
    }

    console.log('FCM notification sent successfully to:', fcmToken.substring(0, 20) + '...');
    return true;
  } catch (error) {
    console.error('Error sending FCM notification:', error);
    return false;
  }
}

serve(async (req) => {
  try {
    // Parse the request body
    const { record } = await req.json();

    if (!record) {
      return new Response(
        JSON.stringify({ error: 'Missing task record' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const taskId = record.id;
    const taskTitle = record.title;
    const taskCategory = record.category;
    const taskPrice = record.price;
    const taskLatitude = record.latitude;
    const taskLongitude = record.longitude;
    const posterId = record.poster_id;

    console.log(`Processing new task: ${taskId} - ${taskTitle}`);

    if (!taskLatitude || !taskLongitude) {
      console.log('Task has no location coordinates, skipping notifications');
      return new Response(
        JSON.stringify({ message: 'Task has no location, no notifications sent' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Initialize Supabase client
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Get all active users (not the poster) with notifications enabled
    // Anyone can take on tasks, regardless of role
    const { data: taskers, error: taskersError } = await supabase
      .from('taskaway_profiles')
      .select('id, full_name, fcm_token, latitude, longitude')
      .eq('notifications_enabled', true) // Notifications enabled
      .eq('is_available', true) // Currently available/online
      .not('fcm_token', 'is', null) // Has FCM token
      .neq('id', posterId); // Not the task poster

    if (taskersError) {
      console.error('Error fetching taskers:', taskersError);
      return new Response(
        JSON.stringify({ error: 'Failed to fetch taskers' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    if (!taskers || taskers.length === 0) {
      console.log('No eligible taskers found');
      return new Response(
        JSON.stringify({ message: 'No eligible taskers to notify' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }

    console.log(`Found ${taskers.length} potential taskers`);

    // Filter taskers within radius and send notifications
    const notificationPromises = [];
    const nearbyTaskers = [];

    for (const tasker of taskers) {
      if (!tasker.latitude || !tasker.longitude) {
        continue; // Skip taskers without location
      }

      const distance = calculateDistance(
        taskLatitude,
        taskLongitude,
        tasker.latitude,
        tasker.longitude
      );

      if (distance <= RADIUS_KM) {
        nearbyTaskers.push({
          id: tasker.id,
          name: tasker.full_name,
          distance: Math.round(distance * 10) / 10, // Round to 1 decimal
        });

        // Send FCM notification
        const notificationTitle = 'New Task Nearby! \uD83D\uDCCD';
        const notificationBody = `${taskTitle} - RM ${taskPrice} (${Math.round(distance)}km away)`;

        const fcmPromise = sendFCMNotification(
          tasker.fcm_token,
          notificationTitle,
          notificationBody,
          {
            type: 'new_task',
            task_id: taskId,
            task_title: taskTitle,
            task_category: taskCategory,
            distance: distance.toString(),
          }
        );

        // Create in-app notification record
        const inAppNotificationPromise = supabase
          .from('taskaway_notifications')
          .insert({
            user_id: tasker.id,
            task_id: taskId,
            type: 'task_posted',
            title: notificationTitle,
            message: notificationBody,
            is_read: false,
          });

        notificationPromises.push(fcmPromise);
        notificationPromises.push(inAppNotificationPromise);
      }
    }

    if (nearbyTaskers.length === 0) {
      console.log('No taskers found within 5km radius');
      return new Response(
        JSON.stringify({ message: 'No nearby taskers found' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Wait for all notifications to be sent
    await Promise.allSettled(notificationPromises);

    console.log(`Sent notifications to ${nearbyTaskers.length} nearby taskers`);

    return new Response(
      JSON.stringify({
        success: true,
        task_id: taskId,
        nearby_taskers_count: nearbyTaskers.length,
        nearby_taskers: nearbyTaskers,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error in notify-nearby-taskers function:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
