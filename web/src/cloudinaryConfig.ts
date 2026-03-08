import { Cloudinary } from '@cloudinary/url-gen';
import { CloudinaryImage, CloudinaryVideo } from '@cloudinary/url-gen';
import { fill } from '@cloudinary/url-gen/actions/resize';
import { improve, sharpen } from '@cloudinary/url-gen/actions/adjust';
import { quality, format } from '@cloudinary/url-gen/actions/delivery';
import { auto as autoQuality } from '@cloudinary/url-gen/qualifiers/quality';
import { auto as autoFormat } from '@cloudinary/url-gen/qualifiers/format';
import { autoGravity } from '@cloudinary/url-gen/qualifiers/gravity';
import { byRadius } from '@cloudinary/url-gen/actions/roundCorners';
import { source } from '@cloudinary/url-gen/actions/overlay';
import { image } from '@cloudinary/url-gen/qualifiers/source';

export const CLOUD_NAME: string =
  import.meta.env.VITE_CLOUDINARY_CLOUD_NAME ?? 'demo';

export const UPLOAD_PRESET: string =
  import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET ?? 'returnclip_demo';

// Singleton Cloudinary instance — the entry point for all SDK operations
export const cld = new Cloudinary({
  cloud: { cloudName: CLOUD_NAME },
  url: { secure: true },
});

/**
 * Build an optimized return photo image using the @cloudinary/url-gen SDK.
 * Applies: auto quality, auto format, AI enhancement, responsive width.
 * Use with <AdvancedImage cldImg={buildReturnPhotoImage(publicId)} />
 */
export function buildReturnPhotoImage(publicId: string, width = 800): CloudinaryImage {
  return cld
    .image(publicId)
    .resize(fill().width(width).gravity(autoGravity()))
    .adjust(improve())
    .adjust(sharpen())
    .delivery(quality(autoQuality()))
    .delivery(format(autoFormat()));
}

/**
 * Build a square thumbnail using c_fill with auto gravity.
 * Use with <AdvancedImage cldImg={buildThumbnailImage(publicId)} />
 */
export function buildThumbnailImage(publicId: string, size = 300): CloudinaryImage {
  return cld
    .image(publicId)
    .resize(fill().width(size).height(size).gravity(autoGravity()))
    .delivery(quality(autoQuality()))
    .delivery(format(autoFormat()));
}

/**
 * Build an optimized video for streaming.
 * Use with <AdvancedVideo cldVid={buildReturnVideo(publicId)} />
 */
export function buildReturnVideo(publicId: string, width = 720): CloudinaryVideo {
  return cld
    .video(publicId)
    .resize(fill().width(width))
    .delivery(quality(autoQuality()))
    .delivery(format(autoFormat()));
}

/**
 * Build a video thumbnail (poster image extracted from video at given second).
 * Cloudinary generates this as a JPEG automatically.
 */
export function buildVideoThumbnailUrl(publicId: string, atSecond = 2): string {
  return `https://res.cloudinary.com/${CLOUD_NAME}/video/upload/so_${atSecond},q_auto,f_auto,w_720/${publicId}.jpg`;
}

/**
 * Returns true if the URL is a Cloudinary-hosted image/video URL.
 * Use this to decide whether to render with <AdvancedImage> vs plain <img>.
 */
export function isCloudinaryUrl(url: string): boolean {
  return url.includes('res.cloudinary.com') || url.includes('.cloudinary.com');
}
