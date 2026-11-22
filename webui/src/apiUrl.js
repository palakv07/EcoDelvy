const apiUrl = (process.env.REACT_APP_API_URL || 'http://localhost:8000').replace(/\/+$/, '');
const apiKey = process.env.REACT_APP_API_KEY;

export const apiAuthHeaders = apiKey ? { 'api-key': apiKey } : {};

export default apiUrl;
