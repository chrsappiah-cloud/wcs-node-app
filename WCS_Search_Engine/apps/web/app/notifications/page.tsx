export default function NotificationsPage() {
  return (
    <div
      style={{
        background: 'var(--gold-gradient)',
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        boxShadow: 'var(--gold-shadow)',
        color: 'var(--foreground)',
      }}
    >
      <h1
        style={{
          color: 'var(--gold)',
          fontWeight: 800,
          fontSize: '2.5rem',
          textShadow: '0 2px 12px #eab30833',
          marginBottom: 12,
        }}
      >
        Notifications
      </h1>
      <p
        style={{
          color: 'var(--gold-dark)',
          fontSize: '1.2rem',
          marginBottom: 24,
          textAlign: 'center',
          maxWidth: 480,
        }}
      >
        View all your smart notifications and alert history here.
      </p>
      {/* TODO: Integrate with backend and Firebase for notifications */}
    </div>
  );
}
