"use client";
import { useState } from 'react';
import { GoogleAuthProvider, signInWithPopup } from 'firebase/auth';
import { auth } from '../../lib/firebase/client';

export default function LoginPage() {
  const [error, setError] = useState<string | null>(null);

  async function handleLogin() {
    setError(null);
    try {
      const provider = new GoogleAuthProvider();
      const result = await signInWithPopup(auth, provider);
      const idToken = await result.user.getIdToken();
      // Send ID token to backend for session
      const res = await fetch("/api/auth/session", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ idToken }),
      });
      if (!res.ok) throw new Error("Session creation failed");
      // Optionally redirect or update UI
      window.location.href = "/";
    } catch (err: any) {
      setError(err.message || "Login failed");
    }
  }

  return (
    <div style={{ maxWidth: 400, margin: "2rem auto", textAlign: "center" }}>
      <h1>Sign in to WCS Search</h1>
      <button onClick={handleLogin}>Sign in with Google</button>
      {error && <p style={{ color: "red" }}>{error}</p>}
    </div>
  );
}
