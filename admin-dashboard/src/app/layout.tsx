import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Bottleji Admin',
  description: 'Admin dashboard for Bottleji application',
  // Next.js 13+ automatically serves icon.png from the app directory
  // Additional icons for better browser compatibility
  icons: {
    icon: [
      { url: '/logo_v2.png', type: 'image/png' },
    ],
    shortcut: '/logo_v2.png',
    apple: '/logo_v2.png',
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