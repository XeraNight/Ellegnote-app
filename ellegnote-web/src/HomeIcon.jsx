import React from 'react';

export function HomeIcon({ size = 24, ...props }) {
  return (
    <svg width={size} height={size} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" {...props}>
      <g fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2">
        <path strokeDasharray="18" d="M4.5 21.5h15">
          <animate fill="freeze" attributeName="stroke-dashoffset" dur="0.3s" values="18;0" />
        </path>
        <path strokeDasharray="16" strokeDashoffset="16" d="M4.5 21.5v-13.5M19.5 21.5v-13.5">
          <animate fill="freeze" attributeName="stroke-dashoffset" begin="0.3s" dur="0.3s" to="0" />
        </path>
        <path strokeDasharray="28" strokeDashoffset="28" d="M2 10l10 -8l10 8">
          <animate fill="freeze" attributeName="stroke-dashoffset" begin="0.6s" dur="0.4s" to="0" />
        </path>
        <path strokeDasharray="26" strokeDashoffset="26" d="M9.5 21.5v-9h5v9">
          <animate fill="freeze" attributeName="stroke-dashoffset" begin="0.9s" dur="0.6s" to="0" />
        </path>
      </g>
    </svg>
  );
}
