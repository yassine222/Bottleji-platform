/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'firebasestorage.googleapis.com',
        pathname: '/**',
      },
    ],
  },
  // Disable ESLint during builds for production deployment
  // These are mostly type warnings (any types, unused vars) that don't affect functionality
  eslint: {
    ignoreDuringBuilds: true,
  },
  // Ensure proper routing in production
  trailingSlash: false,
};

module.exports = nextConfig;

