# SERRMA - Aplicacion de gestion de recogida de aceite

## 1. Introduccion

Este documento resume los puntos principales de la aplicacion desarrollada para el TFG: una solucion multiplataforma para gestionar solicitudes de recogida de residuos de aceite entre clientes, operarios y encargado.

La aplicacion nace de una necesidad concreta: digitalizar un proceso que habitualmente puede depender de llamadas, mensajes o registros manuales. Con SERRMA, el cliente puede solicitar una recogida desde la app y el operario puede consultar en tiempo real las solicitudes asignadas a su ruta, marcarlas como recogidas y mantener una trazabilidad basica del servicio.

## 2. Problema que resuelve

En una empresa de recogida de residuos, la coordinacion entre clientes y trabajadores puede generar retrasos, duplicidades o falta de informacion actualizada. El sistema desarrollado intenta reducir estos problemas mediante:

- Registro centralizado de clientes.
- Solicitud digital de recogidas.
- Asignacion automatica de solicitudes por ruta.
- Consulta en tiempo real para operarios.
- Diferenciacion visual entre recogidas pendientes y realizadas.
- Papel especial de encargado para consultar todas las rutas y gestionar clientes.

## 3. Objetivos del proyecto

Los objetivos principales del TFG son:

- Crear una aplicacion funcional para una situacion real de gestion de residuos.
- Separar claramente los perfiles de usuario: cliente, operario y encargado.
- Utilizar una arquitectura sencilla, mantenible y adecuada para una version beta.
- Aprovechar tecnologias modernas que permitan evolucionar el proyecto en el futuro.
- Desarrollar una base preparada para incorporar autenticacion real, permisos avanzados, notificaciones y estadisticas.

## 4. Tecnologias utilizadas

### Flutter

Flutter se ha elegido como framework principal porque permite desarrollar una misma aplicacion para varias plataformas desde una unica base de codigo. Esto es importante en un TFG de este tipo porque una empresa puede necesitar usar la app en movil, tablet o navegador sin rehacer el proyecto para cada entorno.

Ventajas principales de Flutter en este proyecto:

- Desarrollo multiplataforma con un unico codigo Dart.
- Interfaz consistente en diferentes dispositivos.
- Buena productividad gracias al sistema de widgets.
- Integracion sencilla con Firebase.
- Posibilidad de evolucionar la beta hacia Android, iOS o web.
- Buen rendimiento para interfaces con formularios, listas y estados en tiempo real.

### Firebase y Cloud Firestore

Firebase se ha utilizado como backend gestionado. En lugar de crear un servidor propio, la aplicacion se conecta a Cloud Firestore para guardar clientes, operarios y solicitudes de recogida.

Ventajas principales de Firebase en este proyecto:

- Base de datos en la nube sin necesidad de administrar un servidor.
- Sincronizacion en tiempo real mediante streams.
- Escalabilidad suficiente para una aplicacion de gestion de servicios.
- Integracion directa con Flutter.
- Posibilidad de anadir Firebase Authentication, reglas de seguridad, Cloud Functions o notificaciones push en futuras versiones.

## 5. Arquitectura general

La aplicacion esta organizada por capas sencillas:

- `main.dart`: inicializa Flutter, Firebase y carga datos iniciales.
- `app.dart`: configura `MaterialApp`, tema y rutas.
- `presentation/screens`: contiene las pantallas de login, cliente y operario.
- `presentation/routes`: centraliza las rutas de navegacion.
- `models`: define las entidades principales del dominio.
- `services/firestore_database.dart`: agrupa las operaciones contra Firestore.

Esta separacion facilita explicar el proyecto durante la defensa porque cada carpeta tiene una responsabilidad clara: pantallas, modelos, rutas y acceso a datos.

## 6. Modelo de datos

El sistema trabaja principalmente con tres tipos de informacion:

### Clientes

Cada cliente contiene datos como CIF, nombre, email, telefono, direccion, ruta, persona de contacto, tipo de negocio, horario de recogida, tipo de contenedor, observaciones y estado activo.

### Solicitudes de recogida

Cada solicitud guarda el email del cliente, nombre, direccion, telefono, ruta, tipo de contenedor, numero de bidones, capacidad, numero de filtros, necesidad de jabon, operario asignado, estado, fecha de creacion y fecha de recogida.

### Operarios y rutas

La app diferencia cinco operarios de ruta y un encargado:

- Operario 1: ruta norte.
- Operario 2: ruta sur.
- Operario 3: ruta oeste.
- Operario 4: ruta este.
- Operario 5: ruta centro.
- Encargado: acceso global a todas las rutas.

## 7. Funcionalidades implementadas

### Acceso diferenciado

La pantalla inicial permite elegir entre acceso de cliente y acceso de operario. El cliente accede con email y contrasena, mientras que el operario accede con codigo y contrasena.

### Cliente

El cliente puede:

- Iniciar sesion.
- Solicitar una recogida.
- Indicar numero de bidones.
- Seleccionar capacidad de bidon, 25 L o 50 L.
- Indicar numero de filtros.
- Solicitar jabon si lo necesita.

Cuando confirma la solicitud, se guarda en Firestore con estado pendiente.

### Operario

El operario puede:

- Ver solo las solicitudes de su ruta.
- Consultar solicitudes en tiempo real.
- Ver datos completos del cliente y de la recogida.
- Filtrar por todas, pendientes o recogidas.
- Marcar una solicitud como recogida.
- Consultar el historico visual de recogidas realizadas.

### Encargado

El encargado tiene permisos funcionales ampliados dentro de la beta:

- Ver solicitudes de todas las rutas.
- Consultar todos los clientes.
- Crear nuevos clientes.
- Eliminar solicitudes de prueba.
- Supervisar el estado general mediante contadores.

## 8. Flujo principal de uso

1. El cliente inicia sesion.
2. El cliente solicita una recogida e introduce los datos necesarios.
3. La solicitud se guarda en Firestore con estado `pendiente`.
4. El operario asignado a la ruta recibe la informacion al consultar la app.
5. La solicitud aparece destacada visualmente como pendiente.
6. El operario realiza la recogida y la marca como completada.
7. El estado cambia a `Recogido` y se registra la fecha de recogida.
8. El encargado puede consultar el historico y el estado global.

## 9. Justificacion tecnica

La combinacion de Flutter y Firebase es adecuada para este TFG porque resuelve dos necesidades clave: crear una interfaz multiplataforma y disponer de una base de datos en tiempo real sin desarrollar un backend completo desde cero.

Flutter aporta rapidez de desarrollo, una experiencia visual uniforme y facilidad para crear formularios, listas, dialogos y navegacion. Firebase aporta persistencia, sincronizacion y una base preparada para crecer. En conjunto, permiten centrar el esfuerzo del proyecto en la logica del negocio: clientes, rutas, recogidas y estados.

Otra decision importante ha sido separar el acceso a datos en `FirestoreDatabase`. Esto evita que todas las pantallas conozcan directamente los detalles de Firestore y hace que el codigo sea mas mantenible.

## 10. Aspectos destacables para la exposicion

- La app esta conectada a una base de datos real en la nube.
- Las solicitudes se actualizan en tiempo real mediante streams.
- Existe asignacion automatica de rutas a operarios.
- Se diferencia el rol de cliente, operario y encargado.
- La interfaz muestra estados visuales: pendiente en rojo y recogido en verde.
- Se registra trazabilidad basica: fecha de solicitud y fecha de recogida.
- La estructura del codigo esta separada en modelos, servicios y pantallas.
- El proyecto esta planteado como beta funcional, con margen claro de evolucion.

## 11. Limitaciones de la version beta

Como version de TFG y demostracion, la aplicacion todavia no esta preparada para produccion. Sus principales limitaciones son:

- No usa Firebase Authentication real por usuario.
- Las contrasenas son simples y estan pensadas para la demo.
- Las reglas de Firestore son temporales y deben endurecerse.
- No existe gestion avanzada de permisos por documento.
- No hay notificaciones push.
- No incluye panel de estadisticas ni exportacion de informes.

Reconocer estas limitaciones durante la exposicion es positivo, porque demuestra criterio tecnico y capacidad de analizar la evolucion del proyecto.

## 12. Mejoras futuras

Las mejoras mas importantes para convertir la beta en una aplicacion de produccion serian:

- Incorporar Firebase Authentication.
- Definir reglas de seguridad por rol y usuario.
- Crear notificaciones push para avisar a los operarios.
- Anadir modo offline para zonas con mala cobertura.
- Implementar estadisticas por ruta, fecha y litros recogidos.
- Exportar historicos en PDF o Excel.
- Crear un panel web de administracion para el encargado.
- Mejorar la gestion de incidencias en recogidas no realizadas.

## 13. Conclusion

SERRMA demuestra como una aplicacion multiplataforma puede mejorar un proceso real de gestion de residuos. El proyecto digitaliza la comunicacion entre cliente, operario y encargado, centraliza la informacion en la nube y ofrece una base funcional sobre la que seguir creciendo.

La eleccion de Flutter y Firebase permite presentar una solucion moderna, escalable y realista para una empresa que necesita movilidad, rapidez de desarrollo y datos actualizados en tiempo real.

