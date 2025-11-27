import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Bottleji Admin',
  description: 'Admin dashboard for Bottleji application',
  icons: {
    icon: '/logo_v2.png',
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
      <head>
        <link rel="icon" type="image/png" href="/logo_v2.png" />
        <link rel="shortcut icon" type="image/png" href="/logo_v2.png" />
        <link rel="apple-touch-icon" href="/logo_v2.png" />
      </head>
      <body className={inter.className}>
        {children}
      </body>
    </html>
  );
} 