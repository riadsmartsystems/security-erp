'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { fetchSerials, fetchStock, WarehouseSerial, WarehouseStockItem } from '@/lib/api'

function SerialsList() {
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)

  const { data, isLoading } = useQuery({
    queryKey: ['serials', search, page],
    queryFn: () => fetchSerials(search, page),
  })

  return (
    <div className="space-y-4">
      <input
        type="text"
        value={search}
        onChange={(e) => { setSearch(e.target.value); setPage(1) }}
        placeholder="Пошук за серійником..."
        className="w-full bg-neutral-800 text-white p-3 rounded-lg border border-neutral-700 focus:border-blue-500 focus:outline-none"
      />

      {isLoading ? (
        <div className="text-neutral-400">Завантаження...</div>
      ) : (
        <div className="space-y-2">
          {data?.items.map((s: WarehouseSerial) => (
            <div key={s.name} className="bg-neutral-800 p-3 rounded-lg flex justify-between items-center">
              <div>
                <div className="text-white font-medium">{s.serial_no}</div>
                <div className="text-neutral-400 text-sm">{s.item_name || s.item || '—'}</div>
              </div>
              <span className={`text-xs px-2 py-1 rounded ${s.status === 'Assigned' ? 'bg-green-800 text-green-200' : 'bg-neutral-700 text-neutral-300'}`}>
                {s.status || 'Available'}
              </span>
            </div>
          ))}
          {data?.items.length === 0 && <div className="text-neutral-500 text-center py-4">Нічого не знайдено</div>}
        </div>
      )}

      {data && data.total > data.page_size && (
        <div className="flex justify-center gap-2">
          <button onClick={() => setPage(Math.max(1, page - 1))} disabled={page === 1} className="px-3 py-1 rounded bg-neutral-700 text-white disabled:opacity-50">←</button>
          <span className="px-3 py-1 text-neutral-400 text-sm">{page} / {Math.ceil(data.total / data.page_size)}</span>
          <button onClick={() => setPage(page + 1)} disabled={page * data.page_size >= data.total} className="px-3 py-1 rounded bg-neutral-700 text-white disabled:opacity-50">→</button>
        </div>
      )}
    </div>
  )
}

function StockList() {
  const { data, isLoading } = useQuery({
    queryKey: ['stock'],
    queryFn: fetchStock,
  })

  return (
    <div className="space-y-2">
      {isLoading ? (
        <div className="text-neutral-400">Завантаження...</div>
      ) : (
        data?.items.map((item: WarehouseStockItem) => (
          <a
            key={item.item_code}
            href={`/warehouse/items/${encodeURIComponent(item.item_code)}`}
            className="block bg-neutral-800 p-3 rounded-lg hover:bg-neutral-700 transition-colors"
          >
            <div className="flex justify-between items-center">
              <div>
                <div className="text-white font-medium">{item.item_name || item.item_code}</div>
                <div className="text-neutral-400 text-sm">{item.item_code}</div>
              </div>
              <div className="text-right">
                <div className="text-white font-bold text-lg">{item.qty}</div>
                <div className="text-neutral-500 text-xs">{item.warehouse || ''}</div>
              </div>
            </div>
          </a>
        ))
      )}
      {data?.items.length === 0 && <div className="text-neutral-500 text-center py-4">Склад порожній</div>}
    </div>
  )
}

export default function WarehouseScreen() {
  const [tab, setTab] = useState<'serials' | 'stock'>('serials')

  return (
    <div className="min-h-screen bg-neutral-900 p-6">
      <div className="max-w-4xl mx-auto space-y-4">
        <h1 className="text-xl font-bold text-white">Склад</h1>

        <div className="flex gap-2">
          <button onClick={() => setTab('serials')} className={`px-4 py-2 rounded-lg text-sm ${tab === 'serials' ? 'bg-blue-600 text-white' : 'bg-neutral-800 text-neutral-400'}`}>
            Серійники
          </button>
          <button onClick={() => setTab('stock')} className={`px-4 py-2 rounded-lg text-sm ${tab === 'stock' ? 'bg-blue-600 text-white' : 'bg-neutral-800 text-neutral-400'}`}>
            Залишки
          </button>
        </div>

        {tab === 'serials' && <SerialsList />}
        {tab === 'stock' && <StockList />}
      </div>
    </div>
  )
}
