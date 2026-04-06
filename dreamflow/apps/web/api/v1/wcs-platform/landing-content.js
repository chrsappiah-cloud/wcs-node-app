const payload = {
  hero: {
    title: 'Dr Christopher Appiah-Thompson',
    subtitle:
      'Global consultant and advocate for social justice, working across disability, mental health, dementia care, education, and creative storytelling through World Class Scholars.',
    primaryCta: 'Request a Conversation'
  },
  phases: [],
  services: [
    {
      key: 'consultancy-advocacy',
      title: 'Consultancy and Advocacy',
      blurb:
        'Advising government, NGOs, and aged-care providers on policy, standards, and co-design grounded in human rights and lived experience.'
    },
    {
      key: 'education-training',
      title: 'Education and Training',
      blurb:
        'Designing online courses, micro-credentials, and tailored workshops for leaders, workers, and community care teams.'
    },
    {
      key: 'campaigns-storytelling',
      title: 'Digital Campaigns and Brand Storytelling',
      blurb:
        'Building ethical campaigns and communications for care organisations and purpose-led brands with a clear social impact narrative.'
    },
    {
      key: 'creative-arts-media',
      title: 'Creative Arts and Media',
      blurb:
        'Producing digital art, healing-arts resources, podcasts, and public-facing media that connect research with lived experience.'
    }
  ]
};

module.exports = (req, res) => {
  if (req.method !== 'GET') {
    res.setHeader('Allow', 'GET');
    return res.status(405).json({ message: 'Method Not Allowed' });
  }

  return res.status(200).json(payload);
};
