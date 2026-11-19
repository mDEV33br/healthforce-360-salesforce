/**
 * @description Ação invocável para o Agentforce 360 / Einstein Copilot.
 * Permite que agentes autônomos ou assistidos consultem o andamento de solicitações
 * de forma segura, determinística e restrita ao escopo administrativo.
 */
public with sharing class AgentforceConsultarStatusAction {

    public class Request {
        @InvocableVariable(label='Identificador da Busca (Número da Solicitação ou Código do Paciente)' description='Ex: SOL-2026-00001 ou PAC-BR-00123' required=true)
        public String termoBusca;
    }

    public class Response {
        @InvocableVariable(label='Solicitação Encontrada' description='Verdadeiro se a solicitação foi localizada')
        public Boolean encontrado;

        @InvocableVariable(label='Número da Solicitação')
        public String numeroSolicitacao;

        @InvocableVariable(label='Nome do Paciente Sintético')
        public String nomePacienteSintetico;

        @InvocableVariable(label='Status Atual')
        public String statusAtual;

        @InvocableVariable(label='Tipo da Solicitação')
        public String tipoSolicitacao;

        @InvocableVariable(label='Unidade de Origem')
        public String unidadeOrigem;

        @InvocableVariable(label='Unidade de Destino')
        public String unidadeDestino;

        @InvocableVariable(label='Status do SLA')
        public String slaStatus;

        @InvocableVariable(label='Dias em Aberto')
        public Integer diasEmAberto;

        @InvocableVariable(label='Último Acompanhamento Registrado')
        public String ultimoAcompanhamento;

        @InvocableVariable(label='Mensagem de Resumo para o Usuário')
        public String mensagemResposta;
    }

    @InvocableMethod(
        label='Healthforce: Consultar Status da Solicitação'
        description='Permite ao Agentforce obter o status administrativo, SLA e último acompanhamento na jornada do paciente. Sem dados clínicos sensíveis.'
        category='Healthforce 360'
    )
    public static List<Response> consultarStatus(List<Request> requests) {
        List<Response> responses = new List<Response>();

        for (Request req : requests) {
            HealthforceJourneyService.JornadaDetalhes detalhes = HealthforceJourneyService.consultarJornada(req.termoBusca);
            Response resp = new Response();
            resp.encontrado = detalhes.encontrado;
            resp.numeroSolicitacao = detalhes.numeroSolicitacao;
            resp.nomePacienteSintetico = detalhes.nomePacienteSintetico;
            resp.statusAtual = detalhes.statusAtual;
            resp.tipoSolicitacao = detalhes.tipoSolicitacao;
            resp.unidadeOrigem = detalhes.unidadeOrigem;
            resp.unidadeDestino = detalhes.unidadeDestino;
            resp.slaStatus = detalhes.slaStatus;
            resp.diasEmAberto = detalhes.diasEmAberto;
            resp.ultimoAcompanhamento = detalhes.ultimoAcompanhamento;
            resp.mensagemResposta = detalhes.mensagem;
            responses.add(resp);
        }

        return responses;
    }
}
