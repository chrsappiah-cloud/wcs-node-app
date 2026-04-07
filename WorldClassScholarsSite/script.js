document.addEventListener('DOMContentLoaded', function () {
  const heroButton = document.querySelector('.primary-button');
  if (!heroButton) {
    return;
  }

  heroButton.addEventListener('click', function (event) {
    event.preventDefault();
    const contactSection = document.querySelector('#contact');
    if (contactSection) {
      contactSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  });

  // Initialize image generator
  initializeImageGenerator();
});

/**
 * Initialize the image generation functionality
 */
function initializeImageGenerator() {
  const generateBtn = document.getElementById('generateBtn');
  const promptInput = document.getElementById('imagePrompt');
  const styleSelect = document.getElementById('imageStyle');
  const statusDiv = document.getElementById('generationStatus');
  const imagesGrid = document.getElementById('generatedImages');
  const imageUpload = document.getElementById('imageUpload');

  if (!generateBtn) return;

  // Initialize API client
  const apiClient = new WCSApiClient();

  generateBtn.addEventListener('click', async function () {
    const prompt = promptInput.value.trim();
    const style = styleSelect.value;
    const file = imageUpload.files && imageUpload.files[0];

    if (!prompt && !file) {
      showStatus(
        'Please enter an image description or upload an image',
        'error',
      );
      promptInput.focus();
      return;
    }

    // Disable button and show loading
    generateBtn.disabled = true;
    generateBtn.textContent = 'Generating...';
    showStatus('Generating your image...', 'info');

    try {
      // Initialize API client if needed
      if (!apiClient.token) {
        showStatus('Connecting to API...', 'info');
        const token = await apiClient.init();
        if (!token) {
          throw new Error('Failed to authenticate with API');
        }
      }

      let imageBase64 = null;
      let mimeType = null;
      if (file) {
        mimeType = file.type;
        imageBase64 = await toBase64(file);
      }

      // Generate image
      const result = await apiClient.generateImages({
        prompt: prompt,
        style: style,
        quantity: 1,
        imageBase64: imageBase64,
        mimeType: mimeType,
      });

      if (result && result.success) {
        showStatus('Image generated successfully!', 'success');
        displayGeneratedImage(result.images[0], prompt, style);
      } else {
        throw new Error(result?.message || 'Image generation failed');
      }
    } catch (error) {
      console.error('Image generation error:', error);
      showStatus(`Error: ${error.message}`, 'error');
    } finally {
      // Re-enable button
      generateBtn.disabled = false;
      generateBtn.textContent = 'Generate Image';
    }
  });

  function toBase64(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result.split(',')[1]);
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  }

  /**
   * Show status message
   */
  function showStatus(message, type) {
    statusDiv.textContent = message;
    statusDiv.className = `status-message ${type}`;
  }

  /**
   * Display generated image
   */
  function displayGeneratedImage(image, prompt, style) {
    const imageCard = document.createElement('div');
    imageCard.className = 'generated-image';

    imageCard.innerHTML = `
      <img src="${image.url}" alt="${image.alt}" onerror="this.src='data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 width=%22200%22 height=%22200%22%3E%3Crect fill=%22%23e0f2fe%22 width=%22200%22 height=%22200%22/%3E%3Ctext x=%2250%25%22 y=%2250%25%22 text-anchor=%22middle%22 dy=%22.3em%22 fill=%22%230c4a6e%22 font-family=%22sans-serif%22 font-size=%2214px%22%3EImage%20Generated%3C/text%3E%3C/svg%3E'">
      <div class="generated-meta">
        <p><strong>Prompt:</strong> ${prompt}</p>
        <p><strong>Style:</strong> ${style}</p>
        <p><strong>Generated:</strong> ${new Date(image.generated_at).toLocaleString()}</p>
      </div>
    `;

    // Clear previous images and add new one
    imagesGrid.innerHTML = '';
    imagesGrid.appendChild(imageCard);
  }

  // Add enter key support for prompt input
  promptInput.addEventListener('keypress', function (e) {
    if (e.key === 'Enter' && !generateBtn.disabled) {
      generateBtn.click();
    }
  });
}
