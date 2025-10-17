-- Usar o schema app_data
SET search_path TO app_data, public;

-- Tabela de atividades (sua fonte verdadeira)
CREATE TABLE IF NOT EXISTS atividades (
    id SERIAL PRIMARY KEY,
    id_entrega VARCHAR(50) UNIQUE NOT NULL,
    identificador VARCHAR(100),
    descricao TEXT,
    cnpj_cliente VARCHAR(20),
    nome_fantasia VARCHAR(255),
    id_oportunidade VARCHAR(50),
    vendedor VARCHAR(100),
    lider_pmo VARCHAR(100),
    etapa_atual VARCHAR(100),
    data_previsao_etapa DATE,
    responsavel VARCHAR(100),
    data_inicio DATE,
    data_fim_previsto_original DATE,
    data_fim_previsto DATE,
    data_fim_efetiva DATE,
    data_da_ultima_movimentacao DATE,
    horas_previstas_entrega DECIMAL(10,2),
    horas_realizadas_entrega DECIMAL(10,2),
    saldo_horas DECIMAL(10,2),
    status VARCHAR(50),
    hash_dados VARCHAR(64), -- SHA256 dos campos importantes
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE
);

-- Tabela de cards Trello
CREATE TABLE IF NOT EXISTS cards_trello (
    id SERIAL PRIMARY KEY,
    id_entrega VARCHAR(50) REFERENCES atividades(id_entrega),
    id_card_trello VARCHAR(100) UNIQUE,
    id_lista_trello VARCHAR(100),
    nome_card VARCHAR(255),
    descricao TEXT,
    ultima_sincronizacao TIMESTAMP,
    hash_sincronizacao VARCHAR(64),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    deleted_at TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE
);

-- Índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_atividades_id_entrega ON atividades(id_entrega);
CREATE INDEX IF NOT EXISTS idx_atividades_status ON atividades(status);
CREATE INDEX IF NOT EXISTS idx_atividades_is_active ON atividades(is_active);
CREATE INDEX IF NOT EXISTS idx_cards_trello_id_entrega ON cards_trello(id_entrega);
CREATE INDEX IF NOT EXISTS idx_cards_trello_id_card_trello ON cards_trello(id_card_trello);
CREATE INDEX IF NOT EXISTS idx_cards_trello_is_active ON cards_trello(is_active);

-- Criar função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para atualizar updated_at automaticamente
CREATE TRIGGER update_atividades_updated_at BEFORE UPDATE ON atividades
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cards_trello_updated_at BEFORE UPDATE ON cards_trello
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
