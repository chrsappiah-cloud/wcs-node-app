const express = require('express');
const path = require('path');

const app = express();
const PORT = 3000;
const CUSTOM_PATH = '/world-class-scholars';

// Set view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Serve static files from public directory
app.use(express.static(path.join(__dirname, 'public')));

function renderProfilePage(req, res) {
  const profileData = {
    name: 'Dr. Christopher Appiah-Thompson',
    title: 'Founder & CEO, World Class Scholars',
    bio: 'Global advocate for social justice in disability, mental health, dementia care, education, and creative storytelling.',
    tagline: 'Bridging research, frontline practice, lived experience, and creative storytelling to design humane services.',
    image: '/images/dr-chris-photo.png',
    links: [
      {
        label: 'Personal Site',
        url: 'https://christopherappiahthompson.link'
      },
      {
        label: 'LinkedIn',
        url: 'https://www.linkedin.com/in/christopher-appiah-thompson-a2014045'
      },
      {
        label: 'World Class Scholars',
        url: 'https://worldclassscholars.org'
      }
    ],
    skills: [
      'Social Justice Advocacy',
      'Dementia Care',
      'Mental Health Policy',
      'Digital Storytelling',
      'Consultancy & Training',
      'Trauma-Aware Communication'
    ]
  };

  const softwareProjects = [
    {
      title: 'AI Companions for Dementia Care',
      description: 'Rok Max-style generative art with voice coaching and activity summaries for elders.',
      tech: 'React Native, Node.js, OpenAI APIs'
    },
    {
      title: 'Reminiscence & Memory Apps',
      description: 'Canvas-based storytelling with therapeutic animations and personalized content recall.',
      tech: 'Flutter, Canvas.js, Firebase'
    },
    {
      title: 'BPSD Prediction & Management',
      description: 'Machine learning models predicting behavioral patterns with preventive interventions.',
      tech: 'Python, TensorFlow, React, REST APIs'
    },
    {
      title: 'Digital Workshop Platform',
      description: 'Hybrid classroom for collaborative video editing and live storytelling sessions.',
      tech: 'Express, WebRTC, EJS, Tailwind CSS'
    }
  ];

  res.render('index', {
    profile: profileData,
    software: softwareProjects,
    workshopImage: '/images/workshop.svg',
    customUrl: `${req.protocol}://${req.get('host')}${CUSTOM_PATH}`
  });
}

// Routes
app.get('/', renderProfilePage);
app.get(CUSTOM_PATH, renderProfilePage);
app.get('/wcs', (req, res) => {
  res.redirect(302, CUSTOM_PATH);
});

app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
  console.log(`🔗 Custom URL: http://localhost:${PORT}${CUSTOM_PATH}`);
  console.log(`📖 World Class Scholars Demo - Healing Arts & Digital Storytelling`);
});
