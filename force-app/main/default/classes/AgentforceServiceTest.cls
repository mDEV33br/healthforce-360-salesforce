/**
 * @description Testes unitários para ações invocáveis do Agentforce 360
 * e serviços da camada de domínio do Healthforce 360.
 */
@IsTest
private class AgentforceServiceTest {

    @TestSetup
    static void setupData() {
        UnidadeSaude__c unidade = new UnidadeSaude__c(
            Name = 'UBS Esperança',
            CodigoCNESSimulado__c = 'CNES-998877',
            TipoUnidade__c = 'Unidade Básica de Saúde (UBS)',
            Municipio__c = 'Curitiba',
            Ativo__c = true
        );
        insert unidade;

        Paciente__c paciente = new Paciente__c(
            CodigoIdentificador__c = 'PAC-CTBA-001',
            NomeSintetico__c = 'Paciente Beta Teste',
            UnidadeReferencia__c = unidade.Id,
            StatusCadastro__c = 'Ativo'
        );
        insert paciente;

        Solicitacao__c sol = new Solicitacao__c(
            Paciente__c = paciente.Id,
            UnidadeOrigem__c = unidade.Id,
            TipoSolicitacao__c = 'Exame de Apoio Diagnóstico',
            Prioridade__c = 'Prioritária',
            Status__c = 'Em análise'
        );
        insert sol;

        Acompanhamento__c acp = new Acompanhamento__c(
            Solicitacao__c = sol.Id,
            TipoEvento__c = 'Contato Administrativo',
            DescricaoAdministrativa__c = 'Paciente avisado sobre a documentação necessária.',
            DataHoraEvento__c = System.now(),
            RegistradoPorAgentforce__c = false
        );
        insert acp;
    }

    @IsTest
    static void testConsultarStatusAction() {
        Solicitacao__c sol = [SELECT Id, Name FROM Solicitacao__c LIMIT 1];

        AgentforceConsultarStatusAction.Request req = new AgentforceConsultarStatusAction.Request();
        req.termoBusca = sol.Name;

        Test.startTest();
        List<AgentforceConsultarStatusAction.Response> responses = AgentforceConsultarStatusAction.consultarStatus(
            new List<AgentforceConsultarStatusAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Deve retornar uma resposta para a requisição');
        AgentforceConsultarStatusAction.Response resp = responses[0];
        System.assertEquals(true, resp.encontrado, 'Solicitação deve ser encontrada');
        System.assertEquals('Em análise', resp.statusAtual);
        System.assertEquals('Exame de Apoio Diagnóstico', resp.tipoSolicitacao);
        System.assert(resp.ultimoAcompanhamento.contains('Paciente avisado'), 'Último acompanhamento deve constar');
    }

    @IsTest
    static void testConsultarStatusPorCodigoPaciente() {
        AgentforceConsultarStatusAction.Request req = new AgentforceConsultarStatusAction.Request();
        req.termoBusca = 'PAC-CTBA-001';

        Test.startTest();
        List<AgentforceConsultarStatusAction.Response> responses = AgentforceConsultarStatusAction.consultarStatus(
            new List<AgentforceConsultarStatusAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].encontrado);
        System.assertEquals('Paciente Beta Teste', responses[0].nomePacienteSintetico);
    }

    @IsTest
    static void testRegistrarAcompanhamentoAgentforce() {
        Solicitacao__c sol = [SELECT Id FROM Solicitacao__c LIMIT 1];

        AgentforceRegistrarAcompanhamentoAction.Request req = new AgentforceRegistrarAcompanhamentoAction.Request();
        req.solicitacaoId = sol.Id;
        req.tipoEvento = 'Interação Agentforce';
        req.descricao = 'Agentforce 360 orientou o paciente sintético via portal sobre datas de exames.';

        Test.startTest();
        List<AgentforceRegistrarAcompanhamentoAction.Response> responses = AgentforceRegistrarAcompanhamentoAction.registrarAcompanhamento(
            new List<AgentforceRegistrarAcompanhamentoAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].sucesso, 'Ação do Agentforce deve ter sucesso');
        System.assertNotEquals(null, responses[0].acompanhamentoId);

        Acompanhamento__c acpCriado = [
            SELECT Id, RegistradoPorAgentforce__c, DescricaoAdministrativa__c 
            FROM Acompanhamento__c 
            WHERE Id = :responses[0].acompanhamentoId
        ];
        System.assertEquals(true, acpCriado.RegistradoPorAgentforce__c, 'Deve auditar como criado pelo Agentforce');
    }

    @IsTest
    static void testConsultarPendenciasPorUnidade() {
        AgentforceConsultarPendenciasAction.Request req = new AgentforceConsultarPendenciasAction.Request();
        req.termoUnidade = 'UBS Esperança';

        Test.startTest();
        List<AgentforceConsultarPendenciasAction.Response> responses = AgentforceConsultarPendenciasAction.consultarPendencias(
            new List<AgentforceConsultarPendenciasAction.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(1, responses[0].totalPendentes);
        System.assert(responses[0].resumoPendencias.contains('UBS Esperança') || responses[0].resumoPendencias.contains('Exame de Apoio'));
    }

    @IsTest
    static void testSecurityUtil() {
        List<Paciente__c> pacientes = [SELECT Id, Name FROM Paciente__c];
        List<SObject> sanitized = HealthforceSecurityUtil.sanitizeForRead(pacientes);
        System.assertEquals(pacientes.size(), sanitized.size());

        System.assertEquals(true, HealthforceSecurityUtil.canRead(Schema.sObjectType.Paciente__c));
        System.assertEquals(true, HealthforceSecurityUtil.canCreate(Schema.sObjectType.Solicitacao__c));
        System.assertEquals(true, HealthforceSecurityUtil.canUpdate(Schema.sObjectType.Solicitacao__c));
    }
}
