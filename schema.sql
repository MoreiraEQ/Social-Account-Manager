-- ═══════════════════════════════════════════════════════════════════
--  SCHEMA — rode UMA vez no Neon (aba "SQL Editor" do console Neon)
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS app_state (
  key         TEXT PRIMARY KEY,            -- ex.: 'cc_accounts', 'cc_financeiro'
  value       TEXT NOT NULL,               -- JSON serializado (igual ao localStorage)
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by  TEXT                         -- e-mail de quem fez a última alteração
);

-- (opcional) histórico/auditoria de alterações:
CREATE TABLE IF NOT EXISTS app_state_log (
  id          BIGSERIAL PRIMARY KEY,
  key         TEXT NOT NULL,
  updated_by  TEXT,
  changed_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
