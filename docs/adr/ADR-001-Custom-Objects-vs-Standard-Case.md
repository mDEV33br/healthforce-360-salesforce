# ADR-001: Modelagem com Custom Objects vs. Reaproveitamento do Objeto Padrão Case (Service Cloud)

## Status
**Aprovado**

## Contexto
O Documento Mestre do Healthforce 360 (Seção 8 e 9) orienta avaliar o reaproveitamento do objeto padrão `Case` do Service Cloud antes de instituir objetos customizados, visando evitar duplicidade de estruturas e justificar a decisão de arquitetura.

## Decisão de Arquitetura
Optou-se pela criação de uma estrutura customizada explícita (`Solicitacao__c`, `Paciente__c`, `UnidadeSaude__c`, `Acompanhamento__c`, `HistoricoStatus__c`), em detrimento do uso direto de `Case` / `Contact` por três fatores determinantes:

1. **Aderência Semântica ao Domínio de Saúde Pública (SUS Digital)**:
   O objeto `Case` carrega campos, terminologias e regras legadas de atendimento comercial (ex: *Case Origin*, *Web-to-Case*, *Entitlement Process*, *Milestones* de call center). Para modelar redes regionalizadas de saúde pública com Unidade de Origem, Unidade de Destino, CNES e transições estritas, os campos customizados trariam ruído visual e sobrecarga de schema no Case.
2. **Segregação Rigorosa e Minimização de Dados (LGPD)**:
   Isolar pacientes sintéticos em `Paciente__c` previne o risco de mesclagem acidental com a base de Contatos/Clientes reais existentes na org Salesforce.
3. **Imutabilidade e Auditoria Específica (`HistoricoStatus__c`)**:
   Embora o Case possua `CaseHistory`, a extração e manipulação granular das transições em tempo real para alimentar o componente LWC e os agentes do Agentforce requer controle programático de campos como `StatusAnterior__c`, `NovoStatus__c` e `Justificativa__c`.

## Consequências
- **Positivas**: Domínio limpo, sem dependência de licenças pesadas de Service Cloud ou Health Cloud; portabilidade para qualquer Developer Edition; clareza arquitetural no repositório público.
- **Mitigações**: As funcionalidades nativas do Case (como Omni-Channel e Entitlements) podem ser integradas futuramente via automações Flow/Apex caso haja necessidade corporativa.
