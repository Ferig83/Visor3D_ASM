# VISOR 3D en Netwide Assembler (NASM) - WINDOWS x64

En desarrollo. Solo utilizo GDI / WinAPI (lo más bajo nivel que puedo llegar con Windows sin perder compatibilidad entre versiones/actualizaciones, porque recordemos que los syscalls cambian de número entre las mismas). No se usa OpenGL, ni DirectX/3D/Draw/2D, pero en un futuro quisiera usar DirectX.

## Estado del proyecto: 

Implementado el Depth Buffer ! Ya se pueden ver correctamente las figuras que no son convexas. Aun queda arreglar el clipping (si las figuras salen de la pantalla el programa se va a colgar), pero estoy muy contento con el progreso.


![alt text](https://github.com/Ferig83/Visor3D_ASM/blob/master/sinister.png)


(las figuras están animadas en el ejecutable. Con rotación. Así bien chulas)

El movimiento de cámara está hecho pero de una forma media vaga (tengo que averiguar cómo hacer para que me lea el teclado sin el delay). Los controles son W,S,A,D (adelante, atrás, izquierda y derecha respectivamente).

Como ya no se usa la linea de comandos, elimino las instrucciones de uso. Recordar igual que se puede armar un objeto en blender, exportarlo a .OBJ y usar el conversor que está en la carpeta "conversor" para pasarlo a mi formato ".3d" (tipo "conversor casita.obj"). Una vez convertido se debe cargar en el main y en la lista de actualizaciones en "Actualizar_Todo". __Todas las figuras tienen que estar con triángulos, sin rectángulos.__








