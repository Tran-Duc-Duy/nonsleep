"use client";

import * as React from "react";
import { Lottie } from "lottie-react";

export interface LottiePlayerProps {
  animationData: Record<string, unknown>;
  className?: string;
  loop?: boolean;
}

export function LottiePlayer({ animationData, className, loop = true }: LottiePlayerProps) {
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return <div className={className} />;
  }

  return (
    <div className={className}>
      <Lottie src={animationData} autoplay loop={loop} className="w-full h-full" />
    </div>
  );
}
