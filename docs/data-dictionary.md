# Dicionário de Dados - Healthforce 360

Este documento especifica as estruturas de dados, tipos de campos, regras de validação e relacionamentos do projeto.

---

### 1. Paciente Sintético (`Paciente__c`)
Entidade para registro mínimo de pessoa fictícia. Não armazena dados clínicos, biometria ou CPF real.

| Campo | API Name | Tipo | Obrigatório | Descrição / Regra |
|---|---|---|---|---|
| Nome do Registro | `Name` | AutoNumber (`PAC-{00000}`) | Sim | Identificador sequencial nativo do Salesforce |
| Código Identificador | `CodigoIdentificador__c` | Text(50), Unique, External ID | Sim | Código de rastreio sintético (ex: `PAC-2026-001`) |
| Nome Sintético | `NomeSintetico__c` | Text(120) | Sim | Nome fictício do paciente de demonstração |
| Data de Nascimento Fictícia | `DataNascimentoFicticia__c` | Date | Não | Data hipotética para cálculo de faixa etária |
| Unidade de Referência | `UnidadeReferencia__c` | Lookup (`UnidadeSaude__c`) | Não | UBS ou posto de saúde de acolhimento do território |
| Telefone Simulado | `TelefoneSimulado__c` | Phone | Não | Máscara de telefone simulado para alertas |
| Status do Cadastro | `StatusCadastro__c` | Picklist | Sim | Valores: `Ativo`, `Em Atualização`, `Inativo` |

---

### 2. Unidade de Saúde (`UnidadeSaude__c`)
Estabelecimentos de saúde da rede pública/simulada.

| Campo | API Name | Tipo | Obrigatório | Descrição / Regra |
|---|---|---|---|---|
| Nome da Unidade | `Name` | Text(80) | Sim | Nome do estabelecimento de saúde |
| Código CNES Simulado | `CodigoCNESSimulado__c` | Text(20), Unique | Sim | Código simulado de Cadastro Nacional de Estabelecimentos |
| Tipo de Unidade | `TipoUnidade__c` | Picklist | Sim | `Unidade Básica de Saúde (UBS)`, `UPA`, `Centro de Especialidades`, `Hospital Geral` |
| Município | `Municipio__c` | Text(80) | Sim | Cidade da unidade |
| Capacidade Diária | `CapacidadeAtendimentoDiario__c` | Number(5, 0) | Não | Estimativa diária para balanceamento de demanda |
| Ativo | `Ativo__c` | Checkbox (Default: True) | Sim | Status operacional da unidade |

---

### 3. Solicitação Administrativa (`Solicitacao__c`)
Núcleo da máquina de estados e acompanhamento da jornada.

| Campo | API Name | Tipo | Obrigatório | Descrição / Regra |
|---|---|---|---|---|
| Número da Solicitação | `Name` | AutoNumber (`SOL-{YYYY}-{00000}`) | Sim | Identificador amigável da solicitação |
| Paciente | `Paciente__c` | Lookup (`Paciente__c`) | Sim | Paciente sintético associado |
| Unidade de Origem | `UnidadeOrigem__c` | Lookup (`UnidadeSaude__c`) | Sim | Unidade solicitante |
| Unidade de Destino | `UnidadeDestino__c` | Lookup (`UnidadeSaude__c`) | Não | Unidade que executará o atendimento |
| Tipo de Solicitação | `TipoSolicitacao__c` | Picklist | Sim | `Consulta Especializada`, `Exame de Apoio Diagnóstico`, `Acompanhamento Pós-Alta`, etc. |
| Status | `Status__c` | Picklist | Sim | `Aberta`, `Em análise`, `Pendente`, `Encaminhada`, `Concluída`, `Cancelada` |
| Prioridade | `Prioridade__c` | Picklist | Sim | `Normal`, `Prioritária`, `Urgência Administrativa` |
| Data de Abertura | `DataAbertura__c` | DateTime | Sim | Padrão: `NOW()` |
| Data de Conclusão | `DataConclusao__c` | DateTime | Não | Preenchida automaticamente no encerramento |
| Justificativa de Status | `JustificativaStatus__c` | LongTextArea(1000) | Não | Obrigatória via Validation Rule para Cancelada/Pendente |
| Dias em Aberto | `DiasEmAberto__c` | Formula (Number) | Não | Cálculo decorrido até hoje ou conclusão |
| Status do SLA | `SLAStatus__c` | Formula (Text) | Não | `Em Dia` (&le;5d), `Atenção SLA` (6-10d), `SLA Crítico` (&gt;10d) |

---

### 4. Acompanhamento Administrativo (`Acompanhamento__c`)
Eventos e anotações cronológicas ao longo do ciclo de vida.

| Campo | API Name | Tipo | Descrição |
|---|---|---|---|
| Solicitação | `Solicitacao__c` | Master-Detail (`Solicitacao__c`) | Vínculo mestre-detalhe |
| Tipo de Evento | `TipoEvento__c` | Picklist | `Contato Administrativo`, `Agendamento`, `Interação Agentforce`, etc. |
| Descrição | `DescricaoAdministrativa__c` | LongTextArea(2000) | Detalhamento da anotação |
| Data/Hora Evento | `DataHoraEvento__c` | DateTime | Carimbo temporal |
| Registrado por Agentforce | `RegistradoPorAgentforce__c` | Checkbox | Flag de auditoria de IA autônoma |

---

### 5. Histórico de Status (`HistoricoStatus__c`)
Trilha indelével gerada programaticamente pelo `SolicitacaoTriggerHandler`.

| Campo | API Name | Tipo | Descrição |
|---|---|---|---|
| Solicitação | `Solicitacao__c` | Master-Detail (`Solicitacao__c`) | Vínculo mestre-detalhe |
| Status Anterior | `StatusAnterior__c` | Text(50) | Estado de onde partiu a transição |
| Novo Status | `NovoStatus__c` | Text(50) | Novo estado alcançado |
| Justificativa | `Justificativa__c` | LongTextArea(1000) | Motivação registrada |
| Data Transição | `DataTransicao__c` | DateTime | Timestamp da transição |
| Responsável | `Responsavel__c` | Text(100) | Usuário ou agente executor |
