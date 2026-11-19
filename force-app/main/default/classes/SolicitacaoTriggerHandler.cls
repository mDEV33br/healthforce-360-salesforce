/**
 * @description Handler de Trigger para Solicitacao__c no Healthforce 360.
 * Responsável pela governança das regras de transição de status e registro automático
 * de trilha de auditoria em HistoricoStatus__c.
 */
public with sharing class SolicitacaoTriggerHandler {

    private static final Map<String, Set<String>> TRANSIÇÕES_PERMITIDAS = new Map<String, Set<String>>{
        'Aberta'      => new Set<String>{ 'Em análise', 'Cancelada' },
        'Em análise'  => new Set<String>{ 'Pendente', 'Encaminhada', 'Cancelada' },
        'Pendente'    => new Set<String>{ 'Em análise', 'Cancelada' },
        'Encaminhada' => new Set<String>{ 'Concluída', 'Cancelada' },
        'Concluída'   => new Set<String>(),
        'Cancelada'   => new Set<String>()
    };

    /**
     * @description Executado antes da inserção
     */
    public static void handleBeforeInsert(List<Solicitacao__c> novasSolicitacoes) {
        for (Solicitacao__c sol : novasSolicitacoes) {
            if (sol.DataAbertura__c == null) {
                sol.DataAbertura__c = System.now();
            }
            if (String.isBlank(sol.Status__c)) {
                sol.Status__c = 'Aberta';
            }
        }
    }

    /**
     * @description Executado antes da atualização para validação estrita de máquina de estados
     */
    public static void handleBeforeUpdate(List<Solicitacao__c> novas, Map<Id, Solicitacao__c> antigasMap) {
        for (Solicitacao__c nova : novas) {
            Solicitacao__c antiga = antigasMap.get(nova.Id);

            if (nova.Status__c != antiga.Status__c) {
                Set<String> permitidos = TRANSIÇÕES_PERMITIDAS.get(antiga.Status__c);
                if (permitidos == null || !permitidos.contains(nova.Status__c)) {
                    nova.Status__c.addError(
                        'Transição inválida de status: de "' + antiga.Status__c + 
                        '" para "' + nova.Status__c + '". Transições permitidas: ' + 
                        (permitidos != null && !permitidos.isEmpty() ? String.join(new List<String>(permitidos), ', ') : 'Nenhuma (estado final)')
                    );
                    continue;
                }

                // Data de conclusão automática ao atingir estado final
                if (nova.Status__c == 'Concluída' || nova.Status__c == 'Cancelada') {
                    nova.DataConclusao__c = System.now();
                } else if (nova.DataConclusao__c != null) {
                    nova.DataConclusao__c = null;
                }
            }
        }
    }

    /**
     * @description Executado após inserção para registrar o histórico inicial
     */
    public static void handleAfterInsert(List<Solicitacao__c> novas) {
        List<HistoricoStatus__c> historicos = new List<HistoricoStatus__c>();
        String userName = UserInfo.getName();

        for (Solicitacao__c sol : novas) {
            historicos.add(new HistoricoStatus__c(
                Solicitacao__c = sol.Id,
                StatusAnterior__c = 'Nenhum (Criação)',
                NovoStatus__c = sol.Status__c,
                Justificativa__c = 'Abertura inicial da solicitação no sistema Healthforce 360.',
                DataTransicao__c = System.now(),
                Responsavel__c = userName
            ));
        }

        if (!historicos.isEmpty() && Schema.sObjectType.HistoricoStatus__c.isCreateable()) {
            insert historicos;
        }
    }

    /**
     * @description Executado após atualização para auditar cada mudança de status
     */
    public static void handleAfterUpdate(List<Solicitacao__c> novas, Map<Id, Solicitacao__c> antigasMap) {
        List<HistoricoStatus__c> historicos = new List<HistoricoStatus__c>();
        String userName = UserInfo.getName();

        for (Solicitacao__c nova : novas) {
            Solicitacao__c antiga = antigasMap.get(nova.Id);

            if (nova.Status__c != antiga.Status__c) {
                historicos.add(new HistoricoStatus__c(
                    Solicitacao__c = nova.Id,
                    StatusAnterior__c = antiga.Status__c,
                    NovoStatus__c = nova.Status__c,
                    Justificativa__c = String.isNotBlank(nova.JustificativaStatus__c) 
                        ? nova.JustificativaStatus__c 
                        : 'Transição administrativa registrada via sistema.',
                    DataTransicao__c = System.now(),
                    Responsavel__c = userName
                ));
            }
        }

        if (!historicos.isEmpty() && Schema.sObjectType.HistoricoStatus__c.isCreateable()) {
            insert historicos;
        }
    }
}
