// @ts-check
import { defineConfig } from 'astro/config';
import svelte from '@astrojs/svelte';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  site: 'https://tribixbite.github.io',
  base: '/bun-on-termux',
  integrations: [svelte()],
  vite: {
    plugins: [tailwindcss()],
  },
});
