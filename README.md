# VISOR 3D en Netwide Assembler (NASM) - WINDOWS x64

En desarrollo. Solo utilizo GDI / WinAPI (lo más bajo nivel que puedo llegar con Windows sin perder compatibilidad entre versiones/actualizaciones, porque recordemos que los syscalls cambian de número entre las mismas). No se usa OpenGL, ni DirectX/3D/Draw/2D, pero en un futuro quisiera usar DirectX.

## Estado del proyecto: 

Desde la última actualización se pulió un poco más el código. Ya no cargo los objetos 3D desde la línea de comandos (duele remover código), sino que en cambio puedo
crear más de un objeto y colocarlos a gusto! Para esto implementé una suerte de array dinámico el cual me va a servir mucho para el clipping (el cual todavía no está implementado). 




El movimiento de cámara está hecho pero de una forma media vaga (tengo que averiguar cómo hacer para que me lea el teclado sin el delay). Los controles son W,S,A,D (adelante, atrás, izquierda y derecha respectivamente).

Como ya no se usa la linea de comandos, elimino las instrucciones de uso. Recordar igual que se puede armar un objeto en blender, exportarlo a .OBJ y usar el conversor que está en la carpeta "conversor" para pasarlo a mi formato ".3d" (tipo "conversor casita.obj"). Una vez convertido se debe cargar en el main y en la lista de actualizaciones en "Actualizar_Todo".

Importante! las figuras deben ser __convexas__ ! todavía no está implementado lo de pintar los triángulos en orden de profundidad, por lo que si la figura no es convexa puede aparecer un triángulo pintado por delante cuando debería estar por detrás. __Todas las figuras tienen que estar con triángulos, sin rectángulos.__








