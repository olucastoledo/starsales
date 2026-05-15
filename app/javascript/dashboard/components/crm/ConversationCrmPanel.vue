<script setup>
import { ref, watch, onMounted } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const currentUser = useMapGetter('getCurrentUser');
const accountId = useMapGetter('getCurrentAccountId');

const deal = ref(null);
const pipelines = ref([]);
const isLoading = ref(true);
const isMoving = ref(false);
const isAdding = ref(false);

// Add-to-pipeline form
const showAddForm = ref(false);
const selectedPipelineId = ref('');
const selectedStageId = ref('');
const pipelineStages = ref([]);

const getAuthHeaders = () => ({
  api_access_token: currentUser.value?.access_token,
  'Content-Type': 'application/json',
});

const loadDeal = async () => {
  isLoading.value = true;
  try {
    const res = await fetch(
      `/api/v1/accounts/${accountId.value}/crm/deals?conversation_id=${props.conversationId}`,
      { headers: getAuthHeaders() }
    );
    if (!res.ok) throw new Error();
    const data = await res.json();
    deal.value = data[0] || null;
  } catch {
    deal.value = null;
  } finally {
    isLoading.value = false;
  }
};

const loadPipelines = async () => {
  try {
    const res = await fetch(
      `/api/v1/accounts/${accountId.value}/crm/pipelines`,
      { headers: getAuthHeaders() }
    );
    if (!res.ok) return;
    pipelines.value = await res.json();
  } catch {
    // ignore
  }
};

const onPipelineChange = () => {
  selectedStageId.value = '';
  const pipeline = pipelines.value.find(p => String(p.id) === String(selectedPipelineId.value));
  pipelineStages.value = pipeline?.stages || [];
  if (pipelineStages.value.length > 0) {
    selectedStageId.value = String(pipelineStages.value[0].id);
  }
};

const addToPipeline = async () => {
  if (!selectedStageId.value) return;
  isAdding.value = true;
  try {
    const res = await fetch(
      `/api/v1/accounts/${accountId.value}/crm/deals`,
      {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify({
          crm_deal: { crm_stage_id: Number(selectedStageId.value) },
          conversation_id: props.conversationId,
        }),
      }
    );
    if (res.ok) {
      showAddForm.value = false;
      await loadDeal();
      useAlert('Conversa adicionada ao pipeline!');
    } else {
      const err = await res.json();
      useAlert(err?.errors?.base?.[0] || 'Erro ao adicionar ao pipeline');
    }
  } catch {
    useAlert('Erro de conexão');
  } finally {
    isAdding.value = false;
  }
};

const moveStage = async stageId => {
  if (!deal.value) return;
  isMoving.value = true;
  try {
    const res = await fetch(
      `/api/v1/accounts/${accountId.value}/crm/deals/${deal.value.id}`,
      {
        method: 'PATCH',
        headers: getAuthHeaders(),
        body: JSON.stringify({ crm_deal: { crm_stage_id: stageId } }),
      }
    );
    if (res.ok) {
      await loadDeal();
      useAlert('Estágio atualizado!');
    } else {
      useAlert('Erro ao mover estágio');
    }
  } catch {
    useAlert('Erro de conexão');
  } finally {
    isMoving.value = false;
  }
};

const removeFromPipeline = async () => {
  if (!deal.value) return;
  isMoving.value = true;
  try {
    await fetch(
      `/api/v1/accounts/${accountId.value}/crm/deals/${deal.value.id}`,
      { method: 'DELETE', headers: getAuthHeaders() }
    );
    deal.value = null;
    useAlert('Conversa removida do pipeline');
  } catch {
    // ignore
  } finally {
    isMoving.value = false;
  }
};

const currentPipeline = () =>
  pipelines.value.find(p => p.id === deal.value?.pipeline_id);

const currentStages = () =>
  currentPipeline()?.stages || [];

watch(() => props.conversationId, () => {
  deal.value = null;
  showAddForm.value = false;
  loadDeal();
});

onMounted(() => {
  loadDeal();
  loadPipelines();
});
</script>

<template>
  <div class="px-1 py-1">
    <!-- Loading skeleton -->
    <div v-if="isLoading" class="flex items-center gap-2 px-1 py-2">
      <div class="h-4 w-24 rounded bg-n-slate-3 animate-pulse" />
      <div class="h-4 w-16 rounded bg-n-slate-3 animate-pulse" />
    </div>

    <!-- Already in pipeline -->
    <template v-else-if="deal">
      <div class="flex items-start gap-2 px-1 py-1.5">
        <i class="i-lucide-kanban size-4 text-n-brand flex-shrink-0 mt-0.5" />
        <div class="flex-1 min-w-0">
          <p class="text-xs font-medium text-n-slate-12 truncate">{{ deal.pipeline_name }}</p>
          <p class="text-xs text-n-slate-8 truncate">{{ deal.stage_name }}</p>
        </div>
        <button
          class="flex-shrink-0 p-0.5 rounded text-n-slate-7 hover:text-red-500 hover:bg-red-50 transition-colors"
          title="Remover do pipeline"
          :disabled="isMoving"
          @click="removeFromPipeline"
        >
          <i class="i-lucide-x size-3.5" />
        </button>
      </div>

      <!-- Move stage selector -->
      <div class="mt-2 px-1">
        <label class="block text-[11px] font-medium text-n-slate-9 mb-1">Mover para outro estágio</label>
        <div class="flex gap-1.5">
          <select
            class="flex-1 text-xs px-2 py-1.5 rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand/30"
            :disabled="isMoving"
            @change="e => moveStage(Number(e.target.value))"
          >
            <option
              v-for="stage in currentStages()"
              :key="stage.id"
              :value="stage.id"
              :selected="stage.id === deal.crm_stage_id"
            >
              {{ stage.name }}
            </option>
          </select>
          <i v-if="isMoving" class="i-lucide-loader-2 size-4 animate-spin text-n-slate-8 self-center" />
        </div>
      </div>
    </template>

    <!-- Not in pipeline -->
    <template v-else>
      <div v-if="!showAddForm" class="flex items-center gap-2 px-1 py-1.5">
        <i class="i-lucide-inbox size-4 text-n-slate-7 flex-shrink-0" />
        <span class="text-xs text-n-slate-8 flex-1">Não está em nenhum pipeline</span>
        <button
          class="flex-shrink-0 text-xs font-medium text-n-brand hover:text-n-brand/80 transition-colors"
          @click="showAddForm = true"
        >
          + Adicionar
        </button>
      </div>

      <!-- Add form -->
      <div v-else class="px-1 space-y-2">
        <div>
          <label class="block text-[11px] font-medium text-n-slate-9 mb-1">Pipeline</label>
          <select
            v-model="selectedPipelineId"
            class="w-full text-xs px-2 py-1.5 rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand/30"
            @change="onPipelineChange"
          >
            <option value="" disabled>Selecione...</option>
            <option v-for="p in pipelines" :key="p.id" :value="String(p.id)">{{ p.name }}</option>
          </select>
        </div>
        <div v-if="pipelineStages.length">
          <label class="block text-[11px] font-medium text-n-slate-9 mb-1">Estágio</label>
          <select
            v-model="selectedStageId"
            class="w-full text-xs px-2 py-1.5 rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand/30"
          >
            <option v-for="s in pipelineStages" :key="s.id" :value="String(s.id)">{{ s.name }}</option>
          </select>
        </div>
        <div class="flex gap-1.5 pt-0.5">
          <button
            class="flex-1 py-1.5 text-xs font-medium rounded-lg bg-n-brand text-white hover:bg-n-brand/90 disabled:opacity-50 transition-colors"
            :disabled="!selectedStageId || isAdding"
            @click="addToPipeline"
          >
            <i v-if="isAdding" class="i-lucide-loader-2 size-3 animate-spin mr-0.5" />
            Adicionar
          </button>
          <button
            class="px-3 py-1.5 text-xs rounded-lg text-n-slate-9 hover:bg-n-slate-2 transition-colors"
            @click="showAddForm = false; selectedPipelineId = ''; selectedStageId = ''"
          >
            Cancelar
          </button>
        </div>
      </div>
    </template>
  </div>
</template>
