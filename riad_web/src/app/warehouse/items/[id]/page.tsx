'use client'

import { useQuery } from '@tanstack/react-query'
import { fetchStockDetail, WarehouseSerial } from '@/lib/api'

export default function StockDetailScreen({ params }: { params: { id: string } }) {
  const itemCode = decodeURIComponent(params.id)

  const { data, isLoading, error } = useQuery({
    queryKey: ['stock-detail', itemCode],
    queryFn: () => fetchStockDetail(itemCode),
  })

  if (isLoading) return <div className="p-8 text-neutral-400">Завантаження...</div>
  if (error || !data) return <div className="p-8 text-red-400">Помилка завантаження</div>

  return (
    <div className="min-h-screen bg-neutral-900 p-6">
      <div className="max-w-4xl mx-auto space-y-6">
        <a href="/warehouse" className="text-blue-400 hover:underline text-sm">← Назад до складу</a>

        <div className="bg-neutral-800 rounded-lg p-6">
          <h1 className="text-xl font-bold text-white">{data.item_name || data.item_code}</h1>
          <div className="mt-2 grid grid-cols-3 gap-4 text-sm">
            <div>
              <div className="text-neutral-400">Код</div>
              <div className="text-white">{data.item_code}</div>
            </div>
            <div>
              <div className="text-neutral-400">Кількість</div>
              <div className="text-white text-2xl font-bold">{data.qty}</div>
            </div>
            <div>
              <div className="text-neutral-400">Склад</div>
              <div className="text-white">{data.warehouse || '—'}</div>
            </div>
          </div>
        </div>

        <div>
          <h2 className="text-sm font-medium text-neutral-300 mb-2">Серійні номери ({data.serials.length})</h2>
          <div className="space-y-2">
            {data.serials.map((s: WarehouseSerial) => (
              <div key={s.name} className="bg-neutral-800 p-3 rounded-lg flex justify-between items-center">
                <div>
                  <div className="text-white font-medium">{s.serial_no}</div>
                  <div className="text-neutral-400 text-sm">{s.warehouse || '—'}</div>
                </div>
                <span className={`text-xs px-2 py-1 rounded ${s.status === 'Assigned' ? 'bg-green-800 text-green-200' : 'bg-neutral-700 text-neutral-300'}`}>
                  {s.status || 'Available'}
                </span>
              </div>
            ))}
            {data.serials.length === 0 && <div className="text-neutral-500 text-center py-4">Серійників немає</div>}
          </div>
        </div>
      </div>
    </div>
  )
}
