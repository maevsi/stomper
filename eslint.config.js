// @ts-check

import eslint from '@eslint/js'
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
    ignores: ['dist'],
  },
  // {
  //   rules: {
  //     'no-console': 'error',
  //   },
  // },
)
