# Las dos vistas de Plustag Monitor AI

## Vista compacta flotante — disponible ahora

Abre la aplicación en `dist/Plustag Monitor AI.app`.

- En la ventana principal, pulsa **Vista compacta**.
- También puedes elegir **Mostrar vista compacta** desde el gráfico de la barra de menú.
- Pulsa **Ampliar** para regresar al monitor con su tamaño original.
- La aplicación recuerda qué modo elegiste. Puedes mover cualquiera de las ventanas por su barra superior.

Ambas vistas comparten una sola consulta de Codex cada cinco minutos. La vista compacta muestra las dos ventanas del grupo Codex; si hay otros grupos, indica cuántos quedan en el monitor completo. Los datos de más de 15 minutos, o de una lectura fallida, se marcan como anteriores.

## Widget nativo del escritorio — preparado, pendiente de instalar con Xcode

El widget tiene tamaños pequeño y mediano. Usa el mismo diseño y los mismos porcentajes que la vista compacta. No lanza Codex ni accede a credenciales: lee un archivo que actualiza la aplicación principal.

La vista compacta y el regreso con «Ampliar» se verificaron en pantalla con datos reales.

Este Mac tiene Command Line Tools, pero no Xcode completo. Se verificaron los tipos del código del widget contra el SDK de macOS y la estructura del proyecto; aún no se ha compilado, firmado ni probado la extensión en la galería de widgets. La aplicación creada con `scripts/build.sh` incluye únicamente las ventanas flotantes.

### Activarlo cuando tengas Xcode

1. Instala **Xcode** desde el App Store y ábrelo para terminar de instalar sus componentes.
2. Abre **PlustagMonitor.xcodeproj** de esta carpeta.
3. En el proyecto, revisa **Signing & Capabilities** de los dos destinos: **Plustag Monitor AI** y **PlustagWidget**. Elige el mismo equipo de Apple en ambos. No compartas tu contraseña ni claves en este chat.
4. Verifica que ambos destinos tengan el mismo App Group: `TU_TEAM_ID.cl.plustag.monitorai`. El proyecto lo define con `$(DEVELOPMENT_TEAM).cl.plustag.monitorai`. Si Xcode solicita registrar el grupo o ajustar los identificadores, completa esa configuración desde tu cuenta de Apple en Xcode.
5. Selecciona el esquema **Plustag Monitor AI**, destino **My Mac**, y pulsa ▶. Esta compilación contiene la extensión y usa macOS 14 o posterior. Cierra antes la app independiente para evitar dos monitores ejecutándose.
6. Espera la primera lectura de Codex. Luego haz clic derecho en el escritorio → **Editar widgets**, busca **Plustag Monitor AI** y agrega el tamaño que prefieras.

Si el widget no aparece, todavía hay que verificar la firma y el registro de la extensión en ese Mac; no se ha validado ese paso en este entorno.

### Actualizaciones y privacidad

Mantén el monitor abierto en la barra de menú para consultar datos nuevos. La aplicación guarda únicamente porcentajes, duración, renovación y hora de lectura en el contenedor compartido del App Group. El widget no puede usar la caché de una compilación independiente sin ese grupo configurado.

La aplicación solicita a WidgetKit recargar al guardar una lectura. **macOS administra cuándo refresca el widget**; no hay una garantía de actualización exacta cada cinco minutos. Si la app se cierra, el widget conserva la última lectura y la marca como antigua después de 15 minutos. No simula porcentajes ni asume que una cuota se renovó sin una lectura nueva.

Al pulsar el widget se abre el monitor completo mediante `plustagmonitor://monitor`.

Documentación de Apple: [crear una extensión de widget](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension), [mantener un widget actualizado](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).
