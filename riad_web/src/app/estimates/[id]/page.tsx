"use client"

import { useState, useEffect } from "react"
import { useRouter, useParams } from "next/navigation"
import {
  fetchEstimate,
  reviewEstimate,
  confirmEstimate,
  EstimateData,
} from "@/lib/api"

const STATUS_LABELS: Record<string, string> = {
  Draft: "Чернетка",
  ai_primary: "AI (основний)",
  ai_fallback: "AI (резервний)",
  manual: "Ручний",
  Approved: "Затверджено",
  Rejected: "Відхилено",
  pending: "Очікує обробки",
  error: "Помилка",
}

const ORIGIN_LABELS: Record<string, string> = {
  ai_primary: "AI-основний",
  ai_fallback: "AI-резервний",
  manual: "Ручний-сценарій",
}

const VARIANT_LABELS: Record<string, string> = {
  budget: "Бюджетний",
  optimal: "Оптимальний",
  premium: "Преміум",
}

export default function EstimateDetailPage() {
  const { id } = useParams<{ id: string }>()
  const router = useRouter()

  const [estimate, setEstimate] = useState<EstimateData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [actionLoading, setActionLoading] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const loadEstimate = () => {
    fetchEstimate(id)
      .then(setEstimate)
      .catch((err) => {
        const axiosErr = err as { response?: { status?: number } }
        if (axiosErr.response?.status === 404) {
          setError("Кошторис не знайдено або немає доступу.")
        } else {
          setError("Помилка завантаження кошторису.")
        }
      })
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    loadEstimate()
  }, [id])

  const handleReview = async (decision: "approved" | "rejected") => {
    setActionLoading(`review-${decision}`)
    setActionError(null)
    try {
      await reviewEstimate(id, { decision })
      loadEstimate()
    } catch (err: unknown) {
      const axiosErr = err as { response?: { status?: number; data?: { detail?: string | { message?: string } } } }
      const detail = axiosErr.response?.data?.detail
      const msg = typeof detail === "string" ? detail : detail?.message || "Помилка перевірки кошторису."
      setActionError(msg)
    } finally {
      setActionLoading(null)
    }
  }

  const handleConfirm = async () => {
    setActionLoading("confirm")
    setActionError(null)
    try {
      const result = await confirmEstimate(id)
      alert(`КП створено: ${result.quotation_name}`)
      loadEstimate()
    } catch (err: unknown) {
      const axiosErr = err as { response?: { status?: number; data?: { detail?: string | { message?: string } } } }
      const detail = axiosErr.response?.data?.detail
      const msg = typeof detail === "string" ? detail : detail?.message || "Помилка підтвердження кошторису."
      setActionError(msg)
    } finally {
      setActionLoading(null)
    }
  }

  if (loading) {
    return (
      <main className="min-h-screen p-4 sm:p-8 max-w-2xl mx-auto">
        <div className="text-gray-500">Завантаження...</div>
      </main>
    )
  }

  if (error) {
    return (
      <main className="min-h-screen p-4 sm:p-8 max-w-2xl mx-auto">
        <div className="bg-red-50 border border-red-200 text-red-800 rounded p-4 text-sm">{error}</div>
        <button onClick={() => router.back()} className="mt-4 px-4 py-2 rounded bg-gray-700 hover:bg-gray-600 text-sm">
          Назад
        </button>
      </main>
    )
  }

  if (!estimate) return null

  const status = estimate.status || ""
  const origin = estimate.origin || ""

  const showReviewButtons =
    status !== "Approved" &&
    status !== "Rejected" &&
    origin !== "manual" &&
    status !== "Draft"

  const showConfirmButton = status === "Approved" && !!estimate.reviewed_by

  let parsedItems: Record<string, unknown>[] = []
  if (estimate.ai_result) {
    try {
      const parsed = JSON.parse(estimate.ai_result)
      parsedItems = Array.isArray(parsed) ? parsed : parsed.items || []
    } catch {
      parsedItems = []
    }
  }

  return (
    <main className="min-h-screen p-4 sm:p-8 max-w-2xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">{estimate.name}</h1>
        <button onClick={() => router.back()} className="px-3 py-1 text-sm border rounded hover:bg-gray-50">
          Назад
        </button>
      </div>

      <div className="space-y-4 mb-6">
        <div className="flex gap-2 flex-wrap">
          <span className="px-3 py-1 rounded text-sm bg-gray-700">
            {STATUS_LABELS[status] || status}
          </span>
          {origin && (
            <span className={`px-3 py-1 rounded text-sm ${
              origin === "ai_primary" ? "bg-green-800" :
              origin === "ai_fallback" ? "bg-yellow-800" :
              "bg-gray-600"
            }`}>
              {ORIGIN_LABELS[origin] || origin}
            </span>
          )}
          {estimate.variant && (
            <span className="px-3 py-1 rounded text-sm bg-blue-800">
              {VARIANT_LABELS[estimate.variant] || estimate.variant}
            </span>
          )}
        </div>

        {estimate.site_brief && (
          <p className="text-sm text-gray-400">Site Brief: {estimate.site_brief}</p>
        )}

        {estimate.reviewed_by && (
          <p className="text-sm text-gray-400">
            Перевірено: {estimate.reviewed_by}
            {estimate.reviewed_at && ` (${new Date(estimate.reviewed_at).toLocaleString("uk-UA")})`}
          </p>
        )}

        {estimate.total_cost != null && (
          <div className="flex gap-4">
            <span className="text-sm text-gray-400">Собівартість: <strong>{estimate.total_cost.toLocaleString("uk-UA")} грн</strong></span>
            {estimate.total_margin != null && (
              <span className="text-sm text-gray-400">Маржа: <strong>{estimate.total_margin.toLocaleString("uk-UA")} грн</strong></span>
            )}
          </div>
        )}
      </div>

      {estimate.items && estimate.items.length > 0 && (
        <div className="mb-6">
          <h2 className="text-lg font-semibold mb-3">Позиції кошторису</h2>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-600 text-left text-gray-400">
                  <th className="py-2 pr-2">Позиція</th>
                  <th className="py-2 pr-2 text-right">К-сть</th>
                  <th className="py-2 pr-2 text-right">Ціна</th>
                  <th className="py-2 text-right">Джерело</th>
                </tr>
              </thead>
              <tbody>
                {estimate.items.map((item, idx) => (
                  <tr key={item.name || idx} className="border-b border-gray-700">
                    <td className="py-2 pr-2">{item.item_name || item.item_code}</td>
                    <td className="py-2 pr-2 text-right">{item.qty}</td>
                    <td className="py-2 pr-2 text-right">
                      {item.unit_price != null ? `${item.unit_price.toLocaleString("uk-UA")} грн` : "—"}
                    </td>
                    <td className="py-2 text-right text-gray-400">{item.line_source || "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {parsedItems.length > 0 && estimate.items?.length === 0 && (
        <div className="mb-6">
          <h2 className="text-lg font-semibold mb-3">AI результат (сирі дані)</h2>
          <pre className="bg-gray-800 rounded p-4 text-xs overflow-auto max-h-80">
            {JSON.stringify(parsedItems, null, 2)}
          </pre>
        </div>
      )}

      {actionError && (
        <div className="bg-red-50 border border-red-200 text-red-800 rounded p-3 text-sm mb-4">
          {actionError}
        </div>
      )}

      <div className="flex gap-3">
        {showReviewButtons && (
          <>
            <button
              onClick={() => handleReview("approved")}
              disabled={!!actionLoading}
              className="px-4 py-2 rounded bg-green-600 hover:bg-green-500 disabled:opacity-50 text-sm"
            >
              {actionLoading === "review-approved" ? "Обробка..." : "Затвердити"}
            </button>
            <button
              onClick={() => handleReview("rejected")}
              disabled={!!actionLoading}
              className="px-4 py-2 rounded bg-red-600 hover:bg-red-500 disabled:opacity-50 text-sm"
            >
              {actionLoading === "review-rejected" ? "Обробка..." : "Відхилити"}
            </button>
          </>
        )}

        {showConfirmButton && (
          <button
            onClick={handleConfirm}
            disabled={!!actionLoading}
            className="px-4 py-2 rounded bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-sm"
          >
            {actionLoading === "confirm" ? "Обробка..." : "Підтвердити → Quotation"}
          </button>
        )}
      </div>
    </main>
  )
}
