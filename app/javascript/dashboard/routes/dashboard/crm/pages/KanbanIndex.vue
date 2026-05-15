<script setup>
import { ref, computed, onMounted } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import KanbanBoard from 'dashboard/components/crm/KanbanBoard.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const currentUser = useMapGetter('getCurrentUser');
const accountId = useMapGetter('getCurrentAccountId');
const inboxes = useMapGetter('inboxes/getInboxes');

const pipelines = ref([]);
const selectedPipelineId = ref(null);
const isLoading = ref(true);

// Create pipeline form
const showCreateForm = ref(false);
const newPipelineName = ref('');
const isSavingPipeline = ref(false);

// Inbox assignment panel
const showInboxPanel = ref(false);
const isSavingInboxes = ref(false);
const pendingInboxIds = ref([]);

const selectedPipeline = computed(() =>
  pipelines.value.find(p => p.id === selectedPipelineId.value)
);

const getAuthHeaders = () => ({
  api_access_token: currentUser.value?.access_token,
  'Content-Type': 'application/json',
});

const loadPipelines = async () => {
  isLoading.value = true;
  try {
    const res = await fetch(
      `/api/v1/accounts/${accountId.value}/crm/pipelines`,
      { headers: getAuthHeaders() }
    );
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();
    pipelines.value = Array.isArray(data) ? data : [];
    if (pipelines.value.length > 0 && !selectedPipelineId.value) {
      selectedPipelineId.value = pipelines.value[0].id;
    }
  } catch (e) {
    useAlert(`Erro ao carregar pipelines: ${e.message}`);
  } finally {
    isLoading.value = false;
  }
};

const onCreatePipeline = async () => {
  const name = newPipelineName.value.trim();
  if (!name) return;
  isSavingPipeline.value = true;
  try {
    const res = await fetch(
      `/api/v1/accounts/${accountId.value}/crm/pipelines`,
      {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify({ crm_pipeline: { name } }),
      }
    );
    if (res.ok) {
      const created = await res.json();
      pipelines.value.push(created);
      selectedPipelineId.value = created.id;
      newPipelineName.value = '';
      showCreateForm.value = false;
      useAlert(`Pipeline "${name}" criado!`);
    } else {
      const err = await res.json();
      useAlert(err?.errors?.name?.[0] || 'Erro ao criar pipeline');
    }
  } catch {
    useAlert('Erro de conexão');
  } finally {
    isSavingPipeline.value = false;
  }
};

const openInboxPanel = () => {
  pendingInboxIds.value = [...(selectedPipeline.value?.assigned_inbox_ids || [])];
  showInboxPanel.value = true;
};

const toggleInbox = id => {
  const idx = pendingInboxIds.value.indexOf(id);
  if (idx === -1) pendingInboxIds.value.push(id);
  else pendingInboxIds.value.splice(idx, 1);
};

const saveInboxAssignment = async () => {
  if (!selectedPipelineId.value) return;
  isSavingInboxes.value = true;
  try {
    const res = await fetch(
      `/api/v1/accounts/${accountId.value}/crm/pipelines/${selectedPipelineId.value}/assign_inboxes`,
      {
        method: 'PATCH',
        headers: getAuthHeaders(),
        body: JSON.stringify({ inbox_ids: pendingInboxIds.value }),
      }
    );
    if (res.ok) {
      const data = await res.json();
      // update local state
      const pipeline = pipelines.value.find(p => p.id === selectedPipelineId.value);
      if (pipeline) pipeline.assigned_inbox_ids = data.assigned_inbox_ids;
      showInboxPanel.value = false;
      useAlert('Configuração salva! Novas conversas serão adicionadas automaticamente.');
    } else {
      useAlert('Erro ao salvar configuração');
    }
  } catch {
    useAlert('Erro de conexão');
  } finally {
    isSavingInboxes.value = false;
  }
};

const channelIcon = type => {
  const icons = {
    'Channel::Whatsapp': 'i-lucide-smartphone',
    'Channel::Instagram': 'i-lucide-camera',
    'Channel::Email': 'i-lucide-mail',
    'Channel::FacebookPage': 'i-lucide-thumbs-up',
    'Channel::WebWidget': 'i-lucide-globe',
    'Channel::Sms': 'i-lucide-message-square',
  };
  return icons[type] || 'i-lucide-inbox';
};

onMounted(() => {
  loadPipelines();
});
</script>

<template>
  <div class="flex h-full bg-n-background overflow-hidden">
    <!-- Pipeline sidebar -->
    <aside class="w-56 flex-shrink-0 border-r border-n-weak flex flex-col bg-n-background">
      <div class="px-3 pt-4 pb-2 flex items-center justify-between">
        <h2 class="text-xs font-semibold uppercase tracking-wider text-n-slate-8">
          Pipelines
        </h2>
        <button
          class="p-1 rounded-md text-n-slate-9 hover:text-n-brand hover:bg-n-brand/10 transition-colors"
          title="Novo Pipeline"
          @click="showCreateForm = !showCreateForm"
        >
          <i class="i-lucide-plus size-4" />
        </button>
      </div>

      <!-- Create form (inline) -->
      <div v-if="showCreateForm" class="px-3 pb-3 space-y-2">
        <input
          v-model="newPipelineName"
          type="text"
          placeholder="Nome do pipeline..."
          class="w-full text-xs px-2.5 py-1.5 rounded-lg border border-n-weak bg-n-background text-n-slate-12 placeholder:text-n-slate-8 focus:outline-none focus:ring-2 focus:ring-n-brand/30"
          autofocus
          @keyup.enter="onCreatePipeline"
          @keyup.esc="showCreateForm = false; newPipelineName = ''"
        />
        <div class="flex gap-1.5">
          <button
            class="flex-1 py-1 text-xs font-medium rounded-md bg-n-brand text-white hover:bg-n-brand/90 disabled:opacity-50 transition-colors"
            :disabled="!newPipelineName.trim() || isSavingPipeline"
            @click="onCreatePipeline"
          >
            <i v-if="isSavingPipeline" class="i-lucide-loader-2 size-3 animate-spin" />
            Criar
          </button>
          <button
            class="px-2 py-1 text-xs rounded-md text-n-slate-9 hover:bg-n-slate-2 transition-colors"
            @click="showCreateForm = false; newPipelineName = ''"
          >
            ✕
          </button>
        </div>
      </div>

      <!-- Pipeline list -->
      <nav class="flex-1 overflow-y-auto px-2 pb-4">
        <template v-if="isLoading">
          <div class="space-y-1 mt-1">
            <div v-for="n in 3" :key="n" class="h-8 rounded-lg bg-n-slate-3 animate-pulse" />
          </div>
        </template>

        <template v-else-if="pipelines.length === 0 && !showCreateForm">
          <div class="mt-6 flex flex-col items-center gap-3 text-center px-2">
            <i class="i-lucide-layout-columns size-8 text-n-slate-6" />
            <p class="text-xs text-n-slate-8 leading-snug">Nenhum pipeline ainda</p>
            <Button size="xs" kind="secondary" @click="showCreateForm = true">
              Criar pipeline
            </Button>
          </div>
        </template>

        <template v-else>
          <button
            v-for="pipeline in pipelines"
            :key="pipeline.id"
            class="w-full flex items-center gap-2 px-2 py-1.5 rounded-lg text-sm transition-colors mb-0.5"
            :class="selectedPipelineId === pipeline.id
              ? 'bg-n-brand/10 text-n-brand font-semibold'
              : 'text-n-slate-11 hover:bg-n-slate-2'"
            @click="selectedPipelineId = pipeline.id; showInboxPanel = false"
          >
            <i
              class="i-lucide-columns-3 size-4 flex-shrink-0"
              :class="selectedPipelineId === pipeline.id ? 'text-n-brand' : 'text-n-slate-8'"
            />
            <span class="truncate flex-1 text-left">{{ pipeline.name }}</span>
            <!-- Inbox count badge -->
            <span
              v-if="(pipeline.assigned_inbox_ids || []).length > 0"
              class="text-[10px] bg-n-brand/20 text-n-brand rounded-full px-1.5 py-px font-medium"
              :title="`${pipeline.assigned_inbox_ids.length} inbox(es) vinculado(s)`"
            >
              {{ pipeline.assigned_inbox_ids.length }}
            </span>
          </button>
        </template>
      </nav>
    </aside>

    <!-- Main content -->
    <main class="flex-1 flex flex-col min-w-0 overflow-hidden">
      <template v-if="selectedPipeline">
        <!-- Pipeline header -->
        <div class="px-5 pt-3 pb-0 border-b border-n-weak flex-shrink-0 flex items-center justify-between">
          <div>
            <h1 class="text-sm font-semibold text-n-slate-12">
              {{ selectedPipeline.name }}
            </h1>
            <p class="text-xs text-n-slate-8 mt-0.5 mb-2">
              <span v-if="(selectedPipeline.assigned_inbox_ids || []).length > 0">
                <i class="i-lucide-zap size-3 text-n-brand inline" />
                {{ selectedPipeline.assigned_inbox_ids.length }} inbox(es) com entrada automática
              </span>
              <span v-else class="text-n-slate-7">Sem entrada automática configurada</span>
            </p>
          </div>
          <button
            class="flex items-center gap-1.5 text-xs text-n-slate-9 hover:text-n-brand mb-2 transition-colors"
            @click="openInboxPanel"
          >
            <i class="i-lucide-settings-2 size-3.5" />
            Configurar entradas
          </button>
        </div>

        <div class="flex-1 overflow-hidden">
          <KanbanBoard
            :key="`pipeline-${selectedPipelineId}`"
            :pipeline-id="selectedPipelineId"
          />
        </div>
      </template>

      <template v-else>
        <div class="flex flex-col items-center justify-center flex-1 gap-4">
          <i class="i-lucide-kanban size-12 text-n-slate-6" />
          <div class="text-center">
            <p class="text-sm font-medium text-n-slate-10">Nenhum pipeline selecionado</p>
            <p class="text-xs text-n-slate-8 mt-1">Selecione ou crie um pipeline</p>
          </div>
          <Button kind="secondary" @click="showCreateForm = true">
            <i class="i-lucide-plus size-4" />
            Criar Pipeline
          </Button>
        </div>
      </template>
    </main>

    <!-- Inbox assignment panel (slide-in) -->
    <Teleport to="body">
      <div v-if="showInboxPanel" class="fixed inset-0 z-40 flex justify-end">
        <div class="absolute inset-0 bg-black/30" @click="showInboxPanel = false" />
        <div class="relative z-10 w-80 bg-n-background border-l border-n-weak flex flex-col shadow-2xl">
          <div class="flex items-center justify-between px-5 py-4 border-b border-n-weak">
            <div>
              <h3 class="text-sm font-semibold text-n-slate-12">Entradas Automáticas</h3>
              <p class="text-xs text-n-slate-8 mt-0.5">{{ selectedPipeline?.name }}</p>
            </div>
            <button
              class="p-1 rounded-md text-n-slate-9 hover:bg-n-slate-2 transition-colors"
              @click="showInboxPanel = false"
            >
              <i class="i-lucide-x size-4" />
            </button>
          </div>

          <div class="flex-1 overflow-y-auto px-4 py-4">
            <p class="text-xs text-n-slate-8 mb-4 leading-relaxed">
              Selecione quais canais alimentam este pipeline automaticamente — como o CRM da Meta Business.
              Toda nova conversa nesses canais vai direto para o primeiro estágio.
            </p>

            <div v-if="inboxes.length === 0" class="text-center py-8 text-sm text-n-slate-8">
              Nenhum canal configurado
            </div>

            <div v-else class="space-y-2">
              <label
                v-for="inbox in inboxes"
                :key="inbox.id"
                class="flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-colors"
                :class="pendingInboxIds.includes(inbox.id)
                  ? 'border-n-brand/40 bg-n-brand/5'
                  : 'border-n-weak hover:bg-n-slate-2'"
              >
                <input
                  type="checkbox"
                  class="sr-only"
                  :checked="pendingInboxIds.includes(inbox.id)"
                  @change="toggleInbox(inbox.id)"
                />
                <div
                  class="size-5 rounded border flex-shrink-0 flex items-center justify-center transition-colors"
                  :class="pendingInboxIds.includes(inbox.id)
                    ? 'bg-n-brand border-n-brand'
                    : 'border-n-weak bg-n-background'"
                >
                  <i
                    v-if="pendingInboxIds.includes(inbox.id)"
                    class="i-lucide-check size-3 text-white"
                  />
                </div>
                <div class="flex items-center gap-2 flex-1 min-w-0">
                  <i :class="[channelIcon(inbox.channel_type), 'size-4 text-n-slate-8 flex-shrink-0']" />
                  <div class="min-w-0">
                    <p class="text-sm font-medium text-n-slate-12 truncate">{{ inbox.name }}</p>
                    <p class="text-xs text-n-slate-8 truncate">{{ inbox.channel_type?.replace('Channel::', '') }}</p>
                  </div>
                </div>
              </label>
            </div>
          </div>

          <div class="px-4 py-3 border-t border-n-weak flex gap-2">
            <button
              class="flex-1 py-2 text-sm rounded-lg text-n-slate-9 hover:bg-n-slate-2 transition-colors"
              @click="showInboxPanel = false"
            >
              Cancelar
            </button>
            <button
              class="flex-1 py-2 text-sm font-medium rounded-lg bg-n-brand text-white hover:bg-n-brand/90 disabled:opacity-50 transition-colors"
              :disabled="isSavingInboxes"
              @click="saveInboxAssignment"
            >
              <i v-if="isSavingInboxes" class="i-lucide-loader-2 size-4 animate-spin mr-1" />
              Salvar
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
