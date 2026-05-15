<script setup>
import { ref, computed, reactive, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { required, helpers } from '@vuelidate/validators';
import { useVuelidate } from '@vuelidate/core';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Select from 'dashboard/components-next/select/Select.vue';

const props = defineProps({
  type: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
  selectedAgent: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['close']);

const MODAL_TYPES = {
  CREATE: 'create',
  EDIT: 'edit',
};

const MODELS = [
  { value: 'gpt-4', label: 'GPT-4' },
  { value: 'gpt-4-turbo', label: 'GPT-4 Turbo' },
  { value: 'gpt-3.5-turbo', label: 'GPT-3.5 Turbo' },
];

const PERSONALITIES = [
  { value: 'sales', label: 'Sales' },
  { value: 'support', label: 'Support' },
  { value: 'billing', label: 'Billing' },
  { value: 'technical', label: 'Technical' },
  { value: 'custom', label: 'Custom' },
];

const store = useStore();
const { t } = useI18n();
const dialogRef = ref(null);
const uiFlags = useMapGetter('aiAgents/getUIFlags');

const formState = reactive({
  name: '',
  description: '',
  personality: '',
  systemPrompt: '',
  temperature: 0.7,
  model: 'gpt-4',
  enabled: true,
  debounceDelay: 5,
  contextWindow: 50,
});

const v$ = useVuelidate(
  {
    name: {
      required: helpers.withMessage(
        () => t('AI_AGENTS.FORM.ERRORS.NAME'),
        required
      ),
    },
    systemPrompt: {
      required: helpers.withMessage(
        () => t('AI_AGENTS.FORM.ERRORS.SYSTEM_PROMPT'),
        required
      ),
    },
  },
  formState
);

const isLoading = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? uiFlags.value.isCreating
    : uiFlags.value.isUpdating
);

const dialogTitle = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? t('AI_AGENTS.ADD.TITLE')
    : t('AI_AGENTS.EDIT.TITLE')
);

const confirmButtonLabel = computed(() =>
  props.type === MODAL_TYPES.CREATE
    ? t('AI_AGENTS.FORM.CREATE')
    : t('AI_AGENTS.FORM.UPDATE')
);

const nameError = computed(() =>
  v$.value.name.$error ? v$.value.name.$errors[0]?.$message : ''
);

const systemPromptError = computed(() =>
  v$.value.systemPrompt.$error
    ? v$.value.systemPrompt.$errors[0]?.$message
    : ''
);

const resetForm = () => {
  Object.assign(formState, {
    name: '',
    description: '',
    personality: '',
    systemPrompt: '',
    temperature: 0.7,
    model: 'gpt-4',
    enabled: true,
    debounceDelay: 5,
    contextWindow: 50,
  });
  v$.value.$reset();
};

const populateForm = () => {
  if (props.type === MODAL_TYPES.EDIT && props.selectedAgent?.id) {
    formState.name = props.selectedAgent.name || '';
    formState.description = props.selectedAgent.description || '';
    formState.personality = props.selectedAgent.personality || '';
    formState.systemPrompt = props.selectedAgent.system_prompt || '';
    formState.temperature = props.selectedAgent.temperature || 0.7;
    formState.model = props.selectedAgent.model || 'gpt-4';
    formState.enabled = props.selectedAgent.enabled !== false;
    formState.debounceDelay = props.selectedAgent.debounce_delay_seconds ?? 5;
    formState.contextWindow = props.selectedAgent.context_window_messages ?? 50;
  }
};

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  const payload = {
    name: formState.name,
    description: formState.description,
    personality: formState.personality,
    system_prompt: formState.systemPrompt,
    temperature: formState.temperature,
    model: formState.model,
    enabled: formState.enabled,
    debounce_delay_seconds: formState.debounceDelay,
    context_window_messages: formState.contextWindow,
  };

  try {
    if (props.type === MODAL_TYPES.CREATE) {
      await store.dispatch('aiAgents/create', payload);
      useAlert(t('AI_AGENTS.CREATE.API.SUCCESS_MESSAGE'));
    } else {
      await store.dispatch('aiAgents/update', {
        id: props.selectedAgent.id,
        data: payload,
      });
      useAlert(t('AI_AGENTS.UPDATE.API.SUCCESS_MESSAGE'));
    }
    resetForm();
    dialogRef.value.close();
  } catch (error) {
    const errorMessage =
      props.type === MODAL_TYPES.CREATE
        ? t('AI_AGENTS.CREATE.API.ERROR_MESSAGE')
        : t('AI_AGENTS.UPDATE.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

watch(
  () => props.selectedAgent,
  () => {
    if (props.type === MODAL_TYPES.EDIT) {
      populateForm();
    }
  },
  { deep: true }
);

defineExpose({
  dialogRef,
});
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="dialogTitle"
    :is-loading="isLoading"
    :confirm-button-label="confirmButtonLabel"
    @confirm="handleSubmit"
    @close-modal="resetForm"
  >
    <form class="space-y-4">
      <Input
        v-model="formState.name"
        :label="$t('AI_AGENTS.FORM.NAME')"
        :placeholder="$t('AI_AGENTS.FORM.NAME_PLACEHOLDER')"
        :error="nameError"
        @blur="v$.name.$touch"
      />

      <TextArea
        v-model="formState.description"
        :label="$t('AI_AGENTS.FORM.DESCRIPTION')"
        :placeholder="$t('AI_AGENTS.FORM.DESCRIPTION_PLACEHOLDER')"
      />

      <div>
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ $t('AI_AGENTS.FORM.PERSONALITY') }}
        </label>
        <Select
          v-model="formState.personality"
          :options="PERSONALITIES"
          :placeholder="$t('AI_AGENTS.FORM.PERSONALITY_PLACEHOLDER')"
        />
      </div>

      <TextArea
        v-model="formState.systemPrompt"
        :label="$t('AI_AGENTS.FORM.SYSTEM_PROMPT')"
        :placeholder="$t('AI_AGENTS.FORM.SYSTEM_PROMPT_PLACEHOLDER')"
        :error="systemPromptError"
        @blur="v$.systemPrompt.$touch"
      />

      <div class="grid grid-cols-2 gap-4">
        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ $t('AI_AGENTS.FORM.MODEL') }}
          </label>
          <Select
            v-model="formState.model"
            :options="MODELS"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ $t('AI_AGENTS.FORM.TEMPERATURE') }}
          </label>
          <input
            v-model.number="formState.temperature"
            type="range"
            min="0"
            max="1"
            step="0.1"
            class="w-full"
          />
          <div class="text-xs text-n-slate-11 mt-1">
            {{ formState.temperature.toFixed(1) }}
          </div>
        </div>
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div>
          <Input
            v-model.number="formState.debounceDelay"
            type="number"
            :label="$t('AI_AGENTS.FORM.DEBOUNCE_DELAY')"
            :placeholder="'5'"
            :message="$t('AI_AGENTS.FORM.DEBOUNCE_DELAY_HINT')"
            min="1"
            max="60"
          />
        </div>
        <div>
          <Input
            v-model.number="formState.contextWindow"
            type="number"
            :label="$t('AI_AGENTS.FORM.CONTEXT_WINDOW')"
            :placeholder="'50'"
            :message="$t('AI_AGENTS.FORM.CONTEXT_WINDOW_HINT')"
            min="5"
            max="200"
          />
        </div>
      </div>

      <div class="flex items-center justify-between p-3 bg-n-slate-2 rounded-lg">
        <label class="text-sm font-medium text-n-slate-12">
          {{ $t('AI_AGENTS.FORM.ENABLED') }}
        </label>
        <input
          v-model="formState.enabled"
          type="checkbox"
          class="w-4 h-4 accent-n-blue-9"
        />
      </div>
    </form>
  </Dialog>
</template>
