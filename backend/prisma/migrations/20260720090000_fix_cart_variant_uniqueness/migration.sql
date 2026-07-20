-- Replace the old one-line-per-product constraint with variant-aware cart lines.
ALTER TABLE "cart_items"
DROP CONSTRAINT IF EXISTS "cart_items_user_id_product_id_key";

DROP INDEX IF EXISTS "cart_items_user_id_product_id_key";

CREATE UNIQUE INDEX "cart_items_user_product_no_variant_key"
ON "cart_items" ("user_id", "product_id")
WHERE "variant_id" IS NULL;

CREATE UNIQUE INDEX "cart_items_user_product_variant_key"
ON "cart_items" ("user_id", "product_id", "variant_id")
WHERE "variant_id" IS NOT NULL;

CREATE INDEX IF NOT EXISTS "idx_cart_user_product_variant"
ON "cart_items" ("user_id", "product_id", "variant_id");
