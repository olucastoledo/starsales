<script setup>
import { ref, computed, watch } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

const props = defineProps({
  stages: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['close', 'link']);

const currentUser = useMapGetter('getCurrentUser');
const accountId = useMapGetter('getCurrentAccountId');

// State
const isOpen = ref(false);
const search = ref('');
const conversations = ref([]);
const isFetching = ref(false);
const isLinking = ref(false);
const selectedStageId = ref('');
const selectedConversationId = ref(null);
const error = ref('');

const getAuthHeaders = () => ({
  api_access_token: currentUser.value?.access_token,
});

const channelIcon = type => {
  const icons = {
    'Channel::Whatsapp': 'i-lucide-smartphone',
    'Channel::Instagram': 'i-lucide-camera',
    'Channel::Email': 'i-lucide-mail',
    'Channel::FacebookPage': 'i-lucide-thumbs-up',
    'Channel::Sms': 'i-lucide-message-square',
    'Channel::TwilioSms': 'i-lucide-message-square',
  };
  return icons[type] || 'i-lucide-message-circle';
};

const statusLabel = status => {
  const map = { open: 'Aberto', pending: 'Pendente', resolved: 'Resolvido', snoozed: 'Adiado' };
  return map[status] || status;
};

const canConfirm = computed(
  () => selectedConversationId.value && selectedStageId.value && !isLinking.value
);

const fetchConversations = async () => {
  isFetching.value = true;
  try {
    const q = search.value.trim();
    const url = q
      ? `/api/v1/accounts/${accountId.value}/conversations?q=${encodeURIComponent(q)}&page=1`
      : `/api/v1/accounts/${accountId.value}/conversations?page=1`;

    const res = await fetch(url, { headers: getAuthHeaders() });
    if (!res.ok) throw new Error('Failed to fetch');
    const data = await res.json();
    conversations.value = data?.data?.payload || data?.payload || [];
  } catch {
    conversations.value = [];
  } finally {
    isFetching.value = false;
  }
};

let debounceTimer = null;
watch(search, () => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(fetchConversations, 300);
});

const open = () => {
  search.value = '';
  selectedConversationId.value = null;
  selectedStageId.value = props.stages[0]?.id ? String(props.stages[0].id) : '';
  error.value = '';
  isOpen.value = true;
  fetchConversations();
};

const close = () => {
  isOpen.value = false;
  emit('close');
};

const onConfirm = async () => {
  if (!canConfirm.value) return;
  isLinking.value = true;
  error.value = '';
  try {
    emit('link', {
      conversationId: selectedConversationId.value,
      stageId: Number(selectedStageId.value),
    });
  } finally {
    isLinking.value = false;
  }
};

const closeAfterLink = () => {
  isOpen.value = false;
};

const initials = name => {
  if (!name) return '?';
  return name.split(' ').slice(0, 2).map(n => n[0]).join('').toUpperCase();
};

defineExpose({ open, closeAfterLink });
</script>

<template>
  <!-- Native modal overlay -->
  <Teleport to="body">
    <div
      v-if="isOpen"
      class="fixed inset-0 z-50 flex items-center justify-center"
    >
      <!-- Backdrop -->
      <div
        class="absolute inset-0 bg-black/40 backdrop-blur-sm"
        @click="close"
      />

      <!-- Panel -->
      <div class="relative z-10 w-full max-w-lg mx-4 bg-n-background rounded-xl shadow-2xl border border-n-weak flex flex-col max-h-[90vh]">
        <!-- Header -->
        <div class="flex items-center justify-between px-5 py-4 border-b border-n-weak flex-shrink-0">
          <h2 class="text-base font-semibold text-n-slate-12">Vincular Conversa ao Pipeline</h2>
          <button
            class="p-1 rounded-md text-n-slate-9 hover:text-n-slate-12 hover:bg-n-slate-2 transition-colors"
            @click="close"
          >
            <i class="i-lucide-x size-4" />
          </button>
        </div>

        <!-- Body -->
        <div class="flex-1 overflow-y-auto px-5 py-4 space-y-4">
          <!-- Stage selector -->
          <div>
            <label class="block text-sm font-medium text-n-slate-11 mb-1.5">Estágio de destino</label>
            <select
              v-model="selectedStageId"
              class="w-full text-sm px-3 py-2 rounded-lg border border-n-weak bg-n-background text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand/30 focus:border-n-brand"
            >
              <option value="" disabled>Selecione um estágio</option>
              <option v-for="stage in stages" :key="stage.id" :value="String(stage.id)">
                {{ stage.name }}
              </option>
            </select>
          </div>

          <!-- Search -->
          <div>
            <label class="block text-sm font-medium text-n-slate-11 mb-1.5">Buscar conversa</label>
            <div class="relative">
              <i class="i-lucide-search size-4 absolute left-3 top-1/2 -translate-y-1/2 text-n-slate-8" />
              <input
                v-model="search"
                type="text"
                placeholder="Nome do contato, canal..."
                class="w-full text-sm pl-9 pr-3 py-2 rounded-lg border border-n-weak bg-n-background text-n-slate-12 placeholder:text-n-slate-8 focus:outline-none focus:ring-2 focus:ring-n-brand/30 focus:border-n-brand"
              />
            </div>
          </div>

          <!-- Conversation list -->
          <div class="rounded-lg border border-n-weak overflow-hidden">
            <div v-if="isFetching" class="p-6 flex items-center justify-center gap-2 text-n-slate-9">
              <i class="i-lucide-loader-2 size-4 animate-spin" />
              <span class="text-sm">Carregando conversas...</span>
            </div>

            <div
              v-else-if="conversations.length === 0"
              class="p-6 text-center text-sm text-n-slate-8"
            >
              <i class="i-lucide-inbox size-8 text-n-slate-7 block mx-auto mb-2" />
              Nenhuma conversa encontrada
            </div>

            <div v-else class="divide-y divide-n-weak/60 max-h-60 overflow-y-auto">
              <button
                v-for="conv in conversations"
                :key="conv.id"
                class="w-full flex items-center gap-3 px-4 py-3 text-left hover:bg-n-slate-2 transition-colors"
                :class="selectedConversationId === conv.id
                  ? 'bg-n-brand/5 border-l-2 border-n-brand pl-3.5'
                  : ''"
                @click="selectedConversationId = conv.id"
              >
                <div
                  class="flex-shrink-0 size-8 rounded-full bg-n-brand/10 text-n-brand text-xs font-bold flex items-center justify-center"
                >
                  {{ initials(conv.meta?.sender?.name) }}
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-medium text-n-slate-12 truncate">
                    {{ conv.meta?.sender?.name || 'Contato desconhecido' }}
                  </p>
                  <p class="text-xs text-n-slate-9 truncate">
                    #{{ conv.id }} · {{ statusLabel(conv.status) }}
                  </p>
                </div>
                <i
                  v-if="selectedConversationId === conv.id"
                  class="flex-shrink-0 i-lucide-check-circle-2 size-4 text-n-brand"
                />
              </button>
            </div>
          </div>

          <p v-if="error" class="text-xs text-red-600">{{ error }}</p>
        </div>

        <!-- Footer -->
        <div class="flex items-center justify-end gap-2 px-5 py-3 border-t border-n-weak bg-n-slate-1 rounded-b-xl flex-shrink-0">
          <button
            class="px-4 py-1.5 text-sm rounded-lg text-n-slate-11 hover:bg-n-slate-2 transition-colors"
            @click="close"
          >
            Cancelar
          </button>
          <button
            class="px-4 py-1.5 text-sm font-medium rounded-lg transition-colors"
            :class="canConfirm
              ? 'bg-n-brand text-white hover:bg-n-brand/90'
              : 'bg-n-slate-3 text-n-slate-8 cursor-not-allowed'"
            :disabled="!canConfirm"
            @click="onConfirm"
          >
            <i v-if="isLinking" class="i-lucide-loader-2 size-4 animate-spin mr-1.5" />
            Vincular
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>
