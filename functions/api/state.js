// ───────────────────────────────────────────────────────────────────────────
//  /api/state  —  Cloudflare Pages Function (roda no servidor, não no navegador)
//
//  GET  /api/state         → devolve { "cc_accounts": "...", "cc_financeiro": "...", ... }
//  POST /api/state {key,value}  → grava/atualiza uma chave (value:null apaga)
//
//  SEGURANÇA:
//  • A string de conexão do banco vem de env.DATABASE_URL (variável de ambiente
//    no Cloudflare). Ela NUNCA é enviada ao navegador.
//  • Toda esta rota fica ATRÁS do Cloudflare Access (Zero Trust): só os e-mails
//    liberados conseguem chegar aqui. O e-mail autenticado é registrado em
//    updated_by para auditoria.
//  • Só chaves da lista branca (cc_*) são aceitas.
// ───────────────────────────────────────────────────────────────────────────
import { neon } from "@neondatabase/serverless";

const ALLOWED = new Set([
  "cc_accounts", "cc_options", "cc_colorder", "cc_customcols",
  "cc_financeiro", "cc_fin_cats", "cc_platforms", "cc_acomp_tasks", "cc_cal_events",
]);

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

export async function onRequestGet({ env }) {
  if (!env.DATABASE_URL) return json({ error: "DATABASE_URL não configurada" }, 500);
  try {
    const sql = neon(env.DATABASE_URL);
    const rows = await sql`SELECT key, value FROM app_state`;
    const out = {};
    for (const r of rows) out[r.key] = r.value;
    return json(out);
  } catch (e) {
    return json({ error: String(e && e.message || e) }, 500);
  }
}

export async function onRequestPost({ env, request }) {
  if (!env.DATABASE_URL) return json({ error: "DATABASE_URL não configurada" }, 500);

  let body;
  try { body = await request.json(); }
  catch { return json({ error: "JSON inválido" }, 400); }

  const { key, value } = body || {};
  if (typeof key !== "string" || !ALLOWED.has(key)) {
    return json({ error: "chave não permitida" }, 400);
  }

  // e-mail autenticado pelo Cloudflare Access (para auditoria de quem alterou)
  const email = request.headers.get("Cf-Access-Authenticated-User-Email") || "desconhecido";

  try {
    const sql = neon(env.DATABASE_URL);
    if (value === null) {
      await sql`DELETE FROM app_state WHERE key = ${key}`;
    } else {
      const text = String(value);
      if (text.length > 4_000_000) return json({ error: "valor muito grande" }, 413);
      await sql`
        INSERT INTO app_state (key, value, updated_by, updated_at)
        VALUES (${key}, ${text}, ${email}, now())
        ON CONFLICT (key) DO UPDATE
          SET value = EXCLUDED.value,
              updated_by = EXCLUDED.updated_by,
              updated_at = now()`;
    }
    return json({ ok: true });
  } catch (e) {
    return json({ error: String(e && e.message || e) }, 500);
  }
}
