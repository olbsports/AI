/** @type {import('eslint').Linter.Config} */
module.exports = {
  extends: ['./eslint-react.js', 'next/core-web-vitals'],
  rules: {
    // Next.js specific
    '@next/next/no-html-link-for-pages': 'error',
    '@next/next/no-img-element': 'warn',
  },
};
