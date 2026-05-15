<script setup>
import { ref, computed, onMounted } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import SelectInput from 'dashboard/components-next/select/Select.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  inbox: { type: Object, default: () => ({}) },
});

const currentUser = useMapGetter('getCurrentUser');
const accountId   = useMapGetter('getCurrentAccountId');

const allAgents       = ref([]);
const selectedAgentId = ref(null);
const currentAgent    = ref(null);
const isLoading       = ref(true);
const isSaving        = ref(false);

const headers = computed(() => ({
  api_access_token: currentUser.value?.access_token,
  'Content-Type': 'application/json',
}));

const baseUrl = computed(() => `/api/v1/accounts/${accountId.value}`);
const inboxId = computed(() => props.inbox?.id);

const agentOptions = computed(() =>
  allAgents.value.map(a => ({ value: a.id, label: `${a.name}${a.personality ? ` — ${a.personality}` : ''}` }))
);

const loadData = async () => {
  isLoading.value = true;
  try {
    const [agentsRes, currentRes] = await Promise.all([
      fetch(`${baseUrl.value}/ai_agents`, { headers: headers.value }),
      fetch(`${baseUrl.value}/inboxes/${inboxId.value}/ai_agent`, { headers: headers.value }),
    ]);
    allAgents.value = await agentsRes.json();
    const current = await currentRes.json();
    currentAgent.value    = current.agent;
    selectedAgentId.value = current.ai_agent_id || null;
  } catch {
    useAlert('Erro ao carregar agentes de IA');
  } finally {
    isLoading.value = false;
  }
};

const save = async () => {
  isSaving.value = true;
  try {
    const res = await fetch(`${baseUrl.value}/inboxes/${inboxId.value}/ai_agent`, {
      method:  'POST',
      headers: headers.value,
      body:    JSON.stringify({ ai_agent_id: selectedAgentId.value }),
    });
    if (!res.ok) throw new Error(await res.text());
    const data = await res.json();
    currentAgent.value = data.agent;
    useAlert(selectedAgentId.value ? 'Agente de IA vinculado!' : 'Agente desconectado');
  } catch (e) {
    useAlert(`Erro: ${e.message}`);
  } finally {
    isSaving.value = false;
  }
};

const disconnect = async () => {
  selectedAgentId.value = null;
  await save();
};

onMounted(loadData);
</script>

<template>
  <div class="mx-6 max-w-4xl">
    <div v-if="isLoading" class="flex items-center gap-2 py-4 text-n-slate-9 text-sm">
      <i class="i-lucide-loader-2 size-4 animate-spin" /> Carregando...
    </div>

    <form v-else @submit.prevent="save">
      <SettingsFieldSection
        label="Agente de IA"
        help-text="Selecione um agente de IA para responder automaticamente às conversas neste inbox. O agente será pausado quando um humano assumir a conversa."
        class="[&>div]:!items-start"
      >
        <!-- Current agent badge -->
        <div v-if="currentAgent" class="mb-3 flex items-center gap-2 px-3 py-2 rounded-lg bg-n-brand/5 border border-n-brand/20">
          <i class="i-lucide-bot size-4 text-n-brand" />
          <span class="text-sm text-n-slate-12 font-medium">{{ currentAgent.name }}</span>
          <span v-if="currentAgent.personality" class="text-xs text-n-slate-8">— {{ currentAgent.personality }}</span>
          <span class="ml-auto text-[10px] text-n-brand font-medium bg-n-brand/10 px-1.5 py-0.5 rounded-full">Ativo</span>
        </div>

        <SelectInput
          v-model="selectedAgentId"
          placeholder="Selecione um agente de IA..."
          :options="agentOptions"
        />

        <p v-if="allAgents.length === 0" class="text-xs text-n-slate-8 mt-2">
          <i class="i-lucide-info size-3 mr-1" />
          Nenhum agente criado ainda. Crie um em
          <strong>Configurações → Agentes de IA</strong>.
        </p>

        <template #extra>
          <div class="grid grid-cols-1 lg:grid-cols-8 mt-3">
            <div class="col-span-1 lg:col-span-2 invisible" />
            <div class="col-span-1 lg:col-span-6 flex gap-2 mx-1">
              <Button
                type="submit"
                label="Salvar"
                :is-loading="isSaving"
                :disabled="allAgents.length === 0"
              />
              <Button
                v-if="currentAgent"
                type="button"
                faded
                ruby
                :is-loading="isSaving"
                @click="disconnect"
              >
                Desconectar agente
              </Button>
            </div>
          </div>
        </template>
      </SettingsFieldSection>
    </form>
  </div>
</template>
