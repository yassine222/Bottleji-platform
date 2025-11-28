import { redirect } from 'next/navigation';

export default function HomePage() {
  // Server-side redirect to login
  // Client-side routing will handle token check in AuthGuard
  redirect('/login');
} 