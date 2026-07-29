import sharp from 'sharp';

export interface ImageAnalysis {
  isBlurry: boolean;
  blurScore: number;
  rotationDegrees: number;
  isDark: boolean;
  averageBrightness: number;
  format: string;
  width: number;
  height: number;
}

export async function analyzeImage(buffer: Buffer): Promise<ImageAnalysis> {
  const metadata = await sharp(buffer).metadata();
  const format = metadata.format || 'unknown';
  const width = metadata.width || 0;
  const height = metadata.height || 0;

  const stats = await sharp(buffer).greyscale().stats();
  const averageBrightness = stats.channels[0].mean;

  const blurScore = await computeLaplacianVariance(buffer);
  const isBlurry = blurScore < 100;

  const isDark = averageBrightness < 50;

  const rotationDegrees = await detectRotation(buffer);

  return {
    isBlurry,
    blurScore,
    rotationDegrees,
    isDark,
    averageBrightness,
    format,
    width,
    height,
  };
}

export async function autoRotate(buffer: Buffer): Promise<Buffer> {
  const rotation = await detectRotation(buffer);
  if (rotation === 0) return buffer;

  const metadata = await sharp(buffer).metadata();

  const needsOrientationFix =
    metadata.orientation && metadata.orientation > 1 && metadata.orientation <= 8;

  if (needsOrientationFix) {
    return sharp(buffer).rotate().toBuffer();
  }

  if (metadata.width && metadata.height) {
    const isPortrait = metadata.height > metadata.width;
    const isRotationNeeded = (rotation === 90 || rotation === 270) && !isPortrait;

    if (isRotationNeeded) {
      return sharp(buffer).rotate(rotation).toBuffer();
    }
  }

  return buffer;
}

export async function convertToJpeg(buffer: Buffer): Promise<Buffer> {
  const metadata = await sharp(buffer).metadata();
  if (metadata.format === 'jpeg') {
    return buffer;
  }
  return sharp(buffer).jpeg({ quality: 90 }).toBuffer();
}

export async function isBlurry(buffer: Buffer): Promise<boolean> {
  const score = await computeLaplacianVariance(buffer);
  return score < 100;
}

async function computeLaplacianVariance(buffer: Buffer): Promise<number> {
  const { data, info } = await sharp(buffer)
    .greyscale()
    .raw()
    .toBuffer({ resolveWithObject: true });

  const { width, height } = info;
  const pixels = new Float32Array(data);

  const laplacianKernel = [
    [0, -1, 0],
    [-1, 4, -1],
    [0, -1, 0],
  ];

  const laplacianValues: number[] = [];

  for (let y = 1; y < height - 1; y++) {
    for (let x = 1; x < width - 1; x++) {
      let sum = 0;
      for (let ky = -1; ky <= 1; ky++) {
        for (let kx = -1; kx <= 1; kx++) {
          const px = pixels[(y + ky) * width + (x + kx)];
          sum += px * laplacianKernel[ky + 1][kx + 1];
        }
      }
      laplacianValues.push(sum);
    }
  }

  if (laplacianValues.length === 0) return 0;

  const mean = laplacianValues.reduce((a, b) => a + b, 0) / laplacianValues.length;
  const variance =
    laplacianValues.reduce((sum, val) => sum + (val - mean) ** 2, 0) / laplacianValues.length;

  return variance;
}

async function detectRotation(buffer: Buffer): Promise<number> {
  const metadata = await sharp(buffer).metadata();

  if (metadata.orientation) {
    const orientationMap: Record<number, number> = {
      1: 0,
      3: 180,
      6: 90,
      8: 270,
    };
    return orientationMap[metadata.orientation] || 0;
  }

  return 0;
}
