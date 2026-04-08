import Navbar from './Navbar';

export default function Home() {
  return (
    <div
      style={{
        fontFamily: 'Inter, Arial, sans-serif',
        background: 'linear-gradient(90deg, #fffbe6 0%, #f5e9c6 100%)',
        minHeight: '100vh',
        padding: '2rem',
      }}
    >
      <Navbar />
      <main
        style={{
          maxWidth: 900,
          margin: '0 auto',
          background: 'linear-gradient(120deg, #fffbe6 0%, #fff7d6 100%)',
          borderRadius: 24,
          boxShadow: '0 8px 48px #eab30833',
          padding: '2.5rem 2rem',
          border: '1.5px solid #f3e8c7',
        }}
      >
        <h1
          style={{
            fontSize: '2.5rem',
            fontWeight: 900,
            color: '#eab308',
            marginBottom: 8,
            letterSpacing: -1,
            textShadow: '0 2px 12px #eab30833',
          }}
        >
          WCS Search Engine
        </h1>
        <p
          style={{
            color: '#bfa14a',
            fontSize: '1.2rem',
            marginBottom: 32,
            fontWeight: 600,
          }}
        >
          Welcome to the GeoWCS platform — a full-stack safety and real-time
          location system for trusted circles.
        </p>
        <section style={{ marginBottom: 32 }}>
          <h2
            style={{
              fontSize: '1.5rem',
              color: '#eab308',
              marginBottom: 8,
              fontWeight: 800,
            }}
          >
            Core Features
          </h2>
          <ul
            style={{
              lineHeight: 1.7,
              color: '#bfa14a',
              fontSize: '1.1rem',
              fontWeight: 600,
            }}
          >
            <li>
              <b>🎤 Audio Evidence Recording:</b> Record, play, and share audio
              evidence securely.
            </li>
            <li>
              <b>👥 Trusted Contacts:</b> Manage circles, roles, and permissions
              for family and friends.
            </li>
            <li>
              <b>🔔 Smart Notifications:</b> Context-aware push notifications
              for all safety events.
            </li>
            <li>
              <b>🔐 Multi-Factor Authentication:</b> Phone OTP, Apple, and
              Google sign-in with JWT security.
            </li>
            <li>
              <b>🔓 Privacy Controls:</b> Fine-grained sharing, consent, and
              data retention settings.
            </li>
          </ul>
        </section>
        <section style={{ marginBottom: 32 }}>
          <h2
            style={{
              fontSize: '1.5rem',
              color: '#eab308',
              marginBottom: 8,
              fontWeight: 800,
            }}
          >
            Subscription Tiers
          </h2>
          <ul
            style={{
              lineHeight: 1.7,
              color: '#bfa14a',
              fontSize: '1.1rem',
              fontWeight: 600,
            }}
          >
            <li>
              <b>Free:</b> audio, trusted contacts, phone auth, geofence setup
              (1 circle).
            </li>
            <li>
              <b>Premium:</b> All Free features plus live map, unlimited
              circles/geofences, analytics, family sharing.
            </li>
          </ul>
        </section>
        <section style={{ marginBottom: 32 }}>
          <h2
            style={{
              fontSize: '1.5rem',
              color: '#eab308',
              marginBottom: 8,
              fontWeight: 800,
            }}
          >
            Integrations & Tech
          </h2>
          <ul
            style={{
              lineHeight: 1.7,
              color: '#bfa14a',
              fontSize: '1.1rem',
              fontWeight: 600,
            }}
          >
            <li>
              <b>Apple Ecosystem:</b> CloudKit, MapKit, StoreKit 2,
              CoreLocation, AVFoundation, UserNotifications, Keychain.
            </li>
            <li>
              <b>External APIs:</b> Twilio, Apple Sign In, Google OAuth, APNs,
              OpenWeather (future).
            </li>
            <li>
              <b>Backend:</b> NestJS REST API, PostgreSQL, Redis, BullMQ, APNs,
              CloudKit sync.
            </li>
          </ul>
        </section>
        <section style={{ marginBottom: 32 }}>
          <h2
            style={{
              fontSize: '1.5rem',
              color: '#eab308',
              marginBottom: 8,
              fontWeight: 800,
            }}
          >
            Premium & Roadmap
          </h2>
          <ul
            style={{
              lineHeight: 1.7,
              color: '#bfa14a',
              fontSize: '1.1rem',
              fontWeight: 600,
            }}
          >
            <li>
              <b>🎥 Video Recording:</b> Capture and share video evidence
              (coming soon).
            </li>
            <li>
              <b>📊 Analytics Dashboard:</b> Safety trends, hotspots, and
              activity reports.
            </li>
            <li>
              <b>🤖 AI-Powered Alerts:</b> Anomaly detection and smart
              filtering.
            </li>
            <li>
              <b>🚨 Emergency Service Integration:</b> Direct dispatch to
              authorities.
            </li>
            <li>
              <b>🏢 Enterprise Features:</b> Admin dashboard, audit logs, SSO,
              DLP, advanced RBAC.
            </li>
          </ul>
        </section>
        <section style={{ marginBottom: 32 }}>
          <h2
            style={{
              fontSize: '1.5rem',
              color: '#eab308',
              marginBottom: 8,
              fontWeight: 800,
            }}
          >
            Performance & Security
          </h2>
          <ul
            style={{
              lineHeight: 1.7,
              color: '#bfa14a',
              fontSize: '1.1rem',
              fontWeight: 600,
            }}
          >
            <li>
              <b>Performance:</b> Adaptive location updates, low battery impact,
              fast notifications, efficient audio and map rendering.
            </li>
            <li>
              <b>Security:</b> End-to-end encryption (planned), HTTPS/TLS, JWT,
              Keychain, input validation, rate limiting, and more.
            </li>
          </ul>
        </section>
        <footer
          style={{
            textAlign: 'center',
            color: '#bfa14a',
            marginTop: 48,
            fontWeight: 700,
            fontSize: 16,
          }}
        >
          <p>© {new Date().getFullYear()} GeoWCS — All rights reserved.</p>
        </footer>
      </main>
    </div>
  );
}
