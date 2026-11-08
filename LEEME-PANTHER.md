# Panther IOS — código para GitHub

Personalización visual de 3105 a petición de Joel. Conserva el motor original y sus créditos/licencia. No es una IPA compilada ni firmada.

## Subir y compilar
1. Descomprime este ZIP.
2. Crea un repositorio en GitHub. Sube **el contenido** de la carpeta descomprimida a la raíz, incluida **.github/workflows/build-ipa.yml**. No subas el ZIP como un solo archivo ni dejes todo dentro de otra carpeta.
3. En GitHub entra en **Actions → Build IPA → Run workflow**. Si GitHub solicita habilitar Actions, acéptalo. La compilación usa un equipo macOS de GitHub; las cuotas/costos dependen de tu cuenta.
4. Al terminar correctamente, abre esa ejecución y descarga **Panther-IOS-unsigned** en **Artifacts**. Descomprime la descarga para obtener **Panther-IOS-unsigned.ipa**.
5. Firma con un certificado empresarial válido usando una herramienta compatible. No cambies `com.apple.mobile.MobileHouseArrest`. El autor no garantiza GBox; la instalación y las funciones dependen del certificado y de la versión exacta de iOS.

## Botones y parches
- La pantalla principal se llama **Panther IOS**. El botón `…` abre todas las herramientas originales.
- **HEAD**, **NECK**, **CHEST**, **WEAPON1** y **WEAPON2** abren la biblioteca filtrada. Importa o crea proyectos con esos nombres o prefijos, por ejemplo `HEAD`, `[HEAD] Personal`, `CHEST custom` o `[WEAPON1] Personal`.
- El botón rojo abre la categoría seleccionada o toda la biblioteca. Selecciona un proyecto y confirma **Apply**. La restauración sigue disponible en ese proyecto cuando hay respaldo.
- Los paquetes con contraseña siguen disponibles para desbloquear; después se filtran por su nombre real.
- Importa un paquete `.3105` válido desde Archivos mediante **IMPORTAR / GESTIONAR → +**. Los proyectos modernos generan su carpeta **Patches** dentro de la carpeta de documentos de la app (puede mostrarse como Panther IOS en Archivos). Puedes editar ahí sus archivos; Apply sincroniza esa carpeta antes de aplicar.
- Una carpeta suelta llamada HEAD no es por sí sola un proyecto: primero importa o crea el proyecto con el gestor original para que tenga su manifiesto y paquete válido.
- No se incluyen archivos de parche, detección automática de juegos, aimbot ni estadísticas inventadas. Los nombres e imágenes son accesos visuales; el efecto real depende exclusivamente de tus parches.
- Se conserva la bienvenida inicial y la comprobación de compatibilidad original. Tras la bienvenida se abre Panther IOS.

## Verificación y límites
Se revisaron estructura del ZIP, recursos, esquema compartido y conservación de los archivos originales del motor. Se incluyen comprobaciones de categorías para ejecutarse en GitHub antes de compilar.
No se dispone de macOS, Xcode, simulador ni iPhone en este entorno: la compilación SwiftUI, el resultado visual nativo y la aplicación/restauración en un dispositivo **no están verificados**. El workflow debe terminar correctamente antes de considerar generada la IPA. No se ejecutó ninguna acción en tu cuenta de GitHub.

Las imágenes fueron recortadas de tu referencia; no son ilustraciones originales separadas y pueden conservar elementos superpuestos. La vista es una adaptación, no una réplica exacta. La gráfica ficticia se sustituyó por conteos reales de paquetes y carpetas. Conserva copias de seguridad y usa solo datos/dispositivos autorizados.

Consulta README.md, LICENSE y THIRD_PARTY_NOTICES.md para las condiciones originales.
