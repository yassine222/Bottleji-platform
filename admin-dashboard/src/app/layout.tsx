import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Bottleji Admin',
  description: 'Admin dashboard for Bottleji application',
  appleWebApp: {
    capable: true,
    statusBarStyle: 'default',
    title: 'Bottleji Admin',
  },
  icons: {
    // Use larger icons for better visibility in browser tabs
    icon: [
      { url: '/favicon/favicon.svg', type: 'image/svg+xml' }, // SVG for modern browsers (scalable)
      { url: '/favicon/web-app-manifest-192x192.png', type: 'image/png', sizes: '192x192' }, // Large icon
      { url: '/favicon/web-app-manifest-512x512.png', type: 'image/png', sizes: '512x512' }, // Extra large
      { url: '/favicon/favicon-96x96.png', type: 'image/png', sizes: '96x96' }, // Medium
      { url: '/favicon.ico', sizes: 'any' }, // Fallback ICO (auto-served from app/favicon.ico)
    ],
    shortcut: '/favicon/favicon.ico',
    apple: '/apple-icon.png', // Auto-served from app/apple-icon.png (180x180)
  },
  manifest: '/favicon/site.webmanifest',
  other: {
    'apple-mobile-web-app-title': 'Bottleji Admin',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        {children}
      </body>
    </html>
  );
} 