/**
 * @description Camada de serviço de domínio (Service Layer) para o Healthforce 360.
 * Centraliza a lógica de negócios para consultas de jornada, auditoria e operações de IA (Agentforce).
 */
public with sharing class HealthforceJourneyService {

    /**
     * @description DTO de retorno consolidado para consulta da jornada administrativa
     */
    public class JornadaDetalhes {
        @AuraEnabled public Boolean encontrado { get; set; }
        @AuraEnabled public Id solicitacaoId { get; set; }
        @AuraEnabled public String numeroSolicitacao { get; set; }
        @AuraEnabled public String nomePacienteSintetico { get; set; }
        @AuraEnabled public String statusAtual { get; set; }
        @AuraEnabled public String tipoSolicitacao { get; set; }
        @AuraEnabled public String prioridade { get; set; }
        @AuraEnabled public String unidadeOrigem { get; set; }
        @AuraEnabled public String unidadeDestino { get; set; }
        @AuraEnabled public Integer diasEmAberto { get; set; }
        @AuraEnabled public String slaStatus { get; set; }
        @AuraEnabled public String ultimoAcompanhamento { get; set; }
        @AuraEnabled public String mensagem { get; set; }

        public JornadaDetalhes() {
            this.encontrado = false;
            this.diasEmAberto = 0;
        }
    }

    /**
     * @description Consulta detalhes administrativos de uma solicitação por número ou código de paciente
     */
    public static JornadaDetalhes consultarJornada(String termoBusca) {
        JornadaDetalhes resultado = new JornadaDetalhes();

        if (String.isBlank(termoBusca)) {
            resultado.mensagem = 'Nenhum identificador informado para busca.';
            return resultado;
        }

        String termoFormatado = termoBusca.trim();

        List<Solicitacao__c> solicitacoes = [
            SELECT Id, Name, Status__c, TipoSolicitacao__c, Prioridade__c, DiasEmAberto__c, SLAStatus__c,
                   Paciente__r.NomeSintetico__c, Paciente__r.CodigoIdentificador__c,
                   UnidadeOrigem__r.Name, UnidadeDestino__r.Name,
                   (SELECT Id, TipoEvento__c, DescricaoAdministrativa__c, DataHoraEvento__c 
                    FROM Acompanhamentos__r 
                    ORDER BY DataHoraEvento__c DESC 
                    LIMIT 1)
            FROM Solicitacao__c
            WHERE Name = :termoFormatado 
               OR Paciente__r.CodigoIdentificador__c = :termoFormatado
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (solicitacoes.isEmpty()) {
            resultado.mensagem = 'Nenhuma solicitação administrativa encontrada para o identificador: ' + termoBusca;
            return resultado;
        }

        Solicitacao__c sol = solicitacoes[0];
        resultado.encontrado = true;
        resultado.solicitacaoId = sol.Id;
        resultado.numeroSolicitacao = sol.Name;
        resultado.nomePacienteSintetico = sol.Paciente__r != null ? sol.Paciente__r.NomeSintetico__c : 'Paciente Sintético';
        resultado.statusAtual = sol.Status__c;
        resultado.tipoSolicitacao = sol.TipoSolicitacao__c;
        resultado.prioridade = sol.Prioridade__c;
        resultado.unidadeOrigem = sol.UnidadeOrigem__r != null ? sol.UnidadeOrigem__r.Name : 'Não informada';
        resultado.unidadeDestino = sol.UnidadeDestino__r != null ? sol.UnidadeDestino__r.Name : 'Pendente de encaminhamento';
        resultado.diasEmAberto = sol.DiasEmAberto__c != null ? sol.DiasEmAberto__c.intValue() : 0;
        resultado.slaStatus = sol.SLAStatus__c;

        if (sol.Acompanhamentos__r != null && !sol.Acompanhamentos__r.isEmpty()) {
            Acompanhamento__c ultimo = sol.Acompanhamentos__r[0];
            resultado.ultimoAcompanhamento = '[' + ultimo.TipoEvento__c + '] ' + ultimo.DescricaoAdministrativa__c;
        } else {
            resultado.ultimoAcompanhamento = 'Nenhum acompanhamento registrado até o momento.';
        }

        resultado.mensagem = 'Solicitação ' + sol.Name + ' localizada. Status: ' + sol.Status__c + 
                             ', Tipo: ' + sol.TipoSolicitacao__c + ', SLA: ' + sol.SLAStatus__c + '.';
        return resultado;
    }

    /**
     * @description Registra anotação administrativa originada pelo Agentforce
     */
    public static Id registrarAcompanhamentoAgentforce(Id solicitacaoId, String tipoEvento, String descricao) {
        if (solicitacaoId == null) {
            throw new IllegalArgumentException('O ID da solicitação é obrigatório para registrar acompanhamento.');
        }

        Acompanhamento__c acp = new Acompanhamento__c(
            Solicitacao__c = solicitacaoId,
            TipoEvento__c = String.isNotBlank(tipoEvento) ? tipoEvento : 'Interação Agentforce',
            DescricaoAdministrativa__c = descricao,
            DataHoraEvento__c = System.now(),
            RegistradoPorAgentforce__c = true
        );

        if (Schema.sObjectType.Acompanhamento__c.isCreateable()) {
            insert acp;
            return acp.Id;
        } else {
            throw new SecurityException('Usuário ou perfil de agente sem permissão para criar Acompanhamento__c.');
        }
    }

    /**
     * @description Obtém lista de pendências operacionais para uma unidade de saúde
     */
    public static List<Solicitacao__c> obterPendenciasPorUnidade(String termoUnidade) {
        if (String.isBlank(termoUnidade)) {
            return new List<Solicitacao__c>();
        }

        String busca = '%' + termoUnidade.trim() + '%';
        return [
            SELECT Id, Name, Status__c, TipoSolicitacao__c, Prioridade__c, DiasEmAberto__c, SLAStatus__c,
                   Paciente__r.NomeSintetico__c, UnidadeOrigem__r.Name
            FROM Solicitacao__c
            WHERE (Status__c = 'Aberta' OR Status__c = 'Em análise' OR Status__c = 'Pendente')
              AND (UnidadeOrigem__r.Name LIKE :busca OR UnidadeOrigem__r.CodigoCNESSimulado__c = :termoUnidade.trim())
            WITH SECURITY_ENFORCED
            ORDER BY Prioridade__c DESC, DiasEmAberto__c DESC
            LIMIT 20
        ];
    }
}
