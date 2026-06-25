import { useState, useEffect } from "react"
import { fetchAiDegradation } from "@/lib/api"

export function useAiDegradation() {
  const [degradation, setDegradation] = useState<{
    level: string
    providers: string[]
    message: string
  } | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    fetchAiDegradation()
      .then(setDegradation)
      .catch((err) => setError(err))
      .finally(() => setLoading(false))
  }, [])

  return { degradation, loading, error }
}
