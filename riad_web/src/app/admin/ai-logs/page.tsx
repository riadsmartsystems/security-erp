'use client'

import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { fetchAIRequestLogs, AIRequestLogEntry } from '@/lib/api'

export default function AiLogsPage() {
  const [page, setPage] = useState(1)
  const pageSize = 20

  const { data, isLoading, isError, error } = useQuery({
    queryKey: ['ai-request-logs', page],
    queryFn: () => fetchAIRequestLogs(page, pageSize),
  })

  return (
    <div className="min-h-screen bg-neutral-900 p-6 text-white">
      <div className="max-w-6xl mx-auto space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-white">Логи AI запитів</h1>
            <p className="text-sm text-neutral-400">
              Перегляд історії звернень до AI провайдерів з анонімізованим корисним навантаженням
            </p>
          </div>
          <a
            href="/"
            className="px-4 py-2 bg-neutral-800 text-neutral-300 hover:bg-neutral-700 rounded-lg text-sm transition-colors"
          >
            На головну
          </a>
        </div>

        {isLoading ? (
          <div className="flex justify-center items-center py-12">
            <div className="text-neutral-400 animate-pulse text-lg">Завантаження логів...</div>
          </div>
        ) : isError ? (
          <div className="bg-red-900/50 border border-red-700 text-red-200 p-4 rounded-lg">
            Помилка завантаження даних: {error instanceof Error ? error.message : 'Невідома помилка'}
          </div>
        ) : (
          <div className="bg-neutral-800 rounded-xl border border-neutral-700 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-neutral-700 bg-neutral-800/50 text-neutral-400 text-xs uppercase tracking-wider">
                    <th className="p-4 font-semibold">Час створення</th>
                    <th className="p-4 font-semibold">Провайдер</th>
                    <th className="p-4 font-semibold">Анонімізований Payload</th>
                    <th className="p-4 font-semibold text-right">Токени</th>
                    <th className="p-4 font-semibold text-right">Латентність (мс)</th>
                    <th className="p-4 font-semibold text-center">Статус</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-neutral-700/50 text-sm">
                  {data?.logs && data.logs.length > 0 ? (
                    data.logs.map((log: AIRequestLogEntry) => (
                      <tr key={log.name} className="hover:bg-neutral-700/30 transition-colors">
                        <td className="p-4 whitespace-nowrap text-neutral-300">
                          {log.creation ? new Date(log.creation).toLocaleString('uk-UA') : '—'}
                        </td>
                        <td className="p-4 whitespace-nowrap font-medium text-white">
                          {log.provider || '—'}
                        </td>
                        <td className="p-4 max-w-xs md:max-w-md lg:max-w-lg">
                          <div className="truncate text-neutral-400" title={log.anonymized_payload || ''}>
                            {log.anonymized_payload || '—'}
                          </div>
                          {log.error_message && (
                            <div className="text-xs text-red-400 mt-1 truncate" title={log.error_message}>
                              Помилка: {log.error_message}
                            </div>
                          )}
                        </td>
                        <td className="p-4 text-right font-mono text-neutral-300">
                          {log.tokens !== null && log.tokens !== undefined ? log.tokens.toLocaleString() : '0'}
                        </td>
                        <td className="p-4 text-right font-mono text-neutral-300">
                          {log.latency_ms !== null && log.latency_ms !== undefined ? Math.round(log.latency_ms).toLocaleString() : '—'}
                        </td>
                        <td className="p-4 text-center">
                          <span
                            className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                              log.status === 'success' || log.status === 'ok'
                                ? 'bg-green-900/60 text-green-200'
                                : 'bg-red-900/60 text-red-200'
                            }`}
                          >
                            {log.status || 'unknown'}
                          </span>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={6} className="p-8 text-center text-neutral-500">
                        Логи AI запитів відсутні
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            {/* Pagination */}
            {data && data.total > pageSize && (
              <div className="p-4 bg-neutral-800/30 border-t border-neutral-700 flex items-center justify-between">
                <span className="text-xs text-neutral-400">
                  Всього записів: <span className="font-semibold text-white">{data.total}</span>
                </span>
                <div className="flex items-center gap-4">
                  <button
                    onClick={() => setPage(Math.max(1, page - 1))}
                    disabled={page === 1}
                    className="px-3 py-1.5 rounded-lg bg-neutral-700 hover:bg-neutral-600 disabled:opacity-40 disabled:hover:bg-neutral-700 text-white text-xs font-medium transition-colors"
                  >
                    ← Назад
                  </button>
                  <span className="text-xs text-neutral-300">
                    Сторінка <span className="font-semibold text-white">{page}</span> з{' '}
                    <span className="font-semibold text-white">{Math.ceil(data.total / pageSize)}</span>
                  </span>
                  <button
                    onClick={() => setPage(page + 1)}
                    disabled={page * pageSize >= data.total}
                    className="px-3 py-1.5 rounded-lg bg-neutral-700 hover:bg-neutral-600 disabled:opacity-40 disabled:hover:bg-neutral-700 text-white text-xs font-medium transition-colors"
                  >
                    Далі →
                  </button>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}
