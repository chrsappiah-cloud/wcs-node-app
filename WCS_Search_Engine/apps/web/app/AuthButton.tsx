'use client';
import { useEffect, useState } from 'react';
import {
  GoogleAuthProvider,
  signInWithPopup,
  signOut,
  onAuthStateChanged,
  User,
} from 'firebase/auth';
import { auth } from '../firebaseClient';

export default function AuthButton() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (u) => {
      setUser(u);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  async function handleSignIn() {
    const provider = new GoogleAuthProvider();
    await signInWithPopup(auth, provider);
  }

  async function handleSignOut() {
    await signOut(auth);
  }

  if (loading)
    return (
      <button
        disabled
        style={{
          padding: '8px 18px',
          fontSize: 16,
          borderRadius: 8,
          background: 'linear-gradient(90deg, #f3e8c7 0%, #fffbe6 100%)',
          color: '#bfa14a',
          fontWeight: 700,
          border: '1.5px solid #eab308',
          boxShadow: '0 1px 4px #eab30822',
        }}
      >
        Loading...
      </button>
    );
  if (!user)
    return (
      <button
        onClick={handleSignIn}
        style={{
          padding: '8px 18px',
          fontSize: 16,
          borderRadius: 8,
          background: 'linear-gradient(90deg, #eab308 0%, #f59e42 100%)',
          color: '#fff',
          fontWeight: 700,
          border: 'none',
          boxShadow: '0 2px 8px #eab30833',
          cursor: 'pointer',
          transition: 'background 0.2s',
        }}
      >
        Sign in with Google
      </button>
    );
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
      <img
        src={user.photoURL || undefined}
        alt="avatar"
        style={{
          width: 32,
          height: 32,
          borderRadius: '50%',
          border: '2px solid #eab308',
          boxShadow: '0 0 8px #eab30855',
        }}
      />
      <span style={{ color: '#bfa14a', fontWeight: 700 }}>
        {user.displayName || user.email}
      </span>
      <button
        onClick={handleSignOut}
        style={{
          padding: '8px 18px',
          fontSize: 16,
          borderRadius: 8,
          background: 'linear-gradient(90deg, #f3e8c7 0%, #fffbe6 100%)',
          color: '#bfa14a',
          fontWeight: 700,
          border: '1.5px solid #eab308',
          boxShadow: '0 1px 4px #eab30822',
          cursor: 'pointer',
          transition: 'background 0.2s',
        }}
      >
        Sign out
      </button>
    </div>
  );
}
