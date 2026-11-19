/**
 * @description Utilitário de segurança e governança para Healthforce 360.
 * Garante aplicação de 'with sharing', validação de FLS e CRUD, e sanitização de dados.
 * Em conformidade com o Salesforce Well-Architected Framework e LGPD.
 */
public with sharing class HealthforceSecurityUtil {

    /**
     * @description Sanitiza lista de registros garantindo que apenas campos acessíveis para leitura sejam retornados.
     */
    public static List<SObject> sanitizeForRead(List<SObject> records) {
        if (records == null || records.isEmpty()) {
            return records;
        }
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, records);
        return decision.getRecords();
    }

    /**
     * @description Sanitiza registros antes de operações de DML de inserção/criação.
     */
    public static List<SObject> sanitizeForCreate(List<SObject> records) {
        if (records == null || records.isEmpty()) {
            return records;
        }
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, records);
        return decision.getRecords();
    }

    /**
     * @description Valida se o usuário atual possui permissão de leitura sobre o objeto especificado.
     */
    public static Boolean canRead(Schema.SObjectType sObjectType) {
        return sObjectType != null && sObjectType.getDescribe().isAccessible();
    }

    /**
     * @description Valida se o usuário atual possui permissão de inserção sobre o objeto especificado.
     */
    public static Boolean canCreate(Schema.SObjectType sObjectType) {
        return sObjectType != null && sObjectType.getDescribe().isCreateable();
    }

    /**
     * @description Valida se o usuário atual possui permissão de atualização sobre o objeto especificado.
     */
    public static Boolean canUpdate(Schema.SObjectType sObjectType) {
        return sObjectType != null && sObjectType.getDescribe().isUpdateable();
    }
}
