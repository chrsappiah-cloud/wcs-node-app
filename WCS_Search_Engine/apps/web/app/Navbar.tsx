import Link from 'next/link';
import AuthButton from './AuthButton';

export default function Navbar() {
  return (
    <nav
      style={{
        display: 'flex',
        gap: 24,
        padding: '1rem 0',
        borderBottom: '2px solid #eab308',
        marginBottom: 32,
        alignItems: 'center',
        justifyContent: 'space-between',
        background: 'linear-gradient(90deg, #fffbe6 0%, #f5e9c6 100%)',
        boxShadow: '0 2px 12px #eab30822',
      }}
    >
      <div style={{ display: 'flex', gap: 24 }}>
        <Link
          href="/"
          style={{
            color: '#eab308',
            fontWeight: 700,
            fontSize: 18,
            textShadow: '0 1px 4px #eab30833',
          }}
        >
          Home
        </Link>
        <Link
          href="/ai-search"
          style={{ color: '#bfa14a', fontWeight: 700, fontSize: 18 }}
        >
          AI Search
        </Link>
        <Link
          href="/audio"
          style={{ color: '#bfa14a', fontWeight: 700, fontSize: 18 }}
        >
          Audio
        </Link>
        {/* <Link href="/sos">SOS</Link> */}
        <Link
          href="/contacts"
          style={{ color: '#bfa14a', fontWeight: 700, fontSize: 18 }}
        >
          Contacts
        </Link>
        <Link
          href="/notifications"
          style={{ color: '#bfa14a', fontWeight: 700, fontSize: 18 }}
        >
          Notifications
        </Link>
        <Link
          href="/subscription"
          style={{ color: '#bfa14a', fontWeight: 700, fontSize: 18 }}
        >
          Subscription
        </Link>
        <Link
          href="/settings"
          style={{ color: '#bfa14a', fontWeight: 700, fontSize: 18 }}
        >
          Settings
        </Link>
      </div>
      <AuthButton />
    </nav>
  );
}
