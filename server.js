const express = require('express');
const path = require('path');

const app = express();
const PORT = 3000;
const CUSTOM_PATH = '/world-class-scholars';

// Admin-friendly profile photo source switch.
// Options: imported, svg, remote
const PROFILE_PHOTO_SOURCE = process.env.WCS_PROFILE_PHOTO_SOURCE || 'imported';

const PROFILE_PHOTO_OPTIONS = {
  imported: '/images/dr-chris-photo.png',
  svg: '/images/dr-chris.svg',
  remote: 'https://0.gravatar.com/avatar/d8bd3742b066b58641607204c431fb47b6b32016887ba1a7b95e91279d7562d3?size=512'
};

const EXTERNAL_INTEGRATIONS = [
  { key: 'personalSite', label: 'Personal Site', url: 'https://christopherappiahthompson.link' },
  { key: 'linkedin', label: 'LinkedIn', url: 'https://www.linkedin.com/in/christopher-appiah-thompson-a2014045' },
  { key: 'worldClassScholars', label: 'World Class Scholars', url: 'https://worldclassscholars.org' },
  { key: 'profileImage', label: 'Profile Image Source', url: PROFILE_PHOTO_OPTIONS.remote }
];

const integrationCache = {
  checkedAt: null,
  results: []
};

function getProfileImage() {
  return PROFILE_PHOTO_OPTIONS[PROFILE_PHOTO_SOURCE] || PROFILE_PHOTO_OPTIONS.imported;
}

async function checkIntegration(url) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);

  try {
    // GET is generally better supported than HEAD by third-party platforms.
    const response = await fetch(url, {
      method: 'GET',
      redirect: 'follow',
      signal: controller.signal,
      headers: {
        'User-Agent': 'WCS-Integration-HealthCheck/1.0'
      }
    });

    return {
      ok: response.status < 500 || response.status === 999,
      status: response.status,
      statusText: response.statusText || 'OK'
    };
  } catch (error) {
    return {
      ok: false,
      status: null,
      statusText: error.name === 'AbortError' ? 'Timeout' : error.message
    };
  } finally {
    clearTimeout(timeout);
  }
}

async function runIntegrationChecks() {
  const results = await Promise.all(
    EXTERNAL_INTEGRATIONS.map(async item => {
      const status = await checkIntegration(item.url);
      return {
        key: item.key,
        label: item.label,
        url: item.url,
        ...status
      };
    })
  );

  integrationCache.checkedAt = new Date().toISOString();
  integrationCache.results = results;
  return integrationCache;
}

// Set view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Serve static files from public directory
app.use(express.static(path.join(__dirname, 'public')));

// Health/status endpoint for external integrations.
app.get('/api/integrations', async (req, res) => {
  const force = req.query.refresh === '1';
  const stale =
    !integrationCache.checkedAt ||
    Date.now() - new Date(integrationCache.checkedAt).getTime() > 5 * 60 * 1000;

  if (force || stale) {
    await runIntegrationChecks();
  }

  res.json({
    profilePhotoSource: PROFILE_PHOTO_SOURCE,
    profilePhotoUrl: getProfileImage(),
    checkedAt: integrationCache.checkedAt,
    integrations: integrationCache.results
  });
});

function renderProfilePage(req, res) {
  const profileData = {
    name: 'Dr. Christopher Appiah-Thompson',
    title: 'Founder & CEO, World Class Scholars',
    bio: 'Global advocate for social justice in disability, mental health, dementia care, education, and creative storytelling.',
    tagline: 'Bridging research, frontline practice, lived experience, and creative storytelling to design humane services.',
    image: getProfileImage(),
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
  console.log(`🖼️ Profile photo source: ${PROFILE_PHOTO_SOURCE} -> ${getProfileImage()}`);
  console.log(`📖 World Class Scholars Demo - Healing Arts & Digital Storytelling`);
});

// Warm the integration cache without blocking startup.
runIntegrationChecks().catch(error => {
  console.error('Integration check warmup failed:', error.message);
});
