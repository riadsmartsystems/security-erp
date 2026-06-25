"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import {
  buildEstimate,
  listSiteBriefs,
  fetchSiteBrief,
  SiteBriefData,
} from "@/lib/api"
import HumanGateDialog from "@/components/HumanGateDialog"
import AiDegradedBanner from "@/components/AiDegradedBanner"
import { useAiDegradation } from "@/hooks/useAiDegradation"

type Variant = "budget" | "optimal" | "premium"

const VARIANT_OPTIONS: { value: Variant; label: string; desc: string }[] = [
  { value: "budget", label: "Бюджетний", desc: "Мінімально необхідне обладнання" },
  { value: "optimal", label: "Оптимальний", desc: "Збалансована конфігурація" },
  { value: "premium", label: "Преміум", desc: "Повна комплектація з запасом" },
]

export default function NewEstimatePage() {
  const router = useRouter()
  const { degradation } = useAiDegradation()

  const [briefs, setBriefs] = useState<{ name: string; brief_name: string | null }[]>([])
  const [selectedBrief, setSelectedBrief] = useState("")
  const [briefData, setBriefData] = useState<SiteBriefData | null>(null)
  const [variant, setVariant] = useState<Variant>("optimal")

  const [showGate, setShowGate] = useState(false)
  const [isBuilding, setIsBuilding] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [loadingBriefs, setLoadingBriefs] = useState(true)
  const [loadingBriefData, setLoadingBriefData] = useState(false)

  useEffect(() => {
    listSiteBriefs()
      .then(setBriefs)
      .catch(() => setBriefs([]))
      .finally(() => setLoadingBriefs(false))
  }, [])

  useEffect(() => {
    if (!selectedBrief) {
      setBriefData(null)
      return
    }
    setLoadingBriefData(true)
    fetchSiteBrief(selectedBrief)
      .then(setBriefData)
      .catch(() => setBriefData(null))
      .finally(() => setLoadingBriefData(false))
  }, [selectedBrief])

  const buildGatePayload = (): Record<string, unknown> => {
    if (!briefData) return { site_brief_name: selectedBrief, variant }
    const payload: Record<string, unknown> = { variant }
    if (briefData.object_type) payload["Тип об'єкта"] = briefData.object_type
    if (briefData.area_m2) payload["Площа (м²)"] = briefData.area_m2
    if (briefData.cameras_count) payload["Камери"] = briefData.cameras_count
    if (briefData.camera_type) payload["Тип камер"] = briefData.camera_type
    if (briefData.archive_days) payload["Дні архіву"] = briefData.archive_days
    if (briefData.access_control) payload["СКУД"] = true
    if (briefData.intercom) payload["Домофон"] = true
    if (briefData.alarm) payload["Сигналізація"] = true
    if (briefData.network_needed) payload["Мережа"] = true
    if (briefData.power_backup) payload["Резервне живлення"] = true
    if (briefData.tech_notes) payload["Технічні нотатки"] = briefData.tech_notes
    payload["site_brief_name"] = selectedBrief
    return payload
  }

  const handleBuild = async () => {
    setIsBuilding(true)
    setError(null)
    try {
      const result = await buildEstimate({
        site_brief_name: selectedBrief,
        variant,
      })
      router.push(`/estimates/${result.name}`)
    } catch (err: unknown) {
      const axiosErr = err as { response?: { status?: number; data?: { detail?: string } } }
      const status = axiosErr.response?.status
      const detail = axiosErr.response?.data?.detail
      if (status === 422) {
        setError(detail || "Невалідні дані. Перевірте вибір Site Brief.")
      } else if (status === 502) {
        setError("Помилка бекенду. Спробуйте пізніше.")
      } else {
        setError(detail || "Невідома помилка. Спробуйте ще раз.")
      }
    } finally {
      setIsBuilding(false)
      setShowGate(false)
    }
  }

  return (
    <main className="min-h-screen p-4 sm:p-8 max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">Новий AI-кошторис</h1>

      <AiDegradedBanner level={degradation?.level || "primary"} />

      <div className="space-y-6">
        <div>
          <label htmlFor="site_brief" className="block text-sm font-medium mb-1">
            Site Brief *
          </label>
          {loadingBriefs ? (
            <div className="text-sm text-gray-500">Завантаження списку...</div>
          ) : (
            <select
              id="site_brief"
              value={selectedBrief}
              onChange={(e) => setSelectedBrief(e.target.value)}
              className="w-full p-2 rounded bg-gray-800 border border-gray-600"
            >
              <option value="">Оберіть Site Brief</option>
              {briefs.map((b) => (
                <option key={b.name} value={b.name}>
                  {b.brief_name || b.name}
                </option>
              ))}
            </select>
          )}
        </div>

        {selectedBrief && loadingBriefData && (
          <div className="text-sm text-gray-500">Завантаження даних brief...</div>
        )}

        {briefData && (
          <div className="bg-gray-800 rounded p-4 text-sm space-y-1">
            <p><strong>Тип:</strong> {briefData.object_type || "—"}</p>
            <p><strong>Площа:</strong> {briefData.area_m2 || "—"} м²</p>
            <p><strong>Камери:</strong> {briefData.cameras_count || "—"} ({briefData.camera_type || "—"})</p>
            <p><strong>Архів:</strong> {briefData.archive_days || "—"} днів</p>
            <div className="flex gap-2 flex-wrap mt-1">
              {briefData.access_control ? <span className="px-2 py-0.5 bg-gray-700 rounded text-xs">СКУД</span> : null}
              {briefData.intercom ? <span className="px-2 py-0.5 bg-gray-700 rounded text-xs">Домофон</span> : null}
              {briefData.alarm ? <span className="px-2 py-0.5 bg-gray-700 rounded text-xs">Сигналізація</span> : null}
              {briefData.network_needed ? <span className="px-2 py-0.5 bg-gray-700 rounded text-xs">Мережа</span> : null}
              {briefData.power_backup ? <span className="px-2 py-0.5 bg-gray-700 rounded text-xs">Резерв. живл.</span> : null}
            </div>
            {briefData.tech_notes && (
              <p className="mt-1 text-gray-400"><strong>Нотатки:</strong> {briefData.tech_notes}</p>
            )}
          </div>
        )}

        <div>
          <label className="block text-sm font-medium mb-2">Варіант</label>
          <div className="grid grid-cols-3 gap-3">
            {VARIANT_OPTIONS.map((v) => (
              <button
                key={v.value}
                onClick={() => setVariant(v.value)}
                className={`p-3 rounded border text-left ${
                  variant === v.value
                    ? "border-blue-500 bg-blue-500/10"
                    : "border-gray-600 bg-gray-800 hover:bg-gray-700"
                }`}
              >
                <div className="text-sm font-medium">{v.label}</div>
                <div className="text-xs text-gray-400 mt-1">{v.desc}</div>
              </button>
            ))}
          </div>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-800 rounded p-3 text-sm">
            {error}
          </div>
        )}

        <button
          onClick={() => setShowGate(true)}
          disabled={!selectedBrief || isBuilding}
          className="w-full py-2 rounded bg-blue-600 hover:bg-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isBuilding ? "Побудова..." : "Запустити AI"}
        </button>
      </div>

      {showGate && (
        <HumanGateDialog
          payload={buildGatePayload()}
          onConfirm={handleBuild}
          onCancel={() => setShowGate(false)}
        />
      )}
    </main>
  )
}
