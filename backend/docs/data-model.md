# WesRugby – Modelo de datos base

Este documento resume el modelo relacional que implementaremos gradualmente en el backend
(TypeORM). La estrategia es crear un núcleo consistente y luego extenderlo módulo por
módulo según los requerimientos funcionales priorizados con el usuario.

## Entidades nucleares

### users
- id (uuid, pk)
- ut (varchar[12], único)
- email (varchar[255], único)
- password (varchar, hash bcrypt)
- ull_name (varchar[150])
- ole (enum: directiva, 	esorera, entrenador, poderado, dministrador)
- phone (varchar[20], opcional)
- status (enum: ctive, inactive, locked, default ctive)
- created_at / updated_at

### players
- id (uuid, pk)
- ut (varchar[12], único)
- irst_name, last_name
- irth_date
- gender (enum)
- school_grade (varchar[30])
- medical_notes (text, opcional)
- guardian_id (uuid fk -> users)
- created_at / updated_at

### enrollments
Representa la inscripción anual del jugador en la rama.
- id (uuid, pk)
- player_id (uuid fk -> players)
- season (varchar[9], ej. 2025-1)
- status (enum: pending, ctive, inactive, withdrawn)
- plan_id (uuid fk -> payment_plans, opcional)
- created_by (uuid fk -> users)
- pproved_by (uuid fk -> users, opcional)
- pproved_at / withdrawn_at
- 
otes (text)
- timestamps

### payment_plans
- id (uuid, pk)
- 
ame
- mount (numeric 10,2)
- requency (enum: mensual, 	rimestral, nual)
- is_active (boolean)
- timestamps

### payments
Incluye comprobantes subidos por apoderados o registros manuales.
- id (uuid, pk)
- enrollment_id (uuid fk -> enrollments)
- submitted_by (uuid fk -> users)
- status (enum: pending, alidated, ejected)
- method (enum: 	ransferencia, efectivo, 	arjeta, webpay, otro)
- mount (numeric 10,2)
- eference_code (varchar[50], único opcional)
- paid_at (date, opcional)
- due_date (date, opcional)
- oucher_url (varchar[255], opcional)
- eviewed_by (uuid fk -> users, opcional)
- eviewed_at (timestamp, opcional)
- comments (text, opcional)
- timestamps

### notifications
- id (uuid, pk)
- ecipient_id (uuid fk -> users)
- 	itle / message
- channel (enum: in_app, email, push)
- payload (jsonb, opcional)
- sent_at (timestamp)
- ead_at (timestamp, opcional)

### attendance_records
- id (uuid, pk)
- enrollment_id (uuid fk -> enrollments)
- ecorded_by (uuid fk -> users)
- ctivity_date (date)
- ctivity_type (enum: entrenamiento, partido, evento)
- status (enum: presente, usente, 	arde, justificado)
- 
otes (text, opcional)
- ecorded_at / updated_at

### inventory_items (para módulo de ventas)
- id (uuid, pk)
- sku (varchar[40], único)
- 
ame
- description
- stock (int)
- unit_price (numeric 10,2)
- is_active (boolean)
- timestamps

### inventory_sales
- id (uuid, pk)
- item_id (uuid fk -> inventory_items)
- quantity (int)
- 	otal_amount (numeric 10,2)
- sold_at (timestamp)
- sold_by (uuid fk -> users)
- uyer_name (varchar[150], opcional)
- 
otes (text, opcional)

## Consideraciones

1. Usaremos uuid como clave primaria para facilitar integraciones y ocultar RUT.
2. Los RUT seguirán almacenados con formato 99.999.999-X y se validarán en el nivel
   de dominio.
3. Todas las tablas tendrán created_at / updated_at automáticos.
4. Las relaciones opcionales (pproved_by, eviewed_by) se permitirán en NULL.
5. El modelo se implementará en migraciones sucesivas para evitar dropSchema y
   proteger datos reales.
6. Para pruebas automáticas se habilitará un DataSource alterno sqlite en memoria.

El siguiente paso es reflejar este diseño en las entidades TypeORM y en una migración
inicial, además de un script de seeding con los usuarios base (directiva, tesorera,
entrenador, apoderado demo).