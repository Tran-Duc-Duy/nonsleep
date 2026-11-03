import type { Metadata } from "next";
import "./globals.css";
import { SITE_CONFIG } from "../shared/const/site-config";
import { generateStructuredData } from "../shared/lib/schema";

export const metadata: Metadata = {
  title: {
    default: SITE_CONFIG.title,
    template: `%s | ${SITE_CONFIG.name}`,
  },
  description: SITE_CONFIG.description,
  keywords: [...SITE_CONFIG.keywords],
  authors: [{ name: SITE_CONFIG.author, url: "https://github.com/Tran-Duc-Duy" }],
  creator: SITE_CONFIG.author,
  publisher: SITE_CONFIG.author,
  metadataBase: new URL(SITE_CONFIG.url),
  // Without this, Google is free to pick its own canonical — and `metadataBase` pointing at the
  // repo made GitHub the obvious candidate, which would consolidate this site away entirely.
  alternates: {
    canonical: "/",
  },
  applicationName: SITE_CONFIG.name,
  category: "technology",
  // No `icons` override: `app/icon.png` (48px) and `app/apple-icon.png` (180px) are picked up
  // by file convention. Pointing them at /AppIcon.png made every visitor download the
  // 786 KB 1024×1024 master just to render a 16px favicon.
  openGraph: {
    type: "website",
    locale: "en_US",
    url: SITE_CONFIG.url,
    title: SITE_CONFIG.title,
    description: SITE_CONFIG.description,
    siteName: SITE_CONFIG.name,
    images: [
      {
        url: "/opengraph-image",
        width: 1200,
        height: 630,
        alt: SITE_CONFIG.title,
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: SITE_CONFIG.title,
    description: SITE_CONFIG.description,
    creator: "@TranDucDuy",
    images: ["/opengraph-image"],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const { softwareAppSchema, faqSchema, websiteSchema } = generateStructuredData();

  return (
    <html lang="en" className="light scroll-smooth" suppressHydrationWarning>
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(softwareAppSchema) }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }}
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(websiteSchema) }}
        />
      </head>
      <body
        className="min-h-screen bg-[#f5f5f7] text-[#1d1d1f] antialiased selection:bg-indigo-500/15 selection:text-indigo-900"
        suppressHydrationWarning
      >
        {children}
      </body>
    </html>
  );
}
