# Sesión 2026-09-14 — Help text, auth fixes, auditoría crítica

## Resumen
Sesión de mejoras UX, fixes de autenticación y auditoría completa del código.

## Cambios realizados

### 1. Help text contextual (cultivos + siembras)
- Strings i18n: `helpUnit`, `helpCycle`, `helpArea`, `helpPlants`, `helpEstablishment`, `helpSowingKind`, `helpSowingPlants`, `helpSowingLostPlants`, `helpSowingArea`
- `crop_editor_dialog.dart`: helperText en 5 campos
- `sowing_screen.dart`: helperText en 4 campos + texto bajo SegmentedButton
- Commit: `973ba32`

### 2. Auth fixes
- Validator unificado en `auth_screen.dart` (regex completa)
- `notifyListeners()` en `signUp()` para que AuthGate navegue a HomeScreen
- Password recovery con validación de email completa
- Commit: `a0b76bf`

### 3. Auditoría completa del código
- 6 bugs críticos encontrados (datos huérfanos)
- 5 bugs medios (validación)
- 5 menores (UI/sync)

### 4. Fixes críticos (B1-B5)
- `deleteCrop()`: borra siembras, cosechas y desvincula transacciones
- `deleteHarvest()`: desvincula transacciones con harvestId
- `deleteSowing()`: desvincula transacciones con sowingId
- Commit: `beed241`

### 5. B6 revertido
- `defaultCrops` no se inserta automáticamente (el onboarding ya guía al usuario)

## Estado
- 162/162 tests verdes
- Deploy: `59a938e` (gh-pages)
- Commit main: `beed241`

## Pendiente (próxima sesión)
- Bugs medios: B7-B11 (validación)
- Bugs menores: B12-B16 (UI/sync)
- Feature: CropEditorDialog variedad/notas/fecha siembra
