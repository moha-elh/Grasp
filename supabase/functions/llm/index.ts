// Edge Function: llm
// Proxies the Groq (OpenAI-compatible) chat API so the API keys never ship
// inside the app. Auth-gated by default (verify_jwt): only a signed-in user's
// request runs, which keeps the keys from being used by anyone with the APK.
//
// Deploy:  supabase functions deploy llm
// Secrets: supabase secrets set GROQ_API_KEY=... GROQ_API_KEY_2=...

const MODEL = "openai/gpt-oss-120b"; // mirror of the old Config.llmModel
const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const { system, user } = await req.json();
    if (typeof system !== "string" || typeof user !== "string") {
      return json({ error: "system and user are required" }, 400);
    }

    // Primary key, then the optional fallback when the first is rate limited or
    // rejected (the fallback logic used to live in the Dart client).
    const keys = [Deno.env.get("GROQ_API_KEY"), Deno.env.get("GROQ_API_KEY_2")]
      .filter((k): k is string => !!k && k.length > 0);
    if (keys.length === 0) return json({ error: "no GROQ key configured" }, 500);

    const payload = JSON.stringify({
      model: MODEL,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: system },
        { role: "user", content: user },
      ],
    });

    let lastErr = "LLM failed";
    for (let i = 0; i < keys.length; i++) {
      const resp = await fetch(GROQ_URL, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${keys[i]}`,
          "Content-Type": "application/json",
        },
        body: payload,
      });
      if (resp.ok) {
        const body = await resp.json();
        const content = body?.choices?.[0]?.message?.content;
        if (typeof content === "string") return json({ content });
        lastErr = "LLM returned no content";
        break;
      }
      lastErr = `LLM failed (${resp.status}): ${await resp.text()}`;
      console.error(lastErr);
      // A plain bad request won't be fixed by another key; only retry on
      // rate-limit / auth / server errors.
      const worthFallback = resp.status === 429 ||
        resp.status === 401 || resp.status === 403 || resp.status >= 500;
      if (!worthFallback) break;
    }
    return json({ error: lastErr }, 502);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(obj: unknown, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}
