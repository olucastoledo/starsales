<script setup>
import { ref, computed, onMounted } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import KanbanColumn from './KanbanColumn.vue';
import DealModal from './DealModal.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { draggingDeal, draggingColumn } from './useCrmDrag';

const props = defineProps({
  pipelineId: { type: [String, Number], required: true },
});

const currentUser = useMapGetter('getCurrentUser');
const accountId = useMapGetter('getCurrentAccountId');

const stages = ref([]);
const deals = ref({});
const isLoading = ref(true);
const isSaving = ref(false);
const linkModalRef = ref(null);

// Stage form
const showStageForm = ref(false);
const newStageName = ref('');
const newStageShowValueSum = ref(false);
const isSavingStage = ref(false);

// Date filters
const filterDateFrom = ref('');
const filterDateTo = ref('');

const getAuthHeaders = () => ({
  api_access_token: currentUser.value?.access_token,
  'Content-Type': 'application/json',
});

// ── Filtered deals per stage ──────────────────────────────────
const stageDealMap = computed(() => {
  const map = {};
  stages.value.forEach(stage => {
    let stageDeals = deals.value[stage.id] || [];
    if (filterDateFrom.value || filterDateTo.value) {
      const from = filterDateFrom.value ? new Date(filterDateFrom.value) : null;
      // set to end of day
      const to = filterDateTo.value ? new Date(filterDateTo.value + 'T23:59:59') : null;
      stageDeals = stageDeals.filter(d => {
        if (!d.last_activity_at) return true;
        const date = new Date(d.last_activity_at);
        if (from && date < from) return false;
        if (to && date > to) return false;
        return true;
      });
    }
    map[stage.id] = stageDeals;
  });
  return map;
});

const totalConversations = computed(() =>
  Object.values(stageDealMap.value).flat().length
);

const hasActiveFilters = computed(() => filterDateFrom.value || filterDateTo.value);

const clearFilters = () => { filterDateFrom.value = ''; filterDateTo.value = ''; };

// ── API ───────────────────────────────────────────────────────
const loadPipelineData = async () => {
  isLoading.value = true;
  try {
    const res = await fetch(
      `/api/v1/accounts/${accountId.value}/crm/pipelines/${props.pipelineId}`,
      { headers: getAuthHeaders() }
    );
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    stages.value = data.stages || [];
    const map = {};
    stages.value.forEach(stage => {
      map[stage.id] = (data.deals || []).filter(d => d.crm_stage_id === stage.id);
    });
    deals.value = map;
  } catch (e) {
    useAlert(`Erro ao carregar pipeline: ${e.message}`);
  } finally {
    isLoading.value = false;
  }
};

const onDealDelete = async dealId => {
  try {
    const res = await fetch(
      `/api/v1/accounts/${accountId.value}/crm/deals/${dealId}`,
      { method: 'DELETE', headers: getAuthHeaders() }
    );
    if (res.ok) await loadPipelineData();
  } catch { /* ignore */ }
};

const onDealMove = async ({ dealId, toStageId }) => {
  // Optimistic update
  for (const [stageId, stageDeals] of Object.entries(deals.value)) {
    const idx = stageDeals.findIndex(d => d.id === dealId);
    if (idx !== -1) {
      const [moved] = deals.value[stageId].splice(idx, 1);
      moved.crm_stage_id = toStageId;
      deals.value[toStageId] = deals.value[toStageId] || [];
      deals.value[toStageId].push(moved);
      break;
    }
  }
  try {
    await fetch(`/api/v1/accounts/${accountId.value}/crm/deals/${dealId}`, {
      method: 'PATCH',
      headers: getAuthHeaders(),
      body: JSON.stringify({ crm_deal: { crm_stage_id: toStageId } }),
    });
  } catch {
    await loadPipelineData();
  }
};

const onDealUpdateValue = async ({ dealId, value }) => {
  for (const stageDeals of Object.values(deals.value)) {
    const deal = stageDeals.find(d => d.id === dealId);
    if (deal) { deal.value = value; break; }
  }
  try {
    await fetch(`/api/v1/accounts/${accountId.value}/crm/deals/${dealId}`, {
      method: 'PATCH',
      headers: getAuthHeaders(),
      body: JSON.stringify({ crm_deal: { value } }),
    });
  } catch {
    await loadPipelineData();
  }
};

const reorderStages = async stageIds => {
  try {
    const res = await fetch(
      `/api/v1/accounts/${accountId.value}/crm/pipelines/${props.pipelineId}/stages/reorder`,
      {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify({ stage_ids: stageIds }),
      }
    );
    if (!res.ok) throw new Error();
  } catch {
    await loadPipelineData();
  }
};

const onLinkConversation = async ({ conversationId, stageId }) => {
  isSaving.value = true;
  try {
    const res = await fetch(`/api/v1/accounts/${accountId.value}/crm/deals`, {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify({
        crm_deal: { crm_stage_id: stageId },
        conversation_id: conversationId,
      }),
    });
    if (res.ok) {
      linkModalRef.value?.closeAfterLink();
      await loadPipelineData();
      useAlert('Conversa vinculada com sucesso!');
    } else {
      const err = await res.json();
      useAlert(err?.errors?.base?.[0] || 'Erro ao vincular conversa');
    }
  } catch {
    useAlert('Erro de conexão ao vincular conversa');
  } finally {
    isSaving.value = false;
  }
};

const onCreateStage = async () => {
  const name = newStageName.value.trim();
  if (!name) return;
  isSavingStage.value = true;
  try {
    const res = await fetch(
      `/api/v1/accounts/${accountId.value}/crm/pipelines/${props.pipelineId}/stages`,
      {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify({ crm_stage: { name, show_value_sum: newStageShowValueSum.value } }),
      }
    );
    if (res.ok) {
      newStageName.value = '';
      newStageShowValueSum.value = false;
      showStageForm.value = false;
      await loadPipelineData();
      useAlert(`Estágio "${name}" criado!`);
    } else {
      const err = await res.json();
      useAlert(err?.errors?.name?.[0] || 'Erro ao criar estágio');
    }
  } catch {
    useAlert('Erro de conexão');
  } finally {
    isSavingStage.value = false;
  }
};

const cancelStageForm = () => {
  showStageForm.value = false;
  newStageName.value = '';
  newStageShowValueSum.value = false;
};

// ── Column drag (native) ──────────────────────────────────────
const dragOverColumnIndex = ref(null);

const onColumnDragStart = (e, stageId, index) => {
  // If a card drag is already in progress (dragstart bubbled up from DealCard),
  // don't also start a column drag.
  if (draggingDeal.value) return;
  draggingColumn.value = { id: stageId, fromIndex: index };
  e.dataTransfer.effectAllowed = 'move';
};

const onColumnDragOver = (e, index) => {
  if (!draggingColumn.value) return;
  e.preventDefault();
  dragOverColumnIndex.value = index;
};

const onColumnDragLeave = () => {
  dragOverColumnIndex.value = null;
};

const onColumnDrop = async (e, toIndex) => {
  e.preventDefault();
  dragOverColumnIndex.value = null;
  const drag = draggingColumn.value;
  draggingColumn.value = null;
  if (!drag || drag.fromIndex === toIndex) return;

  // Reorder stages array optimistically
  const reordered = [...stages.value];
  const [moved] = reordered.splice(drag.fromIndex, 1);
  reordered.splice(toIndex, 0, moved);
  stages.value = reordered;

  await reorderStages(reordered.map(s => s.id));
};

const onColumnDragEnd = () => {
  draggingColumn.value = null;
  dragOverColumnIndex.value = null;
};

onMounted(() => loadPipelineData());
</script>

<template>
  <div class="flex flex-col h-full">
    <!-- Toolbar -->
    <div class="flex items-center justify-between px-5 py-3 bg-n-background border-b border-n-weak flex-shrink-0">
      <div class="flex items-center gap-2">
        <i class="i-lucide-kanban size-4 text-n-slate-8" />
        <span class="text-sm text-n-slate-10">
          {{ stages.length }} estágio{{ stages.length !== 1 ? 's' : '' }}
          · {{ totalConversations }} conversa{{ totalConversations !== 1 ? 's' : '' }}
        </span>
        <span v-if="hasActiveFilters" class="text-xs text-n-brand font-medium">(filtrado)</span>
      </div>
      <div class="flex items-center gap-2">
        <Button size="sm" kind="secondary" :disabled="showStageForm" @click="showStageForm = true">
          <i class="i-lucide-columns-3 size-4" />
          Novo Estágio
        </Button>
        <Button size="sm" @click="linkModalRef?.open()">
          <i class="i-lucide-link size-4" />
          Vincular Conversa
        </Button>
      </div>
    </div>

    <!-- Date filter bar -->
    <div class="flex items-center gap-3 px-5 py-2 bg-n-background border-b border-n-weak flex-shrink-0">
      <i class="i-lucide-calendar size-3.5 text-n-slate-8" />
      <span class="text-xs text-n-slate-8">Filtrar por data:</span>
      <div class="flex items-center gap-1.5">
        <label class="text-xs text-n-slate-9">De</label>
        <input
          v-model="filterDateFrom"
          type="date"
          class="text-xs px-2 py-1 rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand/30"
        />
      </div>
      <div class="flex items-center gap-1.5">
        <label class="text-xs text-n-slate-9">Até</label>
        <input
          v-model="filterDateTo"
          type="date"
          class="text-xs px-2 py-1 rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand/30"
        />
      </div>
      <button
        v-if="hasActiveFilters"
        class="flex items-center gap-1 text-xs text-n-slate-9 hover:text-red-500 transition-colors"
        @click="clearFilters"
      >
        <i class="i-lucide-x size-3" />
        Limpar
      </button>
    </div>

    <!-- Board -->
    <div class="flex-1 overflow-x-auto p-4">
      <!-- Loading skeletons -->
      <div v-if="isLoading" class="flex gap-3 min-w-min h-full items-start">
        <div v-for="n in 3" :key="n" class="flex-shrink-0 w-[272px] rounded-xl border border-n-weak bg-n-slate-2 animate-pulse h-72" />
      </div>

      <!-- Empty state -->
      <div v-else-if="stages.length === 0 && !showStageForm" class="flex flex-col items-center justify-center w-full gap-3 text-n-slate-9 py-16">
        <i class="i-lucide-layout-columns size-12 text-n-slate-6" />
        <p class="text-sm font-medium text-n-slate-10">Nenhum estágio configurado</p>
        <p class="text-xs text-n-slate-8">Crie estágios para organizar suas conversas</p>
        <Button size="sm" @click="showStageForm = true">
          <i class="i-lucide-plus size-4" />
          Criar primeiro estágio
        </Button>
      </div>

      <!-- Columns -->
      <div v-else class="flex gap-3 min-w-min h-full items-start">
        <div
          v-for="(stage, index) in stages"
          :key="stage.id"
          class="transition-opacity duration-150"
          :class="{
            'opacity-40': draggingColumn?.id === stage.id,
            'ring-2 ring-n-brand/40 rounded-xl': dragOverColumnIndex === index && draggingColumn?.id !== stage.id,
          }"
          :draggable="true"
          @dragstart="e => onColumnDragStart(e, stage.id, index)"
          @dragover="e => onColumnDragOver(e, index)"
          @dragleave="onColumnDragLeave"
          @drop="e => onColumnDrop(e, index)"
          @dragend="onColumnDragEnd"
        >
          <KanbanColumn
            :stage="stage"
            :deals="stageDealMap[stage.id] || []"
            :is-loading="false"
            :show-value-sum="stage.show_value_sum"
            @deal-delete="onDealDelete"
            @deal-move="onDealMove"
            @deal-update-value="onDealUpdateValue"
          />
        </div>

        <!-- New stage form column -->
        <div
          v-if="showStageForm"
          class="flex-shrink-0 w-[272px] rounded-xl border-2 border-dashed border-n-brand/40 bg-n-brand/5 p-3"
        >
          <p class="text-xs font-semibold text-n-brand mb-2 uppercase tracking-wide">Novo Estágio</p>
          <input
            v-model="newStageName"
            type="text"
            placeholder="Ex: Novo Lead, Negociação..."
            class="w-full text-sm px-3 py-2 rounded-lg border border-n-weak bg-n-background text-n-slate-12 placeholder:text-n-slate-8 focus:outline-none focus:ring-2 focus:ring-n-brand/30 focus:border-n-brand mb-2"
            autofocus
            @keyup.enter="onCreateStage"
            @keyup.esc="cancelStageForm"
          />
          <label class="flex items-center gap-2 mb-2 cursor-pointer">
            <input v-model="newStageShowValueSum" type="checkbox" class="rounded border-n-weak text-n-brand focus:ring-n-brand/30" />
            <span class="text-xs text-n-slate-10">Mostrar soma de valores</span>
          </label>
          <div class="flex gap-2">
            <button
              class="flex-1 py-1.5 text-xs font-medium rounded-lg bg-n-brand text-white hover:bg-n-brand/90 transition-colors disabled:opacity-50"
              :disabled="!newStageName.trim() || isSavingStage"
              @click="onCreateStage"
            >
              <i v-if="isSavingStage" class="i-lucide-loader-2 size-3 animate-spin mr-1" />
              Criar
            </button>
            <button class="px-3 py-1.5 text-xs rounded-lg text-n-slate-9 hover:bg-n-slate-2 transition-colors" @click="cancelStageForm">
              Cancelar
            </button>
          </div>
        </div>
      </div>
    </div>

    <DealModal ref="linkModalRef" :stages="stages" @close="() => {}" @link="onLinkConversation" />
  </div>
</template>
