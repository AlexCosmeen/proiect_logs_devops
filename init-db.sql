-- Creare tip enum pentru nivelul logului (opțional, dar recomandat pentru consistență)
CREATE TYPE log_level AS ENUM ('INFO', 'WARNING', 'ERROR');

CREATE TABLE logs (
    id SERIAL PRIMARY KEY,
    level log_level NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);