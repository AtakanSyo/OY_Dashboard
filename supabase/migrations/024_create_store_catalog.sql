-- Yönetilebilir mağaza kataloğu ve kliniğe özel fiyatlar.
CREATE TABLE public.store_products (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  short_description TEXT NOT NULL DEFAULT '',
  full_description TEXT NOT NULL DEFAULT '',
  usage_title TEXT NOT NULL DEFAULT 'Kimler için uygun?',
  usage_description TEXT NOT NULL DEFAULT '',
  why_recommended TEXT NOT NULL DEFAULT '',
  base_price NUMERIC(12,2) NOT NULL CHECK (base_price >= 0),
  currency_code TEXT NOT NULL DEFAULT 'TRY',
  image_path TEXT NOT NULL DEFAULT '',
  is_add_on BOOLEAN NOT NULL DEFAULT FALSE,
  can_be_purchased_alone BOOLEAN NOT NULL DEFAULT TRUE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.store_product_clinic_prices (
  product_id TEXT NOT NULL REFERENCES public.store_products(id) ON DELETE CASCADE,
  clinic_id BIGINT NOT NULL REFERENCES public.clinics(id) ON DELETE CASCADE,
  price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (product_id, clinic_id)
);

INSERT INTO public.store_products
  (id, title, short_description, full_description, usage_description, why_recommended, base_price, image_path, is_add_on, sort_order)
VALUES
  ('custom-insole', 'Kişiye Özel Tabanlık', 'Ayak analizinize göre kişiselleştirilmiş destek.', 'Günlük kullanım için ölçüm verilerinize göre tasarlanan kişiye özel tabanlık.', 'Kişiselleştirilmiş ayak desteğine ihtiyaç duyan kullanıcılar için uygundur.', 'Öneriler bilgilendirme amaçlıdır.', 4000, 'assets/images/products/custom_insole.png', FALSE, 10),
  ('sport-insole', 'Spor Tabanlığı', 'Aktif yaşam ve spor için dinamik destek.', 'Spor sırasında denge ve yük dağılımını desteklemek üzere kişiselleştirilir.', 'Aktif yaşam süren ve spor yapan kullanıcılar için uygundur.', 'Öneriler bilgilendirme amaçlıdır.', 4500, 'assets/images/products/sport_insole.png', FALSE, 20),
  ('heel-pad', 'Topuk Pedi', 'Topuk bölgesi için yumuşak destek.', 'Topuk bölgesindeki yükü dağıtmaya yardımcı aksesuar.', 'Topuk desteğine ihtiyaç duyan kullanıcılar içindir.', 'Öneriler bilgilendirme amaçlıdır.', 350, 'assets/images/addons/heel_pad.png', TRUE, 30),
  ('met-pad', 'Metatars Pedi', 'Ön ayak bölgesi için destek.', 'Metatars bölgesindeki yük dağılımına yardımcı aksesuar.', 'Ön ayak desteğine ihtiyaç duyan kullanıcılar içindir.', 'Öneriler bilgilendirme amaçlıdır.', 420, 'assets/images/addons/met_pad.png', TRUE, 40),
  ('cleaning-spray', 'Temizleme Spreyi', 'Ürün bakımı için pratik temizlik.', 'Tabanlık ve aksesuarların düzenli bakımı için temizleme ürünü.', 'Ürünlerinin bakımını kolaylaştırmak isteyen kullanıcılar içindir.', 'Öneriler bilgilendirme amaçlıdır.', 250, 'assets/images/addons/cleaning_spray.png', TRUE, 50),
  ('carry-case', 'Taşıma Çantası', 'Ürünlerinizi güvenle taşıyın.', 'Tabanlık ve aksesuarlar için koruyucu taşıma çantası.', 'Ürünlerini yanında taşıyan kullanıcılar içindir.', 'Öneriler bilgilendirme amaçlıdır.', 300, 'assets/images/addons/carry_case.png', TRUE, 60)
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.store_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_product_clinic_prices ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_optityou_team_member()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    JOIN public.roles r ON r.id = up.role_id
    WHERE up.auth_id = auth.uid() AND up.is_active = TRUE AND r.role_code = 'OPTIYOU_TEAM'
  );
$$;

CREATE POLICY "Authenticated users read active store products" ON public.store_products
  FOR SELECT TO authenticated USING (is_active OR public.is_optityou_team_member());
CREATE POLICY "Optiyou team manages store products" ON public.store_products
  FOR ALL TO authenticated USING (public.is_optityou_team_member()) WITH CHECK (public.is_optityou_team_member());
CREATE POLICY "Authenticated users read clinic prices" ON public.store_product_clinic_prices
  FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "Optiyou team manages clinic prices" ON public.store_product_clinic_prices
  FOR ALL TO authenticated USING (public.is_optityou_team_member()) WITH CHECK (public.is_optityou_team_member());

CREATE OR REPLACE FUNCTION public.get_store_products(
  p_clinic_id BIGINT DEFAULT NULL,
  p_include_inactive BOOLEAN DEFAULT FALSE
) RETURNS TABLE (
  id TEXT, title TEXT, short_description TEXT, full_description TEXT,
  usage_title TEXT, usage_description TEXT, why_recommended TEXT,
  base_price NUMERIC, effective_price NUMERIC, currency_code TEXT,
  image_path TEXT, is_add_on BOOLEAN, can_be_purchased_alone BOOLEAN,
  is_active BOOLEAN, sort_order INTEGER
) LANGUAGE sql STABLE SECURITY INVOKER AS $$
  SELECT p.id, p.title, p.short_description, p.full_description,
    p.usage_title, p.usage_description, p.why_recommended,
    p.base_price, COALESCE(cp.price, p.base_price), p.currency_code,
    p.image_path, p.is_add_on, p.can_be_purchased_alone, p.is_active, p.sort_order
  FROM public.store_products p
  LEFT JOIN public.store_product_clinic_prices cp
    ON cp.product_id = p.id AND cp.clinic_id = p_clinic_id
  WHERE p.is_active OR (p_include_inactive AND public.is_optityou_team_member())
  ORDER BY p.sort_order, p.title;
$$;

GRANT EXECUTE ON FUNCTION public.get_store_products(BIGINT, BOOLEAN) TO authenticated;
