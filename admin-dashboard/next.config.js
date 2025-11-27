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
  // Remove CORS headers - Next.js doesn't need them for same-origin requests
  // CORS should be handled by the backend API, not the frontend
  // If you need CORS for API routes, configure it in the backend
};

module.exports = nextConfig;

