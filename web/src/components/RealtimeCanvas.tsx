'use client'

import React, { useState, useEffect, useRef, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { RealtimeChannel } from '@supabase/supabase-js'

export type CanvasNodeItem = {
  id: string
  routine_id: string
  x: number
  y: number
  figure_name: string
  rhythm: string
  notes: string
  video_path?: string | null
  order_index: number
  transition_notes: string
}

export type RoutineInfo = {
  id: string
  name: string
  dance_name: string
  dance_category: string
  updated_at: string
  last_modified_by?: string
}

export type FigureItem = {
  id: string
  name: string
  dance_name: string
  rhythm: string
  technique_notes: string
  is_custom: boolean
}

type PresencePayload = {
  userId: string
  userName: string
  x: number
  y: number
  draggingNodeId: string | null
}

type DragBroadcastPayload = {
  nodeId: string
  x: number
  y: number
  senderId?: string
}

type CanvasActionPayload = {
  senderId?: string
  action?: 'added' | 'deleted' | string
  nodeId?: string
  x?: number
  y?: number
  figureName?: string
  rhythm?: string
  notes?: string
  videoPath?: string | null
  orderIndex?: number
  transitionNotes?: string
  senderName?: string
}

type Props = {
  routine: RoutineInfo
  user: { email: string; id: string }
  availableFigures: FigureItem[]
  onClose: () => void
}

const CANVAS_SIZE = 3000
const MIN_SCALE = 0.4
const MAX_SCALE = 2.2
const CARD_WIDTH = 180
const CARD_HEIGHT = 140
const GRID_SNAP = 20

// Clamping bounds for center of 180x140 card on a 3000x3000 ballroom
const MIN_X = 90
const MAX_X = 2910
const MIN_Y = 86
const MAX_Y = 2914

export default function RealtimeCanvas({ routine, user, availableFigures, onClose }: Props) {
  const supabase = createClient()
  const mySenderIdRef = useRef<string>(crypto.randomUUID())
  const myUserName = user.email ? user.email.split('@')[0] : 'Tanečník'

  const [nodes, setNodes] = useState<CanvasNodeItem[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [partnerPresences, setPartnerPresences] = useState<Record<string, PresencePayload>>({})
  const [isConnected, setIsConnected] = useState(false)
  const [activeDancersCount, setActiveDancersCount] = useState(1)

  // Viewport / Pan & Zoom State
  const [scale, setScale] = useState(0.85)
  const [pan, setPan] = useState<{ x: number; y: number }>({ x: 0, y: 0 })
  const [isPanning, setIsPanning] = useState(false)
  const panStartRef = useRef<{ clientX: number; clientY: number; startPanX: number; startPanY: number }>({
    clientX: 0,
    clientY: 0,
    startPanX: 0,
    startPanY: 0,
  })

  // Node Dragging State
  const [draggingNodeId, setDraggingNodeId] = useState<string | null>(null)
  const dragInfoRef = useRef<{
    nodeId: string
    startX: number
    startY: number
    initialNodeX: number
    initialNodeY: number
  } | null>(null)

  const lastBroadcastRef = useRef<number>(0)
  const lastPresenceTrackRef = useRef<number>(0)
  const viewportRef = useRef<HTMLDivElement>(null)
  const channelRef = useRef<RealtimeChannel | null>(null)

  // Quick Figure Add Modal
  const [showAddModal, setShowAddModal] = useState(false)
  const [searchFig, setSearchFig] = useState('')

  // Toast Notification
  const [toastMsg, setToastMsg] = useState<string | null>(null)
  const showToast = (msg: string) => {
    setToastMsg(msg)
    setTimeout(() => setToastMsg(null), 3000)
  }

  // ── 1. Fetch initial nodes ──────────────────────────────────────────────
  useEffect(() => {
    let isMounted = true
    async function fetchNodes() {
      setIsLoading(true)
      const { data, error } = await supabase
        .from('canvas_nodes')
        .select('*')
        .eq('routine_id', routine.id)
        .order('order_index', { ascending: true })

      if (!error && data && isMounted) {
        setNodes(data as CanvasNodeItem[])
      }
      if (isMounted) setIsLoading(false)
    }
    fetchNodes()
    return () => { isMounted = false }
  }, [routine.id])

  // ── 2. Connect Supabase Realtime Channel ─────────────────────────────────
  useEffect(() => {
    const channelName = `canvas_${routine.id.toLowerCase()}`
    const ch = supabase.channel(channelName, {
      config: {
        broadcast: { ack: false, self: false },
        presence: { key: mySenderIdRef.current },
      },
    })
    channelRef.current = ch

    // A. Broadcast: Node moved in real-time (60fps drag)
    ch.on('broadcast', { event: 'node_moved' }, ({ payload }: { payload: DragBroadcastPayload }) => {
      if (payload.senderId === mySenderIdRef.current) return
      setNodes(prev =>
        prev.map(n => (n.id === payload.nodeId ? { ...n, x: payload.x, y: payload.y } : n))
      )
    })

    // B. Broadcast: Canvas structural actions (node added, deleted, updated)
    ch.on('broadcast', { event: 'canvas_action' }, ({ payload }: { payload: CanvasActionPayload }) => {
      if (payload.senderId === mySenderIdRef.current) return
      if (payload.action === 'added' && payload.nodeId) {
        setNodes(prev => {
          if (prev.some(n => n.id === payload.nodeId)) return prev
          return [
            ...prev,
            {
              id: payload.nodeId!,
              routine_id: routine.id,
              x: payload.x ?? 0,
              y: payload.y ?? 0,
              figure_name: payload.figureName ?? '',
              rhythm: payload.rhythm ?? '',
              notes: payload.notes ?? '',
              video_path: payload.videoPath,
              order_index: payload.orderIndex ?? prev.length,
              transition_notes: payload.transitionNotes ?? '',
            },
          ]
        })
        showToast(`${payload.senderName || 'Partner'} pridal figúru ${payload.figureName}`)
      } else if (payload.action === 'deleted' && payload.nodeId) {
        setNodes(prev => prev.filter(n => n.id !== payload.nodeId))
        showToast(`${payload.senderName || 'Partner'} odstránil figúru`)
      }
    })

    // C. Postgres Changes: Fallback DB-level synchronization
    ch.on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'canvas_nodes',
        filter: `routine_id=eq.${routine.id.toLowerCase()}`,
      },
      (payload: { eventType: string; new: Record<string, unknown>; old: Record<string, unknown> }) => {
        if (payload.eventType === 'INSERT') {
          const newNode = payload.new as unknown as CanvasNodeItem
          setNodes(prev => {
            if (prev.some(n => n.id === newNode.id)) return prev
            return [...prev, newNode]
          })
        } else if (payload.eventType === 'UPDATE') {
          const updatedNode = payload.new as unknown as CanvasNodeItem
          setNodes(prev =>
            prev.map(n => (n.id === updatedNode.id ? updatedNode : n))
          )
        } else if (payload.eventType === 'DELETE') {
          const oldId = (payload.old as { id?: string }).id
          if (oldId) {
            setNodes(prev => prev.filter(n => n.id !== oldId))
          }
        }
      }
    )

    // D. Presence: Live partner cursors & soft-locking
    ch.on('presence', { event: 'sync' }, () => {
      const state = ch.presenceState<PresencePayload>()
      const partners: Record<string, PresencePayload> = {}
      let totalDancers = 0

      Object.entries(state).forEach(([key, presenceList]) => {
        totalDancers += presenceList.length
        presenceList.forEach(p => {
          if (p.userId !== mySenderIdRef.current) {
            partners[p.userId] = p
          }
        })
      })

      setPartnerPresences(partners)
      setActiveDancersCount(Math.max(1, totalDancers))
    })

    // Subscribe to channel
    ch.subscribe(status => {
      if (status === 'SUBSCRIBED') {
        setIsConnected(true)
        // Initial presence track
        ch.track({
          userId: mySenderIdRef.current,
          userName: myUserName,
          x: 1500,
          y: 1500,
          draggingNodeId: null,
        })
      } else {
        setIsConnected(false)
      }
    })

    return () => {
      ch.untrack()
      supabase.removeChannel(ch)
      channelRef.current = null
      setIsConnected(false)
    }
  }, [routine.id, myUserName])

  // ── 3. Coordinate Transformation Math ───────────────────────────────────
  // Screen Viewport -> Canvas World (3000x3000px centered at 1500, 1500)
  const screenToCanvas = useCallback(
    (clientX: number, clientY: number): { x: number; y: number } => {
      if (!viewportRef.current) return { x: 1500, y: 1500 }
      const rect = viewportRef.current.getBoundingClientRect()
      const vWidth = rect.width
      const vHeight = rect.height

      const localX = clientX - rect.left
      const localY = clientY - rect.top

      const canvasX = 1500 + (localX - vWidth / 2 - pan.x) / scale
      const canvasY = 1500 + (localY - vHeight / 2 - pan.y) / scale

      return {
        x: Math.min(Math.max(canvasX, 0), CANVAS_SIZE),
        y: Math.min(Math.max(canvasY, 0), CANVAS_SIZE),
      }
    },
    [pan, scale]
  )

  // ── 4. Broadcast Mouse / Cursor Presence ─────────────────────────────────
  const handleViewportPointerMove = (e: React.PointerEvent) => {
    // If panning canvas background
    if (isPanning) {
      const dx = e.clientX - panStartRef.current.clientX
      const dy = e.clientY - panStartRef.current.clientY
      setPan({
        x: panStartRef.current.startPanX + dx,
        y: panStartRef.current.startPanY + dy,
      })
      return
    }

    // If dragging a node
    if (draggingNodeId && dragInfoRef.current) {
      const dxScreen = e.clientX - dragInfoRef.current.startX
      const dyScreen = e.clientY - dragInfoRef.current.startY

      // Scale-invariant delta: Δx = δx / scale
      const rawX = dragInfoRef.current.initialNodeX + dxScreen / scale
      const rawY = dragInfoRef.current.initialNodeY + dyScreen / scale

      // Boundary clamping
      const clampedX = Math.min(Math.max(rawX, MIN_X), MAX_X)
      const clampedY = Math.min(Math.max(rawY, MIN_Y), MAX_Y)

      // Update local state immediately for 60fps local drag
      setNodes(prev =>
        prev.map(n => (n.id === draggingNodeId ? { ...n, x: clampedX, y: clampedY } : n))
      )

      // Broadcast at ~35ms intervals
      const now = performance.now()
      if (now - lastBroadcastRef.current >= 35) {
        lastBroadcastRef.current = now
        if (channelRef.current && isConnected) {
          channelRef.current.send({
            type: 'broadcast',
            event: 'node_moved',
            payload: {
              nodeId: draggingNodeId,
              x: clampedX,
              y: clampedY,
              senderId: mySenderIdRef.current,
            },
          })
          channelRef.current.track({
            userId: mySenderIdRef.current,
            userName: myUserName,
            x: clampedX,
            y: clampedY,
            draggingNodeId: draggingNodeId,
          })
        }
      }
      return
    }

    // Otherwise, normal pointer motion: update partner presence cursor (~50ms throttle)
    const now = performance.now()
    if (now - lastPresenceTrackRef.current >= 50) {
      lastPresenceTrackRef.current = now
      const canvasCoords = screenToCanvas(e.clientX, e.clientY)
      if (channelRef.current && isConnected) {
        channelRef.current.track({
          userId: mySenderIdRef.current,
          userName: myUserName,
          x: Math.round(canvasCoords.x),
          y: Math.round(canvasCoords.y),
          draggingNodeId: null,
        })
      }
    }
  }

  // ── 5. End Panning or Node Dragging ──────────────────────────────────────
  const handleViewportPointerUp = async () => {
    if (isPanning) {
      setIsPanning(false)
    }

    if (draggingNodeId && dragInfoRef.current) {
      const activeNode = nodes.find(n => n.id === draggingNodeId)
      if (activeNode) {
        // Magnetic snap to 20px grid
        const snappedX = Math.min(Math.max(Math.round(activeNode.x / GRID_SNAP) * GRID_SNAP, MIN_X), MAX_X)
        const snappedY = Math.min(Math.max(Math.round(activeNode.y / GRID_SNAP) * GRID_SNAP, MIN_Y), MAX_Y)

        setNodes(prev =>
          prev.map(n => (n.id === draggingNodeId ? { ...n, x: snappedX, y: snappedY } : n))
        )

        // Broadcast final position
        if (channelRef.current && isConnected) {
          channelRef.current.send({
            type: 'broadcast',
            event: 'node_moved',
            payload: {
              nodeId: draggingNodeId,
              x: snappedX,
              y: snappedY,
              senderId: mySenderIdRef.current,
            },
          })
          channelRef.current.track({
            userId: mySenderIdRef.current,
            userName: myUserName,
            x: snappedX,
            y: snappedY,
            draggingNodeId: null,
          })
        }

        // Persist to PostgreSQL database
        await supabase
          .from('canvas_nodes')
          .update({ x: snappedX, y: snappedY })
          .eq('id', draggingNodeId)

        await supabase
          .from('routines')
          .update({
            updated_at: new Date().toISOString(),
            last_modified_by: myUserName,
          })
          .eq('id', routine.id)
      }

      setDraggingNodeId(null)
      dragInfoRef.current = null
    }
  }

  // ── 6. Mouse Wheel Zoom ──────────────────────────────────────────────────
  const handleWheel = (e: React.WheelEvent) => {
    e.preventDefault()
    const zoomFactor = e.deltaY < 0 ? 1.08 : 0.92
    const newScale = Math.min(Math.max(scale * zoomFactor, MIN_SCALE), MAX_SCALE)
    setScale(newScale)
  }

  // ── 7. Card Drag Start (Soft-Locking Protection) ─────────────────────────
  const handleCardPointerDown = (e: React.PointerEvent, node: CanvasNodeItem) => {
    e.stopPropagation()

    // Check soft-lock: is another dancer currently dragging this node?
    const lockedPartner = Object.values(partnerPresences).find(p => p.draggingNodeId === node.id)
    if (lockedPartner) {
      showToast(`${lockedPartner.userName} práve presúva túto figúru!`)
      return
    }

    setDraggingNodeId(node.id)
    dragInfoRef.current = {
      nodeId: node.id,
      startX: e.clientX,
      startY: e.clientY,
      initialNodeX: node.x,
      initialNodeY: node.y,
    }

    // Immediately claim soft-lock via presence
    if (channelRef.current && isConnected) {
      channelRef.current.track({
        userId: mySenderIdRef.current,
        userName: myUserName,
        x: node.x,
        y: node.y,
        draggingNodeId: node.id,
      })
    }
  }

  // ── 8. Add Figure to Canvas ──────────────────────────────────────────────
  const handleAddFigure = async (fig: FigureItem) => {
    const nextOrder = nodes.length > 0 ? Math.max(...nodes.map(n => n.order_index)) + 1 : 0
    const lastNode = nodes[nodes.length - 1]
    const newX = lastNode ? Math.min(lastNode.x + 220, MAX_X) : 1500
    const newY = lastNode ? Math.min(lastNode.y + 120, MAX_Y) : 1500

    const newNodeId = crypto.randomUUID()
    const newNodeData: CanvasNodeItem = {
      id: newNodeId,
      routine_id: routine.id,
      x: newX,
      y: newY,
      figure_name: fig.name,
      rhythm: fig.rhythm || '1 2 3',
      notes: fig.technique_notes || '',
      order_index: nextOrder,
      transition_notes: '',
    }

    // Optimistic local add
    setNodes(prev => [...prev, newNodeData])
    setShowAddModal(false)

    // Broadcast to partner for instant appearance
    if (channelRef.current && isConnected) {
      channelRef.current.send({
        type: 'broadcast',
        event: 'canvas_action',
        payload: {
          action: 'added',
          nodeId: newNodeId,
          figureName: fig.name,
          x: newX,
          y: newY,
          rhythm: fig.rhythm,
          notes: fig.technique_notes,
          orderIndex: nextOrder,
          transitionNotes: '',
          senderId: mySenderIdRef.current,
          senderName: myUserName,
        },
      })
    }

    // Save to Supabase DB
    await supabase.from('canvas_nodes').insert({
      id: newNodeId,
      routine_id: routine.id,
      x: newX,
      y: newY,
      figure_name: fig.name,
      rhythm: fig.rhythm || '1 2 3',
      notes: fig.technique_notes || '',
      order_index: nextOrder,
      transition_notes: '',
    })

    showToast(`Pridaná figúra: ${fig.name}`)
  }

  // ── 9. Delete Node from Canvas ───────────────────────────────────────────
  const handleDeleteNode = async (nodeId: string, figName: string) => {
    setNodes(prev => prev.filter(n => n.id !== nodeId))

    // Broadcast deletion
    if (channelRef.current && isConnected) {
      channelRef.current.send({
        type: 'broadcast',
        event: 'canvas_action',
        payload: {
          action: 'deleted',
          nodeId: nodeId,
          figureName: figName,
          senderId: mySenderIdRef.current,
          senderName: myUserName,
        },
      })
    }

    // Delete in DB
    await supabase.from('canvas_nodes').delete().eq('id', nodeId)
    showToast(`Figúra ${figName} odstránená`)
  }

  // Filter figures for modal
  const filteredFigures = availableFigures.filter(f =>
    f.name.toLowerCase().includes(searchFig.toLowerCase()) ||
    f.dance_name.toLowerCase().includes(searchFig.toLowerCase())
  )

  // Sorted nodes for connection lines
  const sortedNodes = [...nodes].sort((a, b) => a.order_index - b.order_index)

  const isStandard = routine.dance_category?.toLowerCase() === 'standard'
  const accentColor = isStandard ? '#3B82F6' : '#F43F5E'

  return (
    <div className="fixed inset-0 z-50 bg-[#050505] text-white flex flex-col select-none overflow-hidden font-sans">
      
      {/* ── Top Bar / Live Sync Header ───────────────────────────────────── */}
      <header className="h-16 px-6 bg-[#0a0a0d]/90 backdrop-blur-xl border-b border-white/[0.08] flex items-center justify-between z-30 shrink-0">
        <div className="flex items-center gap-4">
          <button
            onClick={onClose}
            className="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-white/[0.05] hover:bg-white/[0.1] border border-white/[0.1] text-xs font-bold transition-colors cursor-pointer"
          >
            <span>←</span> Späť do nástenky
          </button>

          <div className="h-4 w-[1px] bg-white/[0.15]" />

          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-sm font-black tracking-wide text-white">{routine.name}</h2>
              <span
                className="text-[10px] font-black px-2 py-0.5 rounded-md uppercase"
                style={{
                  backgroundColor: `${accentColor}25`,
                  color: accentColor,
                  border: `1px solid ${accentColor}40`,
                }}
              >
                {routine.dance_name}
              </span>
            </div>
            <p className="text-[11px] text-white/40">
              {nodes.length} figúr · {routine.dance_category}
            </p>
          </div>
        </div>

        {/* Realtime Status Indicator & Actions */}
        <div className="flex items-center gap-4">
          {/* Connection badge */}
          <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-[#121217] border border-white/[0.08] text-xs">
            <span
              className={`w-2 h-2 rounded-full ${
                isConnected ? 'bg-[#10B981] shadow-[0_0_8px_#10B981]' : 'bg-[#EF4444]'
              }`}
            />
            <span className="text-white/70 font-medium">
              {isConnected ? 'Realtime Aktívny' : 'Pripájanie...'}
            </span>
            <span className="text-white/30 text-[10px]">|</span>
            <span className="text-[#D4AF37] font-bold text-xs flex items-center gap-1">
              👥 {activeDancersCount} {activeDancersCount === 1 ? 'tanečník' : 'tanečníci'}
            </span>
          </div>

          {/* Quick Add Figure Button */}
          <button
            onClick={() => setShowAddModal(true)}
            className="btn-ellegance text-xs py-2 px-4 flex items-center gap-1.5 cursor-pointer"
          >
            <span>+</span> Pridať figúru
          </button>

          {/* Reset Zoom & View */}
          <button
            onClick={() => { setScale(0.85); setPan({ x: 0, y: 0 }) }}
            title="Vycentrovať plátno"
            className="w-9 h-9 rounded-xl bg-white/[0.05] hover:bg-white/[0.1] border border-white/[0.1] flex items-center justify-center text-xs font-bold transition-colors cursor-pointer"
          >
            🎯
          </button>
        </div>
      </header>

      {/* ── Toast Notification ───────────────────────────────────────────── */}
      {toastMsg && (
        <div className="fixed top-20 left-1/2 -translate-x-1/2 z-50 px-4 py-2 rounded-xl bg-[#18181f]/95 border border-[#D4AF37]/50 text-[#FFE088] text-xs font-bold shadow-2xl flex items-center gap-2 backdrop-blur-md">
          <span className="text-[#D4AF37]">✦</span> {toastMsg}
        </div>
      )}

      {/* ── Main Canvas Viewport ─────────────────────────────────────────── */}
      <div
        ref={viewportRef}
        onWheel={handleWheel}
        onPointerDown={e => {
          // Pan canvas on background click
          if (e.target === e.currentTarget || (e.target as HTMLElement).classList.contains('canvas-bg')) {
            setIsPanning(true)
            panStartRef.current = {
              clientX: e.clientX,
              clientY: e.clientY,
              startPanX: pan.x,
              startPanY: pan.y,
            }
          }
        }}
        onPointerMove={handleViewportPointerMove}
        onPointerUp={handleViewportPointerUp}
        className="flex-1 relative overflow-hidden cursor-grab active:cursor-grabbing bg-[#050505]"
      >
        {/* Loading Spinner */}
        {isLoading && (
          <div className="absolute inset-0 z-40 bg-[#050505]/80 flex items-center justify-center">
            <div className="flex flex-col items-center gap-3">
              <div className="w-8 h-8 border-2 border-[#D4AF37] border-t-transparent rounded-full animate-spin" />
              <p className="text-xs font-bold text-[#D4AF37]">Načítavam tanečné plátno...</p>
            </div>
          </div>
        )}

        {/* ── Scaled & Panned Ballroom Canvas Container ─────────────────────── */}
        <div
          className="absolute origin-center transition-transform ease-out will-change-transform"
          style={{
            width: `${CANVAS_SIZE}px`,
            height: `${CANVAS_SIZE}px`,
            left: `calc(50% - ${CANVAS_SIZE / 2}px + ${pan.x}px)`,
            top: `calc(50% - ${CANVAS_SIZE / 2}px + ${pan.y}px)`,
            transform: `scale(${scale})`,
          }}
        >
          {/* Ballroom Parquet Wood Floor with Luxury Depth */}
          <div
            className="absolute inset-0 canvas-bg pointer-events-auto rounded-[32px] overflow-hidden shadow-2xl"
            style={{
              backgroundImage: `url('/dance_parquet_floor.jpg')`,
              backgroundSize: '800px 800px',
              backgroundRepeat: 'repeat',
            }}
          >
            {/* Subtle dark tint overlay for high contrast node reading */}
            <div className="absolute inset-0 bg-[#080305]/70" />

            {/* Precision dance grid lines overlay */}
            <div
              className="absolute inset-0"
              style={{
                backgroundImage: `
                  linear-gradient(to right, rgba(212, 175, 55, 0.08) 1px, transparent 1px),
                  linear-gradient(to bottom, rgba(212, 175, 55, 0.08) 1px, transparent 1px)
                `,
                backgroundSize: '100px 100px',
              }}
            />
          </div>

          {/* ── Ballroom Perimeter Walls & LOD Directions ─────────────────── */}
          {/* Outer Gold Border Wall */}
          <div className="absolute inset-8 rounded-[40px] border-2 border-[#D4AF37]/35 shadow-[inset_0_0_60px_rgba(0,0,0,0.8)] pointer-events-none" />

          {/* Top Wall: Short Wall LOD */}
          <div className="absolute top-10 left-1/2 -translate-x-1/2 px-6 py-1.5 rounded-full bg-black/60 border border-[#D4AF37]/40 text-[#FFE088] text-xs font-black tracking-widest uppercase pointer-events-none flex items-center gap-2">
            <span>▲ HORNÁ KRÁTKA STENA</span>
            <span className="text-[#D4AF37]">•</span>
            <span className="text-emerald-400">LOD SMER ▶</span>
          </div>

          {/* Bottom Wall: Short Wall LOD */}
          <div className="absolute bottom-10 left-1/2 -translate-x-1/2 px-6 py-1.5 rounded-full bg-black/60 border border-[#D4AF37]/40 text-[#FFE088] text-xs font-black tracking-widest uppercase pointer-events-none flex items-center gap-2">
            <span>▼ DOLNÁ KRÁTKA STENA</span>
            <span className="text-[#D4AF37]">•</span>
            <span className="text-emerald-400">◀ LOD SMER</span>
          </div>

          {/* Right Wall: Long Wall */}
          <div className="absolute right-10 top-1/2 -translate-y-1/2 px-5 py-1.5 rounded-full bg-black/60 border border-white/10 text-white/60 text-xs font-black tracking-widest uppercase pointer-events-none rotate-90 origin-center flex items-center gap-2">
            <span>PRAVÁ DLHÁ STENA</span>
            <span className="text-emerald-400">▼</span>
          </div>

          {/* Left Wall: Long Wall */}
          <div className="absolute left-10 top-1/2 -translate-y-1/2 px-5 py-1.5 rounded-full bg-black/60 border border-white/10 text-white/60 text-xs font-black tracking-widest uppercase pointer-events-none -rotate-90 origin-center flex items-center gap-2">
            <span>ĽAVÁ DLHÁ STENA</span>
            <span className="text-emerald-400">▲</span>
          </div>

          {/* Center of Room Gold Compass Rose */}
          <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[280px] h-[280px] rounded-full border border-[#D4AF37]/20 flex flex-col items-center justify-center pointer-events-none text-center shadow-[0_0_50px_rgba(212,175,55,0.05)]">
            <div className="w-[180px] h-[180px] rounded-full border border-dashed border-[#D4AF37]/15 flex flex-col items-center justify-center">
              <span className="text-[11px] font-black tracking-widest text-[#D4AF37]/50 uppercase font-sans">
                STRED SÁLY
              </span>
              <span className="text-[9px] text-[#FFE088]/30 font-mono">(Center of Room)</span>
            </div>
          </div>

          {/* ── SVG Connection Lines Layer ─────────────────────────────────── */}
          <svg className="absolute inset-0 w-full h-full pointer-events-none">
            <defs>
              <linearGradient id="connectionGold" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" stopColor="#D4AF37" stopOpacity="0.7" />
                <stop offset="100%" stopColor="#FFE088" stopOpacity="0.2" />
              </linearGradient>
            </defs>
            {sortedNodes.map((curr, idx) => {
              if (idx === 0) return null
              const prev = sortedNodes[idx - 1]
              const dx = curr.x - prev.x
              const p1 = { x: prev.x, y: prev.y }
              const p2 = { x: curr.x, y: curr.y }
              const pathD = `M ${p1.x} ${p1.y} C ${p1.x + dx * 0.5} ${p1.y}, ${p1.x + dx * 0.5} ${p2.y}, ${p2.x} ${p2.y}`

              return (
                <path
                  key={`line-${prev.id}-${curr.id}`}
                  d={pathD}
                  fill="none"
                  stroke="url(#connectionGold)"
                  strokeWidth="3"
                  strokeDasharray="6 4"
                  strokeLinecap="round"
                />
              )
            })}
          </svg>

          {/* ── Canvas Node Cards ───────────────────────────────────────────── */}
          {nodes.map(node => {
            const isDragging = draggingNodeId === node.id
            const lockedPartner = Object.values(partnerPresences).find(
              p => p.draggingNodeId === node.id
            )

            return (
              <div
                key={node.id}
                onPointerDown={e => handleCardPointerDown(e, node)}
                style={{
                  position: 'absolute',
                  left: `${node.x}px`,
                  top: `${node.y}px`,
                  transform: 'translate(-50%, -50%)',
                  width: `${CARD_WIDTH}px`,
                  zIndex: isDragging ? 50 : 20,
                }}
                className={`group cursor-grab active:cursor-grabbing select-none p-3 rounded-2xl transition-shadow ${
                  lockedPartner
                    ? 'bg-[#18181f] border-2 border-[#D4AF37] shadow-[0_0_24px_rgba(212,175,55,0.4)] animate-pulse'
                    : isDragging
                    ? 'bg-[#141419] border-2 border-[#D4AF37] shadow-[0_12px_36px_rgba(0,0,0,0.8),0_0_20px_rgba(212,175,55,0.3)] scale-105'
                    : 'bg-[#0e0e12]/95 backdrop-blur-md border border-white/[0.08] hover:border-[#D4AF37]/50 shadow-lg'
                }`}
              >
                {/* Partner Lock Pill */}
                {lockedPartner && (
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-2.5 py-0.5 rounded-full bg-[#D4AF37] text-[#050505] text-[10px] font-black uppercase tracking-wider shadow-md whitespace-nowrap flex items-center gap-1">
                    <span>🔒</span> {lockedPartner.userName} presúva
                  </div>
                )}

                {/* Card Header: Order Number & Delete */}
                <div className="flex items-center justify-between mb-2">
                  <span
                    className="text-[10px] font-black px-2 py-0.5 rounded-md uppercase"
                    style={{
                      backgroundColor: `${accentColor}20`,
                      color: accentColor,
                      border: `1px solid ${accentColor}40`,
                    }}
                  >
                    #{node.order_index + 1}
                  </span>

                  <button
                    onPointerDown={e => e.stopPropagation()}
                    onClick={() => handleDeleteNode(node.id, node.figure_name)}
                    className="opacity-0 group-hover:opacity-100 transition-opacity text-white/30 hover:text-[#EF4444] text-xs p-1 cursor-pointer"
                    title="Odstrániť figúru"
                  >
                    ✕
                  </button>
                </div>

                {/* Figure Title */}
                <h4 className="font-bold text-xs text-white leading-tight line-clamp-1 group-hover:text-[#D4AF37] transition-colors">
                  {node.figure_name}
                </h4>

                {/* Rhythm & Info */}
                <div className="mt-2 flex items-center justify-between">
                  <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-white/[0.06] text-white/70">
                    {node.rhythm || '1 2 3'}
                  </span>
                  {node.notes && (
                    <span className="text-[10px] text-white/40 truncate max-w-[70px]">
                      {node.notes}
                    </span>
                  )}
                </div>
              </div>
            )
          })}

          {/* ── Partner Cursors Layer (Supabase Presence) ──────────────────── */}
          {Object.entries(partnerPresences).map(([partnerId, presence]) => {
            const isDraggingPartner = Boolean(presence.draggingNodeId)
            return (
              <div
                key={`partner-${partnerId}`}
                style={{
                  position: 'absolute',
                  left: `${presence.x}px`,
                  top: `${presence.y}px`,
                  transform: 'translate(-2px, -2px)',
                  pointerEvents: 'none',
                  zIndex: 100,
                  transition: 'left 60ms linear, top 60ms linear',
                }}
              >
                {/* Pulsing Gold Halo */}
                <div className="absolute -inset-2 rounded-full bg-[#D4AF37]/20 blur-sm animate-ping" />

                {/* Cursor Arrow Pointer */}
                <svg
                  width="22"
                  height="22"
                  viewBox="0 0 24 24"
                  fill="none"
                  className="drop-shadow-[0_2px_8px_rgba(0,0,0,0.8)]"
                >
                  <path
                    d="M3 3L10.07 20.97L13.58 13.58L20.97 10.07L3 3Z"
                    fill="#D4AF37"
                    stroke="#050505"
                    strokeWidth="1.5"
                    strokeLinejoin="round"
                  />
                </svg>

                {/* Dancer Name Pill */}
                <div className="ml-4 -mt-2 px-2.5 py-1 rounded-full bg-[#121217]/90 border border-[#D4AF37]/60 shadow-[0_4px_12px_rgba(0,0,0,0.6)] flex items-center gap-1.5 whitespace-nowrap">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#D4AF37]" />
                  <span className="text-[11px] font-bold text-[#FFE088]">
                    {presence.userName || 'Partner'}
                  </span>
                  {isDraggingPartner && (
                    <span className="text-[10px] text-white/50">· ťahá figúru</span>
                  )}
                </div>
              </div>
            )
          })}
        </div>

        {/* ── Zoom Controls Overlay (Bottom Right) ─────────────────────────── */}
        <div className="absolute bottom-6 right-6 z-30 flex items-center gap-1.5 p-1.5 rounded-2xl bg-[#0e0e12]/90 backdrop-blur-xl border border-white/[0.08] shadow-2xl">
          <button
            onClick={() => setScale(s => Math.max(s - 0.15, MIN_SCALE))}
            className="w-8 h-8 rounded-xl bg-white/[0.05] hover:bg-white/[0.1] text-sm font-bold flex items-center justify-center transition-colors cursor-pointer"
          >
            −
          </button>
          <span className="text-[11px] font-mono px-2 text-white/70">
            {Math.round(scale * 100)}%
          </span>
          <button
            onClick={() => setScale(s => Math.min(s + 0.15, MAX_SCALE))}
            className="w-8 h-8 rounded-xl bg-white/[0.05] hover:bg-white/[0.1] text-sm font-bold flex items-center justify-center transition-colors cursor-pointer"
          >
            +
          </button>
        </div>

        {/* ── Empty State ─────────────────────────────────────────────────── */}
        {!isLoading && nodes.length === 0 && (
          <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-20 text-center p-8 rounded-3xl bg-[#0e0e12]/90 border border-white/[0.08] backdrop-blur-xl max-w-sm space-y-4">
            <div className="w-12 h-12 rounded-2xl bg-[#D4AF37]/15 text-[#D4AF37] flex items-center justify-center text-2xl mx-auto">
              💃
            </div>
            <div>
              <h3 className="text-sm font-bold text-white">Prázdny tanečný parket</h3>
              <p className="text-xs text-white/50 mt-1">
                Pridajte prvú figúru do zostavy a začnite tvoriť choreografiu spoločne v reálnom čase.
              </p>
            </div>
            <button
              onClick={() => setShowAddModal(true)}
              className="btn-ellegance text-xs py-2 px-5 cursor-pointer"
            >
              + Pridať figúru
            </button>
          </div>
        )}
      </div>

      {/* ── Modal: Add Figure from Library ───────────────────────────────── */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="w-full max-w-md bg-[#0e0e12] border border-white/[0.1] rounded-3xl p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-base font-bold text-white">Pridať figúru na parket</h3>
              <button
                onClick={() => setShowAddModal(false)}
                className="text-white/40 hover:text-white text-sm cursor-pointer"
              >
                ✕
              </button>
            </div>

            <input
              type="text"
              value={searchFig}
              onChange={e => setSearchFig(e.target.value)}
              placeholder="Hľadať figúru..."
              className="w-full px-4 py-2.5 rounded-xl bg-white/[0.04] border border-white/[0.08] text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-[#D4AF37]"
            />

            <div className="max-h-64 overflow-y-auto space-y-2 pr-1">
              {filteredFigures.length === 0 ? (
                <p className="text-xs text-white/40 text-center py-6">
                  Nenašli sa žiadne figúry.
                </p>
              ) : (
                filteredFigures.map(f => (
                  <div
                    key={f.id}
                    onClick={() => handleAddFigure(f)}
                    className="p-3 rounded-xl bg-white/[0.03] hover:bg-white/[0.08] border border-white/[0.05] hover:border-[#D4AF37]/40 cursor-pointer transition-all flex items-center justify-between group"
                  >
                    <div>
                      <h4 className="text-xs font-bold text-white group-hover:text-[#D4AF37] transition-colors">
                        {f.name}
                      </h4>
                      <p className="text-[10px] text-white/40 mt-0.5">
                        {f.dance_name} · {f.rhythm || '1 2 3'}
                      </p>
                    </div>
                    <span className="text-xs text-[#D4AF37] font-bold opacity-0 group-hover:opacity-100 transition-opacity">
                      + Vložiť
                    </span>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
