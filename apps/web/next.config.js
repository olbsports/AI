const createNextIntlPlugin = require('next-intl/plugin');

const withNextIntl = createNextIntlPlugin();

/** @type {import('next').NextConfig} */
const nextConfig = {
  transpilePackages: [
    '@horse-vision/ui',
    '@horse-vision/core',
    '@horse-vision/types',
    '@horse-vision/config',
    '@horse-vision/api-client',
  ],
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '*.amazonaws.com',
      },
      {
        protocol: 'https',
        hostname: '*.cloudfront.net',
      },
      {
        protocol: 'https',
        hostname: '*.vercel.app',
      },
    ],
  },
  experimental: {
    // typedRoutes disabled - too strict for this codebase
    typedRoutes: false,
  },
  // Production optimizations
  poweredByHeader: false,
  compress: true,
  reactStrictMode: true,
  // Enable standalone output for containerized deployments
  output: process.env.STANDALONE === 'true' ? 'standalone' : undefined,
};

module.exports = withNextIntl(nextConfig);
