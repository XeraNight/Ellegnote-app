'use client'

import React, { useState } from 'react'
import type { SVGProps } from 'react'

export interface MirrorRectangularIconProps extends SVGProps<SVGSVGElement> {
  size?: number
}

/**
 * Animated Mirror Rectangular Icon
 * Vector SVG with light glint sweep on hover or touch (plays once).
 */
export function MirrorRectangularIcon({ size = 24, className = '', ...props }: MirrorRectangularIconProps) {
  const [isHovered, setIsHovered] = useState(false)

  const handleTrigger = () => {
    setIsHovered(true)
    setTimeout(() => {
      setIsHovered(false)
    }, 700)
  }

  return (
    <div
      className={`inline-flex items-center justify-center cursor-pointer transition-transform duration-300 ${
        isHovered ? 'scale-110' : 'scale-100'
      } ${className}`}
      onMouseEnter={handleTrigger}
      onTouchStart={handleTrigger}
    >
      <svg
        width={size}
        height={size}
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
        {...props}
      >
        <g
          fill="none"
          stroke="currentColor"
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth="2"
        >
          {/* Diagonal glints */}
          <path
            d="M11 6L8 9m8-2l-8 8"
            className={`transition-all duration-500 ${
              isHovered ? 'stroke-[#FFF] drop-shadow-[0_0_6px_rgba(255,255,255,0.8)]' : 'stroke-current'
            }`}
          />
          {/* Mirror outer frame */}
          <rect
            width="16"
            height="20"
            x="4"
            y="2"
            rx="2"
            className="transition-colors duration-300"
          />
        </g>
      </svg>
    </div>
  )
}

export default MirrorRectangularIcon
