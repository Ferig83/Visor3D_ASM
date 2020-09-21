# VISOR 3D en Netwide Assembler (NASM) - WINDOWS x64

En desarrollo. Solo utilizo GDI / WinAPI (lo más bajo nivel que puedo llegar con Windows sin perder compatibilidad entre versiones/actualizaciones, porque recordemos que los syscalls cambian de número entre las mismas). No se usa OpenGL, ni DirectX/3D/Draw/2D, pero en un futuro quisiera usar DirectX.

## Estado del proyecto: 

El movimiento de cámara está hecho pero de una forma media vaga (tengo que averiguar cómo hacer para que me lea el teclado sin el delay). También falta arreglar algunas cosas relativas al color. En fin, hay mucho por hacer!  Ahora tengo que implementar en assembler los arrays dinámicos (para algo que se llama "clipping"), y algunas cosas me van a llevar cierto tiempo. Todavía debo un buen pulido de código, aunque hice bastante.


### Instrucciones de uso: Abrir la terminal (command prompt) y ejecutar el main.exe poniendo de argumento el nombre del objeto ".3d".  

Se puede armar un objeto en blender, exportarlo a .OBJ y usar el conversor que está en la carpeta "conversor" para pasarlo a mi formato ".3d" (tipo "conversor casita.obj"). Una vez convertido iniciar con "main objeto.3d".

Importante! las figuras deben ser __convexas__ ! todavía no está implementado lo de pintar los triángulos en orden de profundidad, por lo que si la figura no es convexa puede aparecer un triángulo pintado por delante cuando debería estar por detrás. Todas las figuras tienen que estar con triángulos.





