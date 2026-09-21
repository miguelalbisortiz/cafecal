# Arquitectura del Sistema — Mi Cafetal

## Diagrama de Componentes (alto nivel)

```mermaid
flowchart TD
    subgraph Usuario
        U((👤 Usuario))
    end

    subgraph FlutterApp["📱 Flutter App (Web)"]
        direction TB

        subgraph Screens["Pantallas"]
            Auth["🔐 AuthScreen<br/>Login / Registro"]
            Home["🏠 HomeScreen<br/>Dashboard + Onboarding"]
            Crops["🌱 CropsScreen<br/>Gestión de cultivos"]
            Sowing["🌿 SowingScreen<br/>Registro de siembras"]
            Register["📝 RegisterScreen<br/>Gastos / Ingresos"]
            Movements["📋 MovementsScreen<br/>Historial"]
            Report["📊 ReportScreen<br/>Reportes"]
            Harvest["🌾 HarvestScreen<br/>Cosechas"]
            Help["❓ HelpScreen<br/>Ayuda"]
            Settings["⚙️ SettingsScreen<br/>Configuración"]
        end

        subgraph Providers["Providers (Estado)"]
            AuthP["AuthProvider<br/>Sesión + login"]
            TxP["TransactionProvider<br/>Datos en memoria"]
            SyncP["SyncProvider<br/>Sync local ↔ remoto"]
            AlertP["AlertProvider<br/>Alertas inteligentes"]
        end

        subgraph Services["Servicios"]
            Local["LocalStorage<br/>SharedPreferences<br/>(offline + namespace por usuario)"]
            Supa["SupabaseService<br/>Auth + DB + RLS"]
            Next["NextStepService<br/>Guía de siguientes pasos"]
            Alert["AlertService<br/>Motor de reglas"]
        end

        subgraph Models["Modelos"]
            Crop["Crop<br/>Cultivo"]
            Tx["Transaction<br/>Gasto / Ingreso"]
            SowingM["Sowing<br/>Siembra"]
            HarvestM["Harvest<br/>Cosecha"]
            SettingsM["FarmSettings<br/>Preferencias"]
        end
    end

    subgraph Supabase["☁️ Supabase (nube)"]
        direction TB
        AuthS["Auth<br/>Usuarios + JWT"]
        DB[("PostgreSQL<br/>RLS por usuario")]
    end

    subgraph Storage["💾 Persistencia Local"]
        SP["SharedPreferences<br/>(datos offline)"]
    end

    %% Conexiones Usuario → App
    U -->|"abre la app"| Auth
    Auth -->|"login OK"| Home

    %% Conexiones Screens → Providers
    Home --> AuthP
    Home --> TxP
    Home --> SyncP
    Home --> AlertP
    Crops --> TxP
    Sowing --> TxP
    Register --> TxP
    Movements --> TxP
    Report --> TxP
    Harvest --> TxP

    %% Conexiones Providers → Services
    AuthP --> Supa
    TxP --> Local
    SyncP --> Supa
    SyncP --> TxP
    AlertP --> Alert
    AlertP --> TxP

    %% Conexiones Services → External
    Local --> SP
    Supa --> AuthS
    Supa --> DB

    %% Conexiones Services → Models
    TxP --> Crop
    TxP --> Tx
    TxP --> SowingM
    TxP --> HarvestM
    TxP --> SettingsM
    Next --> Crop
    Next --> SowingM
```

## Flujo de Datos (sync)

```mermaid
sequenceDiagram
    participant U as 👤 Usuario
    participant App as 📱 Flutter App
    participant Local as 💾 LocalStore
    participant Supa as ☁️ Supabase

    Note over App: Al iniciar sesión
    App->>Supa: signIn(email, password)
    Supa-->>App: JWT + user.id
    App->>Local: bindUser(uid)<br/>migrar namespace

    Note over App: Uso normal (offline-first)
    U->>App: registra gasto/cultivo/siembra
    App->>Local: saveTransactions()<br/>saveCrops()<br/>saveSowings()
    App-->>U: guardado local ✓

    Note over App: Sync automática o manual
    App->>Local: pendingSync()
    App->>Supa: upsert(transactions/crops/sowings)
    Supa-->>App: confirmación
    App->>Local: markAllSynced()

    Note over App: Pull remoto
    App->>Supa: select().eq('user_id', uid)
    Supa-->>App: datos remotos
    App->>Local: mergeRemote()<br/>solo IDs nuevos
```

## Flujo de Onboarding (puerta de entrada)

```mermaid
stateDiagram-v2
    [*] --> Bloqueado: App abierta<br/>0 cultivos, 0 siembras

    state Bloqueado {
        [*] --> CardsPrimerPaso
        CardsPrimerPaso: Solo 2 cards:<br/>🌱 Registrar siembra<br/>🧑🌾 Registrar cultivo
    }

    Bloqueado --> Desbloqueado: Crear 1 cultivo<br/>O registrar 1 siembra

    state Desbloqueado {
        [*] --> Dashboard
        Dashboard: Resumen + gastos +<br/>ingresos + historial
    }

    Desbloqueado --> Dashboard: Cualquier<br/>acceso futuro
```

## Modelo de Datos (relaciones)

```mermaid
erDiagram
    USER ||--o{ CROP : tiene
    USER ||--o{ SOWING : registra
    USER ||--o{ TRANSACTION : genera
    USER ||--o{ HARVEST : cosecha

    CROP ||--o{ SOWING : recibe
    CROP ||--o{ TRANSACTION : associa
    CROP ||--o{ HARVEST : produce

    SOWING ||--o{ TRANSACTION : genera_siembra
    HARVEST ||--o{ TRANSACTION : genera_venta

    USER {
        uuid id PK
        string email
        string encrypted_password
    }

    CROP {
        uuid id PK
        uuid user_id FK
        string name
        string phase
        string cycle
        float area_ha
        int live_plants
        float establishment_cost
    }

    SOWING {
        uuid id PK
        uuid user_id FK
        uuid crop_id FK
        string kind
        int plants
        float area_ha
        date sowing_date
    }

    TRANSACTION {
        uuid id PK
        uuid user_id FK
        uuid crop_id FK
        string type
        string category
        float amount
        date txn_date
        string description
    }

    HARVEST {
        uuid id PK
        uuid user_id FK
        uuid crop_id FK
        float amount
        string unit
        string destination
        date harvest_date
    }
```

---

*Generado: 2026-09-09 | Proyecto: Mi Cafetal | Versión: 1.0*