<script setup>
import { ref, computed, onMounted } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { picoSearch } from '@scmmishra/pico-search';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import AiAgentModal from './components/AiAgentModal.vue';
import AiAgentReportConfigs from './components/AiAgentReportConfigs.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

const MODAL_TYPES = {
  CREATE: 'create',
  EDIT: 'edit',
};

const activeTab = ref('agents'); // 'agents' | 'reports'

const store = useStore();
const { t } = useI18n();

const aiAgents = useMapGetter('aiAgents/getAgents');
const uiFlags = useMapGetter('aiAgents/getUIFlags');

const selectedAgent = ref({});
const searchQuery = ref('');
const loading = ref({});
const modalType = ref(MODAL_TYPES.CREATE);
const aiAgentModalRef = ref(null);
const aiAgentDeleteDialogRef = ref(null);

const tableHeaders = computed(() => {
  return [
    t('AI_AGENTS.LIST.TABLE_HEADER.NAME'),
    t('AI_AGENTS.LIST.TABLE_HEADER.PERSONALITY'),
    t('AI_AGENTS.LIST.TABLE_HEADER.MODEL'),
    t('AI_AGENTS.LIST.TABLE_HEADER.STATUS'),
    t('AI_AGENTS.LIST.TABLE_HEADER.ACTIONS'),
  ];
});

const selectedAgentName = computed(() => selectedAgent.value?.name || '');

const filteredAiAgents = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return aiAgents.value;
  return picoSearch(aiAgents.value, query, ['name', 'description', 'personality']);
});

const openAddModal = () => {
  modalType.value = MODAL_TYPES.CREATE;
  selectedAgent.value = {};
  aiAgentModalRef.value.dialogRef.open();
};

const openEditModal = agent => {
  modalType.value = MODAL_TYPES.EDIT;
  selectedAgent.value = agent;
  aiAgentModalRef.value.dialogRef.open();
};

const openDeletePopup = agent => {
  selectedAgent.value = agent;
  aiAgentDeleteDialogRef.value.open();
};

const deleteAiAgent = async id => {
  try {
    await store.dispatch('aiAgents/delete', id);
    useAlert(t('AI_AGENTS.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(t('AI_AGENTS.DELETE.API.ERROR_MESSAGE'));
  } finally {
    loading.value[id] = false;
    selectedAgent.value = {};
  }
};

const confirmDeletion = () => {
  loading.value[selectedAgent.value.id] = true;
  deleteAiAgent(selectedAgent.value.id);
  aiAgentDeleteDialogRef.value.close();
};

onMounted(() => {
  store.dispatch('aiAgents/fetch');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching && activeTab === 'agents'"
    :loading-message="t('AI_AGENTS.LIST.LOADING')"
    :no-records-found="activeTab === 'agents' && !aiAgents.length"
    :no-records-message="t('AI_AGENTS.LIST.404')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="t('AI_AGENTS.HEADER')"
        :description="t('AI_AGENTS.DESCRIPTION')"
        :search-placeholder="activeTab === 'agents' ? t('AI_AGENTS.SEARCH_PLACEHOLDER') : ''"
      >
        <template v-if="activeTab === 'agents' && aiAgents?.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ $t('AI_AGENTS.COUNT', { n: aiAgents.length }) }}
          </span>
        </template>
        <template #actions>
          <div class="flex items-center gap-2">
            <!-- Tab switcher -->
            <div class="flex rounded-lg border border-n-weak overflow-hidden">
              <button
                class="px-3 py-1.5 text-xs font-medium transition-colors"
                :class="activeTab === 'agents'
                  ? 'bg-n-brand text-white'
                  : 'bg-n-background text-n-slate-9 hover:bg-n-slate-2'"
                @click="activeTab = 'agents'"
              >
                <i class="i-lucide-bot size-3.5 mr-1" />Agentes
              </button>
              <button
                class="px-3 py-1.5 text-xs font-medium transition-colors"
                :class="activeTab === 'reports'
                  ? 'bg-n-brand text-white'
                  : 'bg-n-background text-n-slate-9 hover:bg-n-slate-2'"
                @click="activeTab = 'reports'"
              >
                <i class="i-lucide-file-chart-column size-3.5 mr-1" />Relatórios
              </button>
            </div>
            <Button
              v-if="activeTab === 'agents'"
              :label="$t('AI_AGENTS.ADD.TITLE')"
              size="sm"
              @click="openAddModal"
            />
          </div>
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <!-- Reports tab -->
      <AiAgentReportConfigs v-if="activeTab === 'reports'" />

      <!-- Agents tab -->
      <BaseTable v-if="activeTab === 'agents'"
        :headers="tableHeaders"
        :items="filteredAiAgents"
        :no-data-message="
          searchQuery ? t('AI_AGENTS.NO_RESULTS') : t('AI_AGENTS.LIST.404')
        "
      >
        <template #row="{ items }">
          <BaseTableRow v-for="agent in items" :key="agent.id" :item="agent">
            <template #default>
              <BaseTableCell class="max-w-0">
                <div class="min-w-0">
                  <div class="text-body-main text-n-slate-12 truncate">
                    {{ agent.name }}
                  </div>
                  <div class="text-body-main text-n-slate-11 block truncate">
                    {{ agent.description }}
                  </div>
                </div>
              </BaseTableCell>

              <BaseTableCell class="max-w-0">
                <span class="text-body-main text-n-slate-11 truncate block">
                  {{ agent.personality || '-' }}
                </span>
              </BaseTableCell>

              <BaseTableCell class="max-w-0">
                <span class="text-body-main text-n-slate-11 truncate block">
                  {{ agent.model || 'gpt-4' }}
                </span>
              </BaseTableCell>

              <BaseTableCell class="max-w-0">
                <span
                  :class="
                    agent.enabled
                      ? 'px-2 py-1 text-xs font-medium text-n-emerald-11 bg-n-emerald-2 rounded'
                      : 'px-2 py-1 text-xs font-medium text-n-amber-11 bg-n-amber-2 rounded'
                  "
                >
                  {{
                    agent.enabled
                      ? $t('AI_AGENTS.STATUS.ENABLED')
                      : $t('AI_AGENTS.STATUS.DISABLED')
                  }}
                </span>
              </BaseTableCell>

              <BaseTableCell align="end" class="w-24">
                <div class="flex gap-3 justify-end flex-shrink-0">
                  <Button
                    v-tooltip.top="t('AI_AGENTS.EDIT.BUTTON_TEXT')"
                    icon="i-woot-edit-pen"
                    slate
                    sm
                    :is-loading="loading[agent.id]"
                    @click="openEditModal(agent)"
                  />
                  <Button
                    v-tooltip.top="t('AI_AGENTS.DELETE.BUTTON_TEXT')"
                    icon="i-woot-bin"
                    slate
                    sm
                    class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
                    :is-loading="loading[agent.id]"
                    @click="openDeletePopup(agent)"
                  />
                </div>
              </BaseTableCell>
            </template>
          </BaseTableRow>
        </template>
      </BaseTable>
    </template>

    <AiAgentModal
      ref="aiAgentModalRef"
      :type="modalType"
      :selected-agent="selectedAgent"
    />

    <Dialog
      ref="aiAgentDeleteDialogRef"
      type="alert"
      :title="t('AI_AGENTS.DELETE.CONFIRM.TITLE')"
      :description="
        t('AI_AGENTS.DELETE.CONFIRM.MESSAGE', { name: selectedAgentName })
      "
      :is-loading="uiFlags.isDeleting"
      :confirm-button-label="t('AI_AGENTS.DELETE.CONFIRM.YES')"
      :cancel-button-label="t('AI_AGENTS.DELETE.CONFIRM.NO')"
      @confirm="confirmDeletion"
    />
  </SettingsLayout>
</template>
