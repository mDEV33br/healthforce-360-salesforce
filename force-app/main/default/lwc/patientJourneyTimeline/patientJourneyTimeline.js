import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

const FIELDS = [
    'Solicitacao__c.Name',
    'Solicitacao__c.Status__c',
    'Solicitacao__c.TipoSolicitacao__c',
    'Solicitacao__c.DiasEmAberto__c',
    'Solicitacao__c.SLAStatus__c',
    'Solicitacao__c.Paciente__r.NomeSintetico__c',
    'Solicitacao__c.UnidadeOrigem__r.Name',
    'Solicitacao__c.UnidadeDestino__r.Name'
];

export default class PatientJourneyTimeline extends LightningElement {
    @api recordId;

    @track solicitacaoName = 'SOL-CARREGANDO';
    @track pacienteNome = 'Carregando...';
    @track unidadeOrigem = 'Carregando...';
    @track unidadeDestino = 'Carregando...';
    @track slaStatus = 'Em Dia';
    @track diasEmAberto = 0;
    @track statusAtual = 'Aberta';

    @track timelineItems = [];

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredSolicitacao({ error, data }) {
        if (data) {
            this.solicitacaoName = getFieldValue(data, 'Solicitacao__c.Name') || 'SOL-2026-0001';
            this.statusAtual = getFieldValue(data, 'Solicitacao__c.Status__c') || 'Aberta';
            this.diasEmAberto = getFieldValue(data, 'Solicitacao__c.DiasEmAberto__c') || 0;
            this.slaStatus = getFieldValue(data, 'Solicitacao__c.SLAStatus__c') || 'Em Dia';
            this.pacienteNome = data.fields.Paciente__r?.displayValue || data.fields.Paciente__r?.value?.fields?.NomeSintetico__c?.value || 'Paciente Sintético';
            this.unidadeOrigem = data.fields.UnidadeOrigem__r?.displayValue || 'UBS Referência';
            this.unidadeDestino = data.fields.UnidadeDestino__r?.displayValue || 'Não Definida';
            this.carregarMockTimeline();
        } else if (error) {
            console.error('Erro ao carregar detalhes da solicitação:', error);
            this.carregarMockTimeline();
        }
    }

    connectedCallback() {
        if (!this.timelineItems || this.timelineItems.length === 0) {
            this.carregarMockTimeline();
        }
    }

    carregarMockTimeline() {
        this.timelineItems = [
            {
                id: '1',
                titulo: 'Transição: Encaminhada',
                descricao: 'Solicitação validada e direcionada ao Centro de Especialidades.',
                dataHoraFormatada: 'Hoje às 14:30',
                responsavel: 'Coordenação Regional',
                icon: 'standard:service_crew',
                iconClass: 'slds-icon-standard-service-crew',
                isAgentforce: false
            },
            {
                id: '2',
                titulo: 'Orientação e Checagem Automática',
                descricao: 'Agente confirmou que os documentos anexos estão completos de acordo com os critérios de regulação.',
                dataHoraFormatada: 'Hoje às 11:15',
                responsavel: 'Agentforce 360 (IA Autônoma)',
                icon: 'standard:bot',
                iconClass: 'slds-icon-standard-bot',
                isAgentforce: true
            },
            {
                id: '3',
                titulo: 'Abertura da Solicitação',
                descricao: 'Registro inicial originado na Unidade Básica de Saúde para acolhimento eletivo.',
                dataHoraFormatada: 'Ontem às 09:00',
                responsavel: 'Atendimento UBS',
                icon: 'standard:record',
                iconClass: 'slds-icon-standard-record',
                isAgentforce: false
            }
        ];
    }

    get temHistorico() {
        return this.timelineItems && this.timelineItems.length > 0;
    }

    get slaBadgeClass() {
        if (this.slaStatus === 'Em Dia') {
            return 'slds-badge slds-theme_success';
        } else if (this.slaStatus === 'Atenção SLA') {
            return 'slds-badge slds-theme_warning';
        } else if (this.slaStatus === 'SLA Crítico / Vencido') {
            return 'slds-badge slds-theme_error';
        }
        return 'slds-badge';
    }

    get steps() {
        const order = ['Aberta', 'Em análise', 'Encaminhada', 'Concluída'];
        const currentIdx = order.indexOf(this.statusAtual);

        return [
            { name: 'Aberta', label: '1. Abertura', class: this.getStepClass(0, currentIdx) },
            { name: 'Em análise', label: '2. Análise', class: this.getStepClass(1, currentIdx) },
            { name: 'Encaminhada', label: '3. Encaminhamento', class: this.getStepClass(2, currentIdx) },
            { name: 'Concluída', label: '4. Conclusão', class: this.getStepClass(3, currentIdx) }
        ];
    }

    getStepClass(stepIdx, currentIdx) {
        if (this.statusAtual === 'Cancelada') {
            return 'slds-path__item slds-is-lost';
        }
        if (currentIdx === -1) {
            return 'slds-path__item slds-is-incomplete';
        }
        if (stepIdx < currentIdx) {
            return 'slds-path__item slds-is-complete';
        } else if (stepIdx === currentIdx) {
            return 'slds-path__item slds-is-current slds-is-active';
        } else {
            return 'slds-path__item slds-is-incomplete';
        }
    }
}
