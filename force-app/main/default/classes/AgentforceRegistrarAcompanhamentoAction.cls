/**
 * @description Ação invocável para o Agentforce 360 / Einstein Copilot.
 * Permite ao agente registrar um contato ou anotação administrativa na jornada do paciente.
 * Rastreabilidade completa com flag RegistradoPorAgentforce__c = true.
 */
public with sharing class AgentforceRegistrarAcompanhamentoAction {

    public class Request {
        @InvocableVariable(label='ID da Solicitação' description='Id do registro de Solicitacao__c' required=true)
        public Id solicitacaoId;

        @InvocableVariable(label='Tipo do Evento' description='Ex: Contato Administrativo, Documentação Pendente, Agendamento Confirmado')
        public String tipoEvento;

        @InvocableVariable(label='Descrição Administrativa' description='Resumo do contato, orientação ou fato administrativo' required=true)
        public String descricao;
    }

    public class Response {
        @InvocableVariable(label='Sucesso' description='Verdadeiro se a anotação foi inserida com sucesso')
        public Boolean sucesso;

        @InvocableVariable(label='ID do Acompanhamento')
        public Id acompanhamentoId;

        @InvocableVariable(label='Mensagem de Retorno')
        public String mensagem;
    }

    @InvocableMethod(
        label='Healthforce: Registrar Acompanhamento'
        description='Registra um evento ou contato administrativo na jornada do paciente a partir do Agentforce.'
        category='Healthforce 360'
    )
    public static List<Response> registrarAcompanhamento(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            Response resp = new Response();
            try {
                Id acpId = HealthforceJourneyService.registrarAcompanhamentoAgentforce(
                    req.solicitacaoId,
                    req.tipoEvento,
                    req.descricao
                );
                resp.sucesso = true;
                resp.acompanhamentoId = acpId;
                resp.mensagem = 'Acompanhamento registrado com sucesso na solicitação.';
            } catch (Exception ex) {
                resp.sucesso = false;
                resp.mensagem = 'Falha ao registrar acompanhamento: ' + ex.getMessage();
            }
            responses.add(resp);
        }

        return responses;
    }
}
