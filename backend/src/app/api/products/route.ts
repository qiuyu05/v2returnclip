// GET /api/products — Fetch exchange products from Shopify (or fallback mock)
import { NextResponse } from 'next/server';
import { logger } from '@/lib/logger';

const STORE_DOMAIN = process.env.SHOPIFY_STORE_DOMAIN || '';
const ADMIN_TOKEN = process.env.SHOPIFY_ADMIN_TOKEN || '';
const SHOPIFY_ENABLED = process.env.SHOPIFY_ENABLED === 'true';

const MOCK_PRODUCTS = [
    { id: 'prod_velvet_chair', title: 'Velvet Accent Chair', handle: 'velvet-accent-chair', description: 'Luxurious velvet upholstered accent chair', minPrice: 299.0, currency: 'CAD', imageUrl: 'https://images.unsplash.com/photo-1567538096630-e0c55bd6374c?w=400', variants: [{ id: 'var_navy', title: 'Navy Blue', price: 299.0, availableForSale: true }, { id: 'var_blush', title: 'Blush Pink', price: 299.0, availableForSale: true }] },
    { id: 'prod_throw_pillow', title: 'Luxury Throw Pillow Set', handle: 'luxury-throw-pillow', description: 'Set of 2 premium throw pillows', minPrice: 79.0, currency: 'CAD', imageUrl: 'https://images.unsplash.com/photo-1584100936595-c0654b55a2e2?w=400', variants: [{ id: 'var_cream', title: 'Cream - Set of 2', price: 79.0, availableForSale: true }, { id: 'var_sage', title: 'Sage Green - Set of 2', price: 79.0, availableForSale: true }] },
    { id: 'prod_marble_table', title: 'Marble Side Table', handle: 'marble-side-table', description: 'Genuine marble top with brass base', minPrice: 249.0, currency: 'CAD', imageUrl: 'https://images.unsplash.com/photo-1532372576444-dda954194ad0?w=400', variants: [{ id: 'var_white_marble', title: 'White Marble', price: 249.0, availableForSale: true }] },
    { id: 'prod_ceramic_lamp', title: 'Ceramic Table Lamp', handle: 'ceramic-table-lamp', description: 'Handcrafted ceramic base with linen shade', minPrice: 189.0, currency: 'CAD', imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400', variants: [{ id: 'var_ivory', title: 'Ivory', price: 189.0, availableForSale: true }, { id: 'var_terracotta', title: 'Terracotta', price: 189.0, availableForSale: true }] },
    { id: 'prod_linen_rug', title: 'Natural Linen Area Rug', handle: 'natural-linen-rug', description: 'Handwoven natural linen, 5x8 ft', minPrice: 249.0, currency: 'CAD', imageUrl: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400', variants: [{ id: 'var_5x8', title: '5 x 8 ft', price: 249.0, availableForSale: true }] },
];

export async function GET() {
    if (SHOPIFY_ENABLED && STORE_DOMAIN && ADMIN_TOKEN) {
        try {
            const url = `https://${STORE_DOMAIN}/admin/api/2024-01/products.json?limit=20&status=active`;
            const response = await fetch(url, {
                headers: { 'X-Shopify-Access-Token': ADMIN_TOKEN, 'Content-Type': 'application/json' },
            });

            if (response.ok) {
                const data = await response.json();
                const products = (data.products || []).map((p: Record<string, unknown>) => {
                    const variants = ((p.variants as Record<string, unknown>[]) || []).map((v: Record<string, unknown>) => ({
                        id: String(v.id),
                        title: String(v.title || 'Default'),
                        price: parseFloat(String(v.price)) || 0,
                        availableForSale: v.inventory_policy === 'continue' || (v.inventory_quantity as number) > 0,
                    }));
                    const images = p.images as Record<string, unknown>[] | undefined;
                    return {
                        id: String(p.id),
                        title: String(p.title || ''),
                        handle: String(p.handle || ''),
                        description: String((p.body_html as string || '').replace(/<[^>]+>/g, '')),
                        minPrice: Math.min(...variants.map((v: { price: number }) => v.price)),
                        currency: 'CAD',
                        imageUrl: images?.[0] ? String((images[0] as Record<string, unknown>).src) : null,
                        variants,
                    };
                });
                logger.info('Fetched products from Shopify', { count: products.length });
                return NextResponse.json({ products });
            }
        } catch (err) {
            logger.error('Shopify products fetch failed', { error: String(err) });
        }
    }

    logger.info('Using mock products (Shopify not configured)');
    return NextResponse.json({ products: MOCK_PRODUCTS });
}
