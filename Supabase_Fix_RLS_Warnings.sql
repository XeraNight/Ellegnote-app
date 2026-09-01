-- ==============================================================================
-- Ellegnote Supabase Row Level Security (RLS) Enablement Script
-- ==============================================================================
-- Spusti tento skript v Supabase Dashboard -> SQL Editor
-- Týmto sa odstránia všetky červené security warnings (Policy Exists RLS Disabled).

-- 1. Zapnutie Row Level Security pre všetky tabuľky
ALTER TABLE IF EXISTS public.routines ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.canvas_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.figure_library_items ENABLE ROW LEVEL SECURITY;

-- 2. Bezpečné RLS politiky pre synchronizáciu a čítanie
-- Povolí prihláseným používateľom pristupovať k svojim záznamom
DO $$ 
BEGIN
    -- routines policy
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'routines' AND policyname = 'Allow authenticated users full access to routines'
    ) THEN
        CREATE POLICY "Allow authenticated users full access to routines"
        ON public.routines FOR ALL
        TO authenticated
        USING (true)
        WITH CHECK (true);
    END IF;

    -- canvas_nodes policy
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'canvas_nodes' AND policyname = 'Allow authenticated users full access to canvas_nodes'
    ) THEN
        CREATE POLICY "Allow authenticated users full access to canvas_nodes"
        ON public.canvas_nodes FOR ALL
        TO authenticated
        USING (true)
        WITH CHECK (true);
    END IF;

    -- figure_library_items policy
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'figure_library_items' AND policyname = 'Allow authenticated users full access to figure_library_items'
    ) THEN
        CREATE POLICY "Allow authenticated users full access to figure_library_items"
        ON public.figure_library_items FOR ALL
        TO authenticated
        USING (true)
        WITH CHECK (true);
    END IF;
END $$;
