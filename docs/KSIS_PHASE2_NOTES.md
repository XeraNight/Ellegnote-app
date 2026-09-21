# KSIS Phase 2 Architecture & Deferred Implementation Notes

> **Status:** DEFERRED (Phase 2).  
> **Hard Gate:** Phase 2 proceeds **ONLY** if live HTML fixtures captured during an active competition prove that "advanced" vs. "eliminated" states are distinguishable in KSIS before the competition concludes. If KSIS only publishes results at the very end, live tracking is not feasible and will not be built.

---

## 1. Concurrency & Worker Lock Architecture

To prevent duplicate fetches and race conditions when multiple users follow the same competition:

- **Table:** `public.worker_locks`
  - Columns: `id text primary key` (e.g. `ksis_worker`), `run_id uuid not null`, `locked_at timestamptz not null`, `expires_at timestamptz not null`.
  - **RLS:** Enabled, **NO policies for anon or authenticated** (accessible strictly via `service_role`).
- **Atomic Lock Acquisition:**
  - One atomic SQL statement using `INSERT ... ON CONFLICT (id) DO UPDATE ... WHERE worker_locks.expires_at < now()`.
  - A unique `run_id` (UUIDv4) is generated at the start of each worker invocation.
- **Lock Extension (Heartbeat):**
  - If a worker batch runs longer than 15 seconds, it extends `expires_at = now() + interval '30 seconds'` strictly with `WHERE id = 'ksis_worker' AND run_id = my_run_id`.
- **Safe Release:**
  - On worker exit (both normal and catch block), release the lock strictly using:
    ```sql
    DELETE FROM public.worker_locks
    WHERE id = 'ksis_worker' AND run_id = my_run_id;
    ```
  - This ensures a slow or timed-out worker can never accidentally delete a lock acquired by a subsequent run.

---

## 2. pg_cron Trigger with Vault & Constant-Time Auth

- **Active Subscriptions Check:**
  - The cron job must not invoke the worker if there are no active tracking sessions.
  - SQL query executed by `pg_cron`:
    ```sql
    SELECT CASE 
      WHEN EXISTS (
        SELECT 1 FROM public.live_subscriptions 
        WHERE expires_at > now() AND is_active = true
      ) THEN
        net.http_post(
          url := 'https://iukblwlttvrcdclmlyxu.supabase.co/functions/v1/ksis-worker',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'X-Cron-Secret', (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'CRON_SECRET' LIMIT 1)
          ),
          body := '{}'::jsonb
        )
      ELSE NULL
    END;
    ```
- **Vault Secret Storage:**
  - `CRON_SECRET` is stored in Supabase Vault (`vault.create_secret(...)`), never hardcoded in plaintext SQL or repository files.
- **Constant-Time Verification:**
  - In `ksis-worker`, compare the incoming `X-Cron-Secret` header using constant-time equality (`crypto.subtle.timingSafeEqual` in Deno) to eliminate timing attack vectors.

---

## 3. Subscription Rules & Limits

- **Per-User Limit:**
  - Maximum **2 active subscriptions** per authenticated user at any time.
  - Enforced in Edge Function and validated with a database check/trigger.
- **TTL / Expiry:**
  - Each subscription expires automatically after **12 hours** (`expires_at = now() + interval '12 hours'`).
  - No zombie polling runs indefinitely.

---

## 4. Live States Table & Data Lifecycle

- **Table:** `public.live_states`
  - Columns: `id uuid primary key`, `user_id uuid references auth.users(id)`, `sutaz_id int not null`, `couple_id int not null`, `state text not null`, `current_round text`, `heat_number int`, `updated_at timestamptz not null`.
  - **RLS:** Enabled, SELECT-only for authenticated (`user_id = auth.uid()`). All writes via `service_role`.
- **Automatic Cleanup:**
  - Daily or hourly cleanup job deletes states older than 24 hours:
    ```sql
    DELETE FROM public.live_states WHERE updated_at < now() - interval '24 hours';
    ```

---

## 5. Apple Push Notification service (APNs) & Live Activities

- **Provider Authentication (JWT):**
  - Use `.p8` private key with ES256 algorithm.
  - Token caching: Cache the generated provider token for **at least 20 minutes** (max 1 refresh per 20 min) to respect Apple APNs guidelines.
- **Environment Distinction:**
  - Store environment (`sandbox` vs. `production`) per device push token in `live_subscriptions.apns_environment`.
  - Development/TestFlight builds talk to `api.sandbox.push.apple.com:443`.
  - App Store production builds talk to `api.push.apple.com:443`.
- **Token Invalidation:**
  - On HTTP `410 Gone` or response reason `BadDeviceToken` / `Unregistered`, immediately deactivate the subscription (`is_active = false`) and delete the invalid push token.
- **Final Termination Event:**
  - When the competition publishes the official final result, send a final APNs update with `event: "end"` and `dismissal-date` to cleanly dismiss the Dynamic Island / Live Activity.
- **Payload Constraints:**
  - Maximum payload size strictly **under 4 KB**.
  - **No `Date` objects** in JSON payload (encode timestamps as UNIX epoch integers).
  - Include `timestamp`, `event` (`update` / `end`), and `stale-date`.

---

## 6. Realtime Order & Client Subscription Contract

To prevent race conditions where a client misses an update that occurred while loading:
1. **Step 1:** Client establishes Supabase Realtime channel subscription to `public.live_states` for its `user_id`.
2. **Step 2:** Only after subscription status is `SUBSCRIBED`, client performs initial `SELECT` from `public.live_states`.
3. **Step 3:** Merge incoming realtime events with local cache using `updated_at` (incoming event discarded if `event.updated_at <= local.updated_at`).

---

## 7. Live Activity Lifecycle & Permissions

- **App Foreground Rule:**
  - iOS ActivityKit strictly forbids starting a Live Activity from a background push notification.
  - Live Activities must be started **exclusively while the Encore iOS app is in the foreground**.
  - App sends the acquired `pushToken` to Supabase `ksis-live-subscribe` Edge Function upon starting.
