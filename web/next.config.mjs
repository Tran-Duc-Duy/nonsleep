/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    // `unoptimized: true` made every <Image> emit the raw file: the 1024×1024 786 KB app icon
    // was shipped to render a 32 px logo, which is what pushed LCP past a second.
    // The deploy target (Vercel) runs the optimizer, so AVIF/WebP at the requested size is free.
    formats: ["image/avif", "image/webp"],
  },
};

export default nextConfig;
