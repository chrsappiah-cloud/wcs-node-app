import { FormEvent, useEffect, useMemo, useRef, useState } from 'react';
import { Link, NavLink, Navigate, Route, Routes, useLocation, useNavigate } from 'react-router-dom';
import { LandingPayload, postBookCall } from './lib/api';

type Theme = 'dark' | 'light';

type IconProps = {
  className?: string;
};

type FormState = {
  name: string;
  email: string;
  phone: string;
  notes: string;
};

type SocialLink = {
  label: string;
  handle: string;
  href: string;
  color: string;
  Icon: ({ className }: IconProps) => JSX.Element;
};

type RouteItem = {
  to: string;
  label: string;
  eyebrow: string;
  summary: string;
};

const defaultLandingData: LandingPayload = {
  hero: {
    title: 'Dr Christopher Appiah-Thompson',
    subtitle:
      'Global consultant and advocate for social justice, working across disability, mental health, dementia care, education, and creative storytelling through the World Class Scholars platform.',
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

function IconLinkedIn({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className} aria-hidden="true">
      <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 0 1-2.063-2.065 2.064 2.064 0 1 1 2.063 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z" />
    </svg>
  );
}

function IconInstagram({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className} aria-hidden="true">
      <path d="M7.75 2h8.5A5.76 5.76 0 0 1 22 7.75v8.5A5.76 5.76 0 0 1 16.25 22h-8.5A5.76 5.76 0 0 1 2 16.25v-8.5A5.76 5.76 0 0 1 7.75 2zm0 1.8A3.96 3.96 0 0 0 3.8 7.75v8.5a3.96 3.96 0 0 0 3.95 3.95h8.5a3.96 3.96 0 0 0 3.95-3.95v-8.5a3.96 3.96 0 0 0-3.95-3.95zm8.95 1.35a1.1 1.1 0 1 1-1.1 1.1 1.1 1.1 0 0 1 1.1-1.1zM12 6.85A5.15 5.15 0 1 1 6.85 12 5.16 5.16 0 0 1 12 6.85zm0 1.8A3.35 3.35 0 1 0 15.35 12 3.36 3.36 0 0 0 12 8.65z" />
    </svg>
  );
}

function IconFacebook({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className} aria-hidden="true">
      <path d="M13.5 22v-8.2h2.77l.41-3.2H13.5V8.56c0-.93.26-1.56 1.6-1.56h1.71V4.14A23.1 23.1 0 0 0 14.31 4c-2.48 0-4.18 1.51-4.18 4.3v2.4H7.3v3.2h2.83V22z" />
    </svg>
  );
}

function IconTikTok({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className} aria-hidden="true">
      <path d="M19.59 6.69a4.83 4.83 0 0 1-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 0 1-2.88 2.5 2.89 2.89 0 0 1-2.89-2.89 2.89 2.89 0 0 1 2.89-2.89c.28 0 .54.04.79.1V9.01a6.33 6.33 0 0 0-.79-.05 6.34 6.34 0 0 0-6.34 6.34 6.34 6.34 0 0 0 6.34 6.34 6.34 6.34 0 0 0 6.33-6.34V8.69a8.18 8.18 0 0 0 4.79 1.52V6.76a4.85 4.85 0 0 1-1.02-.07z" />
    </svg>
  );
}

function IconYouTube({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className} aria-hidden="true">
      <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z" />
    </svg>
  );
}

function IconMic({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden="true"
    >
      <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" />
      <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
      <line x1="12" y1="19" x2="12" y2="23" />
      <line x1="8" y1="23" x2="16" y2="23" />
    </svg>
  );
}

function IconBrush({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden="true"
    >
      <path d="M9.06 11.9l8.07-8.06a2.85 2.85 0 1 1 4.03 4.03l-8.06 8.08" />
      <path d="M7.07 14.94c-1.66 0-3 1.35-3 3.02 0 1.33-2.5 1.52-2 2.02 1 1 2.48 1.02 3.5 1.02 2.2 0 3-1.8 3-3.04a3.002 3.002 0 0 0-1.5-2.02z" />
    </svg>
  );
}

function IconStar({ className = 'h-5 w-5' }: IconProps) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden="true"
    >
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
    </svg>
  );
}

function IconArrow({ className = 'h-4 w-4' }: IconProps) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden="true"
    >
      <line x1="5" y1="12" x2="19" y2="12" />
      <polyline points="12 5 19 12 12 19" />
    </svg>
  );
}

const navItems: RouteItem[] = [
  {
    to: '/',
    label: 'Overview',
    eyebrow: 'Entry Point',
    summary: 'A clear landing page that frames the practice, signals the themes, and launches the rest of the journey.'
  },
  {
    to: '/practice',
    label: 'Practice',
    eyebrow: 'What I Do',
    summary: 'Consultancy, advocacy, education, and public themes arranged as one focused route.'
  },
  {
    to: '/media',
    label: 'Media',
    eyebrow: 'Podcast + Art',
    summary: 'Audio storytelling, digital art, and public social presence combined into one media route.'
  },
  {
    to: '/connect',
    label: 'Connect',
    eyebrow: 'Platforms + Contact',
    summary: 'External platforms, verified channels, and direct collaboration pathways in one destination.'
  }
];

const routeSequence = navItems.map(item => item.to);

function getRouteIndex(pathname: string): number {
  const index = routeSequence.indexOf(pathname);
  return index === -1 ? 0 : index;
}

function getRouteLabel(pathname: string): string {
  const item = navItems.find(entry => entry.to === pathname);
  return item ? item.label : 'Home';
}

const platformLinks = [
  {
    title: 'Future Lab Gallery',
    href: 'https://myworldclass.net/',
    summary: 'A living gallery of emerging curricula, research projects, and learning tools connected to Dr Christopher Appiah-Thompson and the World Class Scholars platform.'
  },
  {
    title: 'Podcast Hub on RSS.com',
    href: 'https://rss.com/podcasts/heartbeats-beyond-memory-creative-care-in-dementia/2357430',
    summary: 'A curated collection of podcast series exploring social justice, dementia care, mental health advocacy, and creative storytelling through audio media.'
  },
  {
    title: 'Future Lab',
    href: 'https://www.wcsflab.com/',
    summary: 'An experimental art and AI research lab where creative pedagogy meets speculative technology.'
  },
  {
    title: 'African History and Its Discontents',
    href: 'https://africanhistoryanditsdiscontents.codeadx.me/',
    summary: 'A storytelling project excavating memory, resistance, and the enduring wound of the transatlantic slave trade.'
  }
];

const podcastSeries = [
  {
    title: 'Heartbeats Beyond Memory',
    show: 'Creative Care in Dementia',
    href: 'https://rss.com/podcasts/heartbeats-beyond-memory-creative-care-in-dementia/2357430',
    description:
      'A searching series weaving social justice, dementia care, mental health, lived experience, and public advocacy into raw, honest conversations about what it truly means to care for others and ourselves.',
    platform: 'RSS Podcast Hub',
    rssUrl: 'https://rss.com/podcasts/heartbeats-beyond-memory-creative-care-in-dementia/',
    topics: ['Social Justice', 'Dementia Care', 'Mental Health', 'Advocacy', 'Creative Storytelling']
  }
];

const digitalArtworks = [
  {
    title: 'NightCafe AI Art Studio',
    handle: 'CKRIZ',
    href: 'https://creator.nightcafe.studio/u/CKRIZ',
    description:
      'Generative AI artworks that traverse cultural memory, historical trauma, speculative futures, and the aesthetics of healing.',
    medium: 'AI-Generated Digital Art',
    tags: ['Cultural Memory', 'Speculative Art', 'Healing Aesthetics']
  },
  {
    title: 'Podcast Content Hub',
    handle: 'RSS.com',
    href: 'https://rss.com/podcasts/heartbeats-beyond-memory-creative-care-in-dementia/',
    description:
      'Audio storytelling and podcast productions exploring social justice narratives, dementia care innovation, and the intersection of creative practice with lived experience advocacy.',
    medium: 'Podcast & Audio Media',
    tags: ['Podcasting', 'Audio Storytelling', 'Social Justice', 'Care Innovation']
  }
];

const socialLinks: SocialLink[] = [
  {
    label: 'Instagram',
    handle: '@christopherappi',
    href: 'https://www.instagram.com/christopherappi/',
    color: 'from-amber-500 via-pink-500 to-fuchsia-700',
    Icon: IconInstagram
  },
  {
    label: 'Facebook',
    handle: '@chrsappiah',
    href: 'https://www.facebook.com/chrsappiah/',
    color: 'from-sky-600 to-blue-800',
    Icon: IconFacebook
  },
  {
    label: 'LinkedIn',
    handle: 'christopher-appiah-thompson',
    href: 'https://www.linkedin.com/in/christopher-appiah-thompson-a2014045',
    color: 'from-blue-600 to-blue-800',
    Icon: IconLinkedIn
  },
  {
    label: 'TikTok',
    handle: '@chrsappiah',
    href: 'https://tiktok.com/@chrsappiah',
    color: 'from-pink-500 to-fuchsia-700',
    Icon: IconTikTok
  },
  {
    label: 'YouTube',
    handle: 'World Class Scholars channel',
    href: 'https://www.youtube.com/channel/UC2a-_QUygsGAKWzEdKHEP9Q',
    color: 'from-red-600 to-rose-800',
    Icon: IconYouTube
  },
  {
    label: 'NightCafe',
    handle: 'CKRIZ',
    href: 'https://creator.nightcafe.studio/u/CKRIZ',
    color: 'from-violet-600 to-purple-800',
    Icon: IconStar
  }
];

const headerSocialLinks = [
  {
    label: 'Instagram',
    href: 'https://www.instagram.com/christopherappi/',
    Icon: IconInstagram
  },
  {
    label: 'Facebook',
    href: 'https://www.facebook.com/chrsappiah/',
    Icon: IconFacebook
  },
  {
    label: 'YouTube',
    href: 'https://www.youtube.com/channel/UC2a-_QUygsGAKWzEdKHEP9Q',
    Icon: IconYouTube
  }
];

function getPreferredTheme(): Theme {
  if (typeof window === 'undefined') return 'dark';
  const persisted = localStorage.getItem('wcs-theme');
  if (persisted === 'dark' || persisted === 'light') return persisted;
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

function useRouteLifecycle(setScrollY: (value: number) => void) {
  const location = useLocation();

  useEffect(() => {
    const root = document.documentElement;
    const page = document.querySelector('.route-stage');
    root.style.scrollBehavior = 'smooth';

    if (location.hash) {
      const id = location.hash.replace('#', '');
      const target = document.getElementById(id);
      if (target) target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    } else {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }

    const revealTargets = Array.from((page || document).querySelectorAll<HTMLElement>('[data-reveal]'));
    const observer = new IntersectionObserver(
      entries => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-revealed');
          }
        });
      },
      { threshold: 0.14 }
    );

    revealTargets.forEach((target, index) => {
      target.classList.remove('is-revealed');
      target.style.setProperty('--reveal-delay', `${Math.min(index * 70, 420)}ms`);
      observer.observe(target);
    });

    return () => {
      observer.disconnect();
    };
  }, [location.pathname, location.hash]);

  useEffect(() => {
    const onScroll = () => setScrollY(window.scrollY);
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, [setScrollY]);

  return location;
}

function SocialCard({ links }: { links: SocialLink[] }) {
  return (
    <article className="glass-card">
      <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">Digital Presence</p>
      <p className="mt-1 text-xs text-content-soft/70">Verified accounts across platforms</p>
      <ul className="mt-4 space-y-3">
        {links.map(({ label, handle, href, color, Icon }) => (
          <li key={label}>
            <a
              href={href}
              target="_blank"
              rel="noreferrer"
              className="group flex items-center gap-3 rounded-2xl border border-white/15 bg-white/10 p-3 transition hover:bg-white/20"
            >
              <span className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br ${color} text-white shadow-md`}>
                <Icon />
              </span>
              <div className="min-w-0 flex-1">
                <p className="text-sm font-bold">{label}</p>
                <p className="truncate text-xs text-content-soft/70">{handle}</p>
              </div>
              <IconArrow className="h-4 w-4 shrink-0 text-content-soft/40 transition group-hover:translate-x-0.5 group-hover:text-cyan-300" />
            </a>
          </li>
        ))}
      </ul>
    </article>
  );
}

function RouteAtlas({ pathname }: { pathname: string }) {
  return (
    <section data-reveal className="reveal mt-14">
      <div className="mb-6 flex items-end justify-between gap-3">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">Route Atlas</p>
          <h2 className="mt-1 font-heading text-3xl font-bold">Four pages, one connected journey</h2>
        </div>
        <p className="max-w-md text-right text-sm text-content-soft/80">
          Each route has a distinct role and hands off cleanly into the next destination.
        </p>
      </div>
      <div className="grid gap-4 lg:grid-cols-4">
        {navItems.map((item, index) => {
          const isActive = item.to === pathname;
          const nextItem = navItems[index + 1];

          return (
            <div key={item.to} className="flex items-center gap-3 lg:contents">
              <Link
                to={item.to}
                className={`glass-card route-link group h-full ${isActive ? 'ring-2 ring-cyan-300/60' : ''}`}
                aria-current={isActive ? 'page' : undefined}
              >
                <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">{item.eyebrow}</p>
                <h3 className="mt-2 font-heading text-2xl font-bold">{item.label}</h3>
                <p className="mt-3 text-sm leading-relaxed text-content-soft">{item.summary}</p>
                <p className="mt-5 inline-flex items-center gap-2 text-sm font-semibold text-cyan-200">
                  Open route <IconArrow className="h-4 w-4 transition group-hover:translate-x-0.5" />
                </p>
              </Link>
              {nextItem ? (
                <div className="route-atlas-connector hidden lg:flex" aria-hidden="true">
                  <span className="route-atlas-line" />
                  <span className="route-atlas-arrow">→</span>
                </div>
              ) : null}
            </div>
          );
        })}
      </div>
    </section>
  );
}

function ServiceSection({ landingData }: { landingData: LandingPayload }) {
  return (
    <section data-reveal className="reveal mt-14">
      <div className="mb-6 flex items-end justify-between gap-3">
        <h2 className="font-heading text-3xl font-bold">What I Do</h2>
        <p className="text-sm text-content-soft">Directly adapted from the source profile</p>
      </div>
      <div className="grid gap-4 md:grid-cols-2">
        {landingData.services.map(service => (
          <article key={service.key} className="glass-card card-3d group transition duration-300 hover:-translate-y-1">
            <h3 className="font-heading text-2xl font-bold">{service.title}</h3>
            <p className="mt-3 text-content-soft">{service.blurb}</p>
            <div className="mt-5 h-1 w-0 rounded bg-accent transition-all duration-300 group-hover:w-20" />
          </article>
        ))}
      </div>
    </section>
  );
}

function PodcastSection() {
  return (
    <section id="featured-work" data-reveal className="reveal mt-14">
      <div className="mb-6 flex items-end justify-between gap-3">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">Audio Media</p>
          <h2 className="mt-1 font-heading text-3xl font-bold">Podcast Series</h2>
        </div>
        <span className="hidden rounded-full border border-white/20 bg-white/10 px-4 py-1.5 text-xs font-semibold uppercase tracking-widest text-content-soft sm:block">
          • Now Live •
        </span>
      </div>
      {podcastSeries.map(pod => (
        <article
          key={pod.title}
          className="relative overflow-hidden rounded-3xl border border-white/20 bg-white/10 p-8 shadow-glass backdrop-blur-xl md:p-10"
        >
          <div className="pointer-events-none absolute right-8 top-8 hidden items-end gap-[3px] opacity-20 md:flex" aria-hidden="true">
            {[18, 28, 22, 35, 15, 30, 25, 40, 20, 32, 14, 27, 38, 22, 16].map((h, i) => (
              <div key={i} className="w-[3px] rounded-full bg-cyan-300" style={{ height: `${h}px` }} />
            ))}
          </div>
          <div className="flex items-start gap-4">
            <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-cyan-500 to-teal-700 text-white shadow-lg">
              <IconMic className="h-6 w-6" />
            </span>
            <div className="flex-1">
              <p className="text-xs font-bold uppercase tracking-[0.16em] text-cyan-300">{pod.platform}</p>
              <h3 className="mt-1 font-heading text-2xl font-bold md:text-3xl">{pod.title}</h3>
              <p className="mt-0.5 text-sm font-medium italic text-content-soft/80">{pod.show}</p>
              <p className="mt-4 max-w-2xl text-base leading-relaxed text-content-soft">{pod.description}</p>
              <div className="mt-5 flex flex-wrap gap-2">
                {pod.topics.map(topic => (
                  <span key={topic} className="rounded-full border border-cyan-500/30 bg-cyan-500/10 px-3 py-1 text-xs font-semibold text-cyan-200">
                    {topic}
                  </span>
                ))}
              </div>
              <a
                href={pod.href}
                target="_blank"
                rel="noreferrer"
                className="mt-6 inline-flex items-center gap-2 rounded-full bg-gradient-to-r from-cyan-600 to-teal-600 px-6 py-3 text-sm font-bold text-white shadow-lg transition hover:from-cyan-500 hover:to-teal-500"
              >
                Listen Now <IconArrow className="h-4 w-4" />
              </a>
            </div>
          </div>
        </article>
      ))}
    </section>
  );
}

function DigitalArtSection() {
  return (
    <section data-reveal className="reveal mt-14">
      <div className="mb-6 flex items-end justify-between gap-3">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">Visual Works & Audio</p>
          <h2 className="mt-1 font-heading text-3xl font-bold">Digital Art and Creative Studios</h2>
        </div>
      </div>
      <div className="grid gap-6 md:grid-cols-2">
        {digitalArtworks.map(art => {
          const isAudio = art.medium.includes('Podcast') || art.medium.includes('Audio');

          return isAudio ? (
            <article key={art.title} className="glass-card card-3d group relative overflow-hidden">
              <div
                className="pointer-events-none absolute -right-8 -top-8 h-40 w-40 rounded-full bg-amber-500/10 blur-2xl transition group-hover:bg-amber-500/20"
                aria-hidden="true"
              />
              <div className="relative">
                <div className="flex items-center gap-3">
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-amber-600 to-red-800 text-white shadow-md">
                    <IconMic className="h-5 w-5" />
                  </span>
                  <div>
                    <p className="text-xs font-bold uppercase tracking-[0.14em] text-amber-300">{art.medium}</p>
                    <h3 className="font-heading text-xl font-bold">{art.title}</h3>
                  </div>
                </div>
                <p className="mt-2 font-mono text-xs font-semibold text-amber-300/80">@{art.handle}</p>
                <p className="mt-4 text-sm leading-relaxed text-content-soft">{art.description}</p>
                <div className="mt-4 flex flex-wrap gap-2">
                  {art.tags.map(tag => (
                    <span key={tag} className="rounded-full border border-amber-500/30 bg-amber-500/10 px-2.5 py-0.5 text-xs font-semibold text-amber-200">
                      {tag}
                    </span>
                  ))}
                </div>
                <a
                  href={art.href}
                  target="_blank"
                  rel="noreferrer"
                  className="mt-5 inline-flex items-center gap-2 text-sm font-bold text-amber-300 underline decoration-amber-500/30 underline-offset-4 transition hover:text-amber-200"
                >
                  Listen & Subscribe <IconArrow className="h-4 w-4" />
                </a>
              </div>
            </article>
          ) : (
            <article key={art.title} className="glass-card card-3d group relative overflow-hidden">
              <div
                className="pointer-events-none absolute -right-8 -top-8 h-40 w-40 rounded-full bg-violet-500/10 blur-2xl transition group-hover:bg-violet-500/20"
                aria-hidden="true"
              />
              <div className="relative">
                <div className="flex items-center gap-3">
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-violet-600 to-purple-800 text-white shadow-md">
                    <IconBrush className="h-5 w-5" />
                  </span>
                  <div>
                    <p className="text-xs font-bold uppercase tracking-[0.14em] text-violet-300">{art.medium}</p>
                    <h3 className="font-heading text-xl font-bold">{art.title}</h3>
                  </div>
                </div>
                <p className="mt-2 font-mono text-xs font-semibold text-violet-300/80">@{art.handle}</p>
                <p className="mt-4 text-sm leading-relaxed text-content-soft">{art.description}</p>
                <div className="mt-4 flex flex-wrap gap-2">
                  {art.tags.map(tag => (
                    <span key={tag} className="rounded-full border border-violet-500/30 bg-violet-500/10 px-2.5 py-0.5 text-xs font-semibold text-violet-200">
                      {tag}
                    </span>
                  ))}
                </div>
                <a
                  href={art.href}
                  target="_blank"
                  rel="noreferrer"
                  className="mt-5 inline-flex items-center gap-2 text-sm font-bold text-violet-300 underline decoration-violet-500/30 underline-offset-4 transition hover:text-violet-200"
                >
                  View Studio <IconArrow className="h-4 w-4" />
                </a>
              </div>
            </article>
          );
        })}
      </div>
    </section>
  );
}

function PlatformsSection() {
  return (
    <section data-reveal className="reveal mt-14">
      <div className="mb-6 flex items-end justify-between gap-3">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">Web Platforms</p>
          <h2 className="mt-1 font-heading text-3xl font-bold">Research Platforms and Galleries</h2>
        </div>
      </div>
      <div className="grid gap-4 md:grid-cols-2">
        {platformLinks.map(link => (
          <article key={link.title} className="glass-card card-3d group">
            <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">Platform</p>
            <h3 className="mt-2 font-heading text-xl font-bold">{link.title}</h3>
            <p className="mt-3 text-sm leading-relaxed text-content-soft">{link.summary}</p>
            <a
              href={link.href}
              target="_blank"
              rel="noreferrer"
              className="mt-5 inline-flex items-center gap-2 text-sm font-semibold text-cyan-200 underline decoration-white/30 underline-offset-4"
            >
              Visit <IconArrow className="h-4 w-4" />
            </a>
          </article>
        ))}
      </div>
    </section>
  );
}

function PublicThemesSection() {
  return (
    <section data-reveal className="reveal mt-14 rounded-3xl border border-white/20 bg-white/10 p-8 shadow-glass backdrop-blur-xl">
      <div className="grid gap-6 lg:grid-cols-[0.95fr_1.05fr]">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">Public Themes</p>
          <h2 className="mt-3 font-heading text-3xl font-bold">Research, care, memory, and culture</h2>
          <p className="mt-4 text-content-soft">
            From disability advocacy to cultural history, healing arts to raw podcast conversations,
            and AI-generated digital galleries, these threads form a cohesive identity built around
            dignity, equity, and the transformative power of creative storytelling.
          </p>
        </div>
        <div className="grid gap-3 sm:grid-cols-2">
          {[
            'Policy and standards advisory',
            'Trauma-aware communication',
            'Course and workshop design',
            'Digital campaigns',
            'Creative arts resources',
            'Podcast and media production'
          ].map(item => (
            <div key={item} className="rounded-2xl border border-white/15 bg-white/10 px-4 py-4 text-sm font-medium text-content-soft">
              {item}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function ContactSection({
  loading,
  submitting,
  submittedMessage,
  formState,
  setFormState,
  onSubmit
}: {
  loading: boolean;
  submitting: boolean;
  submittedMessage: string;
  formState: FormState;
  setFormState: React.Dispatch<React.SetStateAction<FormState>>;
  onSubmit: (event: FormEvent<HTMLFormElement>) => Promise<void>;
}) {
  return (
    <section id="contact" data-reveal className="reveal mt-14">
      <div className="grid gap-8 rounded-3xl border border-white/20 bg-white/10 p-8 shadow-glass backdrop-blur-xl lg:grid-cols-[1fr_1fr]">
        <div>
          <h2 className="font-heading text-3xl font-bold">Start a Conversation</h2>
          <p className="mt-3 max-w-md text-content-soft">
            Use this form for speaking engagements, consultancy, research collaboration, training,
            arts programmes, or media enquiries.
          </p>
          <div className="mt-6 space-y-3 text-sm text-content-soft">
            <p>Areas of enquiry include social justice, dementia care, disability policy, education, and creative media.</p>
            <p>{loading ? 'Loading live profile details...' : 'Profile content is now aligned with the connected site and live API.'}</p>
          </div>
        </div>

        <form onSubmit={onSubmit} className="space-y-4">
          <label className="form-label">
            Full Name
            <input
              required
              value={formState.name}
              onChange={event => setFormState(prev => ({ ...prev, name: event.target.value }))}
              className="form-input"
            />
          </label>
          <label className="form-label">
            Email
            <input
              required
              type="email"
              value={formState.email}
              onChange={event => setFormState(prev => ({ ...prev, email: event.target.value }))}
              className="form-input"
            />
          </label>
          <label className="form-label">
            Phone
            <input
              value={formState.phone}
              onChange={event => setFormState(prev => ({ ...prev, phone: event.target.value }))}
              className="form-input"
            />
          </label>
          <label className="form-label">
            Message
            <textarea
              value={formState.notes}
              onChange={event => setFormState(prev => ({ ...prev, notes: event.target.value }))}
              className="form-input min-h-28"
            />
          </label>
          <button disabled={submitting} className="cta-primary w-full disabled:opacity-60" type="submit">
            {submitting ? 'Submitting...' : 'Send Enquiry'}
          </button>
          {submittedMessage ? <p className="text-sm text-content-soft">{submittedMessage}</p> : null}
        </form>
      </div>
    </section>
  );
}

function RouteConnectors({ toPrimary, toSecondary, primaryLabel, secondaryLabel }: {
  toPrimary: string;
  toSecondary: string;
  primaryLabel: string;
  secondaryLabel: string;
}) {
  return (
    <section data-reveal className="reveal mt-12">
      <div className="grid gap-4 sm:grid-cols-2">
        <Link className="glass-card route-link group" to={toPrimary}>
          <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">Next Route</p>
          <p className="mt-2 font-heading text-xl font-bold">{primaryLabel}</p>
          <p className="mt-2 inline-flex items-center gap-2 text-sm text-cyan-200">
            Continue <IconArrow className="h-4 w-4 transition group-hover:translate-x-0.5" />
          </p>
        </Link>
        <Link className="glass-card route-link group" to={toSecondary}>
          <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">Or Explore</p>
          <p className="mt-2 font-heading text-xl font-bold">{secondaryLabel}</p>
          <p className="mt-2 inline-flex items-center gap-2 text-sm text-cyan-200">
            Jump <IconArrow className="h-4 w-4 transition group-hover:translate-x-0.5" />
          </p>
        </Link>
      </div>
    </section>
  );
}

function RouteProgressRail({ pathname }: { pathname: string }) {
  const activeIndex = getRouteIndex(pathname);

  return (
    <div className="route-progress" aria-label="Route progress map">
      {navItems.map((item, index) => {
        const isActive = pathname === item.to;
        const isVisited = index < activeIndex;

        return (
          <Link
            key={item.to}
            to={item.to}
            className={`route-progress-node ${isActive ? 'is-active' : ''} ${isVisited ? 'is-visited' : ''}`}
            aria-current={isActive ? 'page' : undefined}
          >
            <span className="route-progress-dot" aria-hidden="true" />
            <span className="route-progress-label">{item.label}</span>
          </Link>
        );
      })}
    </div>
  );
}

function RouteHandoffStrip({ pathname, fromPath }: { pathname: string; fromPath: string | null }) {
  const activeIndex = getRouteIndex(pathname);
  const previous = activeIndex > 0 ? navItems[activeIndex - 1] : null;
  const next = activeIndex < navItems.length - 1 ? navItems[activeIndex + 1] : null;
  const fromLabel = fromPath ? getRouteLabel(fromPath) : null;

  return (
    <section className="route-handoff" aria-label="Route continuity strip">
      <div className="route-handoff-block route-handoff-from">
        <p className="route-handoff-kicker">From</p>
        <p className="route-handoff-value">{fromLabel || (previous ? previous.label : 'Entry')}</p>
      </div>

      <div className="route-handoff-current" aria-live="polite">
        <span className="route-handoff-pulse" aria-hidden="true" />
        <p className="route-handoff-kicker">Now Viewing</p>
        <p className="route-handoff-value">{getRouteLabel(pathname)}</p>
      </div>

      <div className="route-handoff-block route-handoff-next">
        <p className="route-handoff-kicker">Next</p>
        {next ? (
          <Link to={next.to} className="route-handoff-link">
            {next.label}
          </Link>
        ) : (
          <Link to="/" className="route-handoff-link">
            Home
          </Link>
        )}
      </div>
    </section>
  );
}

function HomePage({
  landingData,
  socialLinksData,
  scrollY
}: {
  landingData: LandingPayload;
  socialLinksData: SocialLink[];
  scrollY: number;
}) {
  return (
    <>
      <section
        data-reveal
        className="reveal rounded-3xl border border-white/20 bg-white/10 p-8 shadow-glass backdrop-blur-xl md:p-12"
        style={{ transform: `translateY(${Math.min(scrollY * 0.06, 24)}px)` }}
      >
        <div className="grid gap-10 lg:grid-cols-[1.3fr_0.9fr]">
          <div>
            <p className="mb-3 inline-flex rounded-full border border-current/30 px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em]">
              Global Consultant and Creative Advocate
            </p>
            <h1 className="font-heading text-4xl font-extrabold leading-tight md:text-6xl">{landingData.hero.title}</h1>
            <p className="mt-5 max-w-2xl text-base leading-relaxed text-content-soft md:text-lg">{landingData.hero.subtitle}</p>
            <p className="mt-4 max-w-2xl text-base leading-relaxed text-content-soft md:text-lg">
              Leading a practice that bridges research, frontline experience, creative storytelling,
              and public advocacy through World Class Scholars to help organisations design humane
              services, trauma-aware communication, and inclusive policy.
            </p>
            <div className="mt-8 flex flex-wrap gap-4">
              <Link to="/connect" className="cta-primary">
                {landingData.hero.primaryCta}
              </Link>
              <Link to="/practice" className="cta-secondary">
                Explore the Practice
              </Link>
            </div>

            <ul className="mt-6 grid gap-3 text-sm sm:grid-cols-3">
              <li className="trust-pill">Social justice</li>
              <li className="trust-pill">Mental health</li>
              <li className="trust-pill">Dementia care</li>
            </ul>
          </div>

          <aside className="rounded-3xl border border-white/20 bg-black/20 p-6 dark:bg-white/10">
            <p className="text-sm font-bold uppercase tracking-[0.16em] text-content-soft">Practice Focus</p>
            <div className="mt-5 space-y-4">
              <div className="rounded-2xl border border-white/15 bg-white/10 p-4">
                <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">Practice</p>
                <p className="mt-2 text-xl font-semibold">Dr Christopher Appiah-Thompson</p>
                <p className="mt-1 text-sm text-content-soft">Platform: World Class Scholars</p>
              </div>
              <div className="rounded-2xl border border-white/15 bg-white/10 p-4">
                <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">Working Method</p>
                <p className="mt-2 text-content-soft">
                  Research-led consulting, lived-experience-centred design, and public storytelling.
                </p>
              </div>
              <div className="rounded-2xl border border-white/15 bg-white/10 p-4">
                <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">Outputs</p>
                <p className="mt-2 text-content-soft">
                  Policy advice, training programmes, campaigns, digital art, and podcast media.
                </p>
              </div>
            </div>
          </aside>
        </div>
      </section>

      <section data-reveal className="reveal mt-14 grid gap-6 lg:grid-cols-[1.15fr_0.85fr]">
        <article className="glass-card">
          <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">About</p>
          <h2 className="mt-3 font-heading text-3xl font-bold">A practice centred on dignity, equity, and care</h2>
          <p className="mt-4 text-base leading-relaxed text-content-soft">
            The source profile describes a practice that connects disability advocacy, mental health,
            dementia care, education, and cultural storytelling. This version of the site reflects
            that directly with purposeful routes and connected journeys.
          </p>
          <p className="mt-4 text-base leading-relaxed text-content-soft">
            Navigate by theme, medium, and intent: from podcast discourse to digital art, from platform
            archives to direct collaboration.
          </p>
        </article>

        <SocialCard links={socialLinksData} />
      </section>

      <RouteAtlas pathname="/" />
      <RouteConnectors
        toPrimary="/practice"
        toSecondary="/media"
        primaryLabel="Move into the Practice Route"
        secondaryLabel="Jump straight to Media"
      />
    </>
  );
}

function PracticePage({ landingData }: { landingData: LandingPayload }) {
  return (
    <>
      <section data-reveal className="reveal rounded-3xl border border-white/20 bg-white/10 p-8 shadow-glass backdrop-blur-xl md:p-10">
        <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">Practice Route</p>
        <h1 className="mt-3 font-heading text-4xl font-bold md:text-5xl">Services, themes, and methods in one place</h1>
        <p className="mt-4 max-w-3xl text-content-soft">
          This route gathers the core consulting offer, public themes, and working method so the site reads as a deliberate professional journey rather than a scattered set of panels.
        </p>
      </section>
      <ServiceSection landingData={landingData} />
      <PublicThemesSection />
      <RouteConnectors
        toPrimary="/media"
        toSecondary="/connect"
        primaryLabel="Continue into Media"
        secondaryLabel="Open the Connect Route"
      />
    </>
  );
}

function MediaPage({ links }: { links: SocialLink[] }) {
  return (
    <>
      <section data-reveal className="reveal rounded-3xl border border-white/20 bg-white/10 p-8 shadow-glass backdrop-blur-xl md:p-10">
        <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">Media Route</p>
        <h1 className="mt-3 font-heading text-4xl font-bold md:text-5xl">Audio, visual culture, and public channels</h1>
        <p className="mt-4 max-w-3xl text-content-soft">
          Podcast work, digital art, and verified channels sit together here so listening, viewing, and following all feel like one continuous media experience.
        </p>
      </section>
      <PodcastSection />
      <DigitalArtSection />
      <section data-reveal className="reveal mt-14">
        <SocialCard links={links} />
      </section>
      <RouteConnectors
        toPrimary="/connect"
        toSecondary="/practice"
        primaryLabel="Move into Connect"
        secondaryLabel="Return to Practice"
      />
    </>
  );
}

function ConnectPage({
  links,
  loading,
  submitting,
  submittedMessage,
  formState,
  setFormState,
  onSubmit
}: {
  links: SocialLink[];
  loading: boolean;
  submitting: boolean;
  submittedMessage: string;
  formState: FormState;
  setFormState: React.Dispatch<React.SetStateAction<FormState>>;
  onSubmit: (event: FormEvent<HTMLFormElement>) => Promise<void>;
}) {
  return (
    <>
      <section data-reveal className="reveal rounded-3xl border border-white/20 bg-white/10 p-8 shadow-glass backdrop-blur-xl md:p-10">
        <p className="text-xs font-bold uppercase tracking-[0.16em] text-content-soft">Connect Route</p>
        <h1 className="mt-3 font-heading text-4xl font-bold md:text-5xl">Platforms, presence, and direct collaboration</h1>
        <p className="mt-4 max-w-3xl text-content-soft">
          External platforms, social presence, and the contact form are grouped here so every outward path ends in a clear next step.
        </p>
      </section>
      <PlatformsSection />
      <section data-reveal className="reveal mt-14">
        <SocialCard links={links} />
      </section>
      <ContactSection
        loading={loading}
        submitting={submitting}
        submittedMessage={submittedMessage}
        formState={formState}
        setFormState={setFormState}
        onSubmit={onSubmit}
      />
      <RouteConnectors
        toPrimary="/"
        toSecondary="/practice"
        primaryLabel="Loop Back to Overview"
        secondaryLabel="Revisit the Practice Route"
      />
    </>
  );
}

export function App() {
  const navigate = useNavigate();
  const [theme, setTheme] = useState<Theme>(() => getPreferredTheme());
  const [landingData, setLandingData] = useState<LandingPayload>(defaultLandingData);
  const [loading, setLoading] = useState(true);
  const [scrollY, setScrollY] = useState(0);
  const [submittedMessage, setSubmittedMessage] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [transitionClass, setTransitionClass] = useState('route-stage-forward');
  const [routeFrom, setRouteFrom] = useState<string | null>(null);
  const previousPathRef = useRef('/');
  const [formState, setFormState] = useState<FormState>({
    name: '',
    email: '',
    phone: '',
    notes: ''
  });

  const location = useRouteLifecycle(setScrollY);

  const routeTitle = useMemo(() => {
    if (location.pathname === '/practice') return 'Practice | Dr Christopher Appiah-Thompson';
    if (location.pathname === '/media') return 'Media | Dr Christopher Appiah-Thompson';
    if (location.pathname === '/connect') return 'Connect | Dr Christopher Appiah-Thompson';
    return 'Dr Christopher Appiah-Thompson | World Class Scholars';
  }, [location.pathname]);

  useEffect(() => {
    const root = document.documentElement;
    root.classList.toggle('dark', theme === 'dark');
    localStorage.setItem('wcs-theme', theme);
  }, [theme]);

  useEffect(() => {
    setLandingData(defaultLandingData);
    setLoading(false);
  }, []);

  useEffect(() => {
    document.title = routeTitle;
  }, [routeTitle]);

  useEffect(() => {
    const previousIndex = getRouteIndex(previousPathRef.current);
    const currentIndex = getRouteIndex(location.pathname);

    if (previousPathRef.current !== location.pathname) {
      setRouteFrom(previousPathRef.current);
    }

    if (currentIndex < previousIndex) {
      setTransitionClass('route-stage-backward');
    } else {
      setTransitionClass('route-stage-forward');
    }

    previousPathRef.current = location.pathname;
  }, [location.pathname]);

  useEffect(() => {
    const activeIndex = getRouteIndex(location.pathname);

    const onKeyDown = (event: KeyboardEvent) => {
      if (!event.altKey) return;

      const target = event.target as HTMLElement | null;
      const tagName = target?.tagName?.toLowerCase();
      if (tagName === 'input' || tagName === 'textarea' || target?.isContentEditable) {
        return;
      }

      if (event.key === 'ArrowRight') {
        const next = navItems[activeIndex + 1];
        if (next) {
          event.preventDefault();
          navigate(next.to);
        }
      }

      if (event.key === 'ArrowLeft') {
        const previous = navItems[activeIndex - 1];
        if (previous) {
          event.preventDefault();
          navigate(previous.to);
        }
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [location.pathname, navigate]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSubmitting(true);
    setSubmittedMessage('');

    try {
      await postBookCall({
        name: formState.name,
        email: formState.email,
        phone: formState.phone || undefined,
        notes: formState.notes || undefined
      });
      setSubmittedMessage('Thanks. Your message has been sent.');
      setFormState({ name: '', email: '', phone: '', notes: '' });
    } catch {
      setSubmittedMessage('We could not submit right now. Please try again shortly.');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="min-h-screen bg-base text-content">
      <div className="bg-orb bg-orb-a" aria-hidden="true" />
      <div className="bg-orb bg-orb-b" aria-hidden="true" />

      <header className="mx-auto flex w-full max-w-6xl flex-col gap-4 px-6 py-7 md:flex-row md:items-center md:justify-between md:px-10">
        <div className="flex items-center justify-between gap-4">
          <div className="flex flex-wrap items-center gap-2">
            {headerSocialLinks.map(({ label, href, Icon }) => (
              <a
                key={label}
                href={href}
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center gap-2 rounded-full border border-white/25 bg-white/10 px-3 py-2 text-sm font-semibold text-slate-100 backdrop-blur transition hover:bg-white/20"
                aria-label={label}
              >
                <Icon className="h-4 w-4" />
                <span>{label}</span>
              </a>
            ))}
          </div>
          <button
            type="button"
            onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
            className="rounded-full border border-white/30 bg-white/10 px-4 py-2 text-sm font-semibold backdrop-blur md:hidden"
          >
            {theme === 'dark' ? 'Switch to light' : 'Switch to dark'}
          </button>
        </div>

        <nav aria-label="Primary" className="route-nav flex flex-wrap items-center gap-2">
          {navItems.map(item => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `route-pill ${isActive ? 'route-pill-active' : ''}`
              }
              end={item.to === '/'}
            >
              {item.label}
            </NavLink>
          ))}
        </nav>

        <button
          type="button"
          onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
          className="hidden rounded-full border border-white/30 bg-white/10 px-4 py-2 text-sm font-semibold backdrop-blur md:inline-flex"
        >
          {theme === 'dark' ? 'Switch to light' : 'Switch to dark'}
        </button>
      </header>

      <main className="mx-auto w-full max-w-6xl px-6 pb-20 pt-8 md:px-10">
        <RouteProgressRail pathname={location.pathname} />
        <RouteHandoffStrip pathname={location.pathname} fromPath={routeFrom} />

        <div key={location.pathname} className={`route-stage ${transitionClass}`}>
          <Routes>
            <Route
              path="/"
              element={
                <HomePage
                  landingData={landingData}
                  socialLinksData={socialLinks}
                  scrollY={scrollY}
                />
              }
            />
            <Route path="/practice" element={<PracticePage landingData={landingData} />} />
            <Route path="/media" element={<MediaPage links={socialLinks} />} />
            <Route
              path="/connect"
              element={
                <ConnectPage
                  links={socialLinks}
                  loading={loading}
                  submitting={submitting}
                  submittedMessage={submittedMessage}
                  formState={formState}
                  setFormState={setFormState}
                  onSubmit={handleSubmit}
                />
              }
            />
            <Route path="/podcast" element={<Navigate to="/media" replace />} />
            <Route path="/art" element={<Navigate to="/media" replace />} />
            <Route path="/platforms" element={<Navigate to="/connect" replace />} />
            <Route path="/contact" element={<Navigate to="/connect" replace />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </div>

        <footer className="mt-16 border-t border-white/20 pt-8 pb-6 text-sm text-content-soft">
          <div className="mb-6 flex flex-wrap items-center justify-center gap-3">
            {socialLinks.map(({ label, href, color, Icon }) => (
              <a
                key={label}
                href={href}
                target="_blank"
                rel="noreferrer"
                aria-label={label}
                className={`flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br ${color} text-white shadow-md transition hover:scale-110 hover:shadow-lg`}
              >
                <Icon />
              </a>
            ))}
          </div>
          <div className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
            <p className="font-semibold tracking-wide">Dr Christopher Appiah-Thompson</p>
            <p className="text-xs opacity-70">© {new Date().getFullYear()} Dr Christopher Appiah-Thompson. All rights reserved.</p>
          </div>
          <p className="mt-2 text-xs opacity-60">
            Consultancy, advocacy, education, and creative media led by Dr Christopher Appiah-Thompson through the World Class Scholars platform.
          </p>
          <p className="mt-3 text-xs opacity-50">
            Public-facing platform for the work, media, and collaborations of Dr Christopher Appiah-Thompson.
            Unauthorised reproduction or distribution of site content is prohibited.
          </p>
        </footer>
      </main>
    </div>
  );
}
