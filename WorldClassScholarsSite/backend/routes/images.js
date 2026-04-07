const express = require('express');
const axios = require('axios');
const NodeCache = require('node-cache');
const config = require('../config/environment');
const { authMiddleware } = require('../middleware/auth');
const { imageGenerationLimiter } = require('../middleware/rateLimiter');
const {
  validateImageGeneration,
  handleValidationErrors,
} = require('../middleware/validation');

const router = express.Router();
const imageCache = new NodeCache({ stdTTL: config.imageGeneration.cacheTtl });

/**
 * Generate images using OpenAI DALL-E
 * POST /api/images/generate
 */
router.post(
  '/generate',
  authMiddleware,
  imageGenerationLimiter,
  validateImageGeneration,
  handleValidationErrors,
  async (req, res) => {
    try {
      const { prompt, style = 'realistic', quantity = 1 } = req.body;

      // Check cache first
      const cacheKey = `${prompt}:${style}`;
      const cached = imageCache.get(cacheKey);
      if (cached) {
        return res.json({
          success: true,
          message: 'Image retrieved from cache',
          images: cached,
          cached: true,
        });
      }

      // Generate image with OpenAI
      const enhancedPrompt = `${prompt}. Style: ${style}. High quality, detailed, professional.`;

      // DALL-E 3 specific configuration
      const requestBody = {
        model: config.imageGeneration.model,
        prompt: enhancedPrompt,
        size: config.imageGeneration.size,
        n: 1, // DALL-E 3 only supports n=1
      };

      const response = await axios.post(
        'https://api.openai.com/v1/images/generations',
        requestBody,
        {
          headers: {
            Authorization: `Bearer ${config.openai.apiKey}`,
            'Content-Type': 'application/json',
          },
        },
      );

      const images = response.data.data.map((img) => ({
        url: img.url,
        alt: prompt,
        generated_at: new Date().toISOString(),
      }));

      // Cache the result
      imageCache.set(cacheKey, images);

      res.json({
        success: true,
        message: 'Images generated successfully',
        images,
        cached: false,
      });
    } catch (error) {
      console.error(
        'Image generation error:',
        error.response?.data || error.message,
      );

      if (error.response?.status === 429) {
        return res
          .status(429)
          .json({ error: 'OpenAI rate limit exceeded. Try again later.' });
      }

      res.status(500).json({
        error: 'Failed to generate images',
        message: config.isDevelopment ? error.message : 'Internal server error',
      });
    }
  },
);

/**
 * Get cached image
 * GET /api/images/cache/:key
 */
router.get('/cache/:key', authMiddleware, (req, res) => {
  try {
    const cached = imageCache.get(req.params.key);
    if (!cached) {
      return res.status(404).json({ error: 'Image not found in cache' });
    }

    res.json({
      success: true,
      images: cached,
      cached_at: new Date().toISOString(),
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to retrieve cached image' });
  }
});

/**
 * Clear cache (admin only)
 * DELETE /api/images/cache
 */
router.delete('/cache', authMiddleware, (req, res) => {
  try {
    // In production, verify admin role here
    imageCache.flushAll();
    res.json({
      success: true,
      message: 'Image cache cleared',
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to clear cache' });
  }
});

module.exports = router;
