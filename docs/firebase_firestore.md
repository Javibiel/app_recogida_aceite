# Firebase Firestore

## Colecciones

### `recogidas`

Cada documento representa una solicitud de recogida creada por un cliente.

```json
{
  "clientEmail": "cliente.norte1@serrma.com",
  "clientName": "Cliente Norte 1",
  "clientAddress": "Calle Norte 1",
  "clientPhone": "600000101",
  "clientRoute": "ruta norte",
  "containerType": "Contenedor 120 L",
  "assignedOperatorCode": 1,
  "notes": "",
  "status": "pendiente",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```
,
```json
{
  "clientEmail": "cliente.norte2@serrma.com",
  "clientName": "Cliente Norte 2",
  "clientRoute": "ruta norte",
  "assignedOperatorCode": 2,
  "notes": "",
  "status": "pendiente",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```
,

```json
{
  "clientEmail": "cliente.norte3@serrma.com",
  "clientName": "Cliente Norte 3",
  "clientRoute": "ruta norte",
  "assignedOperatorCode": 3,
  "notes": "",
  "status": "pendiente",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```
,

```json
{
  "clientEmail": "cliente.norte4@serrma.com",
  "clientName": "Cliente norte 4",
  "clientRoute": "ruta norte",
  "assignedOperatorCode": 4,
  "notes": "",
  "status": "pendiente",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```
,

```json
{
  "clientEmail": "cliente.norte5@serrma.com",
  "clientName": "Cliente Norte 5",
  "clientRoute": "ruta norte",
  "assignedOperatorCode": 5,
  "notes": "",
  "status": "pendiente",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```
,
Estados recomendados para `status`:

- `pendiente`
- `asignada`
- `recogida`
- `cancelada`

### `clientes`

Coleccion recomendada para la siguiente fase, cuando se sustituya la contrasena
fija por autenticacion real.

```json
{
  "cif": "A12345678",
  "nombre": "Bar Ejemplo",
  "direccion": "Calle Ejemplo 1",
  "telefono": "600000000",
  "email": "cliente@example.com",
  "ruta": "ruta norte",
  "personaContacto": "Responsable del local",
  "tipoNegocio": "Restaurante",
  "horarioRecogida": "Lunes de 9:00 a 11:00",
  "tipoContenedor": "Contenedor 120 L",
  "litrosEstimados": 75,
  "observaciones": "Ficha pendiente de validacion en proxima visita.",
  "activo": true,
  "createdAt": "serverTimestamp"
}
```

### `operarios`

```json
{
  "codigo": 1,
  "nombre": "Operario 1",
  "rol": "operario",
  "ruta": "ruta norte",
  "activo": true,
  "createdAt": "serverTimestamp"
}
```

Asignacion por ruta:

- Operario 1: `ruta norte`
- Operario 2: `ruta sur`
- Operario 3: `ruta oeste`
- Operario 4: `ruta este`
- Operario 5: `ruta centro`
- Encargado: codigo `6`, ve todas las solicitudes

Correos de clientes de la ruta norte asignados al operario 1:

- `cliente.norte1@serrma.com`
- `cliente.norte2@serrma.com`
- `cliente.norte3@serrma.com`
- `cliente.norte4@serrma.com`
- `cliente.norte5@serrma.com`

## Reglas temporales de desarrollo

Estas reglas sirven solo para probar la app durante el desarrollo. Antes de
entregar el proyecto conviene usar Firebase Auth y reglas por usuario.
Para que el boton de eliminar del encargado funcione, estas reglas deben estar
publicadas en Firebase Console.

```js
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /recogidas/{document} {
      allow read, create: if true;
      allow delete: if true;
      allow update: if false;
    }

    match /clientes/{document} {
      allow read, write: if true;
    }

    match /operarios/{document} {
      allow read, write: if true;
    }
  }
}
```
