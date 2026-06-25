"use client"

import { useState } from "react"

interface HumanGateDialogProps {
  payload: Record<string, unknown>
  onConfirm: () => void
  onCancel: () => void
}

export default function HumanGateDialog({
  payload,
  onConfirm,
  onCancel,
}: HumanGateDialogProps) {
  const [confirmed, setConfirmed] = useState(false)

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 max-w-lg w-full mx-4">
        <h2 className="text-lg font-bold mb-4">Підтвердження AI-запиту</h2>
        <p className="text-sm text-gray-600 mb-4">
          Наступні дані будуть відправлені у зовнішній AI-провайдер:
        </p>
        <pre className="bg-gray-100 rounded p-3 text-xs overflow-auto max-h-60 mb-4">
          {JSON.stringify(payload, null, 2)}
        </pre>
        <label className="flex items-center gap-2 text-sm mb-4">
          <input
            type="checkbox"
            checked={confirmed}
            onChange={(e) => setConfirmed(e.target.checked)}
          />
          Я підтверджую відправку цих даних в AI
        </label>
        <div className="flex gap-2 justify-end">
          <button
            onClick={onCancel}
            className="px-4 py-2 text-sm border rounded hover:bg-gray-50"
          >
            Скасувати
          </button>
          <button
            onClick={onConfirm}
            disabled={!confirmed}
            className="px-4 py-2 text-sm bg-blue-600 text-white rounded disabled:opacity-50"
          >
            Запустити AI
          </button>
        </div>
      </div>
    </div>
  )
}
