# Plan: Sección "Ayuda" (guía de primeros pasos dentro de la app)

- **Fecha**: 2026-09-07
- **Tipo**: Implementación (feature UI de contenido)
- **Objetivo**: exponer la guía de primeros pasos dentro de la app (sin depender de
  GitHub ni internet), accesible desde el menú **⋮ → Ayuda** y desde la tarjeta
  "Tu próximo paso" vía **"Ver guía completa"**.
- **Decisión previa confirmada por el usuario**: crear una sección Ayuda donde colocar
  la guía (opción 1 interna, no enlace externo).

## Alcance

1. **`lib/screens/help_screen.dart`** (nuevo): pantalla con la guía en es/en:
   - Intro (para qué sirve la app + la promesa "no adivinamos tu producción").
   - **¿Dónde entro cada dato?** (tabla situación → pantalla real, reutilizando
     strings existentes: `tabOverview`, `menuCrops`, `menuSowings`, `menuHarvests`,
     `tabRegister` + tipos Gasto/Ingreso).
   - **¿Por dónde empiezo?** casos A (ya sembrado) y B (voy a sembrar), pasos numerados.
   - **Unidades**: kg, arroba (12.5 kg), saco (70 kg).
   - **Glosario**: resumen agrícola (plantines, área, plantas vivas, destino,
     sincronizar, alerta) + botón que abre el glosario financiero existente
     (`showTerminologyGuide`).
2. **Menú Home** (⋮): nuevo ítem "Ayuda" → `HelpScreen`.
3. **Tarjeta "Tu próximo paso"**: link "Ver guía completa" (TextButton bajo el
   subtítulo) → `HelpScreen`.
4. i18n es/en (`app_es.arb` / `app_en.arb`) con ~32 strings nuevos por idioma;
   regen con `flutter gen-l10n`.

## Reglas

- No hay lógica nueva: solo UI + strings. Cero impacto en Supabase/GH Pages
  (los mismos flujos de deploy de siempre).
- Reutilizar strings i18n existentes siempre que aplique (fases, destinos,
  glosario financiero, pantallas).
- El glosario financiero NO se duplica: se abre el diálogo existente.

## Criterios de aceptación

- **AC-1**: `HelpScreen` se abre desde el menú ⋮ ("Ayuda") y muestra todas las
  secciones (intro, dónde entro cada dato, casos A/B, unidades, glosario).
- **AC-2**: La tabla de "dónde entro cada dato" referencia las pantallas reales
  (Cultivos, Siembras, Cosechas, Registrar Gasto/Ingreso).
- **AC-3**: El botón del glosario abre el diálogo `showTerminologyGuide`.
- **AC-4**: La tarjeta "Tu próximo paso" muestra el link "Ver guía completa" y lo
  dispara (widget test).
- **AC-5**: `flutter analyze` sin issues; `flutter test` verde (111 actuales + nuevos).
- **AC-6**: Desplegado en GitHub Pages con HTTP 200, es/en correctos.

## Fuera de alcance

- Vínculo "Ver guía completa" a contenido externo/host de la guía (se mantiene
  interna y estática; el markdown de `docs/guides/` sigue siendo la fuente del repo).