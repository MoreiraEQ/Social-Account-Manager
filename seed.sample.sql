-- ============================================================
--  SAMPLE SEED — fictional demo data only (no real credentials)
--  Run once in your Postgres (e.g. Neon SQL Editor) AFTER schema.sql
-- ============================================================

-- Demo accounts
INSERT INTO app_state (key, value, updated_by)
VALUES (
  'cc_accounts',
  $json$[
    {"id":"demo-001","ativa":true,"user":"Alex","situacao":"RODANDO","celular":"Device A","redeSocial":"FACEBOOK","conta":"Demo Account One","email":"demo1@example.com","senha":"demo-password-1","funilBio":"https://example.com/","funilBioCurto":"https://exmpl.co/a","nicho":"DEMO-APP","ipProxy":"10.0.0.1","renovacao":"2026-08-01"},
    {"id":"demo-002","ativa":true,"user":"Sam","situacao":"AQUECER","celular":"Device B","redeSocial":"TIKTOK","conta":"Demo Account Two","email":"demo2@example.com","senha":"demo-password-2","funilBio":"https://example.com/","funilBioCurto":"https://exmpl.co/b","nicho":"DEMO-APP","ipProxy":"10.0.0.2","renovacao":"2026-08-05"},
    {"id":"demo-003","ativa":false,"user":"Jordan","situacao":"BANIDA","celular":"Device C","redeSocial":"INSTAGRAM","conta":"Demo Account Three","email":"demo3@example.com","senha":"demo-password-3","funilBio":"https://example.com/","funilBioCurto":"https://exmpl.co/c","nicho":"DEMO-APP","ipProxy":"10.0.0.3","renovacao":"2026-07-20"}
  ]$json$,
  'sample'
)
ON CONFLICT (key) DO NOTHING;

-- Demo financial entries
INSERT INTO app_state (key, value, updated_by)
VALUES (
  'cc_financeiro',
  $json$[
    {"id":"finx-1","tipo":"entrada","desc":"Sample revenue","valor":120,"mesano":"2026-06","cat":"Receita"},
    {"id":"finx-2","tipo":"saida","desc":"Sample tooling","valor":40,"mesano":"2026-06","cat":"Ferramentas"},
    {"id":"finx-3","tipo":"saida","desc":"Sample proxy","valor":15,"mesano":"2026-06","cat":"Proxy"}
  ]$json$,
  'sample'
)
ON CONFLICT (key) DO NOTHING;
