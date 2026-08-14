import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'export',
  images: {
    unoptimized: true,
  },
  basePath: process.env.NEXT_PUBLIC_BASE_PATH || '',
  assetPrefix: process.env.NEXT_PUBLIC_BASE_PATH || '',
  turbopack: {}, // Enable Turbopack (silence webpack config warning)
  webpack: (config, { isServer }) => {
    // Enable WASM support
    config.experiments = {
      ...config.experiments,
      asyncWebAssembly: true,
      layers: true,
    };

    // Handle .wasm files
    config.module.rules.push({
      test: /\.wasm$/,
      type: 'webassembly/async',
    });

    // Avoid bundling WASM on server side
    if (isServer) {
      config.externals = config.externals || [];
      config.externals.push({
        '@/lib/wasm-onnx/hologram_onnx': 'commonjs @/lib/wasm-onnx/hologram_onnx',
      });
    }

    return config;
  },
};

export default nextConfig;
