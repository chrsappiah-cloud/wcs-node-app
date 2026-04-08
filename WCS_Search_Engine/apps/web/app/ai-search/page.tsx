"use client";
import React from "react";

export default function AISearchPage() {
  return (
    <div style={{ padding: 32 }}>
      <h1>AI Search</h1>
      <p>This page is under reconstruction. Please check back soon.</p>
    </div>
  );
}
"use client";
import React from "react";

export default function AISearchPage() {
  return (
    <div style={{ padding: 32 }}>
      <h1>AI Search</h1>
      <p>This page is under reconstruction. Please check back soon.</p>
    </div>
  );
}
        const res = await fetch('/api/ai-search/domain', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ query: safeQuery, domain }),
        });
        const data = await res.json();
        answer = data.aiSummary || 'No summary.';
        sources = data.results || [];
      } else if (!file) {
        const res = await fetch('/api/ai-search', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ query: safeQuery }),
        });
        const data = await res.json();
        answer = data.answer;
      } else {
        setError('You must be signed in to upload files.');
        setLoading(false);
        return;
      }
      if (answer) {
        setConversation((prev) => [...prev, { role: 'ai', content: answer, sources }]);
        setTimeout(() => { answerRef.current?.scrollIntoView({ behavior: 'smooth' }); }, 100);
        if (user) {
          await addDoc(collection(db, 'aiSearchHistory'), {
            uid: user.uid,
            query: file ? `${safeQuery} [File: ${file?.name}]` : safeQuery,
            answer,
            createdAt: new Date().toISOString(),
          });
        }
      } else setError('No answer returned.');
    } catch (err) {
      setError('Error contacting AI search API.');
    } finally {
      setLoading(false);
      setQuery('');
      setFile(null);
    }
  }
  return (
    <div style={{
      display: 'flex',
      minHeight: '100vh',
      background: 'linear-gradient(120deg, #fffbe6 0%, #f5e9c6 100%)',
      fontFamily: 'Inter, Arial, sans-serif',
    }}>
      <div style={{
        display: 'flex',
        minHeight: '100vh',
        background: 'linear-gradient(120deg, #fffbe6 0%, #f5e9c6 100%)',
        fontFamily: 'Inter, Arial, sans-serif',
      }}>
        {/* Sidebar and main content go here, only valid JSX, no JS logic */}
      </div>
                  <div style={{ background: msg.role === 'user' ? 'linear-gradient(90deg, #eab308 0%, #f59e42 100%)' : 'linear-gradient(90deg, #fffbe6 0%, #f5e9c6 100%)', color: msg.role === 'user' ? '#fff' : '#bfa14a', borderRadius: 16, padding: '14px 18px', fontSize: 18, maxWidth: 340, boxShadow: msg.role === 'user' ? '0 2px 8px #eab30833' : '0 1px 4px #eab30822', fontWeight: 500, border: msg.role === 'user' ? '1.5px solid #eab308' : '1px solid #f3e8c7', transition: 'background 0.2s' }}>{msg.content}</div>
                  {/* Show sources/links if present and AI */}
                  {msg.role === 'ai' && Array.isArray(msg.sources) && msg.sources.length > 0 && (
                    <div style={{ marginTop: 8, fontSize: 15, background: '#fffbe6', borderRadius: 10, padding: '8px 12px', border: '1px solid #f3e8c7', color: '#bfa14a', maxWidth: 320 }}>
                      <div style={{ fontWeight: 600, color: '#bfa100', marginBottom: 4 }}>Sources:</div>
                      <ul style={{ paddingLeft: 18, margin: 0 }}>
                        {msg.sources.map((src: any, idx: number) => (
                          <li key={idx} style={{ marginBottom: 2 }}>
                            {src.url ? (
                              <a href={src.url} target="_blank" rel="noopener noreferrer" style={{ color: '#bfa100', textDecoration: 'underline' }}>
              if (answer) {
                setConversation((prev) => [...prev, { role: 'ai', content: answer, sources }]);
                setTimeout(() => { answerRef.current?.scrollIntoView({ behavior: 'smooth' }); }, 100);
                if (user) {
                  await addDoc(collection(db, 'aiSearchHistory'), {
                    uid: user.uid,
                    query: file ? `${safeQuery} [File: ${file?.name}]` : safeQuery,
                    answer,
                    createdAt: new Date().toISOString(),
                  });
                }
              } else setError('No answer returned.');
            } catch (err) {
              setError('Error contacting AI search API.');
            } finally {
              setLoading(false);
              setQuery('');
              setFile(null);
            }
          }} style={{ display: 'flex', flexDirection: 'column', gap: 10, margin: '0 auto', maxWidth: 420, background: '#f1f5f9', borderRadius: 12, padding: 10, boxShadow: '0 1px 4px #0001' }}>
            <div style={{ display: 'flex', gap: 10 }}>
              <select value={domain} onChange={e => setDomain(e.target.value)} style={{ padding: '12px 8px', fontSize: 16, borderRadius: 8, border: '1px solid #f3e8c7', color: '#bfa14a', background: '#fffbe6', fontWeight: 600 }} disabled={loading}>
                <option value="">General AI</option>
                <option value="dementia">Dementia (MedlinePlus)</option>
                <option value="disability">Disability (WHO)</option>
                <option value="mental_health">Mental Health (WHO)</option>
                <option value="diagnosis">Diagnosis (MedlinePlus)</option>
                <option value="medication">Medication (RxNorm)</option>
                <option value="creative_arts">Creative Arts (Arts.gov)</option>
              </select>
              <input type="text" value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Ask anything about education, accessibility, or research..." style={{ flex: 1, padding: '12px 16px', fontSize: 18, border: 'none', borderRadius: 8, outline: 'none', background: '#fffbe6', color: '#bfa14a', boxShadow: '0 1px 4px #eab30822', fontWeight: 500 }} aria-label="Search query" disabled={loading} autoFocus />
              <button type="submit" disabled={loading || !query} style={{ padding: '0 24px', fontSize: 18, borderRadius: 8, border: 'none', background: loading || !query ? '#f3e8c7' : 'linear-gradient(90deg, #eab308 0%, #f59e42 100%)', color: loading || !query ? '#bfa14a' : '#fff', fontWeight: 700, cursor: loading || !query ? 'not-allowed' : 'pointer', boxShadow: '0 2px 8px #eab30833', transition: 'background 0.2s' }}>{loading ? 'Searching...' : 'Ask'}</button>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <input type="file" accept=".pdf,.doc,.docx,application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document" onChange={(e) => { if (e.target.files && e.target.files[0]) setFile(e.target.files[0]); else setFile(null); }} disabled={loading} style={{ fontSize: 16, color: '#bfa14a', background: '#fffbe6', border: '1px solid #f3e8c7', borderRadius: 6, padding: '4px 8px' }} />
              {file && (<span style={{ color: '#eab308', fontWeight: 700 }}>{file.name}</span>)}
              <span style={{ color: '#bfa14a', fontSize: 18, marginLeft: 'auto', opacity: 0.8, filter: 'drop-shadow(0 0 2px #eab30888)' }} title="Voice input coming soon!">🎤</span>
            </div>
            {fileText && (
              <div style={{ background: 'linear-gradient(90deg, #fffbe6 0%, #f5e9c6 100%)', color: '#bfa14a', borderRadius: 8, padding: 12, margin: '10px auto', maxWidth: 400, fontSize: 15, border: '1px solid #f3e8c7', boxShadow: '0 1px 4px #eab30822' }}>
                <b>Extracted file text:</b>
                <div style={{ whiteSpace: 'pre-wrap', marginTop: 4 }}>{fileText.slice(0, 1200)}{fileText.length > 1200 ? '...' : ''}</div>
              </div>
            )}
            {error && (<div style={{ color: '#eab308', marginBottom: 8, fontWeight: 700 }}>{error}</div>)}
          </form>
        </div>
      </main>
    </div>
  );
              if (answer) {
