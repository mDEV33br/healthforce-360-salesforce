/**
 * @description Ação invocável para o Agentforce 360 / Einstein Copilot.
 * Permite ao agente listar solicitações em aberto ou pendentes para uma unidade de saúde,
 * auxiliando a equipe de regulação e coordenação na identificação de gargalos.
 */
public with sharing class AgentforceConsultarPendenciasAction {

    public class Request {
        @InvocableVariable(label='Nome da Unidade ou Código CNES' description='Ex: UBS Central ou CNES-123456' required=true)
        public String termoUnidade;
    }

    public class Response {
        @InvocableVariable(label='Total de Solicitações Pendentes')
        public Integer totalPendentes;

        @InvocableVariable(label='Resumo Formatado das Solicitações')
        public String resumoPendencias;

        @InvocableVariable(label='Mensagem de Retorno')
        public String mensagem;
    }

    @InvocableMethod(
        label='Healthforce: Consultar Pendências da Unidade'
        description='Retorna a lista de solicitações pendentes e em análise para uma unidade de saúde de origem.'
        category='Healthforce 360'
    )
    public static List<Response> consultarPendencias(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            List<Solicitacao__c> pendentes = HealthforceJourneyService.obterPendenciasPorUnidade(req.termoUnidade);
            Response resp = new Response();
            resp.totalPendentes = pendentes.size();

            if (pendentes.isEmpty()) {
                resp.resumoPendencias = 'Nenhuma solicitação pendente encontrada para a unidade: ' + req.termoUnidade;
                resp.mensagem = 'Unidade regularizada sem pendências imediatas.';
            } else {
                List<String> linhas = new List<String>();
                for (Solicitacao__c sol : pendentes) {
                    linhas.add('• ' + sol.Name + ' | Paciente: ' + sol.Paciente__r.NomeSintetico__c + 
                               ' | Tipo: ' + sol.TipoSolicitacao__c + 
                               ' | Status: ' + sol.Status__c + 
                               ' | SLA: ' + sol.SLAStatus__c + 
                               ' (' + sol.DiasEmAberto__c + ' dias)');
                }
                resp.resumoPendencias = String.join(linhas, '\n');
                resp.mensagem = 'Localizadas ' + pendentes.size() + ' solicitações com atenção necessária.';
            }

            responses.add(resp);
        }

        return responses;
    }
}
