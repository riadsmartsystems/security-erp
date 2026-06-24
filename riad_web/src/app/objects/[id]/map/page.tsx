'use client'

import { useEffect, useState, useRef, useCallback } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { fetchMap, addMountPoint, approveMap, MapData, MountPoint, MapPointRequest } from '@/lib/api'

type Mode = 'view' | 'edit' | 'approve'

function generateUuid(): string {
  return crypto.randomUUID ? crypto.randomUUID() : Math.random().toString(36).substring(2, 15)
}

function PlanOverlay({
  mapData,
  mode,
  onAddPoint,
}: {
  mapData: MapData
  mode: Mode
  onAddPoint: (x: number, y: number) => void
}) {
  const containerRef = useRef<HTMLDivElement>(null)

  const handleClick = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      if (mode !== 'edit') return
      const rect = e.currentTarget.getBoundingClientRect()
      const x = (e.clientX - rect.left) / rect.width
      const y = (e.clientY - rect.top) / rect.height
      onAddPoint(Math.round(x * 1000) / 1000, Math.round(y * 1000) / 1000)
    },
    [mode, onAddPoint]
  )

  return (
    <div ref={containerRef} className="relative w-full aspect-video bg-neutral-800 rounded-lg overflow-hidden cursor-crosshair" onClick={handleClick}>
      {mapData.base_plan_media && (
        <img src={`/api/v2/media/${mapData.base_plan_media}/file`} alt="Plan" className="w-full h-full object-contain" />
      )}
      {!mapData.base_plan_media && (
        <div className="flex items-center justify-center h-full text-neutral-500">Підкладка не завантажена</div>
      )}
      {mapData.mount_points.map((pt) => (
        <PointMarker key={pt.point_uuid} point={pt} mapKind="план приміщення" />
      ))}
      {mapData.cable_routes.map((route) => (
        <RouteLine key={route.route_uuid} route={route} points={mapData.mount_points} mapKind="план приміщення" />
      ))}
    </div>
  )
}

function PointMarker({ point, mapKind }: { point: MountPoint; mapKind: string }) {
  let left: string, top: string

  if (mapKind === 'план приміщення' && point.x != null && point.y != null) {
    left = `${point.x * 100}%`
    top = `${point.y * 100}%`
  } else {
    return null
  }

  const typeColors: Record<string, string> = {
    камера: 'bg-red-500',
    wifi: 'bg-blue-500',
    скуд: 'bg-green-500',
    домофон: 'bg-yellow-500',
    датчик: 'bg-purple-500',
    реєстратор: 'bg-orange-500',
  }
  const color = typeColors[point.type || ''] || 'bg-neutral-400'

  return (
    <div
      className={`absolute w-3 h-3 ${color} rounded-full border-2 border-white transform -translate-x-1/2 -translate-y-1/2 z-10`}
      style={{ left, top }}
      title={`${point.label || point.point_uuid} (${point.type || 'невідомо'})`}
    />
  )
}

function RouteLine({ route, points, mapKind }: { route: import('@/lib/api').CableRoute; points: MountPoint[]; mapKind: string }) {
  if (mapKind !== 'план приміщення' || !route.path || route.path.length < 2) return null

  const fromPt = points.find((p) => p.point_uuid === route.from_point)
  const toPt = points.find((p) => p.point_uuid === route.to_point)
  if (!fromPt || !toPt || fromPt.x == null || fromPt.y == null || toPt.x == null || toPt.y == null) return null

  return (
    <svg className="absolute inset-0 w-full h-full pointer-events-none z-5">
      <line
        x1={`${fromPt.x * 100}%`}
        y1={`${fromPt.y * 100}%`}
        x2={`${toPt.x * 100}%`}
        y2={`${toPt.y * 100}%`}
        stroke="#60a5fa"
        strokeWidth="2"
        strokeDasharray="4 2"
      />
    </svg>
  )
}

function PointForm({ onAdd, onCancel }: { onAdd: (point: MapPointRequest) => void; onCancel: () => void }) {
  const [type, setType] = useState('камера')
  const [label, setLabel] = useState('')

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onAdd({ point_uuid: generateUuid(), type, label: label || undefined })
    setLabel('')
  }

  return (
    <form onSubmit={handleSubmit} className="bg-neutral-800 p-4 rounded-lg space-y-3">
      <select value={type} onChange={(e) => setType(e.target.value)} className="w-full bg-neutral-700 text-white p-2 rounded">
        <option value="камера">Камера</option>
        <option value="wifi">Wi-Fi</option>
        <option value="скуд">СКУД</option>
        <option value="домофон">Домофон</option>
        <option value="датчик">Датчик</option>
        <option value="реєстратор">Реєстратор</option>
      </select>
      <input
        type="text"
        value={label}
        onChange={(e) => setLabel(e.target.value)}
        placeholder="Мітка (опціонально)"
        className="w-full bg-neutral-700 text-white p-2 rounded"
      />
      <div className="flex gap-2">
        <button type="submit" className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">Додати</button>
        <button type="button" onClick={onCancel} className="bg-neutral-600 text-white px-4 py-2 rounded hover:bg-neutral-500">Скасувати</button>
      </div>
    </form>
  )
}

export default function MapEditorScreen({ params }: { params: { id: string } }) {
  const queryClient = useQueryClient()
  const [mode, setMode] = useState<Mode>('view')
  const [showForm, setShowForm] = useState(false)
  const [pendingCoords, setPendingCoords] = useState<{ x: number; y: number } | null>(null)

  const { data: mapData, isLoading, error } = useQuery({
    queryKey: ['map', params.id],
    queryFn: () => fetchMap(params.id),
  })

  const addPointMutation = useMutation({
    mutationFn: (point: MapPointRequest) => addMountPoint(params.id, point),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['map', params.id] })
      setShowForm(false)
      setPendingCoords(null)
    },
  })

  const approveMutation = useMutation({
    mutationFn: () => approveMap(params.id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['map', params.id] })
      setMode('view')
    },
  })

  const handlePlanClick = (x: number, y: number) => {
    setPendingCoords({ x, y })
    setShowForm(true)
  }

  const handleAddPoint = (point: MapPointRequest) => {
    if (pendingCoords && mapData?.map_kind === 'план приміщення') {
      point.x = pendingCoords.x
      point.y = pendingCoords.y
    }
    addPointMutation.mutate(point)
  }

  if (isLoading) return <div className="p-8 text-neutral-400">Завантаження...</div>
  if (error || !mapData) return <div className="p-8 text-red-400">Помилка завантаження карти</div>

  return (
    <div className="min-h-screen bg-neutral-900 p-6">
      <div className="max-w-6xl mx-auto space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold text-white">Карта монтажу — {mapData.name}</h1>
          <div className="flex gap-2">
            <span className={`px-2 py-1 rounded text-xs font-medium ${
              mapData.map_kind === 'план приміщення' ? 'bg-blue-600' :
              mapData.map_kind === 'територія' ? 'bg-green-600' : 'bg-purple-600'
            }`}>
              {mapData.map_kind}
            </span>
            {mapData.approved_by && (
              <span className="px-2 py-1 rounded text-xs bg-emerald-700">Затверджено</span>
            )}
          </div>
        </div>

        <div className="flex gap-2">
          <button onClick={() => setMode('view')} className={`px-3 py-1 rounded text-sm ${mode === 'view' ? 'bg-neutral-600 text-white' : 'bg-neutral-800 text-neutral-400'}`}>Перегляд</button>
          <button onClick={() => setMode('edit')} className={`px-3 py-1 rounded text-sm ${mode === 'edit' ? 'bg-blue-600 text-white' : 'bg-neutral-800 text-neutral-400'}`}>Редагування</button>
          <button onClick={() => setMode('approve')} className={`px-3 py-1 rounded text-sm ${mode === 'approve' ? 'bg-emerald-600 text-white' : 'bg-neutral-800 text-neutral-400'}`}>Затвердження</button>
        </div>

        {(mapData.map_kind === 'план приміщення' || mapData.map_kind === 'гібрид') && (
          <PlanOverlay mapData={mapData} mode={mode} onAddPoint={handlePlanClick} />
        )}

        {mapData.map_kind === 'територія' && (
          <div className="w-full aspect-video bg-neutral-800 rounded-lg flex items-center justify-center text-neutral-500">
            MapLibre GL — OSM підкладка (територія)
            {mapData.mount_points.map((pt) => (
              <PointMarker key={pt.point_uuid} point={pt} mapKind="територія" />
            ))}
          </div>
        )}

        {showForm && (
          <PointForm onAdd={handleAddPoint} onCancel={() => { setShowForm(false); setPendingCoords(null) }} />
        )}

        {mode === 'approve' && !mapData.approved_by && (
          <button
            onClick={() => approveMutation.mutate()}
            disabled={approveMutation.isPending}
            className="bg-emerald-600 text-white px-4 py-2 rounded hover:bg-emerald-700 disabled:opacity-50"
          >
            {approveMutation.isPending ? 'Затверджується...' : 'Затвердити карту'}
          </button>
        )}

        <div className="bg-neutral-800 rounded-lg p-4">
          <h2 className="text-sm font-medium text-neutral-300 mb-2">Точки ({mapData.mount_points.length})</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
            {mapData.mount_points.map((pt) => (
              <div key={pt.point_uuid} className="bg-neutral-700 p-2 rounded text-sm">
                <div className="text-white font-medium">{pt.label || pt.point_uuid}</div>
                <div className="text-neutral-400 text-xs">{pt.type || 'невідомо'}</div>
                {pt.status && <div className="text-xs mt-1 text-neutral-500">{pt.status}</div>}
              </div>
            ))}
          </div>
        </div>

        {addPointMutation.isError && (
          <div className="text-red-400 text-sm">Помилка додавання точки</div>
        )}
      </div>
    </div>
  )
}
