'use client'

import { useRef, useEffect } from 'react'

interface TurnstileWidgetProps {
  sitekey: string
  onVerify: (token: string) => void
  onExpire: () => void
}

export default function TurnstileWidget({ sitekey, onVerify, onExpire }: TurnstileWidgetProps) {
  const containerRef = useRef<HTMLDivElement>(null)
  const widgetIdRef = useRef<string>('')

  useEffect(() => {
    if (!containerRef.current || !window.turnstile) return

    widgetIdRef.current = window.turnstile.render(containerRef.current, {
      sitekey,
      callback: onVerify,
      'expired-callback': onExpire,
    })

    return () => {
      if (widgetIdRef.current && window.turnstile) {
        window.turnstile.remove(widgetIdRef.current)
      }
    }
  }, [sitekey, onVerify, onExpire])

  return <div ref={containerRef} />
}
