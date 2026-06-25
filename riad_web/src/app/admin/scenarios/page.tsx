"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { listScenarios, deleteScenario, ScenarioData } from "@/lib/api"

export default function ScenariosPage() {
  const router = useRouter()
  const [scenarios, setScenarios] = useState<ScenarioData[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const loadScenarios = () => {
    setLoading(true)
    setError(null)
    listScenarios()
      .then(setScenarios)
      .catch((err) => {
        const axiosErr = err as { response?: { status?: number } }
        if (axiosErr.response?.status === 403) {
          setError("Недостатньо прав. Потрібна роль RIAD Scenario Admin.")
        } else {
          setError("Помилка завантаження сценаріїв.")
        }
      })
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    loadScenarios()
  }, [])

  const handleDelete = async (name: string, label: string) => {
    if (!window.confirm(`Видалити сценарій "${label}"? Ця дія незворотна.`)) return
    try {
      await deleteScenario(name)
      setScenarios((prev) => prev.filter((s) => s.name !== name))
    } catch (err: unknown) {
      setError("Помилка видалення сценарію.")
    }
  }

  return (
    <main className="min-h-screen p-4 sm:p-8 max-w-2xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold">Сценарії</h1>
        <button
          onClick={() => router.push("/admin/scenarios/new")}
          className="px-4 py-2 rounded bg-blue-600 hover:bg-blue-500 text-sm"
        >
          + Новий
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-800 rounded p-3 text-sm mb-4">
          {error}
        </div>
      )}

      {loading ? (
        <div className="text-gray-500 text-sm">Завантаження...</div>
      ) : scenarios.length === 0 ? (
        <div className="text-gray-500 text-sm">Сценаріїв поки немає.</div>
      ) : (
        <div className="space-y-2">
          {scenarios.map((s) => (
            <div
              key={s.name}
              className="flex items-center justify-between p-3 bg-gray-800 rounded"
            >
              <div>
                <div className="font-medium">{s.scenario_name || s.name}</div>
                {s.description && (
                  <div className="text-sm text-gray-400 mt-1">{s.description}</div>
                )}
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => router.push(`/admin/scenarios/${s.name}`)}
                  className="px-3 py-1 text-sm border border-gray-600 rounded hover:bg-gray-700"
                >
                  Редагувати
                </button>
                <button
                  onClick={() => handleDelete(s.name, s.scenario_name || s.name)}
                  className="px-3 py-1 text-sm border border-red-600 text-red-400 rounded hover:bg-red-900/30"
                >
                  Видалити
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </main>
  )
}
