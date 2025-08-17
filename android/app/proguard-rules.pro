# Flutter Stripe ProGuard Rules
-keep class com.stripe.android.** { *; }
-keep class com.reactnativestripesdk.** { *; }

# Keep Push Provisioning classes
-keep class com.stripe.android.pushProvisioning.** { *; }
-keep interface com.stripe.android.pushProvisioning.** { *; }

# Keep Stripe 3DS2 classes
-keep class com.stripe.android.stripe3ds2.** { *; }

# General Stripe rules
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.pushprovisioning.**

# Keep Gson classes used by Stripe
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod