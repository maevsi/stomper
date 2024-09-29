// @ts-check

import eslint from '@eslint/js'
import vitest from '@vitest/eslint-plugin'
import globals from 'globals'
import prettierRecommended from 'eslint-plugin-prettier/recommended'
import tseslint from 'typescript-eslint'

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  prettierRecommended,
  {
    languageOptions: {
      globals: {
        ...globals.node,
      },
    },
  },
  {
    files: ['tests/**'], // or any other pattern
    plugins: {
      vitest,
    },
    rules: {
      ...vitest.configs.recommended.rules, // you can also use vitest.configs.all.rules to enable all rules
    },
  },
  {
    ignores: ['dist'],
  },
  // {
  //   rules: {
  //     'no-console': 'error',
  //   },
  // },
)
