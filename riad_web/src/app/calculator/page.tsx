"use client"

import { useState } from "react"
import { submitCalculator, CalcSubmitResponse } from "@/lib/api"
import TurnstileWidget from "@/components/TurnstileWidget"

type Step = 1 | 2 | 3

interface FormData {
  object_type: string
  area_m2: string
  cameras_count: string
  archive_days: string
  contact_name: string
  contact_phone: string
  contact_email: string
}

const OBJECT_TYPES = [
  "CCTV Analog",
  "CCTV IP",
  "Access Control",
  "Alarm",
  "Network",
  "Mixed",
]

const INITIAL_FORM: FormData = {
  object_type: "",
  area_m2: "",
  cameras_count: "",
  archive_days: "",
  contact_name: "",
  contact_phone: "",
  contact_email: "",
}

export default function CalculatorPage() {
  const [step, setStep] = useState<Step>(1)
  const [form, setForm] = useState<FormData>(INITIAL_FORM)
  const [captchaToken, setCaptchaToken] = useState("")
  const [isLoading, setIsLoading] = useState(false)
  const [result, setResult] = useState<CalcSubmitResponse | null>(null)
  const [error, setError] = useState<string | null>(null)

  const updateField = (field: keyof FormData, value: string) => {
    setForm((prev) => ({ ...prev, [field]: value }))
  }

  const canGoNext = (): boolean => {
    if (step === 1) {
      return form.object_type !== "" && form.area_m2 !== "" && Number(form.area_m2) > 0
    }
    if (step === 2) {
      return form.contact_name.trim() !== "" && form.contact_phone.trim() !== ""
    }
    return false
  }

  const handleSubmit = async () => {
    setIsLoading(true)
    setError(null)
    try {
      const response = await submitCalculator({
        object_type: form.object_type,
        area_m2: Number(form.area_m2),
        cameras_count: Number(form.cameras_count) || 0,
        archive_days: Number(form.archive_days) || 0,
        contact_name: form.contact_name,
        contact_phone: form.contact_phone,
        contact_email: form.contact_email,
        captcha_token: captchaToken,
      })
      setResult(response)
    } catch (err: unknown) {
      const axiosErr = err as { response?: { status?: number } }
      const status = axiosErr.response?.status
      if (status === 429) {
        setError("Забагато запитів. Спробуйте пізніше.")
      } else if (status === 422) {
        setError("Перевірка CAPTCHA не пройдена. Оновіть сторінку.")
      } else {
        setError("Сервіс тимчасово недоступний. Залиште контакти і ми передзвонимо.")
      }
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <main className="min-h-screen p-4 sm:p-8 max-w-xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">Калькулятор вартості</h1>

      <div className="flex items-center gap-2 mb-6 text-sm text-gray-400">
        {[1, 2, 3].map((s) => (
          <span
            key={s}
            className={`px-2 py-1 rounded ${
              step === s
                ? "bg-blue-600 text-white"
                : s < step
                  ? "bg-green-700 text-white"
                  : "bg-gray-700"
            }`}
          >
            {s}
          </span>
        ))}
        <span className="ml-2">
          {step === 1 && "Параметри"}
          {step === 2 && "Контакти"}
          {step === 3 && "Результат"}
        </span>
      </div>

      {step === 1 && (
        <div className="space-y-4">
          <div>
            <label htmlFor="object_type" className="block text-sm mb-1">Тип системи</label>
            <select
              id="object_type"
              value={form.object_type}
              onChange={(e) => updateField("object_type", e.target.value)}
              className="w-full p-2 rounded bg-gray-800 border border-gray-600"
            >
              <option value="">Оберіть тип</option>
              {OBJECT_TYPES.map((t) => (
                <option key={t} value={t}>
                  {t}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label htmlFor="area_m2" className="block text-sm mb-1">Площа, м²</label>
            <input
              id="area_m2"
              type="number"
              min="0"
              step="any"
              value={form.area_m2}
              onChange={(e) => updateField("area_m2", e.target.value)}
              className="w-full p-2 rounded bg-gray-800 border border-gray-600"
              placeholder="0"
            />
          </div>

          <div>
            <label htmlFor="cameras_count" className="block text-sm mb-1">Кількість камер</label>
            <input
              id="cameras_count"
              type="number"
              min="0"
              value={form.cameras_count}
              onChange={(e) => updateField("cameras_count", e.target.value)}
              className="w-full p-2 rounded bg-gray-800 border border-gray-600"
              placeholder="0"
            />
          </div>

          <div>
            <label htmlFor="archive_days" className="block text-sm mb-1">Дні зберігання архіву</label>
            <input
              id="archive_days"
              type="number"
              min="0"
              value={form.archive_days}
              onChange={(e) => updateField("archive_days", e.target.value)}
              className="w-full p-2 rounded bg-gray-800 border border-gray-600"
              placeholder="0"
            />
          </div>
        </div>
      )}

      {step === 2 && (
        <div className="space-y-4">
          <div>
            <label htmlFor="contact_name" className="block text-sm mb-1">Ім'я *</label>
            <input
              id="contact_name"
              type="text"
              value={form.contact_name}
              onChange={(e) => updateField("contact_name", e.target.value)}
              className="w-full p-2 rounded bg-gray-800 border border-gray-600"
            />
          </div>

          <div>
            <label htmlFor="contact_phone" className="block text-sm mb-1">Телефон *</label>
            <input
              id="contact_phone"
              type="tel"
              value={form.contact_phone}
              onChange={(e) => updateField("contact_phone", e.target.value)}
              className="w-full p-2 rounded bg-gray-800 border border-gray-600"
              placeholder="+380"
            />
          </div>

          <div>
            <label htmlFor="contact_email" className="block text-sm mb-1">Email (опціонально)</label>
            <input
              id="contact_email"
              type="email"
              value={form.contact_email}
              onChange={(e) => updateField("contact_email", e.target.value)}
              className="w-full p-2 rounded bg-gray-800 border border-gray-600"
            />
          </div>
        </div>
      )}

      {step === 3 && !result && (
        <div className="space-y-4">
          <div className="bg-gray-800 rounded p-4 text-sm space-y-1">
            <p><strong>Тип:</strong> {form.object_type}</p>
            <p><strong>Площа:</strong> {form.area_m2} м²</p>
            <p><strong>Камери:</strong> {form.cameras_count || "0"}</p>
            <p><strong>Архів:</strong> {form.archive_days || "0"} днів</p>
            <p><strong>Контакт:</strong> {form.contact_name}, {form.contact_phone}</p>
          </div>

          <TurnstileWidget
            sitekey={process.env.NEXT_PUBLIC_TURNSTILE_SITEKEY || ""}
            onVerify={setCaptchaToken}
            onExpire={() => setCaptchaToken("")}
          />

          {error && (
            <p className="text-red-400 text-sm">{error}</p>
          )}

          <button
            onClick={handleSubmit}
            disabled={!captchaToken || isLoading}
            className="w-full py-2 rounded bg-blue-600 hover:bg-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isLoading ? "Завантаження..." : "Розрахувати"}
          </button>
        </div>
      )}

      {step === 3 && result && (
        <div className="bg-gray-800 rounded p-6 text-center space-y-3">
          <p className="text-lg">Орієнтовна вартість:</p>
          <p className="text-3xl font-bold text-green-400">
            {result.estimated_total.toLocaleString("uk-UA")} грн
          </p>
          {result.matched_scenario && (
            <p className="text-sm text-gray-400">{result.matched_scenario}</p>
          )}
          <p className="text-xs text-gray-500">
            Заявка #{result.submission_name} створена
          </p>
        </div>
      )}

      {step === 3 && error && (
        <div className="space-y-4 mt-4">
          <p className="text-sm text-gray-400">Залиште контакти — ми передзвонимо.</p>
          <div>
            <label className="block text-sm mb-1">Ім'я</label>
            <input
              type="text"
              value={form.contact_name}
              onChange={(e) => updateField("contact_name", e.target.value)}
              className="w-full p-2 rounded bg-gray-800 border border-gray-600"
            />
          </div>
          <div>
            <label className="block text-sm mb-1">Телефон</label>
            <input
              type="tel"
              value={form.contact_phone}
              onChange={(e) => updateField("contact_phone", e.target.value)}
              className="w-full p-2 rounded bg-gray-800 border border-gray-600"
            />
          </div>
        </div>
      )}

      <div className="flex gap-2 mt-6">
        {step > 1 && !result && (
          <button
            onClick={() => setStep((s) => (s - 1) as Step)}
            className="px-4 py-2 rounded bg-gray-700 hover:bg-gray-600"
          >
            Назад
          </button>
        )}
        {step < 3 && (
          <button
            onClick={() => setStep((s) => (s + 1) as Step)}
            disabled={!canGoNext()}
            className="px-4 py-2 rounded bg-blue-600 hover:bg-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Далі
          </button>
        )}
      </div>
    </main>
  )
}
