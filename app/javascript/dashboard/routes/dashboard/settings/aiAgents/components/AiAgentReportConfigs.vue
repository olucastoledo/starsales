<script setup>
import { ref, computed, onMounted } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';

const currentUser = useMapGetter('getCurrentUser');
const accountId   = useMapGetter('getCurrentAccountId');

const configs   = ref([]);
const inboxes   = ref([]);
const isLoading = ref(true);
const isSaving  = ref(false);
const showForm  = ref(false);
const editingId = ref(null);

const defaultForm = () => ({
  inbox_id:                  '',
  frequency:                 'daily',
  send_hour:                 8,
  send_day_of_week:          1,
  send_day_of_month:         1,
  whatsapp_number:           '',
  custom_prompt:             '',
  include_conversation_count: true,
  include_agent_stats:       true,
  include_handoff_rate:      true,
  include_tool_usage:        false,
  enabled:                   true,
});

const form = ref(defaultForm());

const headers = computed(() => ({
  api_access_token: currentUser.value?.access_token,
  'Content-Type': 'application/json',
}));

const baseUrl = computed(() => `/api/v1/accounts/${accountId.value}`);

const frequencyOptions = [
  { value: 'daily',   label: 'Diário' },
  { value: 'weekly',  label: 'Semanal' },
  { value: 'monthly', label: 'Mensal' },
];

const weekdayOptions = [
  { value: 0, label: 'Domingo' }, { value: 1, label: 'Segunda' },
  { value: 2, label: 'Terça' },   { value: 3, label: 'Quarta' },
  { value: 4, label: 'Quinta' },  { value: 5, label: 'Sexta' },
  { value: 6, label: 'Sábado' },
];

const whatsappInboxes = computed(() =>
  inboxes.value.filter(i => ['Channel::Whatsapp', 'Channel::TwilioWhatsapp'].includes(i.channel_type))
);

const loadData = async () => {
  isLoading.value = true;
  try {
    const [cfgRes, inboxRes] = await Promise.all([
      fetch(`${baseUrl.value}/ai_agent_report_configs`, { headers: headers.value }),
      fetch(`${baseUrl.value}/inboxes`, { headers: headers.value }),
    ]);
    configs.value = await cfgRes.json();
    const inboxData = await inboxRes.json();
    inboxes.value = inboxData.payload || [];
  } catch {
    useAlert('Erro ao carregar configurações');
  } finally {
    isLoading.value = false;
  }
};

const openCreate = () => {
  editingId.value = null;
  form.value = defaultForm();
  showForm.value = true;
};

const openEdit = config => {
  editingId.value = config.id;
  form.value = { ...config };
  showForm.value = true;
};

const closeForm = () => {
  showForm.value = false;
  editingId.value = null;
};

const save = async () => {
  if (!form.value.whatsapp_number) {
    useAlert('Informe o número WhatsApp para receber o relatório');
    return;
  }
  isSaving.value = true;
  try {
    const url    = editingId.value
      ? `${baseUrl.value}/ai_agent_report_configs/${editingId.value}`
      : `${baseUrl.value}/ai_agent_report_configs`;
    const method = editingId.value ? 'PATCH' : 'POST';
    const res = await fetch(url, {
      method,
      headers: headers.value,
      body: JSON.stringify({ ai_agent_report_config: form.value }),
    });
    if (!res.ok) throw new Error(await res.text());
    await loadData();
    closeForm();
    useAlert(editingId.value ? 'Configuração atualizada!' : 'Configuração criada!');
  } catch (e) {
    useAlert(`Erro: ${e.message}`);
  } finally {
    isSaving.value = false;
  }
};

const remove = async id => {
  if (!confirm('Remover esta configuração de relatório?')) return;
  try {
    await fetch(`${baseUrl.value}/ai_agent_report_configs/${id}`, {
      method: 'DELETE', headers: headers.value,
    });
    await loadData();
    useAlert('Removido');
  } catch {
    useAlert('Erro ao remover');
  }
};

const sendNow = async id => {
  try {
    await fetch(`${baseUrl.value}/ai_agent_report_configs/${id}/send_now`, {
      method: 'POST', headers: headers.value,
    });
    useAlert('Relatório será enviado em instantes!');
  } catch {
    useAlert('Erro ao enviar');
  }
};

const toggleEnabled = async config => {
  try {
    await fetch(`${baseUrl.value}/ai_agent_report_configs/${config.id}`, {
      method: 'PATCH',
      headers: headers.value,
      body: JSON.stringify({ ai_agent_report_config: { enabled: !config.enabled } }),
    });
    await loadData();
  } catch {
    useAlert('Erro ao atualizar');
  }
};

const formatSchedule = config => {
  const hour = String(config.send_hour).padStart(2, '0') + ':00 UTC';
  if (config.frequency === 'daily')   return `Diário às ${hour}`;
  if (config.frequency === 'weekly')  return `Semanal — ${weekdayOptions[config.send_day_of_week]?.label} às ${hour}`;
  if (config.frequency === 'monthly') return `Mensal — dia ${config.send_day_of_month} às ${hour}`;
  return config.frequency;
};

onMounted(loadData);
</script>

<template>
  <div class="p-6">
    <div class="flex items-center justify-between mb-6">
      <div>
        <h2 class="text-lg font-semibold text-n-slate-12">Relatórios Automáticos</h2>
        <p class="text-sm text-n-slate-9 mt-0.5">
          Configure envios de relatório do agente de IA via WhatsApp
        </p>
      </div>
      <Button size="sm" @click="openCreate">
        <i class="i-lucide-plus size-4" />
        Novo Relatório
      </Button>
    </div>

    <!-- Loading -->
    <div v-if="isLoading" class="flex items-center justify-center py-12 text-n-slate-8">
      <i class="i-lucide-loader-2 size-5 animate-spin mr-2" /> Carregando...
    </div>

    <!-- Empty -->
    <div v-else-if="configs.length === 0 && !showForm"
         class="flex flex-col items-center justify-center py-16 text-n-slate-8 gap-3">
      <i class="i-lucide-file-chart-column size-10 text-n-slate-5" />
      <p class="text-sm font-medium text-n-slate-10">Nenhum relatório configurado</p>
      <p class="text-xs">Configure relatórios automáticos enviados via WhatsApp</p>
      <Button size="sm" @click="openCreate">Criar primeiro relatório</Button>
    </div>

    <!-- Config cards -->
    <div v-else class="space-y-3">
      <div v-for="config in configs" :key="config.id"
           class="rounded-xl border border-n-weak bg-n-background p-4 flex items-start justify-between gap-4">
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2 mb-1">
            <i class="i-lucide-smartphone size-4 text-n-brand flex-shrink-0" />
            <span class="font-semibold text-n-slate-12 text-sm truncate">{{ config.whatsapp_number }}</span>
            <span
              class="text-[10px] font-medium px-1.5 py-0.5 rounded-full"
              :class="config.enabled
                ? 'bg-green-50 text-green-700 border border-green-200'
                : 'bg-n-slate-2 text-n-slate-8 border border-n-weak'"
            >
              {{ config.enabled ? 'Ativo' : 'Pausado' }}
            </span>
          </div>
          <p class="text-xs text-n-slate-9">
            <i class="i-lucide-clock size-3 mr-1" />{{ formatSchedule(config) }}
          </p>
          <p v-if="config.inbox_name" class="text-xs text-n-slate-8 mt-0.5">
            <i class="i-lucide-inbox size-3 mr-1" />{{ config.inbox_name }}
          </p>
          <div class="flex gap-3 mt-2 text-[11px] text-n-slate-8">
            <span v-if="config.include_conversation_count">✓ Conversas</span>
            <span v-if="config.include_agent_stats">✓ Stats do agente</span>
            <span v-if="config.include_handoff_rate">✓ Handoffs</span>
            <span v-if="config.include_tool_usage">✓ Ferramentas</span>
          </div>
          <p v-if="config.last_sent_at" class="text-[11px] text-n-slate-7 mt-1">
            Último envio: {{ new Date(config.last_sent_at).toLocaleString('pt-BR') }}
          </p>
        </div>

        <div class="flex items-center gap-1 flex-shrink-0">
          <button
            class="p-1.5 rounded-lg text-n-slate-8 hover:bg-n-brand/10 hover:text-n-brand transition-colors"
            title="Enviar agora (teste)"
            @click="sendNow(config.id)"
          >
            <i class="i-lucide-send size-4" />
          </button>
          <button
            class="p-1.5 rounded-lg text-n-slate-8 hover:bg-n-slate-2 transition-colors"
            :title="config.enabled ? 'Pausar' : 'Ativar'"
            @click="toggleEnabled(config)"
          >
            <i :class="[config.enabled ? 'i-lucide-pause' : 'i-lucide-play', 'size-4']" />
          </button>
          <button
            class="p-1.5 rounded-lg text-n-slate-8 hover:bg-n-slate-2 transition-colors"
            title="Editar"
            @click="openEdit(config)"
          >
            <i class="i-lucide-pencil size-4" />
          </button>
          <button
            class="p-1.5 rounded-lg text-n-slate-8 hover:text-red-600 hover:bg-red-50 transition-colors"
            title="Remover"
            @click="remove(config.id)"
          >
            <i class="i-lucide-trash-2 size-4" />
          </button>
        </div>
      </div>
    </div>

    <!-- Create/Edit Form -->
    <div v-if="showForm" class="mt-6 rounded-xl border-2 border-dashed border-n-brand/40 bg-n-brand/5 p-5">
      <h3 class="text-sm font-semibold text-n-brand mb-4">
        {{ editingId ? 'Editar Relatório' : 'Novo Relatório' }}
      </h3>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <!-- WhatsApp inbox -->
        <div>
          <label class="block text-xs font-medium text-n-slate-10 mb-1">Inbox WhatsApp (para envio)</label>
          <select v-model="form.inbox_id"
                  class="w-full text-sm px-3 py-2 rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand/30">
            <option value="">Selecione um inbox</option>
            <option v-for="inbox in whatsappInboxes" :key="inbox.id" :value="inbox.id">
              {{ inbox.name }}
            </option>
          </select>
        </div>

        <!-- Recipient number -->
        <div>
          <label class="block text-xs font-medium text-n-slate-10 mb-1">Número que receberá o relatório</label>
          <input v-model="form.whatsapp_number" type="text" placeholder="+5511999999999"
                 class="w-full text-sm px-3 py-2 rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand/30" />
        </div>

        <!-- Frequency -->
        <div>
          <label class="block text-xs font-medium text-n-slate-10 mb-1">Frequência</label>
          <select v-model="form.frequency"
                  class="w-full text-sm px-3 py-2 rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand/30">
            <option v-for="opt in frequencyOptions" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
          </select>
        </div>

        <!-- Send hour -->
        <div>
          <label class="block text-xs font-medium text-n-slate-10 mb-1">Horário de envio (UTC)</label>
          <select v-model.number="form.send_hour"
                  class="w-full text-sm px-3 py-2 rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand/30">
            <option v-for="h in 24" :key="h-1" :value="h-1">{{ String(h-1).padStart(2,'0') }}:00 UTC</option>
          </select>
        </div>

        <!-- Day of week (weekly) -->
        <div v-if="form.frequency === 'weekly'">
          <label class="block text-xs font-medium text-n-slate-10 mb-1">Dia da semana</label>
          <select v-model.number="form.send_day_of_week"
                  class="w-full text-sm px-3 py-2 rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand/30">
            <option v-for="day in weekdayOptions" :key="day.value" :value="day.value">{{ day.label }}</option>
          </select>
        </div>

        <!-- Day of month (monthly) -->
        <div v-if="form.frequency === 'monthly'">
          <label class="block text-xs font-medium text-n-slate-10 mb-1">Dia do mês</label>
          <input v-model.number="form.send_day_of_month" type="number" min="1" max="28" placeholder="1"
                 class="w-full text-sm px-3 py-2 rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand/30" />
        </div>
      </div>

      <!-- Custom prompt -->
      <div class="mt-4">
        <label class="block text-xs font-medium text-n-slate-10 mb-1">
          Prompt personalizado para o relatório
          <span class="text-n-slate-7 font-normal">(opcional — define o tom e foco da mensagem)</span>
        </label>
        <textarea v-model="form.custom_prompt" rows="3"
                  placeholder="Ex: Seja objetivo, foque nas conversas resolvidas e mencione o número de novos clientes abordados pelo agente."
                  class="w-full text-sm px-3 py-2 rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand/30 resize-none" />
      </div>

      <!-- Data to include -->
      <div class="mt-4">
        <label class="block text-xs font-medium text-n-slate-10 mb-2">Dados incluídos no relatório</label>
        <div class="flex flex-wrap gap-3">
          <label class="flex items-center gap-2 cursor-pointer text-sm text-n-slate-10">
            <input v-model="form.include_conversation_count" type="checkbox" class="rounded border-n-weak text-n-brand" />
            Conversas atendidas
          </label>
          <label class="flex items-center gap-2 cursor-pointer text-sm text-n-slate-10">
            <input v-model="form.include_agent_stats" type="checkbox" class="rounded border-n-weak text-n-brand" />
            Performance do agente
          </label>
          <label class="flex items-center gap-2 cursor-pointer text-sm text-n-slate-10">
            <input v-model="form.include_handoff_rate" type="checkbox" class="rounded border-n-weak text-n-brand" />
            Handoffs para humano
          </label>
          <label class="flex items-center gap-2 cursor-pointer text-sm text-n-slate-10">
            <input v-model="form.include_tool_usage" type="checkbox" class="rounded border-n-weak text-n-brand" />
            Uso de ferramentas
          </label>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex gap-2 mt-5">
        <button
          class="flex-1 py-2 text-sm font-medium rounded-lg bg-n-brand text-white hover:bg-n-brand/90 transition-colors disabled:opacity-50"
          :disabled="isSaving"
          @click="save"
        >
          <i v-if="isSaving" class="i-lucide-loader-2 size-4 animate-spin mr-1" />
          {{ editingId ? 'Salvar alterações' : 'Criar configuração' }}
        </button>
        <button class="px-4 py-2 text-sm rounded-lg text-n-slate-9 hover:bg-n-slate-2 transition-colors" @click="closeForm">
          Cancelar
        </button>
      </div>
    </div>
  </div>
</template>
