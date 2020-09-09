# VISOR 3D en Netwide Assembler (NASM) - WINDOWS x64

En desarrollo. Solo utilizo GDI / WinAPI (lo más bajo nivel que puedo llegar con Windows sin perder compatibilidad entre versiones/actualizaciones, porque recordemos que los syscalls cambian de número entre las mismas para jodernos la vida). No se usa OpenGL, ni DirectX/3D/Draw/2D.

## Estado del proyecto: 

Antes de continuar con el movimiento de cámara y rasterización por orden de profundidad, sería bueno una linda optimización (se puede y se debe), y limpieza de código (mucho parche). De momento dejenme disfrutarlo, por el amor de Cristo.

### Instrucciones de uso: Abrir la terminal (command prompt) y ejecutar el main.exe poniendo de argumento el nombre del objeto ".3d".  

Se puede armar un objeto en blender, exportarlo a .OBJ y usar el conversor que está en la carpeta "conversor" para pasarlo a mi formato ".3d" (tipo "conversor casita.obj"). La idea más adelante es poder recorrerlo, crear colisiones, etc.

Importante! las figuras deben ser __convexas__ ! todavía no está implementado lo de pintar los triángulos en orden de profundidad, por lo que si la figura no es convexa puede aparecer un triángulo pintado por delante cuando debería estar por detrás. 
