import { ref } from 'vue';

// Shared drag state — single source of truth across all columns
export const draggingDeal = ref(null);   // { id, fromStageId }
export const draggingColumn = ref(null); // { id, fromIndex }
