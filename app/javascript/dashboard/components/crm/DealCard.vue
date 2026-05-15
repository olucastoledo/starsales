<script setup>
import { computed, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { draggingDeal } from './useCrmDrag';

const props = defineProps({
  deal: { type: Object, required: true },
  stageId: { type: [Number, String], required: true },
});

const emit = defineEmits(['delete', 'update-value']);

const router = useRouter();
const accountId = useMapGetter('getCurrentAccountId');

// ── Navigation ───────────────────────────────────────────────
const goToConversation = () => {
  if (!props.deal.conversation_id) return;
  router.push({
    name: 'inbox_conversation',
    params: { conversation_id: props.deal.conversation_id },
  });
};

// ── Channel icon ──────────────────────────────────────────────
const channelIcon = computed(() => {
  const type = props.deal.channel_type;
  if (type === 'Channel::Whatsapp') return 'i-lucide-smartphone';
  if (type === 'Channel::Instagram') return 'i-lucide-camera';
  if (type === 'Channel::Email') return 'i-lucide-mail';
  if (type === 'Channel::FacebookPage') return 'i-lucide-thumbs-up';
  if (type === 'Channel::Sms' || type === 'Channel::TwilioSms') return 'i-lucide-message-square';
  return 'i-lucide-message-circle';
});

// ── Status badge ──────────────────────────────────────────────
const statusConfig = computed(() => {
  switch (props.deal.conversation_status) {
    case 'open': return { label: 'Aberto', cls: 'text-green-700 bg-green-50 border-green-200' };
    case 'pending': return { label: 'Pendente', cls: 'text-yellow-700 bg-yellow-50 border-yellow-200' };
    case 'resolved': return { label: 'Resolvido', cls: 'text-slate-600 bg-slate-100 border-slate-200' };
    case 'snoozed': return { label: 'Adiado', cls: 'text-purple-700 bg-purple-50 border-purple-200' };
    default: return null;
  }
});

// ── Time ago ──────────────────────────────────────────────────
const timeAgo = computed(() => {
  if (!props.deal.last_activity_at) return '';
  const diff = Math.floor((Date.now() - new Date(props.deal.last_activity_at)) / 1000);
  if (diff < 60) return 'agora';
  if (diff < 3600) return `${Math.floor(diff / 60)}m`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h`;
  return `${Math.floor(diff / 86400)}d`;
});

// ── Initials ──────────────────────────────────────────────────
const initials = computed(() =>
  (props.deal.contact_name || '?')
    .split(' ').slice(0, 2).map(n => n[0]).join('').toUpperCase()
);

// ── Value inline edit ─────────────────────────────────────────
const editingValue = ref(false);
const valueInput = ref('');

const formattedValue = computed(() => {
  if (props.deal.value == null) return null;
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(props.deal.value);
});

const startEditValue = e => {
  e.stopPropagation();
  valueInput.value = props.deal.value ?? '';
  editingValue.value = true;
};

const confirmEditValue = e => {
  e?.stopPropagation();
  const parsed = parseFloat(String(valueInput.value).replace(',', '.')) || null;
  emit('update-value', { dealId: props.deal.id, value: parsed });
  editingValue.value = false;
};

const cancelEditValue = e => { e?.stopPropagation(); editingValue.value = false; };

// ── Delete ────────────────────────────────────────────────────
const onDelete = e => { e.stopPropagation(); emit('delete', props.deal.id); };

// ── Native drag ───────────────────────────────────────────────
const isDragging = ref(false);

const onDragStart = e => {
  isDragging.value = true;
  draggingDeal.value = { id: props.deal.id, fromStageId: props.stageId };
  e.dataTransfer.effectAllowed = 'move';
  // Tiny delay so the ghost snapshot is captured before we hide the source
  setTimeout(() => { isDragging.value = true; }, 0);
};

const onDragEnd = () => {
  isDragging.value = false;
  draggingDeal.value = null;
};
</script>

<template>
  <div
    draggable="true"
    class="group relative p-3 mb-2 rounded-lg bg-white border border-n-weak hover:border-n-brand/40 hover:shadow-sm transition-all duration-150 select-none"
    :class="{ 'opacity-40': isDragging }"
    @click="goToConversation"
    @dragstart="onDragStart"
    @dragend="onDragEnd"
  >
    <!-- Unread dot -->
    <div
      v-if="deal.unread_count > 0"
      class="absolute top-3 right-3 size-2 rounded-full bg-n-brand"
    />

    <!-- Header: avatar + name + time -->
    <div class="flex items-start gap-2.5">
      <div v-if="deal.contact_avatar" class="flex-shrink-0 size-8 rounded-full overflow-hidden">
        <img :src="deal.contact_avatar" class="size-full object-cover" />
      </div>
      <div v-else class="flex-shrink-0 size-8 rounded-full bg-n-brand/10 text-n-brand text-xs font-bold flex items-center justify-center">
        {{ initials }}
      </div>
      <div class="flex-1 min-w-0 pr-4">
        <p class="text-sm font-semibold text-n-slate-12 truncate leading-tight">
          {{ deal.contact_name || 'Sem contato' }}
        </p>
        <div class="flex items-center gap-1 mt-0.5">
          <i :class="[channelIcon, 'size-3 text-n-slate-9 flex-shrink-0']" />
          <span class="text-xs text-n-slate-9 truncate">{{ deal.inbox_name }}</span>
        </div>
      </div>
      <span class="flex-shrink-0 text-xs text-n-slate-8 mt-0.5">{{ timeAgo }}</span>
    </div>

    <!-- Footer: status + value + remove -->
    <div class="flex items-center justify-between mt-2.5 pt-2 border-t border-n-weak/60">
      <span
        v-if="statusConfig"
        class="text-[10px] font-medium px-1.5 py-0.5 rounded border flex-shrink-0"
        :class="statusConfig.cls"
      >
        {{ statusConfig.label }}
      </span>
      <span v-else class="flex-shrink-0" />

      <!-- Inline value editor -->
      <div class="flex-1 flex justify-center px-1">
        <form v-if="editingValue" class="flex gap-0.5" @submit.prevent="confirmEditValue">
          <input
            v-model="valueInput"
            type="text"
            inputmode="decimal"
            placeholder="0,00"
            class="w-20 text-[10px] px-1.5 py-0.5 rounded border border-n-brand/40 bg-n-background text-n-slate-12 focus:outline-none"
            autofocus
            @keyup.esc="cancelEditValue"
            @click.stop
          />
          <button type="submit" class="p-0.5 rounded text-green-600 hover:bg-green-50" @click.stop="confirmEditValue">
            <i class="i-lucide-check size-3" />
          </button>
          <button type="button" class="p-0.5 rounded text-n-slate-7 hover:bg-n-slate-2" @click.stop="cancelEditValue">
            <i class="i-lucide-x size-3" />
          </button>
        </form>
        <button
          v-else
          class="text-[10px] text-n-slate-8 hover:text-n-brand transition-colors truncate max-w-[80px]"
          :title="formattedValue ? 'Editar valor' : 'Adicionar valor'"
          @click.stop="startEditValue"
        >
          {{ formattedValue ?? '+ valor' }}
        </button>
      </div>

      <button
        class="opacity-0 group-hover:opacity-100 flex-shrink-0 p-0.5 rounded text-n-slate-8 hover:text-red-600 hover:bg-red-50 transition-all"
        title="Remover do pipeline"
        @click.stop="onDelete"
      >
        <i class="i-lucide-x size-3.5" />
      </button>
    </div>
  </div>
</template>
