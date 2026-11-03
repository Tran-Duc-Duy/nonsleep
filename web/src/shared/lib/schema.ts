import { SITE_CONFIG } from "../const/site-config";
import { FAQS } from "../const/faq";

export function generateStructuredData() {
  const softwareAppSchema = {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    "@id": `${SITE_CONFIG.url}/#software`,
    name: SITE_CONFIG.name,
    url: SITE_CONFIG.url,
    image: `${SITE_CONFIG.url}/opengraph-image`,
    operatingSystem: "macOS 13+, Linux (systemd)",
    applicationCategory: "UtilitiesApplication",
    applicationSubCategory: "Power Management",
    license: "https://opensource.org/licenses/MIT",
    isAccessibleForFree: true,
    softwareRequirements: "macOS 13 or later; Linux with systemd-logind",
    inLanguage: ["en", "vi"],
    offers: {
      "@type": "Offer",
      price: "0",
      priceCurrency: "USD",
    },
    description: SITE_CONFIG.description,
    softwareVersion: SITE_CONFIG.latestVersion,
    datePublished: "2026-10-20",
    dateModified: SITE_CONFIG.latestReleaseDate,
    author: {
      "@type": "Person",
      name: SITE_CONFIG.author,
      url: "https://github.com/Tran-Duc-Duy",
    },
    downloadUrl: SITE_CONFIG.downloadMacUrl,
    installUrl: SITE_CONFIG.releasesUrl,
    softwareHelp: {
      "@type": "CreativeWork",
      url: `${SITE_CONFIG.githubUrl}/blob/main/README.md`,
    },
    maintainer: {
      "@type": "Person",
      name: SITE_CONFIG.author,
      url: "https://github.com/Tran-Duc-Duy",
    },
    featureList: [
      "MacBook clamshell mode without external monitor",
      "Automatic keep-awake for Claude Code, Cursor, and Codex",
      "Sleep-when-done lifecycle management",
      "Automatic screen lock on lid close",
      "Hardware thermal and low battery cut-outs",
      "100% offline with zero network code",
    ],
  };

  const faqSchema = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: FAQS.map((faq) => ({
      "@type": "Question",
      name: faq.question,
      acceptedAnswer: {
        "@type": "Answer",
        text: faq.answer,
      },
    })),
  };

  const websiteSchema = {
    "@context": "https://schema.org",
    "@type": "WebSite",
    "@id": `${SITE_CONFIG.url}/#website`,
    name: SITE_CONFIG.name,
    url: SITE_CONFIG.url,
    description: SITE_CONFIG.description,
    inLanguage: ["en", "vi"],
    license: "https://opensource.org/licenses/MIT",
    publisher: {
      "@type": "Person",
      name: SITE_CONFIG.author,
      url: "https://github.com/Tran-Duc-Duy",
    },
    about: { "@id": `${SITE_CONFIG.url}/#software` },
  };

  return { softwareAppSchema, faqSchema, websiteSchema };
}
