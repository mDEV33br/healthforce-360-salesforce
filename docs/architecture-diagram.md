# Arquitetura Técnica - Healthforce 360

A arquitetura do **Healthforce 360** foi estruturada seguindo as diretrizes do **Salesforce Well-Architected Framework** (Trusted, Easy, Adaptable) e a metodologia **Design Science Research (DSR)**.

## Diagrama da Solução (Mermaid)

```mermaid
flowchart TD
    subgraph UI_Layer["Camada de Apresentação (Lightning Experience)"]
        APP["App Lightning: Healthforce 360"]
        LWC["LWC: patientJourneyTimeline"]
        REC["Páginas de Registro & List Views"]
        DASH["Painel de Indicadores Operacionais & SLA"]
    end

    subgraph Agentforce_Layer["Camada de IA Autônoma (Agentforce 360)"]
        AGENT["Healthforce Assistant (Copilot/Agent)"]
        GUARD["Guardrails Éticos & LGPD (Não-Clínico)"]
        TOPIC1["Tópico: Consulta_Status_Jornada"]
        TOPIC2["Tópico: Registro_Acompanhamento_Administrativo"]
        TOPIC3["Tópico: Visao_Regulacao_Pendencias"]
        AGENT --> GUARD
        GUARD --> TOPIC1
        GUARD --> TOPIC2
        GUARD --> TOPIC3
    end

    subgraph Service_Layer["Camada de Serviço Apex (Clean Architecture)"]
        ACT1["AgentforceConsultarStatusAction"]
        ACT2["AgentforceRegistrarAcompanhamentoAction"]
        ACT3["AgentforceConsultarPendenciasAction"]
        SVC["HealthforceJourneyService"]
        SEC["HealthforceSecurityUtil (FLS/CRUD with sharing)"]
        
        TOPIC1 --> ACT1
        TOPIC2 --> ACT2
        TOPIC3 --> ACT3
        ACT1 --> SVC
        ACT2 --> SVC
        ACT3 --> SVC
        SVC --> SEC
    end

    subgraph Automation_Layer["Automações & Regras de Transição"]
        TRIG["SolicitacaoTrigger"]
        HAND["SolicitacaoTriggerHandler (State Machine)"]
        VAL["Validation Rules (Justificativa Obrigatória)"]
        TRIG --> HAND
    end

    subgraph Data_Layer["Camada de Dados & Metadados"]
        PAC["Paciente__c (Dados Sintéticos)"]
        UNI["UnidadeSaude__c (UBS / UPA / Especialidades)"]
        SOL["Solicitacao__c (Núcleo do Fluxo)"]
        ACP["Acompanhamento__c (Eventos & Agentforce)"]
        HST["HistoricoStatus__c (Trilha Imutável)"]
        MDT["RegraFluxo__mdt (Parâmetros de SLA)"]

        PAC -->|1:N| SOL
        UNI -->|1:N Origem/Destino| SOL
        SOL -->|1:N| ACP
        SOL -->|1:N| HST
        MDT -.->|Configuração| HAND
    end

    LWC --> SOL
    SVC --> SOL
    HAND --> HST
    HAND --> SOL
```

## Princípios de Arquitetura
1. **Segregação Estrita de Domínio**: Separação clara entre a jornada administrativa (agendamentos, regulação, transporte sanitário) e o prontuário eletrônico do paciente (PEP/clínico).
2. **Minimização de Dados (LGPD)**: Todos os registros criados utilizam dados inequivocamente fictícios e anônimos.
3. **Imutabilidade e Auditoria**: Cada mudança de status na máquina de estados gera um registro indelével no objeto `HistoricoStatus__c`.
4. **Agentforce com Ações Tipadas**: Agentes de IA operam através de chamadas de métodos Apex `@InvocableMethod` fortemente tipados, sem acesso a queries SQL dinâmicas irrestritas.
