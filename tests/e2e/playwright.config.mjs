import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: ".",
  testMatch: "*.spec.mjs",
  reporter: "list",
  use: { baseURL: "http://127.0.0.1:4243" },
  webServer: { command: "node serve.mjs", url: "http://127.0.0.1:4243/", reuseExistingServer: false },
  projects: [{ name: "chromium", use: { browserName: "chromium" } }],
});
