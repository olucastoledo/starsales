import { FEATURE_FLAGS } from '../../../../featureFlags';
import Index from './Index.vue';
import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/ai-agents'),
      meta: {
        permissions: ['administrator'],
      },
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'ai_agents',
          component: Index,
          meta: {
            featureFlag: FEATURE_FLAGS.AI_AGENTS,
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
