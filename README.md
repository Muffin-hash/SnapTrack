# SnapTrack
ASL Internship — Mobile App Development Track — Week 4
Device-Integrated App: Camera, Location & Push Notifications (Supabase backend)
What this is
A Flutter app that extends a Week 3 auth + database app with device hardware: capturing/picking a photo and uploading it, reading and attaching the device's location, and receiving push notifications — handled in both foreground and background/terminated states.
Backend: Supabase, not Firebase. Auth, the Postgres database, and file storage are all Supabase. Push notifications use OneSignal, since Supabase has no built-in push service — see Push Notifications below for why.
Architecture / Folder Structure
lib/
  main.dart                    # App entry, Supabase + notification init, auth gate
  models/
    post_model.dart            # Maps Postgres rows <-> Dart object
  services/                    # All platform/API calls live here — never in widgets
    supabase_service.dart      # Supabase client bootstrap
    auth_service.dart          # Sign up / sign in / sign out
    database_service.dart      # posts table CRUD + realtime stream
    storage_service.dart       # Image upload to Supabase Storage
    image_service.dart         # Camera capture / gallery pick (image_picker)
    location_service.dart      # Current location + reverse geocode
    notification_service.dart  # OneSignal init, foreground/background handling
    permission_service.dart    # Central runtime permission requests
  screens/
    login_screen.dart
    home_screen.dart           # Realtime list of the user's posts
    add_post_screen.dart       # Mini-project screen: create post + attach photo/location
    post_detail_screen.dart
  widgets/
    post_card.dart             # Displays a post's image + location
    permission_denied_view.dart # Shared fallback UI for denied permissions
platform_config/
  AndroidManifest_additions.xml
  Info_plist_additions.xml
supabase_setup.sql             # Table, RLS policies, storage bucket — run once in Supabase
Every call to the camera, gallery, location, storage, or notifications goes through a services/ class. Widgets only call services and render state — they never touch image_picker, geolocator, or supabase_flutter directly.
Environment Setup
    1. Create a Supabase project at supabase.com.
    2. Open SQL Editor and run supabase_setup.sql — creates the posts table, RLS policies, enables realtime, and creates the post-images storage bucket.
    3. Copy your project's URL and anon public key from Project Settings > API.
    4. Create a OneSignal app at onesignal.com (free tier), add your Android/iOS platform, and copy the OneSignal App ID.
    5. Add the manifest/plist permissions from platform_config/ into android/app/src/main/AndroidManifest.xml and ios/Runner/Info.plist.
    6. Run:
flutter pub get

flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=ONESIGNAL_APP_ID=your-onesignal-app-id
No keys are hard-coded in source — everything above is read via String.fromEnvironment, satisfying the "no hard-coded secrets" validation rule.
Implemented Features
    • ☒ Camera/gallery and location permissions requested with a clear rationale (PermissionService, shown before each request)
    • ☒ Capture or pick an image, upload it to Supabase Storage
    • ☒ Store the uploaded image's public URL on the related posts row
    • ☒ Read and attach device location (lat/lng + reverse-geocoded label)
    • ☒ Display the attached image and location (PostCard)
    • ☒ Push notifications via OneSignal, including a test send from the OneSignal dashboard
    • ☒ Foreground notifications intercepted and handled separately from background/terminated taps
    • ☒ Denied/permanently-denied permissions show a non-crashing fallback UI with a retry or "Open Settings" action (PermissionDeniedView)
    • ☒ Camera/location/storage/notification logic isolated in services/, never inside a build() method
Bonus / Optional
    • ☒ Basic image compression before upload (imageQuality: 80, maxWidth: 1600 in ImageService)
    • ☐ Map view for attached location — not implemented; PostCard shows the reverse-geocoded label and raw coordinates instead
    • ☐ Local notifications for in-app reminders — not implemented
    • [~] Deep-link a tapped notification to its post — the tap hook is wired in main.dart (onNotificationTapped), but resolving a postId to a PostModel needs a getPostById method that wasn't otherwise required by the spec; left as a clearly marked TODO rather than adding scope silently
Push Notifications
The original brief pointed at Firebase Cloud Messaging, but this project runs on Supabase, which doesn't ship a push service — Supabase Realtime pushes data changes over websockets while the app is open, but it can't wake a backgrounded/terminated app the way FCM/APNs can.
OneSignal was chosen as the replacement because it:
    • wraps FCM (Android) and APNs (iOS) under one SDK, so no separate Firebase project is needed just for messaging,
    • has a generous free tier and a dashboard for sending test pushes (used for the "at least one test push notification" requirement),
    • exposes the same three hooks FCM would: a device identifier (OneSignal.User.pushSubscription.id), a foreground-notification listener, and a notification-click listener for deep-linking.
NotificationService.init() registers both listeners; foreground notifications call event.preventDefault() so the app can decide how to present them instead of the OS showing its default banner.
Known Limitations
    • The map view and local-reminder bonus features are not implemented.
    • getPostById (needed for full notification deep-linking) is not yet written — see the marked TODO in main.dart.
    • This app assumes a Week 3 Supabase Auth setup already exists; the included LoginScreen/AuthService are a minimal working version so Week 4 can be run standalone, not a claim that Week 3 is unchanged.
Testing Notes
    • Tested permission-denied and permanently-denied paths manually by revoking permissions in system settings between runs.
    • Tested offline reverse-geocoding failure by disabling network after granting location permission — the app falls back to raw coordinates.
    • Tested foreground vs. background notification behavior by sending a test push from the OneSignal dashboard while the app was open, then backgrounded, then fully closed.
