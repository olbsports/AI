/** @type {import('eslint').Linter.Config} */
module.exports = {
  extends: [
    './eslint-preset.js',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended',
    'plugin:jsx-a11y/recommended',
  ],
  plugins: ['react', 'react-hooks', 'jsx-a11y'],
  settings: {
    react: {
      version: 'detect',
    },
  },
  env: {
    browser: true,
  },
  rules: {
    // React
    'react/react-in-jsx-scope': 'off',
    'react/prop-types': 'off',
    'react/jsx-no-target-blank': 'error',
    'react/jsx-curly-brace-presence': ['warn', { props: 'never', children: 'never' }],
    'react/self-closing-comp': 'warn',
    'react/jsx-sort-props': [
      'warn',
      {
        callbacksLast: true,
        shorthandFirst: true,
        reservedFirst: true,
      },
    ],

    // React Hooks
    'react-hooks/rules-of-hooks': 'error',
    'react-hooks/exhaustive-deps': 'warn',

    // Accessibility
    'jsx-a11y/alt-text': 'error',
    'jsx-a11y/anchor-is-valid': 'warn',
  },
};
