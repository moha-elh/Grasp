// Edge Function: search
// Proxies the Tavily web search so the search key never ships in the app.
// Auth-gated by default (verify_jwt). Best-effort: with no key configured it
// returns an empty result set, so Explore still shows its adjacent-concept cards.
//
// Deploy:  supabase functions deploy search
// Secret:  supabase secrets set SEARCH_API_KEY=...

const TAVILY_URL = "https://api.tavily.com/search";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const { query, maxResults } = await req.json();
    if (typeof query !== "string" || query.length === 0) {
      return json({ error: "query is required" }, 400);
    }

    const key = Deno.env.get("SEARCH_API_KEY");
    if (!key || key.length === 0) return json({ results: [] });

    const resp = await fetch(TAVILY_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        api_key: key,
        query,
        max_results: typeof maxResults === "number" ? maxResults : 2,
        search_depth: "basic",
      }),
    });
    if (!resp.ok) return json({ error: `search failed (${resp.status})` }, 502);

    const body = await resp.json();
    const results = (body.results ?? []).map((r: Record<string, unknown>) => ({
      title: (r.title as string) ?? "",
      url: (r.url as string) ?? "",
      content: (r.content as string) ?? "",
    }));
    return json({ results });
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
