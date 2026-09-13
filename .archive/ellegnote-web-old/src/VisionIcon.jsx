import React from 'react';

export function VisionIcon({ size = 24, ...props }) {
  return (
    <svg width={size} height={size} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" {...props}>
      <g fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2">
        <path
          strokeDasharray="36"
          strokeDashoffset="36"
          d="M2 12c2.5 -5 6.5 -8 10 -8c3.5 0 7.5 3 10 8c-2.5 5 -6.5 8 -10 8c-3.5 0 -7.5 -3 -10 -8Z"
        >
          <animate fill="freeze" attributeName="stroke-dashoffset" dur="0.5s" to="0" />
        </path>
        <path
          strokeDasharray="14"
          strokeDashoffset="14"
          d="M12 9a3 3 0 1 1 0 6a3 3 0 0 1 0 -6Z"
        >
          <animate fill="freeze" attributeName="stroke-dashoffset" begin="0.4s" dur="0.3s" to="0" />
        </path>
        <circle cx="12" cy="12" r="1" fill="currentColor" opacity="0">
          <set fill="freeze" attributeName="opacity" begin="0.7s" to="1" />
          <animate
            attributeName="r"
            values="1;1.6;1"
            dur="2s"
            repeatCount="indefinite"
            begin="0.7s"
          />
        </circle>
      </g>
    </svg>
  );
}
