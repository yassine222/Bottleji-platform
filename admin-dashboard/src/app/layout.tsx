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
    // Next.js 13+ automatically serves app/favicon.ico at /favicon.ico
    // Also provide explicit paths for better compatibility
    icon: [
      { url: '/favicon.ico', sizes: 'any' }, // Auto-served from app/favicon.ico
      { url: '/favicon/favicon.ico', sizes: 'any' },
      { url: '/favicon/favicon.svg', type: 'image/svg+xml' },
      { url: '/favicon/favicon-96x96.png', type: 'image/png', sizes: '96x96' },
    ],
    shortcut: '/favicon.ico',
    apple: '/apple-icon.png', // Auto-served from app/apple-icon.png
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