# Instalar Plustag Monitor AI en tu Mac

## 1. Revisa tu Mac

En el menú Apple → **Acerca de esta Mac**, comprueba que indique un chip de la serie **M** y macOS **13 o posterior**. Esta descarga no funciona en Mac Intel. La primera versión se probó en macOS 27.0.1; si usas otra versión, avisa al responsable del proyecto si encuentras un problema.

## 2. Descarga la aplicación

1. Abre [la última versión en GitHub](https://github.com/lopezlab13/plustag-monitor-ai/releases/latest).
2. En **Assets**, descarga **Plustag-Monitor-AI-0.1.0-macOS-arm64.zip**. No elijas «Source code» si solo quieres usar la app.
3. Haz doble clic en el ZIP para descomprimirlo.
4. Arrastra **Plustag Monitor AI.app** a tu carpeta **Aplicaciones**. Hazlo antes de configurar sus permisos y evita moverla después.

No necesitas Xcode ni Terminal para instalar la descarga. Si prefieres compilarla, el README del proyecto explica esa alternativa.

## 3. Ábrela por primera vez

Abre la aplicación desde Aplicaciones. Verás el monitor y un gráfico en la barra de menú.

Esta primera versión usa firma local y **no está notarizada por Apple**. Si macOS indica que no puede verificar al desarrollador y tú confías en esta descarga del repositorio del equipo:

1. Intenta abrir la app una vez.
2. Ve a **Configuración del Sistema → Privacidad y seguridad**.
3. Revisa el aviso de **Plustag Monitor AI** y, si decides autorizar esa aplicación, pulsa **Abrir de todos modos**. Confirma personalmente con Touch ID o tu contraseña si macOS lo pide.

No desactives Gatekeeper ni elimines atributos de seguridad con comandos. Si el Mac informa que la app está dañada, contiene malware o tu empresa impide abrirla, detente y contacta al responsable del proyecto o de TI.

[Instrucciones oficiales de Apple sobre apertura segura](https://support.apple.com/en-gb/102445).

## 4. Conecta OpenAI

1. Ten instalada la aplicación de escritorio de ChatGPT/Codex o una instalación compatible del CLI de Codex.
2. Inicia sesión con **tu propia cuenta**. El acceso de tu plan determina qué límites están disponibles.
3. En Plustag, elige **OpenAI** y pulsa **Actualizar**.

La app busca las ubicaciones habituales de Codex en Aplicaciones y en la instalación local del usuario. Si dice que no encuentra Codex, pide ayuda al responsable del proyecto indicando cómo lo instalaste. Si encuentra Codex pero la sesión no está disponible para su servidor local, completa el inicio de sesión desde esa instalación de Codex. No pegues tokens ni contraseñas en el monitor, en GitHub ni en un chat.

Los valores mostrados son compartidos por **Codex y ChatGPT Work**. Los chats habituales de ChatGPT no tienen una cuota conectada en esta versión.

## 5. Conecta Claude

1. Abre Claude de escritorio e inicia sesión con **tu cuenta**.
2. En Plustag, elige **Claude → Conectar Claude**.
3. Lee el aviso. Para continuar, autoriza **Plustag Monitor AI** en **Configuración del Sistema → Privacidad y seguridad → Accesibilidad**. En algunas versiones de macOS aparece como **Control de dispositivos y acceso a los datos**.
4. Si no figura en la lista, usa **+** y selecciona la copia que guardaste en Aplicaciones. Confirma personalmente con Touch ID si se solicita.
5. En Claude, abre tu perfil → **Usage** (Uso).
6. Regresa al monitor y pulsa **Leer Usage**. Si sigue indicando que falta permiso, cierra y vuelve a abrir Plustag.

Accesibilidad es un permiso amplio del sistema. Esta integración lo usa para leer el panel Usage de Claude; puedes desconectarla desde Plustag y revocar el permiso desde Configuración del Sistema.

**Importante:** Claude se actualiza solo mientras su pantalla Usage esté abierta y expuesta por Accesibilidad. Si vuelves a un chat, la app conserva la última lectura. La cuota disponible de la sesión y la semana se muestra aparte del reparto del uso entre productos.

## 6. Déjala a mano

- Elige **Vista compacta** si quieres ocupar menos espacio.
- Arrastra el ícono desde Aplicaciones al **Dock** para dejar un acceso fijo.
- Usa el gráfico de la barra de menú para mostrarla cuando cierres su ventana.

No se configura inicio automático con el Mac en esta versión.

## Actualizar o desinstalar

Para actualizar, sal del monitor desde su menú, descarga la nueva versión y reemplaza la app en Aplicaciones. macOS puede pedir que renueves Accesibilidad porque esta versión utiliza firma local. Si el permiso figura activo pero no funciona, quita únicamente Plustag de la lista, vuelve a agregar la copia actual y reinicia el monitor.

Para desinstalar, sal de la app, elimina su permiso de Accesibilidad y mueve la aplicación a la Papelera. Las preferencias locales de tamaño y proveedor pueden permanecer en macOS; no contienen credenciales.

## Si algo no funciona

- **No aparece la ventana:** usa el gráfico de la barra de menú → Mostrar monitor.
- **Claude indica «Sin lectura»:** abre Usage, revisa Accesibilidad y pulsa Leer Usage. Un dato ausente no se interpreta como cero.
- **Los porcentajes no cambian:** revisa la hora de lectura. OpenAI se consulta cada 5 minutos; Claude se lee cada 30 segundos, pero su propia página puede llevar otra frecuencia.
- **Faltan productos o etiquetas:** la interfaz de Claude puede cambiar. Informa al responsable del proyecto; no se calculan porcentajes a partir de valores de otras secciones.

Al reportar un problema, comparte la versión de macOS, el chip de tu Mac y el mensaje del monitor. No publiques sesiones, contraseñas, tokens ni capturas con datos privados.
