"use client"

import type * as React from "react"
import { motion, useReducedMotion } from "framer-motion"
import type { JSX } from "react/jsx-runtime"

type FadeUpProps = {
  as?: keyof JSX.IntrinsicElements
  className?: string
  children: React.ReactNode
  delay?: number
}

export function FadeUp({ as = "div", className, children, delay = 0 }: FadeUpProps) {
  const prefersReducedMotion = useReducedMotion()
  const Comp: any = motion[as as keyof typeof motion] ?? motion.div

  if (prefersReducedMotion) {
    return <Comp className={className}>{children}</Comp>
  }

  return (
    <Comp
      className={className}
      initial={{ opacity: 0, y: 16 }}
      whileInView={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, ease: "easeOut", delay }}
      viewport={{ once: true, amount: 0.3 }}
    >
      {children}
    </Comp>
  )
}
