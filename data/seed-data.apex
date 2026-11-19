/**
 * Healthforce 360 - Script de Carga de Dados Fictícios / Sintéticos
 * Executar via Anonymous Apex ou Salesforce CLI:
 * sf apex run --file data/seed-data.apex
 */

// 1. Limpeza opcional prévia de dados sintéticos
delete [SELECT Id FROM Acompanhamento__c WHERE Solicitacao__r.Paciente__r.CodigoIdentificador__c LIKE 'PAC-%'];
delete [SELECT Id FROM HistoricoStatus__c WHERE Solicitacao__r.Paciente__r.CodigoIdentificador__c LIKE 'PAC-%'];
delete [SELECT Id FROM Solicitacao__c WHERE Paciente__r.CodigoIdentificador__c LIKE 'PAC-%'];
delete [SELECT Id FROM Paciente__c WHERE CodigoIdentificador__c LIKE 'PAC-%'];
delete [SELECT Id FROM UnidadeSaude__c WHERE CodigoCNESSimulado__c LIKE 'CNES-%'];

// 2. Unidades de Saúde Fictícias
List<UnidadeSaude__c> unidades = new List<UnidadeSaude__c>{
    new UnidadeSaude__c(
        Name = 'UBS Jardim Esperança',
        CodigoCNESSimulado__c = 'CNES-100201',
        TipoUnidade__c = 'Unidade Básica de Saúde (UBS)',
        Municipio__c = 'São Paulo',
        CapacidadeAtendimentoDiario__c = 120,
        Ativo__c = true
    ),
    new UnidadeSaude__c(
        Name = 'UPA Central 24h',
        CodigoCNESSimulado__c = 'CNES-200302',
        TipoUnidade__c = 'Unidade de Pronto Atendimento (UPA)',
        Municipio__c = 'São Paulo',
        CapacidadeAtendimentoDiario__c = 250,
        Ativo__c = true
    ),
    new UnidadeSaude__c(
        Name = 'Centro Especializado Santa Cruz',
        CodigoCNESSimulado__c = 'CNES-300403',
        TipoUnidade__c = 'Centro de Especialidades Médicas',
        Municipio__c = 'São Paulo',
        CapacidadeAtendimentoDiario__c = 80,
        Ativo__c = true
    )
};
insert unidades;

// 3. Pacientes Sintéticos
List<Paciente__c> pacientes = new List<Paciente__c>{
    new Paciente__c(
        CodigoIdentificador__c = 'PAC-2026-001',
        NomeSintetico__c = 'Maria da Silva (Sintética)',
        DataNascimentoFicticia__c = Date.newInstance(1985, 4, 12),
        UnidadeReferencia__c = unidades[0].Id,
        TelefoneSimulado__c = '(11) 91111-0001',
        StatusCadastro__c = 'Ativo'
    ),
    new Paciente__c(
        CodigoIdentificador__c = 'PAC-2026-002',
        NomeSintetico__c = 'Carlos Pereira (Sintético)',
        DataNascimentoFicticia__c = Date.newInstance(1972, 9, 28),
        UnidadeReferencia__c = unidades[0].Id,
        TelefoneSimulado__c = '(11) 92222-0002',
        StatusCadastro__c = 'Ativo'
    ),
    new Paciente__c(
        CodigoIdentificador__c = 'PAC-2026-003',
        NomeSintetico__c = 'Ana Beatriz Souza (Sintética)',
        DataNascimentoFicticia__c = Date.newInstance(1998, 1, 15),
        UnidadeReferencia__c = unidades[1].Id,
        TelefoneSimulado__c = '(11) 93333-0003',
        StatusCadastro__c = 'Ativo'
    )
};
insert pacientes;

// 4. Solicitações Administrativas
Solicitacao__c sol1 = new Solicitacao__c(
    Paciente__c = pacientes[0].Id,
    UnidadeOrigem__c = unidades[0].Id,
    UnidadeDestino__c = unidades[2].Id,
    TipoSolicitacao__c = 'Consulta Especializada',
    Prioridade__c = 'Prioritária',
    Status__c = 'Aberta',
    DataAbertura__c = System.now().addDays(-4)
);
insert sol1;

// Transição controlada para sol1
sol1.Status__c = 'Em análise';
update sol1;

sol1.Status__c = 'Encaminhada';
update sol1;

// Solicitação 2 - Pendente
Solicitacao__c sol2 = new Solicitacao__c(
    Paciente__c = pacientes[1].Id,
    UnidadeOrigem__c = unidades[0].Id,
    TipoSolicitacao__c = 'Exame de Apoio Diagnóstico',
    Prioridade__c = 'Normal',
    Status__c = 'Aberta',
    DataAbertura__c = System.now().addDays(-8)
);
insert sol2;

sol2.Status__c = 'Em análise';
update sol2;

sol2.Status__c = 'Pendente';
sol2.JustificativaStatus__c = 'Aguardando envio do comprovante de residência atualizado para transporte sanitário.';
update sol2;

// 5. Acompanhamento Registrado pelo Agentforce
insert new Acompanhamento__c(
    Solicitacao__c = sol1.Id,
    TipoEvento__c = 'Interação Agentforce',
    DescricaoAdministrativa__c = 'Agentforce 360 notificou a coordenação do Centro de Especialidades Santa Cruz e atualizou o status de agendamento.',
    DataHoraEvento__c = System.now().addHours(-2),
    RegistradoPorAgentforce__c = true
);

System.debug('=== Healthforce 360: Dados Sintéticos Inseridos com Sucesso ===');
