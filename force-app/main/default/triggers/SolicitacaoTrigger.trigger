/**
 * @description Trigger principal para o objeto Solicitacao__c
 * Healthforce 360 - Plataforma Inteligente de Gestão e Jornada do Paciente
 */
trigger SolicitacaoTrigger on Solicitacao__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            SolicitacaoTriggerHandler.handleBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            SolicitacaoTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            SolicitacaoTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            SolicitacaoTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
