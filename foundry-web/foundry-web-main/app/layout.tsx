import type {Metadata} from 'next';
import './globals.css'; // Global styles

export const metadata: Metadata = {
  title: 'The Foundry - UOR Foundation',
  description: 'The Foundry - UOR Foundation: AI-powered semantic research assistant and platform model framework inspired by PrismPM and Universal Object Reference (UOR) principles.',
  openGraph: {
    title: 'The Foundry - UOR Foundation',
    description: 'The Foundry - UOR Foundation: AI-powered semantic research assistant and platform model framework inspired by PrismPM and Universal Object Reference (UOR) principles.',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'The Foundry - UOR Foundation',
    description: 'The Foundry - UOR Foundation: AI-powered semantic research assistant and platform model framework inspired by PrismPM and Universal Object Reference (UOR) principles.',
  },
  other: {
    'foundry-machinery': 'ADR-Core',
    'foundry-export': 'docs/adr',
    'adr-registry': '/api/adr/registry',
    'foundry-status': '/api/foundry',
  },
};

export default function RootLayout({children}: {children: React.ReactNode}) {
  return (
    <html lang="en">
      <body suppressHydrationWarning>{children}</body>
    </html>
  );
}
