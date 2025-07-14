/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#e6f7ff',
          100: '#b3e0ff',
          200: '#80c9ff',
          300: '#4db2ff',
          400: '#1a9bff',
          500: '#0084e6',
          600: '#0066b3',
          700: '#004d80',
          800: '#00334d',
          900: '#001a26',
        },
      },
    },
  },
  plugins: [],
}
