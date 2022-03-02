import { defineConfig } from "vite";
import coffee from "vite-plugin-coffee";

export default defineConfig({
  base: './',
  plugins: [
    coffee({
      jsx: false,
    }),
  ],
  server: {
    watch: {
      usePolling: true
    }
  }
});
