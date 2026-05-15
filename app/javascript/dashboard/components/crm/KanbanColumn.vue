<script setup>
import { ref, computed } from 'vue';
import DealCard from './DealCard.vue';
import { draggingDeal } from './useCrmDrag';

const props = defineProps({
  stage: { type: Object, required: true },
  deals: { type: Array, default: () => [] },
  isLoading: { type: Boolean, default: false },
  showValueSum: { type: Boolean, default: false },
});

const emit = defineEmits(['deal-delete', 'deal-move', 'deal-update-value']);

// ── Value sum ─────────────────────────────────────────────────
const totalValue = computed(() => {
  const sum = props.deals.reduce((acc, d) => acc + (parseFloat(d.value) || 0), 0);
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(sum);
});

const hasAnyValue = computed(() => props.deals.some(d => d.value != null && d.value > 0));

// ── Drop zone ─────────────────────────────────────────────────
const isDragOver = ref(false);

const onDragOver = e => {
  if (!draggingDeal.value) return;
  e.preventDefault();
  e.dataTransfer.dropEffect = 'move';
  isDragOver.value = true;
};

const onDragLeave = e => {
  // Only clear when leaving the column entirely (not just moving between children)
  if (!e.currentTarget.contains(e.relatedTarget)) {
    isDragOver.value = false;
  }
};

const onDrop = e => {
  e.preventDefault();
  isDragOver.value = false;
  const drag = draggingDeal.value;
  if (!drag) return;
  const toStageId = props.stage.id;
  if (drag.fromStageId !== toStageId) {
    emit('deal-move', { dealId: drag.id, toStageId });
  }
  draggingDeal.value = null;
};
</script>

<template>
  <div
    :data-stage-id="stage.id"
    class="column-drag-target flex-shrink-0 flex flex-col rounded-xl border transition-colors duration-150 bg-n-slate-1 min-w-[272px] max-w-[272px] max-h-full"
    :class="isDragOver ? 'border-n-brand/60 bg-n-brand/5' : 'border-n-weak'"
    @dragover="onDragOver"
    @dragleave="onDragLeave"
    @drop="onDrop"
  >
    <!-- Header -->
    <div class="px-3 py-2.5 border-b border-n-weak flex items-center gap-2 flex-shrink-0">
      <i class="column-drag-handle i-lucide-grip-vertical size-4 text-n-slate-6 cursor-grab active:cursor-grabbing flex-shrink-0" />
      <h3 class="text-sm font-semibold text-n-slate-11 truncate flex-1">{{ stage.name }}</h3>
      <span class="flex-shrink-0 text-xs font-medium bg-n-slate-3 text-n-slate-9 rounded-full px-2 py-0.5 min-w-[22px] text-center">
        {{ deals.length }}
      </span>
    </div>

    <!-- Cards area -->
    <div class="flex-1 overflow-y-auto p-2 min-h-[100px]">
      <!-- Loading -->
      <template v-if="isLoading">
        <div class="space-y-2">
          <div v-for="n in 3" :key="n" class="h-20 rounded-lg bg-n-slate-3 animate-pulse" />
        </div>
      </template>

      <!-- Empty -->
      <template v-else-if="deals.length === 0">
        <div class="h-full min-h-[80px] flex flex-col items-center justify-center gap-1 text-n-slate-8 rounded-lg border-2 border-dashed transition-colors"
          :class="isDragOver ? 'border-n-brand/40 bg-n-brand/5' : 'border-transparent'">
          <i class="i-lucide-inbox size-5" />
          <p class="text-xs">{{ isDragOver ? 'Soltar aqui' : 'Arraste conversas aqui' }}</p>
        </div>
      </template>

      <!-- Cards -->
      <template v-else>
        <DealCard
          v-for="deal in deals"
          :key="deal.id"
          :deal="deal"
          :stage-id="stage.id"
          @delete="id => emit('deal-delete', id)"
          @update-value="payload => emit('deal-update-value', payload)"
        />
      </template>
    </div>

    <!-- Value sum footer — shows when stage has show_value_sum OR any deal has a value -->
    <div
      v-if="showValueSum || hasAnyValue"
      class="px-3 py-2 border-t border-n-weak bg-n-slate-2 rounded-b-xl flex-shrink-0 flex items-center justify-between"
    >
      <span class="text-[11px] text-n-slate-8">Total vendas</span>
      <span class="text-xs font-semibold text-n-slate-11">{{ totalValue }}</span>
    </div>
  </div>
</template>
