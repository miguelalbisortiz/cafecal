-- =============================================
-- E1 · la venta real: deducciones y estado de pago.
--
-- En café real no siempre se paga lo que se entrega: el comprador descuenta
-- impureza, humedad o piedras. Hasta ahora la app solo podía guardar el monto
-- que entraba, y con eso se perdía la mitad del negocio: no se podía decir
-- "coseché 480 kg, me descontaron 80, me pagaron por 400".
--
--   deduction_qty     kilos que el comprador descontó  (null = ninguno)
--   deduction_reason  motivo, en palabras del usuario ("impureza", "húmedo")
--   paid              false = por cobrar. default true: un ingreso ya
--                     registrado sin marca es plata que entró, y así quedan
--                     los datos viejos.
--
-- `amount` NO cambia de significado: sigue siendo lo neto, lo que entró a
-- caja. Los reportes y la caja menor siguen leyendo amount tal cual, así que
-- nada existente se mueve.
--
-- ⚠️ ORDEN IMPORTANTE: aplicar ANTES de desplegar la app que envía estas
-- columnas. `buildTransactionPayload` manda las columnas a mano, así que si
-- no existen Postgrest responde PGRST204 y se cae el subido COMPLETO — el
-- mismo caso que `currency` (202609250001) y `saco_kg` (202610100002).
--
-- Idempotente: se puede re-ejecutar sin efecto.
-- =============================================

alter table public.transactions
  add column if not exists deduction_qty numeric,
  add column if not exists deduction_reason text,
  add column if not exists paid boolean not null default true;
