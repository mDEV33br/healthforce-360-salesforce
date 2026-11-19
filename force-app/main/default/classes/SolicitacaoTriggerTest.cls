/**
 * @description Testes unitários para SolicitacaoTrigger e SolicitacaoTriggerHandler.
 * Valida a integridade da máquina de estados, regras de transição, preenchimento de datas
 * e criação automática de trilha de auditoria em HistoricoStatus__c.
 */
@IsTest
private class SolicitacaoTriggerTest {

    @TestSetup
    static void setupData() {
        UnidadeSaude__c unidade = new UnidadeSaude__c(
            Name = 'UBS Central Teste',
            CodigoCNESSimulado__c = 'CNES-TESTE-01',
            TipoUnidade__c = 'Unidade Básica de Saúde (UBS)',
            Municipio__c = 'São Paulo',
            Ativo__c = true
        );
        insert unidade;

        Paciente__c paciente = new Paciente__c(
            CodigoIdentificador__c = 'PAC-TEST-001',
            NomeSintetico__c = 'Paciente Sintético Alfa',
            UnidadeReferencia__c = unidade.Id,
            StatusCadastro__c = 'Ativo'
        );
        insert paciente;
    }

    @IsTest
    static void testCriacaoSolicitacaoComDefaults() {
        Paciente__c paciente = [SELECT Id FROM Paciente__c LIMIT 1];
        UnidadeSaude__c unidade = [SELECT Id FROM UnidadeSaude__c LIMIT 1];

        Test.startTest();
        Solicitacao__c sol = new Solicitacao__c(
            Paciente__c = paciente.Id,
            UnidadeOrigem__c = unidade.Id,
            TipoSolicitacao__c = 'Consulta Especializada',
            Prioridade__c = 'Normal'
        );
        insert sol;
        Test.stopTest();

        Solicitacao__c inserida = [SELECT Id, Status__c, DataAbertura__c, DataConclusao__c FROM Solicitacao__c WHERE Id = :sol.Id];
        System.assertEquals('Aberta', inserida.Status__c, 'O status inicial padrão deve ser Aberta');
        System.assertNotEquals(null, inserida.DataAbertura__c, 'Data de abertura deve ser preenchida automaticamente');
        System.assertEquals(null, inserida.DataConclusao__c, 'Data de conclusão deve estar em branco inicialmente');

        List<HistoricoStatus__c> historicos = [SELECT Id, NovoStatus__c FROM HistoricoStatus__c WHERE Solicitacao__c = :sol.Id];
        System.assertEquals(1, historicos.size(), 'Deve existir 1 histórico gerado na inserção');
        System.assertEquals('Aberta', historicos[0].NovoStatus__c);
    }

    @IsTest
    static void testFluxoValidoTransicao() {
        Paciente__c paciente = [SELECT Id FROM Paciente__c LIMIT 1];
        UnidadeSaude__c unidade = [SELECT Id FROM UnidadeSaude__c LIMIT 1];

        Solicitacao__c sol = new Solicitacao__c(
            Paciente__c = paciente.Id,
            UnidadeOrigem__c = unidade.Id,
            TipoSolicitacao__c = 'Consulta Especializada',
            Prioridade__c = 'Normal',
            Status__c = 'Aberta'
        );
        insert sol;

        Test.startTest();
        // Aberta -> Em análise
        sol.Status__c = 'Em análise';
        update sol;

        // Em análise -> Encaminhada
        sol.Status__c = 'Encaminhada';
        update sol;

        // Encaminhada -> Concluída
        sol.Status__c = 'Concluída';
        update sol;
        Test.stopTest();

        Solicitacao__c finalizada = [SELECT Id, Status__c, DataConclusao__c FROM Solicitacao__c WHERE Id = :sol.Id];
        System.assertEquals('Concluída', finalizada.Status__c);
        System.assertNotEquals(null, finalizada.DataConclusao__c, 'Ao concluir, a data de conclusão deve ser preenchida');

        List<HistoricoStatus__c> historicos = [SELECT Id, NovoStatus__c FROM HistoricoStatus__c WHERE Solicitacao__c = :sol.Id ORDER BY CreatedDate ASC];
        System.assertEquals(4, historicos.size(), 'Deve conter histórico de criação + 3 transições');
    }

    @IsTest
    static void testTransicaoInvalidaBloqueada() {
        Paciente__c paciente = [SELECT Id FROM Paciente__c LIMIT 1];
        UnidadeSaude__c unidade = [SELECT Id FROM UnidadeSaude__c LIMIT 1];

        Solicitacao__c sol = new Solicitacao__c(
            Paciente__c = paciente.Id,
            UnidadeOrigem__c = unidade.Id,
            TipoSolicitacao__c = 'Consulta Especializada',
            Prioridade__c = 'Normal',
            Status__c = 'Aberta'
        );
        insert sol;

        Test.startTest();
        Boolean excecaoLancada = false;
        try {
            // Tentativa de pular diretamente de Aberta para Concluída (inválido)
            sol.Status__c = 'Concluída';
            update sol;
        } catch (DmlException e) {
            excecaoLancada = true;
            System.assert(e.getMessage().contains('Transição inválida de status'), 'Mensagem de erro esperada');
        }
        Test.stopTest();

        System.assert(excecaoLancada, 'Deveria bloquear transição inválida de status');
    }

    @IsTest
    static void testCancelamentoComJustificativa() {
        Paciente__c paciente = [SELECT Id FROM Paciente__c LIMIT 1];
        UnidadeSaude__c unidade = [SELECT Id FROM UnidadeSaude__c LIMIT 1];

        Solicitacao__c sol = new Solicitacao__c(
            Paciente__c = paciente.Id,
            UnidadeOrigem__c = unidade.Id,
            TipoSolicitacao__c = 'Consulta Especializada',
            Prioridade__c = 'Normal',
            Status__c = 'Aberta'
        );
        insert sol;

        Test.startTest();
        sol.Status__c = 'Cancelada';
        sol.JustificativaStatus__c = 'Cancelamento administrativo simulado para validação.';
        update sol;
        Test.stopTest();

        Solicitacao__c cancelada = [SELECT Id, Status__c, DataConclusao__c FROM Solicitacao__c WHERE Id = :sol.Id];
        System.assertEquals('Cancelada', cancelada.Status__c);
        System.assertNotEquals(null, cancelada.DataConclusao__c);
    }
}
