-- Script SQL para añadir columnas de descuento a la tabla configuracion_precios
-- Ejecutar este script si la tabla ya existe y las columnas no han sido creadas

-- Verificar si las columnas existen antes de añadirlas
DO $$ 
BEGIN
    -- Añadir descuentoMensualidad2 si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'configuracion_precios' 
        AND column_name = 'descuentoMensualidad2'
    ) THEN
        ALTER TABLE configuracion_precios 
        ADD COLUMN "descuentoMensualidad2" INTEGER NOT NULL DEFAULT 0;
        COMMENT ON COLUMN configuracion_precios."descuentoMensualidad2" IS 'Descuento en porcentaje para 2 estudiantes (0-100) aplicado sobre la suma total';
    END IF;

    -- Añadir descuentoMensualidad3Plus si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'configuracion_precios' 
        AND column_name = 'descuentoMensualidad3Plus'
    ) THEN
        ALTER TABLE configuracion_precios 
        ADD COLUMN "descuentoMensualidad3Plus" INTEGER NOT NULL DEFAULT 0;
        COMMENT ON COLUMN configuracion_precios."descuentoMensualidad3Plus" IS 'Descuento en porcentaje para 3 o más estudiantes (0-100)';
    END IF;

    -- Añadir descuentoMatricula2 si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'configuracion_precios' 
        AND column_name = 'descuentoMatricula2'
    ) THEN
        ALTER TABLE configuracion_precios 
        ADD COLUMN "descuentoMatricula2" INTEGER NOT NULL DEFAULT 0;
        COMMENT ON COLUMN configuracion_precios."descuentoMatricula2" IS 'Descuento en porcentaje para 2 estudiantes (0-100) aplicado sobre la suma total';
    END IF;

    -- Añadir descuentoMatricula3Plus si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'configuracion_precios' 
        AND column_name = 'descuentoMatricula3Plus'
    ) THEN
        ALTER TABLE configuracion_precios 
        ADD COLUMN "descuentoMatricula3Plus" INTEGER NOT NULL DEFAULT 0;
        COMMENT ON COLUMN configuracion_precios."descuentoMatricula3Plus" IS 'Descuento en porcentaje para 3 o más estudiantes (0-100)';
    END IF;
    
    RAISE NOTICE 'Columnas de descuento añadidas o ya existían';
END $$;

-- Verificar las columnas añadidas
SELECT 
    column_name, 
    data_type, 
    column_default,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'configuracion_precios'
AND column_name LIKE '%descuento%'
ORDER BY ordinal_position;
