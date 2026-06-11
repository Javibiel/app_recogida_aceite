# SERRMA - App de recogida de aceite

Aplicacion Flutter desarrollada como version beta para gestionar solicitudes de
recogida de residuos de aceite.

## Roles

- Cliente: accede con su email y contrasena, solicita una recogida e indica los
  datos de bidones, filtros y jabon.
- Operario: consulta las recogidas de su ruta y marca como recogidas las
  solicitudes pendientes.
- Encargado: consulta todas las rutas, crea nuevos clientes, revisa el historico
  de recogidas y puede eliminar solicitudes de prueba.

## Flujo principal

1. El cliente solicita una recogida.
2. La solicitud queda en estado `Pendiente`.
3. El operario de la ruta ve la solicitud en rojo.
4. El operario confirma la recogida realizada.
5. La solicitud pasa a `Recogido`, se guarda la fecha de recogida y se muestra
   en verde.

## Funciones de la beta

- Login diferenciado para cliente, operario y encargado.
- Alta de clientes desde la consola del encargado.
- Resumen de recogidas pendientes, recogidas y totales.
- Filtros por estado: todas, pendientes y recogidas.
- Historico visual separado por pendientes y recogidas.
- Trazabilidad basica con fecha de solicitud y fecha de recogida.
- Reglas temporales de Firestore para facilitar la demostracion.

## Limitaciones beta

Esta version no esta preparada para produccion. Las principales limitaciones son:

- No usa Firebase Auth real por usuario.
- Las reglas de Firestore son abiertas para facilitar pruebas.
- Las contrasenas son simples y estan pensadas solo para la demo.
- No incluye auditoria avanzada ni gestion de permisos por documento.
- No hay notificaciones push ni modo offline completo.

## Mejoras futuras

- Autenticacion real con Firebase Auth.
- Reglas de seguridad por rol y usuario.
- Notificaciones al operario cuando entra una nueva solicitud.
- Panel de informes por fechas, rutas y volumen recogido.
- Exportacion de historicos para administracion.
