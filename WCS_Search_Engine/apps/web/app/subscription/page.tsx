export default function SubscriptionPage() {
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
        Subscription
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
        Manage your subscription tier and access premium features.
      </p>
      {/* TODO: Integrate with backend for subscription management */}
    </div>
  );
}
