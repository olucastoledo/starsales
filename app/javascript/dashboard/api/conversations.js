/* global axios */
import ApiClient from './ApiClient';

class ConversationApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  getLabels(conversationID) {
    return axios.get(`${this.url}/${conversationID}/labels`);
  }

  updateLabels(conversationID, labels) {
    return axios.post(`${this.url}/${conversationID}/labels`, { labels });
  }

  assignAiAgent(conversationID, aiAgentId) {
    return axios.post(`${this.url}/${conversationID}/assign_ai_agent`, {
      ai_agent_id: aiAgentId,
    });
  }

  unassignAiAgent(conversationID) {
    return axios.post(`${this.url}/${conversationID}/assign_ai_agent`, {
      ai_agent_id: null,
    });
  }
}

export default new ConversationApi();
