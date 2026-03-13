import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,md,mdx}',
    './components/**/*.{js,ts,jsx,tsx,md,mdx}',
    './app/**/*.{js,ts,jsx,tsx,md,mdx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
export default config
