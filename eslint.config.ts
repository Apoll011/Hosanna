import tseslint from "@typescript-eslint/eslint-plugin";
import tsparser from "@typescript-eslint/parser";
import prettierConfig from "eslint-config-prettier";
import prettierPlugin from "eslint-plugin-prettier";
import pluginReact from "eslint-plugin-react";
import globals from "globals";

export default [
    {
        files: ["**/*.{js,mjs,cjs,ts,mts,cts,jsx,tsx}"],

        languageOptions: {
            parser: tsparser,
            sourceType: "module",
            globals: globals.browser,
        },

        plugins: {
            "@typescript-eslint": tseslint,
            prettier: prettierPlugin,
        },

        rules: {
            ...tseslint.configs.recommended.rules,
            ...prettierConfig.rules,
            "@typescript-eslint/no-unused-vars": "warn",
            "no-console": "warn",
            semi: ["error", "always"],
            quotes: ["error", "double"],
            "prettier/prettier": "error",
        },
        ignores: [
            "node_modules/**",
            "dist/**",
            "build/**",
            "coverage/**",
            "android/**",
        ],
    },
    pluginReact.configs.flat.recommended,
    {
        settings: {
            react: {
                version: "detect",
            },
        },
        rules: {
            "react/react-in-jsx-scope": "off",
            "react/jsx-uses-react": "off",
        },
    },
];
