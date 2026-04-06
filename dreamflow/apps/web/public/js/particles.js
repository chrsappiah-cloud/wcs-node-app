/**
 * 🎨 Healing Arts - Canvas Particle System
 * 
 * Therapeutic particle animation system inspired by healing arts therapy
 * Creates flowing, organic motion patterns for dementia care interfaces
 * 
 * Performance: ~60 FPS @ 1920x1080, ~120 particles
 */

class ParticleSystem {
  constructor(canvasId = 'canvas-bg') {
    this.canvas = document.getElementById(canvasId);
    this.ctx = this.canvas.getContext('2d', { alpha: true });
    this.particles = [];
    this.particleCount = this.calculateParticleCount();
    this.time = 0;

    this.init();
    this.setupEventListeners();
  }

  calculateParticleCount() {
    const width = window.innerWidth;
    const height = window.innerHeight;
    const area = width * height;
    // ~0.00005 particles per pixel for balanced performance
    return Math.floor(area * 0.00005);
  }

  init() {
    this.resizeCanvas();
    this.createParticles();
    this.animate();
  }

  resizeCanvas() {
    this.canvas.width = window.innerWidth;
    this.canvas.height = window.innerHeight;
  }

  createParticles() {
    this.particles = [];
    const colors = [
      'hsl(270, 70%, 60%)',  // Primary purple
      'hsl(160, 70%, 60%)',  // Accent green
      'hsl(200, 70%, 60%)',  // Teal
      'hsl(280, 70%, 60%)',  // Indigo
    ];

    for (let i = 0; i < this.particleCount; i++) {
      this.particles.push({
        x: Math.random() * this.canvas.width,
        y: Math.random() * this.canvas.height,
        vx: (Math.random() - 0.5) * 0.8,
        vy: (Math.random() - 0.5) * 0.8,
        ax: (Math.random() - 0.5) * 0.01,
        ay: (Math.random() - 0.5) * 0.01,
        radius: Math.random() * 2 + 0.5,
        baseRadius: Math.random() * 2 + 0.5,
        color: colors[Math.floor(Math.random() * colors.length)],
        opacity: Math.random() * 0.6 + 0.4,
        baseOpacity: Math.random() * 0.6 + 0.4,
        life: 1,
        maxLife: Math.random() * 200 + 100,
        pulse: Math.random() * Math.PI * 2,
      });
    }
  }

  setupEventListeners() {
    window.addEventListener('resize', () => this.onWindowResize(), false);
  }

  onWindowResize() {
    const oldWidth = this.canvas.width;
    const oldHeight = this.canvas.height;
    
    this.resizeCanvas();
    
    // Adjust particles for new viewport
    const particles = this.particles;
    particles.forEach(p => {
      p.x = (p.x / oldWidth) * this.canvas.width;
      p.y = (p.y / oldHeight) * this.canvas.height;
    });
  }

  updateParticles() {
    const width = this.canvas.width;
    const height = this.canvas.height;

    this.particles.forEach(p => {
      // Update velocity with acceleration
      p.vx += p.ax;
      p.vy += p.ay;

      // Apply drag
      p.vx *= 0.99;
      p.vy *= 0.99;

      // Update position
      p.x += p.vx;
      p.y += p.vy;

      // Wrap around edges (therapeutic flow effect)
      if (p.x < 0) p.x = width;
      if (p.x > width) p.x = 0;
      if (p.y < 0) p.y = height;
      if (p.y > height) p.y = 0;

      // Gently redirect particles toward center (healing attraction)
      const centerX = width / 2;
      const centerY = height / 2;
      const dx = centerX - p.x;
      const dy = centerY - p.y;
      const distance = Math.sqrt(dx * dx + dy * dy);
      const maxDistance = Math.sqrt(width * width + height * height) / 2;

      if (distance > maxDistance * 0.8) {
        const angle = Math.atan2(dy, dx);
        p.vx += Math.cos(angle) * 0.02;
        p.vy += Math.sin(angle) * 0.02;
      }

      // Pulse effect (life cycle)
      p.pulse += 0.02;
      const pulseAmount = Math.sin(p.pulse) * 0.3 + 0.7;
      p.radius = p.baseRadius * pulseAmount;
      p.opacity = p.baseOpacity * pulseAmount;
    });
  }

  drawParticles() {
    this.particles.forEach(p => {
      // Draw particle with glow
      const gradient = this.ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, p.radius * 2);
      gradient.addColorStop(0, p.color.replace(')', `, ${p.opacity})`).replace('hsl(', 'hsla('));
      gradient.addColorStop(1, p.color.replace(')', ', 0)').replace('hsl(', 'hsla('));

      this.ctx.fillStyle = gradient;
      this.ctx.beginPath();
      this.ctx.arc(p.x, p.y, p.radius * 2, 0, Math.PI * 2);
      this.ctx.fill();

      // Draw core
      this.ctx.fillStyle = p.color.replace(')', `, ${p.opacity})`).replace('hsl(', 'hsla(');
      this.ctx.beginPath();
      this.ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
      this.ctx.fill();
    });
  }

  drawConnections() {
    const maxDistance = 150;
    const particles = this.particles;

    for (let i = 0; i < particles.length; i++) {
      for (let j = i + 1; j < particles.length; j++) {
        const p1 = particles[i];
        const p2 = particles[j];
        const dx = p1.x - p2.x;
        const dy = p1.y - p2.y;
        const distance = Math.sqrt(dx * dx + dy * dy);

        if (distance < maxDistance) {
          const opacity = (1 - distance / maxDistance) * 0.3;
          this.ctx.strokeStyle = `rgba(124, 58, 237, ${opacity})`;
          this.ctx.lineWidth = 0.5;
          this.ctx.beginPath();
          this.ctx.moveTo(p1.x, p1.y);
          this.ctx.lineTo(p2.x, p2.y);
          this.ctx.stroke();
        }
      }
    }
  }

  animate = () => {
    // Clear canvas with slight trail effect (ethereal look)
    this.ctx.fillStyle = 'rgba(15, 23, 42, 0.1)';
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);

    this.updateParticles();
    this.drawConnections();
    this.drawParticles();

    this.time++;
    requestAnimationFrame(this.animate);
  }
}

// Initialize particle system
let particleSystem;

document.addEventListener('DOMContentLoaded', () => {
  particleSystem = new ParticleSystem('canvas-bg');
});

// Ensure canvas is recreated if needed
window.addEventListener('orientationchange', () => {
  if (particleSystem) {
    particleSystem.onWindowResize();
  }
});
