# CLAUDE.md — Not Delivered (`not_delivered`)

Context for future Claude Code sessions. Read this before changing anything.

Owner: Chirag (final-year AIML engineering student). This is a fun project.
GitHub: https://github.com/chiragparamesh/not_delivered (public). Org / package: `com.chirag.not_delivered`.

## Project brief

### 3. not_delivered — "Not Delivered" (fun project; tagline "Hungry? We'll fix that.")

A fully offline food-delivery app for Bengaluru. Colors: maroon #8B1E3F, gold #F4B400, background #FFF8F0; Poppins headings, Inter body. Data comes from assets/data/restaurants.json and dishes.json, which I will provide. Hive for local storage. Screens: splash, onboarding, location (GPS with manual fallback), home with cuisine chips and filters, search, restaurant menu, cart with coupons and tip, checkout with simulated payment clearly labeled as a demo, timer-based order tracking, order history with reorder, favorites, profile, notifications.

Delivery fee: ₹30 below ₹199, free from ₹199. One coupon at a time; "first order" means order history is empty.

Coupons: WELCOME50 (50%, max ₹100, min ₹149, first order), FREEDEL199 (free delivery, min ₹199), FLAT20 (₹20 off, min ₹300), BIGFEAST (₹75 off, min ₹600), WEEKEND10 (10%, max ₹50), SWEETTOOTH (₹30 off, min ₹150, dessert/bakery only).

Fun features: confetti and haptics on order, scratch card after delivery, savings counter, badges and streaks, funny tracking messages ("Rider stuck at Silk Board…"), a rare "Not Delivered… just kidding!" easter egg, daily spin wheel.

## Lightweight rules

My Windows laptop has low RAM: Android Studio and the Android emulator froze it. Everything must stay lightweight:

- No Android Studio, no emulator, no local Gradle/APK builds.
- Daily preview with: `flutter run -d chrome`
- APKs are built by GitHub Actions and installed on my Pixel 9a.
- ML models are trained in Google Colab; only the exported .tflite files live in the project.
- Everything goes inside `D:\Projects`. Nothing else on `D:\` root.
- Never run Gradle or `flutter build apk` locally.
- One install / one heavy task at a time. Never run parallel heavy tasks.
- `android/gradle.properties` stays capped: `org.gradle.jvmargs=-Xmx1536m`, `org.gradle.daemon=false`, `org.gradle.parallel=false`.
- Toolchain lives in `D:\Projects\_tools` (flutter, jdk, android-sdk, caches\pub, caches\gradle).

## How to work in this repo

- Preview: `flutter run -d chrome` (web is the dev target; Android is built only by CI).
- Checks you may run locally: `flutter pub get`, `flutter analyze`, `flutter test`.
- Never run: `flutter build apk`, `./gradlew`, `flutter run -d <android device>` with a local build, or anything that starts Gradle.
- APK: push to GitHub → Actions → "Build APK" → download the `not_delivered-release-apk` artifact → install on the Pixel 9a.
- Plugins that don't support web (camera, tflite, GPS, haptics, …) must sit behind an interface in `lib/core/services/` with a web/mock implementation so Chrome preview keeps working.

## Structure

- `lib/main.dart`, `lib/app.dart` — entry point and `MaterialApp.router`.
- `lib/core/theme/` — theme and colors. `lib/core/router/` — go_router routes.
- `lib/core/services/` — platform/service interfaces. `lib/core/utils/` — constants, helpers. `lib/core/widgets/` — shared widgets.
- `lib/features/<feature>/{data,domain,presentation}/` — one folder per feature:
  - `lib/features/splash/` — Splash screen
  - `lib/features/onboarding/` — Onboarding carousel
  - `lib/features/location/` — GPS location with manual fallback
  - `lib/features/home/` — Home with cuisine chips and filters
  - `lib/features/search/` — Search restaurants and dishes
  - `lib/features/restaurant/` — Restaurant menu
  - `lib/features/cart/` — Cart with coupons and tip
  - `lib/features/checkout/` — Checkout with simulated (demo) payment
  - `lib/features/tracking/` — Timer-based order tracking with funny messages
  - `lib/features/orders/` — Order history with reorder
  - `lib/features/favorites/` — Favorites
  - `lib/features/profile/` — Profile
  - `lib/features/notifications/` — Notifications
  - `lib/features/rewards/` — Scratch card, savings counter, badges, streaks, spin wheel
- `docs/architecture.md` — full system design and roadmap. Keep it updated.
- `.github/workflows/build-apk.yml` — the only place APKs are built.

## Status

Skeleton only: folders, theme, router, placeholder home screen, CI. No features built yet.
Update the features table in README.md (Built / Planned) as features land.
