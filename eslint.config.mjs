import js from "@eslint/js";
import globals from "globals";

export default [
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "commonjs",
      globals: {
        ...globals.node,
        ...globals.jest,
      },
    },
    rules: {
      "no-unused-vars": ["warn", { "argsIgnorePattern": "^next$" }],
      "no-console": "off",
    },
  },
  {
    files: ["**/*.mjs"],
    languageOptions: {
      sourceType: "module",
    }
  }
];
