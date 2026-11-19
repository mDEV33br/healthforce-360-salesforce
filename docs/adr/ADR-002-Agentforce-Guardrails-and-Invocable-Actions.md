# ADR-002: Arquitetura de Ações Invocáveis e Guardrails Éticos no Agentforce 360

## Status
**Aprovado**

## Contexto
O Agentforce 360 utiliza Modelos de Linguagem de Grande Porte (LLMs) para orquestrar raciocínio autônomo (ReAct / Atlas Reasoning Engine). Em cenários de saúde pública, a introdução de IA generativa requer salvaguardas rígidas contra alucinações, execução descontrolada de DML e violações éticas/regulatórias (LGPD e CFM).

## Decisão de Arquitetura
1. **Padrão Apex Invocable Determinístico**:
   O Agentforce não executa queries diretas em SQL/SOQL livre pelo usuário final. A comunicação ocorre exclusivamente através de Apex `@InvocableMethod` com interfaces tipadas (`Request` e `Response`), sanitizadas por `Security.stripInaccessible` e regras de negócio com `with sharing`.
2. **Flag de Auditoria de Agente**:
   Toda inserção de acompanhamento gerada pelo assistente preenche compulsoriamente a flag `RegistradoPorAgentforce__c = true` para rastreabilidade de autoria de máquina.
3. **Guardrails de Não-Intervenção Clínica**:
   O prompt de sistema do Agentforce veda estritamente qualquer resposta que configure recomendação de medicamento, diagnóstico ou triagem médica. A resposta do agente limita-se ao fluxo de informações de regulação administrativa.

## Consequências
- **Positivas**: Confiança e auditoria comprováveis, zero risco de alucinação sobre dados de pacientes, conformidade com a Lei Geral de Proteção de Dados Pessoais (LGPD).
