# Edge Functions

These keep the sensitive API keys OFF the device. The app calls these functions
through `supabase.functions.invoke(...)` with the signed-in user's session, and
the functions hold the keys as server-side secrets.

- **`llm`** — proxies the Groq chat API (card generation + Explore authoring).
- **`search`** — proxies the Tavily web search (Explore web cards).

The Supabase anon/publishable key and the Dropbox app key stay in the app: the
anon key is protected by RLS and is meant to be public, and Dropbox uses PKCE
(no client secret).

## One-time setup

1. Install the CLI and sign in:
   ```
   npm i -g supabase        # or: scoop install supabase
   supabase login
   ```
2. Link this folder to your project (project ref is in the dashboard URL):
   ```
   supabase link --project-ref <your-project-ref>
   ```
3. Set the secrets (these replace the keys that used to live in `.env`):
   ```
   supabase secrets set GROQ_API_KEY=... GROQ_API_KEY_2=... SEARCH_API_KEY=...
   ```
   `GROQ_API_KEY_2` and `SEARCH_API_KEY` are optional (fallback key / web cards).

## Deploy (run after any change to a function)

```
supabase functions deploy llm
supabase functions deploy search
```

Both verify the caller's JWT by default, so only a signed-in user can invoke
them. Nothing else to configure.

## Verify

After deploying, generating cards and loading the Explore tab should work with
no keys present in `.env`. Logs: `supabase functions logs llm` (or `search`).

## Rotating a key

`supabase secrets set GROQ_API_KEY=<new>` then redeploy is not needed — secrets
are read at request time. If you ever leaked the old keys (they were in the APK
before this change), rotate them in the Groq / Tavily dashboards.
