/* global axios */
import ApiClient from './ApiClient';

class AiAgentsAPI extends ApiClient {
  constructor() {
    super('ai_agents', { accountScoped: true });
  }

  getAgents() {
    return axios.get(this.url);
  }

  getAgent(id) {
    return axios.get(`${this.url}/${id}`);
  }

  create(data) {
    return axios.post(this.url, data);
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}`, data);
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }

  // Tools API
  getTools(agentId) {
    return axios.get(`${this.url}/${agentId}/ai_agent_tools`);
  }

  getTool(agentId, toolId) {
    return axios.get(`${this.url}/${agentId}/ai_agent_tools/${toolId}`);
  }

  createTool(agentId, data) {
    return axios.post(`${this.url}/${agentId}/ai_agent_tools`, data);
  }

  updateTool(agentId, toolId, data) {
    return axios.patch(`${this.url}/${agentId}/ai_agent_tools/${toolId}`, data);
  }

  deleteTool(agentId, toolId) {
    return axios.delete(`${this.url}/${agentId}/ai_agent_tools/${toolId}`);
  }
}

export default new AiAgentsAPI();
