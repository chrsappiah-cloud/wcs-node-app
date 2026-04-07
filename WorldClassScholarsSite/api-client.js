/**
 * World Class Scholars API Client Library
 * Simple helper functions to interact with the backend API
 */

const API_BASE_URL = 'http://localhost:3000/v1';

class WCSApiClient {
  constructor() {
    this.token = null;
    this.baseUrl = API_BASE_URL;
  }

  /**
   * Initialize the client and get an auth token
   */
  async init() {
    try {
      const response = await fetch(`${this.baseUrl}/auth/token`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      });

      if (!response.ok) throw new Error('Failed to get token');

      const data = await response.json();
      this.token = data.token;
      console.log('✅ API Client initialized with token');
      return this.token;
    } catch (error) {
      console.error('❌ Failed to initialize API client:', error);
      return null;
    }
  }

  /**
   * Generate images using the backend API
   * @param {object} options - Generation options
   * @param {string} options.prompt - Image prompt
   * @param {string} options.style - Style (realistic, artistic, cartoon, sketch)
   * @param {number} options.quantity - Number of images (1-4)
   */
  async generateImages(options) {
    if (!this.token) {
      console.error('❌ Not authenticated. Call init() first.');
      return null;
    }

    try {
      const payload = {
        prompt: options.prompt || '',
      };
      if (options.imageBase64) {
        payload.imageBase64 = options.imageBase64;
        if (options.mimeType) payload.mimeType = options.mimeType;
      }

      const response = await fetch(
        `${this.baseUrl}/media-support/image/analyze`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${this.token}`,
          },
          body: JSON.stringify(payload),
        },
      );

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Image generation failed');
      }

      const data = await response.json();
      console.log('✅ Images generated successfully');
      return data;
    } catch (error) {
      console.error('❌ Image generation error:', error);
      return null;
    }
  }

  /**
   * Get cached images
   * @param {string} key - Cache key (prompt:style)
   */
  async getCachedImages(key) {
    if (!this.token) {
      console.error('❌ Not authenticated. Call init() first.');
      return null;
    }

    try {
      const response = await fetch(`${this.baseUrl}/images/cache/${key}`, {
        headers: { Authorization: `Bearer ${this.token}` },
      });

      if (!response.ok) throw new Error('Cache miss');

      const data = await response.json();
      console.log('✅ Retrieved cached images');
      return data;
    } catch (error) {
      console.error('❌ Cache retrieval error:', error);
      return null;
    }
  }

  /**
   * Clear image cache (admin)
   */
  async clearCache() {
    if (!this.token) {
      console.error('❌ Not authenticated. Call init() first.');
      return false;
    }

    try {
      const response = await fetch(`${this.baseUrl}/images/cache`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${this.token}` },
      });

      if (!response.ok) throw new Error('Failed to clear cache');

      console.log('✅ Cache cleared');
      return true;
    } catch (error) {
      console.error('❌ Cache clear error:', error);
      return false;
    }
  }
}

// Export for use in HTML
window.WCSApiClient = WCSApiClient;
