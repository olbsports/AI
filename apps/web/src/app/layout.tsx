import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Horse Vision AI',
  description: "Plateforme d'analyse équestre et vétérinaire par intelligence artificielle",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
