import { MetadataRoute } from "next";
import { SITE_CONFIG } from "../shared/const/site-config";

export default function sitemap(): MetadataRoute.Sitemap {
  return [
    {
      url: `${SITE_CONFIG.url}/`,
      // The release date, not `new Date()`: a lastmod that changes on every build is noise
      // crawlers learn to ignore.
      lastModified: new Date(SITE_CONFIG.latestReleaseDate),
      changeFrequency: "weekly",
      priority: 1,
    },
  ];
}
