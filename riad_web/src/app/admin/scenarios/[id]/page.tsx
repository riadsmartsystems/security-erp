"use client"

import { useState, useEffect, useCallback } from "react"
import { useRouter, useParams } from "next/navigation"
import {
  fetchScenario,
  createScenario,
  updateScenario,
  ScenarioData,
  ScenarioItemData,
} from "@/lib/api"

export default function ScenarioEditPage() {
  const { id } = useParams<{ id: string }>()
  const router = useRouter()
  const isNew = id === "new"

  const [scenarioName, setScenarioName] = useState("")
  const [description, setDescription] = useState("")
  const [items, setItems] = useState<ScenarioData["items"]>([])
  const [loading, setLoading] = useState(!isNew)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  const loadScenario = useCallback(async () => {
    if (isNew) return
    setLoading(true)
    try {
      const data = await fetchScenario(id)
      setScenarioName(data.scenario_name || "")
      setDescription(data.description || "")
      setItems(data.items || [])
    } catch {
      setError("Помилка завантаження сценарію.")
    } finally {
      setLoading(false)
    }
  }, [id, isNew])

  useEffect(() => {
    loadScenario()
  }, [loadScenario])

  const handleSave = async () => {
    if (!scenarioName.trim()) {
      setError("Назва обов'язкова.")
      return
    }
    setSaving(true)
    setError(null)
    setSuccess(null)
    try {
      if (isNew) {
        const result = await createScenario({
          scenario_name: scenarioName.trim(),
          description: description.trim(),
        })
        setSuccess(`Створено: ${result.name}`)
        setTimeout(() => router.push(`/admin/scenarios/${result.name}`), 500)
      } else {
        await updateScenario(id, {
          scenario_name: scenarioName.trim(),
          description: description.trim(),
        })
        setSuccess("Збережено")
      }
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { detail?: string } } }
      setError(axiosErr.response?.data?.detail || "Помилка збереження.")
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <main className="min-h-screen p-4 sm:p-8 max-w-2xl mx-auto">
        <div className="text-gray-500 text-sm">Завантаження...</div>
      </main>
    )
  }

  return (
    <main className="min-h-screen p-4 sm:p-8 max-w-2xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">
          {isNew ? "Новий сценарій" : "Редагування сценарію"}
        </h1>
        <button
          onClick={() => router.back()}
          className="px-3 py-1 text-sm border rounded hover:bg-gray-50"
        >
          Назад
        </button>
      </div>

      <div className="space-y-4">
        <div>
          <label htmlFor="scenario_name" className="block text-sm font-medium mb-1">
            Назва *
          </label>
          <input
            id="scenario_name"
            type="text"
            value={scenarioName}
            onChange={(e) => setScenarioName(e.target.value)}
            className="w-full p-2 rounded bg-gray-800 border border-gray-600"
            placeholder="Напр. 8 IP камер"
          />
        </div>

        <div>
          <label htmlFor="description" className="block text-sm font-medium mb-1">
            Опис
          </label>
          <textarea
            id="description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="w-full p-2 rounded bg-gray-800 border border-gray-600 h-24 resize-none"
            placeholder="Короткий опис конфігурації"
          />
        </div>

        {items.length > 0 && !isNew && (
          <div>
            <h2 className="text-sm font-medium mb-2">Позиції ({items.length})</h2>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-600 text-left text-gray-400">
                    <th className="py-2 pr-2">Item</th>
                    <th className="py-2 pr-2">Назва</th>
                    <th className="py-2 pr-2 text-right">К-сть</th>
                    <th className="py-2 pr-2">Правило</th>
                    <th className="py-2 text-right">Ціна</th>
                  </tr>
                </thead>
                <tbody>
                  {items.map((item: ScenarioItemData, idx: number) => (
                    <tr key={item.name || idx} className="border-b border-gray-700">
                      <td className="py-2 pr-2">{item.item_code}</td>
                      <td className="py-2 pr-2 text-gray-400">{item.item_name || "—"}</td>
                      <td className="py-2 pr-2 text-right">{item.qty ?? "—"}</td>
                      <td className="py-2 pr-2">{item.qty_rule || "—"}</td>
                      <td className="py-2 text-right">
                        {item.rate != null ? `${item.rate.toLocaleString("uk-UA")} грн` : "—"}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-800 rounded p-3 text-sm">
            {error}
          </div>
        )}

        {success && (
          <div className="bg-green-50 border border-green-200 text-green-800 rounded p-3 text-sm">
            {success}
          </div>
        )}

        <button
          onClick={handleSave}
          disabled={saving || !scenarioName.trim()}
          className="px-6 py-2 rounded bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-sm"
        >
          {saving ? "Збереження..." : isNew ? "Створити" : "Зберегти"}
        </button>
      </div>
    </main>
  )
}
