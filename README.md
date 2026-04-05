# 🌍 World Class Scholars - Digital Storytelling for Dementia Care

A sophisticated Node.js web application showcasing Dr. Christopher Appiah-Thompson's consultancy and innovative software solutions in dementia care, disability advocacy, and digital healing arts.

## 🎨 Features

### Advanced UI/UX
- **Canvas Particle Animations**: 120+ animated particles with physics simulation and interactive connections
- **Glassmorphism Design**: Frosted glass effect cards with backdrop blur and gradient overlays
- **Responsive Typography**: Fluid sizing with CSS `clamp()` for all screen sizes
- **Interactive Animations**: Hover effects, scroll reveals, and staggered transitions
- **Hero Section**: Gradient-text heading with parallax scrolling and floating animations

### Profile & Content
- **Dynamic Profile Card**: Circular avatar with scale/rotate animations
- **Skills Grid**: Interactive skill tags with glow effects
- **Software Projects**: 4 featured dementia care solutions with tech stack details
- **Social Links**: Direct integration with professional platforms

### Technology Stack
- **Backend**: Express.js (Node.js)
- **Templating**: EJS
- **Frontend**: Vanilla JS with Canvas API
- **Styling**: Advanced CSS3 (Grid, Flexbox, Gradients, Animations)
- **Responsive**: Mobile-first design with breakpoints

## 🚀 Getting Started

### Prerequisites
- Node.js v14+
- npm or yarn

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/wcs-node-app.git
cd wcs-node-app

# Install dependencies
npm install

# Start development server
node server.js
```

The app will be available at **http://localhost:3000**

## 📁 Project Structure

```
wcs-node-app/
├── server.js                 # Express server configuration
├── package.json              # Dependencies and scripts
├── README.md                 # This file
├── .gitignore               # Git ignore file
├── views/
│   └── index.ejs            # Main EJS template with animations
└── public/
    └── images/
        ├── workshop.jpg     # Workshop scene visualization
        └── dr-chris.jpg     # Profile image
```

## 🎯 Key Components

### Canvas Particle System
- Real-time particle animation with physics
- Mouse interaction tracking
- Dynamic particle connections based on proximity
- Responsive canvas resizing

### Profile Section
- Dr. Christopher Appiah-Thompson bio and credentials
- 6 core skills with interactive tags
- Links to personal site, LinkedIn, and World Class Scholars
- Responsive grid layout

### Software Solutions
1. **AI Companions for Dementia Care** - Rok Max-style generative art with voice coaching
2. **Reminiscence & Memory Apps** - Canvas-based storytelling with therapeutic animations
3. **BPSD Prediction & Management** - ML models for behavioral pattern prediction
4. **Digital Workshop Platform** - Hybrid classroom for collaborative video editing

## 🎨 Design System

### Color Palette
- **Primary**: `#7c3aed` (Purple)
- **Secondary**: `#06b6d4` (Cyan)
- **Accent**: `#10b981` (Green)
- **Dark**: `#0f172a` (Navy)
- **Light**: `#e2e8f0` (Slate)

### Typography
- **Font Family**: Segoe UI, Roboto, sans-serif
- **Heading Scale**: clamp(1.8rem, 4vw, 2.5rem)
- **Body**: clamp(0.9rem, 1.2vw, 1.1rem)

## 🔧 Customization

### Edit Profile Data
Modify `server.js` route data:
```javascript
const profileData = {
  name: 'Dr. Christopher Appiah-Thompson',
  title: 'Founder & CEO, World Class Scholars',
  // ... update fields
};
```

### Update Software Projects
Add or modify projects in the `softwareProjects` array in `server.js`.

### Change Color Theme
Update CSS variables in `views/index.ejs`:
```css
:root {
  --primary: #7c3aed;
  --secondary: #06b6d4;
  --accent: #10b981;
}
```

## 📱 Responsive Breakpoints

- **Mobile**: < 768px
- **Tablet**: 768px - 1024px
- **Desktop**: > 1024px

## ✨ Performance Features

- Lazy-loaded canvas animations
- Intersection Observer for scroll reveals
- Optimized CSS animations (GPU-accelerated)
- Minimal JavaScript bundle
- Server-side rendering via EJS

## 🌐 Deployment

### Heroku
```bash
git push heroku main
```

### Vercel
```bash
vercel
```

### DigitalOcean App Platform
```bash
doctl apps create --spec app.yaml
```

## 📝 Environment Variables

Create a `.env` file (optional):
```
NODE_ENV=production
PORT=3000
```

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

© 2026 World Class Scholars Productions. All rights reserved.

---

**Built with ❤️ using Node.js, Express, and Canvas animations**

**Contact**: christopher@worldclassscholars.com
