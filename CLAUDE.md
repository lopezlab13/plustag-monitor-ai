# Claude, Codex, Work y ChatGPT en el flotante

## Qué muestra

- **OpenAI:** límites de Codex y ChatGPT Work, que comparten cuota. La fuente oficial `account/rateLimits/read` no devuelve un reparto de consumo entre ambos. Los chats habituales de ChatGPT figuran sin cuota conectada; no se usan los límites de Codex como sustituto.
- **Claude:** cuota disponible de la sesión y de la semana, textos de renovación y reparto semanal por Claude Code, Chats, Cowork y Other, cuando están presentes en la pantalla oficial de Uso.
- El reparto semanal es **participación en el uso**, no porcentaje de cuota disponible. Un valor ausente nunca se convierte en cero.

## Conectar Claude de escritorio

1. En el flotante, elige **Claude**. En la ventana completa también está la tarjeta Claude.
2. Pulsa **Conectar Claude** y lee el aviso sobre Accesibilidad.
3. Si decides autorizarlo, macOS te pedirá habilitar **Plustag Monitor AI** en Configuración del Sistema → Privacidad y seguridad → Accesibilidad. Puedes necesitar agregar la aplicación de la carpeta `dist` con el botón +. La autorización se aplica a esa aplicación; autorizar Terminal o ChatGPT no sustituye este paso.
4. En Claude, pulsa tu perfil y elige **Usage** (Uso). Deja esa pantalla abierta y pulsa **Leer Usage** en el monitor. También se intenta leer cada 30 segundos si la conexión está habilitada.
5. Si macOS solicita reiniciar el monitor tras dar el permiso, hazlo. Algunas compilaciones con firma local pueden requerir volver a autorizar la app tras actualizarla.

La integración no realiza prompts ni solicita API keys, tokens o cookies. No instala Claude Code. Se limita al proceso oficial `com.anthropic.claudefordesktop` y busca el panel Settings antes de leer sus indicadores y textos de uso. No abre conversaciones ni escribe en Claude.

**Limitación:** necesita que la pantalla Usage esté abierta y expuesta por la accesibilidad de Claude. Si pasas a un chat o Claude se cierra, se conserva la última lectura y aparece una advertencia. El monitor no refresca la página de Claude: muestra también la antigüedad que indique esa página, cuando esté disponible. El horario «Leído» indica cuándo se leyó la pantalla, no cuándo Anthropic actualizó sus estadísticas.

El permiso de Accesibilidad de macOS es amplio técnicamente; el código de esta app lo usa solo para esa lectura. **Desconectar** detiene las lecturas y borra la copia en memoria. Para revocar el permiso del sistema, desactiva la app en Accesibilidad. Los datos de Claude no se guardan en disco.

## Uso del flotante

El tamaño no cambia. El selector **OpenAI / Claude** cambia el contenido; puedes desplazarte dentro de la vista compacta para ver el reparto completo. **Ampliar** muestra todas las tarjetas en la ventana original.

## Validación y fuentes

Se verificaron las reglas del lector con pruebas locales: cuota frente a reparto, cero real, porcentajes inválidos, textos de renovación y rechazo de pantallas de chat. El usuario habilitó el permiso de macOS y se verificó la lectura real en el monitor el 27 de octubre de 2026: cuota de sesión, cuota semanal y cuatro categorías del reparto. La lectura con herramientas de asistencia durante el desarrollo no sustituye ese permiso.

La lectura depende de la interfaz de Claude y puede necesitar ajustes si sus etiquetas cambian. Solo se reconocen etiquetas verificadas en inglés y sus equivalentes básicos en español. Nunca se estiman valores si no se reconocen. Cuando faltan los valores de accesibilidad de las barras, se lee el texto explícito «N% used» dentro de la sección de sesión o semana correspondiente. Las filas permanecen visibles con «Sin lectura» si ambos métodos fallan.

Fuentes: [Pricing de OpenAI: Work y Codex comparten uso](https://learn.chatgpt.com/docs/pricing), [Codex app-server](https://learn.chatgpt.com/docs/app-server), pantalla **Claude → Settings → Usage** observada en este Mac. [Límites compartidos de Claude y Claude Code para Pro/Max](https://support.claude.com/en/articles/11145838-use-claude-code-with-your-pro-or-max-plan).
