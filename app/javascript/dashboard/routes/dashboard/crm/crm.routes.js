import { frontendURL } from '../../../helper/URLHelper';
import KanbanIndex from './pages/KanbanIndex.vue';

const meta = {
  permissions: ['administrator', 'agent'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/crm'),
    component: KanbanIndex,
    name: 'crm_kanban_index',
    meta,
  },
];
