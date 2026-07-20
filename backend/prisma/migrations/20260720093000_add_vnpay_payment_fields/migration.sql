ALTER TABLE "orders"
ADD COLUMN IF NOT EXISTS "payment_transaction_id" VARCHAR(255),
ADD COLUMN IF NOT EXISTS "paid_at" TIMESTAMP(6);

CREATE UNIQUE INDEX IF NOT EXISTS "orders_payment_transaction_id_key"
ON "orders" ("payment_transaction_id");
