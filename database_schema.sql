CREATE TABLE
    public.categories (
        id uuid NOT NULL DEFAULT gen_random_uuid (),
        code character varying NOT NULL UNIQUE,
        name character varying NOT NULL,
        description text,
        parent_id uuid,
        created_at timestamp
        with
            time zone DEFAULT now (),
            CONSTRAINT categories_pkey PRIMARY KEY (id),
            CONSTRAINT categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.categories (id)
    );

CREATE TABLE
    public.orders (
        id uuid NOT NULL DEFAULT gen_random_uuid (),
        order_date date NOT NULL,
        product_id uuid,
        units integer NOT NULL CHECK (units > 0),
        total_cost numeric NOT NULL,
        created_at timestamp
        with
            time zone DEFAULT now (),
            CONSTRAINT orders_pkey PRIMARY KEY (id),
            CONSTRAINT orders_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products (id)
    );

CREATE TABLE
    public.product_categories (
        product_id uuid NOT NULL,
        category_id uuid NOT NULL,
        created_at timestamp
        with
            time zone DEFAULT now (),
            CONSTRAINT product_categories_pkey PRIMARY KEY (product_id, category_id),
            CONSTRAINT product_categories_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products (id),
            CONSTRAINT product_categories_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories (id)
    );

CREATE TABLE
    public.products (
        id uuid NOT NULL DEFAULT gen_random_uuid (),
        code character varying NOT NULL UNIQUE,
        name character varying NOT NULL,
        description text,
        photos ARRAY,
        created_at timestamp
        with
            time zone DEFAULT now (),
            CONSTRAINT products_pkey PRIMARY KEY (id)
    );

CREATE TABLE
    public.rates (
        id uuid NOT NULL DEFAULT gen_random_uuid (),
        product_id uuid,
        start_date date NOT NULL,
        end_date date NOT NULL,
        price numeric NOT NULL,
        created_at timestamp
        with
            time zone DEFAULT now (),
            CONSTRAINT rates_pkey PRIMARY KEY (id),
            CONSTRAINT rates_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products (id)
    );

CREATE INDEX idx_categories_parent ON categories (parent_id);

CREATE INDEX idx_products_code ON products (code);

CREATE INDEX idx_product_categories_pid ON product_categories (product_id);

CREATE INDEX idx_product_categories_cid ON product_categories (category_id);

CREATE INDEX idx_rates_product_dates ON rates (product_id, start_date, end_date);

CREATE INDEX idx_orders_date ON orders (order_date);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.rates ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Total access for authenticated users" ON "public"."categories" FOR ALL TO public USING (auth.role () = CAST('authenticated' AS text))
WITH
    CHECK (auth.role () = CAST('authenticated' AS text));

CREATE POLICY "Total access for authenticated users" ON "public"."products" FOR ALL TO public USING (auth.role () = CAST('authenticated' AS text))
WITH
    CHECK (auth.role () = CAST('authenticated' AS text));

CREATE POLICY "Total access for authenticated users" ON "public"."product_categories" FOR ALL TO public USING (auth.role () = CAST('authenticated' AS text))
WITH
    CHECK (auth.role () = CAST('authenticated' AS text));

CREATE POLICY "Total access for authenticated users" ON "public"."rates" FOR ALL TO public USING (auth.role () = CAST('authenticated' AS text))
WITH
    CHECK (auth.role () = CAST('authenticated' AS text));

CREATE POLICY "Total access for authenticated users" ON "public"."orders" FOR ALL TO public USING (auth.role () = CAST('authenticated' AS text))
WITH
    CHECK (auth.role () = CAST('authenticated' AS text));

INSERT INTO
    public.categories (code, name)
VALUES
    ('CAT001', 'Electrónica'),
    ('CAT002', 'Hogar');

INSERT INTO
    public.products (code, name, description)
VALUES
    (
        'PROD001',
        'Smartphone X',
        'Descripción del teléfono...'
    );