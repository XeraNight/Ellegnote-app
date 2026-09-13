import React, { useState, useEffect } from 'react';
import { supabase } from './supabase';

export default function App() {
  const [user, setUser] = useState(null);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [nickname, setNickname] = useState('');
  const [isSignUp, setIsSignUp] = useState(false);
  const [nodes, setNodes] = useState([]);
  const [partnerPresences, setPartnerPresences] = useState({});
  const [loading, setLoading] = useState(true);

  // 1. Check Auth session
  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      setLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });

    return () => subscription.unsubscribe();
  }, []);

  // 2. Fetch Canvas Nodes & subscribe to Realtime Postgres Changes
  useEffect(() => {
    fetchNodes();

    const channel = supabase
      .channel('canvas-realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'canvas_nodes' }, (payload) => {
        if (payload.eventType === 'INSERT' || payload.eventType === 'UPDATE') {
          setNodes((prev) => {
            const idx = prev.findIndex((n) => n.id === payload.new.id);
            if (idx >= 0) {
              const updated = [...prev];
              updated[idx] = payload.new;
              return updated;
            }
            return [...prev, payload.new];
          });
        } else if (payload.eventType === 'DELETE') {
          setNodes((prev) => prev.filter((n) => n.id === payload.old.id));
        }
      })
      .on('presence', { event: 'sync' }, () => {
        const state = channel.presenceState();
        const presences = {};
        Object.keys(state).forEach((key) => {
          if (state[key].length > 0) {
            const p = state[key][0];
            presences[p.userId] = p;
          }
        });
        setPartnerPresences(presences);
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const fetchNodes = async () => {
    const { data, error } = await supabase.from('canvas_nodes').select('*').order('order_index');
    if (!error && data) {
      setNodes(data);
    }
  };

  const handleAuth = async (e) => {
    e.preventDefault();
    setLoading(true);
    if (isSignUp) {
      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: { data: { name: nickname } },
      });
      if (error) alert(error.message);
    } else {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) alert(error.message);
    }
    setLoading(false);
  };

  const handleSignOut = () => {
    supabase.auth.signOut();
  };

  if (loading) {
    return (
      <div style={styles.container}>
        <div style={styles.card}>Načítavam Ellegnote...</div>
      </div>
    );
  }

  return (
    <div style={styles.container}>
      {/* Header Bar */}
      <header style={styles.header}>
        <div>
          <h1 style={styles.logoTitle}>ELLEGNOTE WEB</h1>
          <p style={styles.subTitle}>Choreografie a Realtime Canvas pre Android & iOS</p>
        </div>
        {user ? (
          <div style={styles.userInfo}>
            <span>👤 {user.email}</span>
            <button style={styles.buttonSecondary} onClick={handleSignOut}>
              Odhlásiť
            </button>
          </div>
        ) : (
          <div style={styles.badgeAlert}> Režim hosťa (Prihlás sa pre úpravy)</div>
        )}
      </header>

      {/* Auth Form modal if not logged in */}
      {!user && (
        <div style={styles.authModal}>
          <form style={styles.authCard} onSubmit={handleAuth}>
            <h2 style={styles.cardTitle}>{isSignUp ? 'Vytvoriť Účet' : 'Prihlásenie'}</h2>
            {isSignUp && (
              <input
                type="text"
                placeholder="Meno / Prezývka"
                value={nickname}
                onChange={(e) => setNickname(e.target.value)}
                style={styles.input}
                required
              />
            )}
            <input
              type="email"
              placeholder="E-mail"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              style={styles.input}
              required
            />
            <input
              type="password"
              placeholder="Heslo"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              style={styles.input}
              required
            />
            <button type="submit" style={styles.buttonPrimary}>
              {isSignUp ? 'Zaregistrovať Sa' : 'Prihlásiť Sa'}
            </button>
            <p style={styles.toggleText} onClick={() => setIsSignUp(!isSignUp)}>
              {isSignUp ? 'Už máš účet? Prihlás sa' : 'Nemáš účet? Zaregistruj sa'}
            </p>
          </form>
        </div>
      )}

      {/* Realtime Interactive Canvas Area */}
      <main style={styles.canvasArea}>
        <div style={styles.canvasHeader}>
          <h2>Tancodrom Canvas ({nodes.length} figúr)</h2>
          <div style={styles.presenceContainer}>
            {Object.values(partnerPresences).map((p) => (
              <span key={p.userId} style={styles.presenceChip}>
                🟢 {p.userName || 'Partner'}
              </span>
            ))}
          </div>
        </div>

        <div style={styles.canvasField}>
          {nodes.map((node) => (
            <div
              key={node.id}
              style={{
                ...styles.nodeCard,
                left: `${node.x}px`,
                top: `${node.y}px`,
              }}
            >
              <div style={styles.nodeHeader}>{node.figure_name}</div>
              <div style={styles.nodeRhythm}>{node.rhythm || 'Count 1-2-3'}</div>
              {node.notes && <div style={styles.nodeNotes}>📝 {node.notes}</div>}
            </div>
          ))}
        </div>
      </main>
    </div>
  );
}

const styles = {
  container: {
    minHeight: '100vh',
    backgroundColor: '#F6F2E9',
    color: '#332211',
    fontFamily: 'serif',
    display: 'flex',
    flexDirection: 'column',
  },
  header: {
    padding: '16px 24px',
    backgroundColor: '#FFFDF9',
    borderBottom: '2px solid #332211',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  logoTitle: { margin: 0, fontSize: '22px', fontWeight: '900', letterSpacing: '1px' },
  subTitle: { margin: 0, fontSize: '11px', opacity: 0.6 },
  userInfo: { display: 'flex', gap: '12px', alignItems: 'center' },
  buttonPrimary: {
    backgroundColor: '#C65D3B',
    color: '#FFF',
    border: '2px solid #332211',
    padding: '10px 16px',
    borderRadius: '12px',
    fontWeight: 'bold',
    cursor: 'pointer',
  },
  buttonSecondary: {
    backgroundColor: '#FFFDF9',
    color: '#332211',
    border: '2px solid #332211',
    padding: '6px 12px',
    borderRadius: '10px',
    fontWeight: 'bold',
    cursor: 'pointer',
  },
  badgeAlert: { fontSize: '12px', fontWeight: 'bold', color: '#C65D3B' },
  authModal: {
    position: 'fixed',
    inset: 0,
    backgroundColor: 'rgba(51, 34, 17, 0.4)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 100,
  },
  authCard: {
    backgroundColor: '#FFFDF9',
    border: '2px solid #332211',
    borderRadius: '20px',
    padding: '28px',
    width: '320px',
    boxShadow: '4px 4px 0px #332211',
    display: 'flex',
    flexDirection: 'column',
    gap: '12px',
  },
  cardTitle: { margin: 0, fontSize: '18px', textAlign: 'center', fontWeight: 'bold' },
  input: {
    padding: '10px 12px',
    border: '1.5px solid #332211',
    borderRadius: '10px',
    fontSize: '14px',
    backgroundColor: '#F6F2E9',
  },
  toggleText: { fontSize: '12px', textAlign: 'center', cursor: 'pointer', opacity: 0.7, marginTop: '8px' },
  canvasArea: { padding: '24px', flex: 1 },
  canvasHeader: { display: 'flex', justifyContent: 'space-between', marginBottom: '16px' },
  presenceContainer: { display: 'flex', gap: '8px' },
  presenceChip: {
    backgroundColor: '#FFFDF9',
    border: '1px solid #332211',
    padding: '4px 8px',
    borderRadius: '12px',
    fontSize: '11px',
    fontWeight: 'bold',
  },
  canvasField: {
    position: 'relative',
    height: '600px',
    backgroundColor: '#FFFDF9',
    border: '2px dashed #332211',
    borderRadius: '20px',
    overflow: 'hidden',
  },
  nodeCard: {
    position: 'absolute',
    backgroundColor: '#F6F2E9',
    border: '2px solid #332211',
    borderRadius: '14px',
    padding: '12px',
    width: '140px',
    boxShadow: '3px 3px 0px #332211',
  },
  nodeHeader: { fontWeight: 'bold', fontSize: '13px' },
  nodeRhythm: { fontSize: '10px', opacity: 0.6, marginTop: '2px' },
  nodeNotes: { fontSize: '11px', marginTop: '6px', color: '#C65D3B' },
};
