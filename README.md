# VISOR 3D en Netwide Assembler (NASM) - WINDOWS x64

En desarrollo. Solo utilizo GDI / WinAPI (lo más bajo nivel que puedo llegar con Windows sin perder compatibilidad entre versiones/actualizaciones, porque recordemos que los syscalls cambian de número entre las mismas). No se usa OpenGL, ni DirectX/3D/Draw/2D, pero en un futuro quisiera usar DirectX.

## Estado del proyecto: 

Implementado el clipping! ya se puede pasear tranquilamente por el mundo virtual sin cuelgues... al menos eso espero. Faltan varias cosas: tengo un problema aparentemente con el depth buffering, en el que estoy sufriendo la perdida de resolución a distancias más lejanas. Tengo una vaga idea de cómo solucionarlo pero aun así me va a llevar algo de tiempo. Esto afecta que algunas cosas se muestren por delante de otras, aunque claramente se vea que están por detrás! 

Agregué el rotar la cámara con Q y E, pero el input está muy mal implementado y W,S,A,D solo recorren los ejes fijos del mundo. Eso es algo de lo que me debo ocupar. Además, el input sigue siendo malo, con delay en las teclas. 

Quisiera también cargar los "mapas" (objetos y sus ubicaciones) desde archivo, y uno por uno dentro del código. 

En fin, quedan muchas cosas por hacer!


![alt text](https://github.com/Ferig83/Visor3D_ASM/blob/master/sinister.png)


(las figuras están animadas en el ejecutable. Con rotación. Así bien chulas)

Como ya no se usa la linea de comandos, elimino las instrucciones de uso. Recordar igual que se puede armar un objeto en blender, exportarlo a .OBJ y usar el conversor que está en la carpeta "conversor" para pasarlo a mi formato ".3d" (tipo "conversor casita.obj"). Una vez convertido se debe cargar en el main y en la lista de actualizaciones en "Actualizar_Todo". __Todas las figuras tienen que estar con triángulos, sin rectángulos.__








