module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',     // New feature
        'fix',      // Bug fix
        'docs',     // Documentation
        'style',    // Formatting, missing semicolons, etc.
        'refactor', // Code refactoring
        'perf',     // Performance improvements
        'test',     // Adding tests
        'chore',    // Maintenance tasks
        'ci',       // CI/CD changes
        'build',    // Build system changes
        'revert',   // Revert commits
      ],
    ],
    'scope-enum': [
      2,
      'always',
      [
        'web',       // Frontend web app
        'api',       // Backend API
        'mobile',    // Mobile app
        'ui',        // UI components
        'core',      // Core business logic
        'types',     // Type definitions
        'config',    // Configuration
        'api-client', // API client
        'infra',     // Infrastructure
        'deps',      // Dependencies
        'i18n',      // Internationalization
        'auth',      // Authentication
        'analysis',  // Analysis features
        'reports',   // Reports features
        'horses',    // Horses features
        'billing',   // Billing features
      ],
    ],
    'subject-case': [2, 'always', 'lower-case'],
    'header-max-length': [2, 'always', 100],
  },
};
