"use client"

interface AiDegradedBannerProps {
  level: string
}

export default function AiDegradedBanner({ level }: AiDegradedBannerProps) {
  if (level === "primary") return null

  const colors: Record<string, string> = {
    fallback: "bg-yellow-50 border-yellow-200 text-yellow-800",
    manual: "bg-red-50 border-red-200 text-red-800",
  }

  const messages: Record<string, string> = {
    fallback: "AI частково доступний. Деякі провайдери недоступні.",
    manual: "AI недоступний. Ручний режим.",
  }

  return (
    <div
      className={`border rounded p-3 mb-4 text-sm ${colors[level] || colors.manual}`}
    >
      {messages[level] || "AI-стан невідомий"}
    </div>
  )
}
