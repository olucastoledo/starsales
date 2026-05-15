import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import AiAgentsAPI from '../../api/aiAgents';
import { throwErrorMessage } from '../utils/api';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getAgents($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getAgent: $state => id => {
    const [agent] = $state.records.filter(record => record.id === Number(id));
    return agent || {};
  },
};

export const actions = {
  fetch: async ({ commit }) => {
    commit(types.SET_AI_AGENT_UI_FLAG, { isFetching: true });
    try {
      const response = await AiAgentsAPI.getAgents();
      commit(types.SET_AI_AGENTS, response.data);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_AI_AGENT_UI_FLAG, { isFetching: false });
    }
  },

  create: async ({ commit }, agentData) => {
    commit(types.SET_AI_AGENT_UI_FLAG, { isCreating: true });
    try {
      const response = await AiAgentsAPI.create({ ai_agent: agentData });
      commit(types.ADD_AI_AGENT, response.data);
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_AI_AGENT_UI_FLAG, { isCreating: false });
    }
    return null;
  },

  update: async ({ commit }, { id, data }) => {
    commit(types.SET_AI_AGENT_UI_FLAG, { isUpdating: true });
    try {
      const response = await AiAgentsAPI.update(id, { ai_agent: data });
      commit(types.EDIT_AI_AGENT, response.data);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_AI_AGENT_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, id) => {
    commit(types.SET_AI_AGENT_UI_FLAG, { isDeleting: true });
    try {
      await AiAgentsAPI.delete(id);
      commit(types.DELETE_AI_AGENT, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_AI_AGENT_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_AI_AGENT_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.ADD_AI_AGENT]: MutationHelpers.setSingleRecord,
  [types.SET_AI_AGENTS]: MutationHelpers.set,
  [types.EDIT_AI_AGENT]: MutationHelpers.update,
  [types.DELETE_AI_AGENT]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
