# Sesión — sábado 17 de octubre de 2026 (la Ayuda, revisada por el usuario)

> Segunda vuelta de la misma jornada: la tanda «la Ayuda fiel a la app» se había cerrado y
> publicado (`d47ea67` / `gh-pages` `441db97`), y el usuario la leyó en el sitio. De ahí
> salieron cuatro observaciones, que son esta sesión.
>
> PRD: `docs/prds/2026-10-17_2038-ayuda-fiel-a-la-app.prd.md` (§A4–A7, SC19–SC23, G3–G6)
> Plan: `docs/plans/2026-10-17-ayuda-fiel-a-la-app.plan.md` (§T4)

## 1. Qué pidió el usuario

Sus palabras, tal cual:

> «tengo obserbaciones y kiero ke rebises si es coerente acorte al flujo de la app y
> finalidad: tenemos en ayuda el titulo de el orden de la app eso parece ke no corresponde o
> esta deactualizada, abla de coseca y cultibo rebisa bien eso, tambien tengo ejemplos de
> cultibo cuando ya tengo y esta produciendo y cuiando no tengo nada igual lo llama cultibo y
> estan con ejemplo de casos, asi mismo beo ke no esta todo el texto justificado y esta
> desalineado con respecto a el resto eso debe corregirse»

> «y lo mas importante el resumen de la app en el menu ayuda donde dice guia para comenzar:
> esto debe represenetra la finalidad, funcionalidad y beneficio de la app y en el sentido ke
> debe darle confianza y control al usuarioa ke kiere y lo esta usando eso tambien debemos
> mejoralo aun mas»

## 2. Las cuatro decisiones (revisadas una por una, con la recomendada delante)

| # | Pregunta | Respuesta del usuario |
|---|---|---|
| 1 | ¿Cómo arreglo «El orden de la app»? | **Cuatro pasos, con la cosecha dentro de la venta** (es la guía real de la app). Alternativas descartadas: cinco pasos con la cosecha al final y marcada como automática; solo cambiar el orden |
| 2 | ¿Qué es lo que no cuadra con «cultivo»? | **Que a la finca vacía se le llame «cultivo»** (si no hay nada, el agricultor esperaría empezar por la siembra) |
| 3 | ¿Cómo corrijo la alineación? | **Unificar tipografía y sangría** (sin justificar: ninguna pantalla de la app justifica) |
| 4 | ¿Cómo mejoro el arranque? | **Párrafo de arranque + tres filas** (`Para qué te sirve` · `Qué hace` · `Tus datos son tuyos`) |
| 5 | ¿Dejo el rótulo «Guía para empezar»? | **Se queda** |

## 3. Lo que se tocó

- **Los cuatro pasos.** `helpFlowStep4*` pasa a ser la venta («Registrar la venta» / «A quién
  vendiste, cuánto y los kilos: de ahí sale tu cosecha», con `Icons.sell_outlined`); los pasos
  5 se borran de los dos ARB y de `_FlowSteps`. El porqué: `next_step_service.dart:7-21`
  deriva `crop → sowing → expenses → sale` y anota que la cosecha **nace de la propia venta**.
- **El caso B de la finca vacía.** Título «No tengo nada todavía y voy a empezar»; paso 1
  («Dile a la app qué vas a sembrar…») y paso 2 que cita `sowingNewCropOption` («Crear nuevo
  cultivo», el desplegable de Siembras, que crea el cultivo con `tx.addCrop`); paso 4 sin
  «cosechas y ventas»; el ejemplo, «plátano recién sembrado».
- **Tipografía y sangría.** Un tamaño por papel: 11 el número del paso, 12.5 celdas de tabla y
  chips, 13 prosa y etiquetas, 13.5 títulos de bloque, 14 solo el arranque. Se tocaron
  `_WhereTable` (13/1.4 y destino 12.5), `_DefList` (cuerpo 12.5→13/1.4), `_MiniTable` (altura
  1.3→1.4), `_CaseExample` (título 12.5→13 w700), `_StepsCard` (título 14→13.5 w700, nota
  12→12.5), `_UnitChip` (12→12.5), `_FlowSteps` (cuerpo 12.5→13/1.4), `helpFlowHint` y
  `helpPerHaWhy` (12→12.5/1.4).
- **El arranque.** `helpIntro` reescrito y tres filas nuevas (`helpWhyTitle/Body`,
  `helpDoesTitle/Body`, `helpDataTitle/Body`); `helpIntroPromesa` **borrada** de los dos ARB
  (su contenido vive en «Tus datos son tuyos»).
- **El inglés del arranque**, que decía otra cosa que el español, ahora dice lo mismo.

## 4. Tests y rojo/verde

Archivo nuevo: `test/help_coherencia_test.dart`, cuatro guardas.

| Guarda | Regla | Rojo visto contra `HEAD` |
|---|---|---|
| G3 | el orden son 4 pasos (8 claves en ES y EN) y ningún paso se llama «cosecha» | 10 claves: el paso 5 seguía ahí |
| G4 | a la finca vacía no se la llama «cultivo», y la puerta que cita existe | «estoy empezando un cultivo nuevo desde cero» |
| G5 | un `fontSize:` por papel, y el 14 una sola vez | `[11.0, 12.0, 12.5, 13.0, 13.5, 14.0]` |
| G6 | el arranque pinta finalidad, funcionalidad y datos | esas claves no existían en `HEAD` |

El rojo se vio **sin tocar el árbol de trabajo**: los archivos de `HEAD` se copiaron a
`%TEMP%` con `cmd /c "git show HEAD:<ruta> > <destino>"` y un test temporal apuntó ahí (se
borró al terminar).

Ajuste colateral: `test/help_screen_test.dart` montaba la pantalla en 900x6000 y, al crecer el
arranque, el Glosario quedaba fuera del viewport (`Found 0 widgets`). Ventana a 900x12000.

## 5. Gate y publicación

- `flutter analyze` sobre el proyecto entero: **sin issues** (15,5 s).
- `flutter test`: **954/954** (950 previos + las 4 guardas nuevas).
- Publicado: `gh-pages` de `441db97` a **`0b5a1de`**, huella
  `D3E4CA3754E8079C30378F151D50DAA0C9F880FD9AB7EE2EFFBDEA0CDD3945C7`, **4.808.752 bytes**
  (antes 4.806.917). El paso 7 del deploy confirmó que producción sirve esa misma huella.

## 6. Correcciones honestas de esta sesión

- El «punto de más» del paso 1 que reporté **no existe**: la consola se comió los puntos
  suspensivos («Qué manejas (café, plátano…).»). Esa línea no se tocó.
- El arranque en inglés del PRD anterior **no decía lo mismo** que el español: se arregló de
  paso.

## 7. Pendientes (del lado del usuario)

Siguen abiertos, sin cambios respecto del cierre anterior:

1. Verificación manual del ciclo: moneda con y sin internet, respaldo P1, banner L2.5b, PDF y
   Excel de período mezclado, borrado real, `backup.html`, cosecha con precio → venta.
2. Revocar el **PAT de Supabase** (`docs/audits/2026-10-17-secretos-y-bloqueador.md`, punto 1).
3. **Tanda 2 de la cosecha derivada**: campo «kilos recolectados» en el jornal «Cosechar»
   (solo con evidencia).
4. **W1-c**: agrupar cultivos por terreno en Reportes.

Del lado de la Ayuda, tras esta vuelta no queda nada abierto: las cuatro observaciones están
cerradas y con guarda.
