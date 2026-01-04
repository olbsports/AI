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
    ],
  },
  experimental: {
    typedRoutes: true,
  },
};

module.exports = withNextIntl(nextConfig);
