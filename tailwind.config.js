/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Primary accent color (purple/blue) - 获奖项目标准色
        accent: {
          DEFAULT: '#6d6eff',
          light: '#b4b6ff',
          dark: '#5456ff',
        },
        // Success color (green)
        success: {
          DEFAULT: '#2bc37b',
          light: '#3dd98c',
          dark: '#199964',
          soft: 'rgba(43, 195, 123, 0.16)',
        },
        // Warning color (yellow)
        warning: {
          DEFAULT: '#f3b13b',
          light: '#fbbf24',
          dark: '#d89a1c',
        },
        // Error color (red)
        error: {
          DEFAULT: '#ef5350',
          light: '#f43f5e',
          dark: '#dc2626',
        },
        // Background colors
        bg: {
          DEFAULT: '#070910',
          alt: '#050614',
          panel: 'rgba(16, 20, 36, 0.92)',
          'panel-alt': 'rgba(10, 13, 22, 0.9)',
        },
        // Border colors
        border: {
          DEFAULT: 'rgba(120, 142, 182, 0.22)',
          strong: 'rgba(148, 163, 184, 0.28)',
          light: 'rgba(148, 163, 184, 0.16)',
        },
        // Text colors
        text: {
          DEFAULT: '#f5f7ff',
          muted: 'rgba(198, 207, 232, 0.72)',
          disabled: 'rgba(198, 207, 232, 0.4)',
        },
      },
      borderRadius: {
        'sm': '0.5rem',    // 8px
        'md': '1.05rem',   // 16-17px
        'lg': '1.35rem',   // 20-22px
        'xl': '1.75rem',   // 28px
        'full': '999px',   // Fully rounded (capsule)
      },
      fontFamily: {
        sans: ['Inter', 'Segoe UI', 'system-ui', '-apple-system', 'sans-serif'],
        mono: ['DM Mono', 'SFMono-Regular', 'Menlo', 'Consolas', 'monospace'],
      },
      boxShadow: {
        'sm': '0 2px 8px rgba(0, 0, 0, 0.1)',
        'md': '0 4px 12px rgba(0, 0, 0, 0.15)',
        'lg': '0 8px 24px rgba(109, 110, 255, 0.25)',
        'panel': '0 18px 42px -32px rgba(5, 8, 18, 0.9)',
        'glow': '0 0 20px rgba(109, 110, 255, 0.3)',
        'focus': '0 0 0 2px rgba(109, 110, 255, 0.2)',
      },
      backdropBlur: {
        'xs': '2px',
        'sm': '10px',
        'md': '18px',
        'lg': '24px',
      },
      animation: {
        'spin-slow': 'spin 0.7s linear infinite',
        'slide-up': 'slideUp 0.3s ease-out',
        'fade-in': 'fadeIn 0.5s ease-out',
        'pulse-glow': 'pulseGlow 2s ease-in-out infinite',
      },
      keyframes: {
        slideUp: {
          from: { transform: 'translateY(100%)', opacity: '0' },
          to: { transform: 'translateY(0)', opacity: '1' },
        },
        fadeIn: {
          from: { opacity: '0' },
          to: { opacity: '1' },
        },
        pulseGlow: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.5' },
        },
      },
    },
  },
  plugins: [],
}
