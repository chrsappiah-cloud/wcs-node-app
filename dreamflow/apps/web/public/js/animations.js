/**
 * 🎬 Healing Arts - Animation Engine
 * 
 * GSAP-like vanilla JavaScript animation library
 * Handles smooth transitions, micro-interactions, and scroll effects
 * Optimized for production performance
 */

class AnimationEngine {
  constructor() {
    this.animations = new Map();
    this.observerOptions = {
      threshold: 0.2,
      rootMargin: '0px 0px -50px 0px'
    };
    this.init();
  }

  init() {
    this.setupIntersectionObserver();
    this.setupCardInteractions();
    this.setupScrollEffects();
  }

  /**
   * Intersection Observer for scroll-triggered animations
   */
  setupIntersectionObserver() {
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          this.revealElement(entry.target);
          observer.unobserve(entry.target);
        }
      });
    }, this.observerOptions);

    // Observe all fade-in-up elements
    document.querySelectorAll('.fade-in-up').forEach(el => {
      observer.observe(el);
    });
  }

  /**
   * Reveal elements with staggered animation
   */
  revealElement(element) {
    element.style.animation = 'fadeInUp 0.8s ease-out forwards';
  }

  /**
   * Card hover interactions
   */
  setupCardInteractions() {
    const cards = document.querySelectorAll('.card, .expertise-card, .project-card');

    cards.forEach((card, index) => {
      card.addEventListener('mouseenter', (e) => this.onCardHover(e));
      card.addEventListener('mousemove', (e) => this.onCardMove(e));
      card.addEventListener('mouseleave', (e) => this.onCardLeave(e));

      // Add stagger delay
      if (!card.style.animationDelay) {
        card.style.animationDelay = `${index * 0.1}s`;
      }
    });
  }

  /**
   * 3D tilt effect on hover
   */
  onCardMove(event) {
    const card = event.currentTarget;
    const rect = card.getBoundingClientRect();
    const centerX = rect.width / 2;
    const centerY = rect.height / 2;

    const mouseX = event.clientX - rect.left;
    const mouseY = event.clientY - rect.top;

    const rotateX = ((mouseY - centerY) / centerY) * -12;
    const rotateY = ((mouseX - centerX) / centerX) * 12;

    // Subtle 3D effect
    card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) scale(1.02)`;
  }

  /**
   * Card hover enter
   */
  onCardHover(event) {
    const card = event.currentTarget;
    card.style.transition = 'all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94)';
  }

  /**
   * Card hover leave
   */
  onCardLeave(event) {
    const card = event.currentTarget;
    card.style.transform = 'perspective(1000px) rotateX(0) rotateY(0) scale(1)';
  }

  /**
   * Parallax scroll effects
   */
  setupScrollEffects() {
    window.addEventListener('scroll', () => this.onScroll(), { passive: true });
  }

  onScroll() {
    const scrolled = window.scrollY;

    // Parallax for hero section
    const hero = document.querySelector('.hero-content');
    if (hero) {
      hero.style.transform = `translateY(${scrolled * 0.4}px)`;
    }

    // Subtle fade for hero
    const heroSection = document.querySelector('.hero');
    if (heroSection) {
      const heroHeight = heroSection.offsetHeight;
      const opacity = Math.max(0, 1 - scrolled / (heroHeight * 0.8));
      heroSection.style.opacity = opacity;
    }
  }

  /**
   * Utility: Animate value from A to B
   */
  static animate(from, to, duration, callback, easing = 'easeOutCubic') {
    const startTime = performance.now();
    const distance = to - from;

    const easeOutCubic = (t) => 1 - Math.pow(1 - t, 3);
    const easeInOutQuad = (t) => t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
    const easeOutQuad = (t) => t * (2 - t);

    const easingFunctions = {
      easeOutCubic,
      easeInOutQuad,
      easeOutQuad,
    };

    const easeFn = easingFunctions[easing] || easeOutCubic;

    const animate = (currentTime) => {
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const easedProgress = easeFn(progress);
      const current = from + distance * easedProgress;

      callback(current);

      if (progress < 1) {
        requestAnimationFrame(animate);
      }
    };

    requestAnimationFrame(animate);
  }

  /**
   * Button ripple effect
   */
  static setupButtonRipple() {
    document.querySelectorAll('.cta-btn').forEach(button => {
      button.addEventListener('click', (e) => {
        const ripple = document.createElement('span');
        const rect = button.getBoundingClientRect();
        const size = Math.max(rect.width, rect.height);
        const x = e.clientX - rect.left - size / 2;
        const y = e.clientY - rect.top - size / 2;

        ripple.style.cssText = `
          position: absolute;
          width: ${size}px;
          height: ${size}px;
          left: ${x}px;
          top: ${y}px;
          background: rgba(255, 255, 255, 0.6);
          border-radius: 50%;
          animation: ripple 0.6s ease-out;
        `;

        button.style.position = 'relative';
        button.style.overflow = 'hidden';
        button.appendChild(ripple);

        setTimeout(() => ripple.remove(), 600);
      });
    });
  }
}

/**
 * Smooth scroll behavior for anchor links
 */
class SmoothScroll {
  constructor() {
    this.init();
  }

  init() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
      anchor.addEventListener('click', (e) => {
        e.preventDefault();
        const target = document.querySelector(anchor.getAttribute('href'));
        if (target) {
          target.scrollIntoView({ behavior: 'smooth' });
        }
      });
    });
  }
}

/**
 * Keyboard navigation accessibility
 */
class KeyboardNav {
  constructor() {
    this.init();
  }

  init() {
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        // Close any open modals/menus
        document.querySelectorAll('[data-modal]').forEach(el => {
          el.style.display = 'none';
        });
      }

      // Tab navigation
      if (e.key === 'Tab') {
        this.updateFocusStyles();
      }
    });
  }

  updateFocusStyles() {
    document.addEventListener('focus', (e) => {
      if (e.target.matches('a, button')) {
        e.target.style.outline = '2px solid var(--primary)';
        e.target.style.outlineOffset = '4px';
      }
    }, true);
  }
}

/**
 * Prefers reduced motion support
 */
class MotionPreferences {
  static prefersReducedMotion() {
    return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  }

  static disableAnimationsIfNeeded() {
    if (this.prefersReducedMotion()) {
      document.documentElement.style.setProperty('--transition', 'none');
      document.documentElement.style.setProperty('--transition-slow', 'none');
      document.querySelectorAll('[style*="animation"]').forEach(el => {
        el.style.animation = 'none';
      });
    }
  }
}

/**
 * Page Performance Monitor
 */
class PerformanceMonitor {
  static logMetrics() {
    if ('PerformanceLongTaskTiming' in window) {
      const observer = new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
          console.warn('⚠️ Long task detected:', entry.duration);
        }
      });
      observer.observe({ entryTypes: ['longtask'] });
    }

    // Log INP (Interaction to Next Paint)
    if ('PerformanceEventTiming' in window) {
      document.addEventListener('pointerup', () => {
        const perfData = performance.getEntriesByType('navigation')[0];
        if (perfData) {
          console.log('Page Load Metrics:', {
            FCP: perfData.responseEnd,
            LCP: performance.getEntriesByName('largest-contentful-paint')[0]?.renderTime,
            FID: performance.getEntriesByType('first-input')[0]?.processingDuration,
          });
        }
      });
    }
  }
}

/**
 * Initialize all animations on load
 */
document.addEventListener('DOMContentLoaded', () => {
  // Check motion preferences
  MotionPreferences.disableAnimationsIfNeeded();

  // Initialize animation engine
  const animationEngine = new AnimationEngine();

  // Setup smooth scroll
  new SmoothScroll();

  // Setup keyboard navigation
  new KeyboardNav();

  // Setup button ripples
  AnimationEngine.setupButtonRipple();

  // Log performance
  PerformanceMonitor.logMetrics();

  // Add page visibility listener
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
      console.log('📉 Page hidden - reducing animations');
    } else {
      console.log('📈 Page visible - resuming animations');
    }
  });
});

/**
 * Podcast Integration - Dynamic RSS Feed Loading
 */
class PodcastManager {
  constructor() {
    this.episodesContainer = document.getElementById('episodes-container');
    this.podcastTitle = document.getElementById('podcast-title');
    this.podcastDescription = document.getElementById('podcast-description');
    this.podcastLink = document.getElementById('podcast-link');
    this.podcastCover = document.getElementById('podcast-cover');
  }

  async loadPodcastData() {
    try {
      const response = await fetch('/podcast');
      const data = await response.json();

      if (data.error) {
        console.warn('Using fallback podcast data:', data.error);
        this.displayPodcastData(data.fallback);
      } else {
        this.displayPodcastData(data);
      }
    } catch (error) {
      console.error('Failed to load podcast data:', error);
      this.showError('Failed to load podcast episodes');
    }
  }

  displayPodcastData(data) {
    // Update podcast header
    if (this.podcastTitle) this.podcastTitle.textContent = data.title;
    if (this.podcastDescription) this.podcastDescription.textContent = data.description;
    if (this.podcastLink) this.podcastLink.href = data.link;
    if (this.podcastCover) this.podcastCover.src = data.image;

    // Clear loading state
    if (this.episodesContainer) {
      this.episodesContainer.innerHTML = '';

      if (data.episodes && data.episodes.length > 0) {
        data.episodes.forEach((episode, index) => {
          const episodeCard = this.createEpisodeCard(episode, index);
          this.episodesContainer.appendChild(episodeCard);
        });
      } else {
        this.episodesContainer.innerHTML = '<div class="episode-placeholder">No episodes available at this time</div>';
      }
    }
  }

  createEpisodeCard(episode, index) {
    const card = document.createElement('div');
    card.className = 'episode-card fade-in-up';
    card.style.animationDelay = `${index * 0.1}s`;

    const pubDate = episode.pubDate ? new Date(episode.pubDate).toLocaleDateString() : 'Unknown date';
    const duration = episode.duration || 'Unknown duration';

    card.innerHTML = `
      <div class="episode-header">
        <h4 class="episode-title">${episode.title}</h4>
        <div class="episode-meta">
          <span class="episode-date">📅 ${pubDate}</span>
          <span class="episode-duration">⏱️ ${duration}</span>
        </div>
      </div>
      <p class="episode-description">${episode.description || 'No description available'}</p>
      <a href="${episode.link}" target="_blank" class="episode-link">
        <span>🎧 Listen Now</span>
      </a>
    `;

    return card;
  }

  showError(message) {
    if (this.episodesContainer) {
      this.episodesContainer.innerHTML = `<div class="episode-error">${message}</div>`;
    }
  }
}

// Initialize podcast manager when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  const podcastManager = new PodcastManager();
  podcastManager.loadPodcastData();
});

// Expose animation utilities globally
window.AnimationEngine = AnimationEngine;
