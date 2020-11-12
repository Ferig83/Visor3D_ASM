
;--- ENCABEZADO -----------------------------------------------------

global Start

%include 'panelcontrol.asm'
%include 'encabezado.asm'
%include 'winproc.asm'
%include 'funciones.asm'
%include 'actualizar.asm'
%include 'pintar.asm'
%include 'matrices.asm'
%include 'arraydinamico.asm'
%include 'queuecircular.asm'

;--- DATA -----------------------------------------------------------

section .data progbits alloc noexec write align=16       

MitadAnchoPantalla dd FSP_MITAD_ANCHO_PANTALLA   ; 683 en float 32
MitadAltoPantalla  dd FSP_MITAD_ALTO_PANTALLA    ; 384 en float 32

rectangulo_pantalla dd 0,0,ANCHO_PANTALLA,ALTO_PANTALLA

BackgroundColour dd 0x00100000  ; Color de fondo, va en little endian (0xBBGGRR)
click_izquierdo  dd 0




;--- CADENAS GENERALES --

WindowName 	 db "Virtual Rigantity", 0                     ; Título de la ventana (nombre de la app)
ClassName        db "Ventana", 0	                       ; Nombre de la clase de la ventana (identificador choto)
ExitText         db "¿Está seguro de que quiere salir?", 0   ; Texto del mensaje de Salir 

;--- CADENAS DE RUTA DE ARCHIVOS --

ruta_cubo	db "persona.3d" ,0
ruta_cilindro   db "vaca.3d",0
ruta_casa	db "casa.3d",0

ruta_almohadas db "almohadas.3d",0
ruta_colchon db "colchon.3d",0
ruta_marcos db "marcos.3d",0
ruta_mesa db "mesa.3d",0
ruta_muebles db "muebles.3d",0
ruta_paredes db "paredes.3d",0
ruta_piso db "piso.3d",0
ruta_techo db "techo.3d",0

; -- CADENAS DE ERRORES --

error1 db 'Fallo en el CreateFile de origen',0
error2 db 'Fallo en el read file de origen',0
error3 db 'Fallo en el create file de destino',0
error4 db 'Fallo en el read file de destino',0
titulo_error db 'Error',0


; -- MOVIMIENTO  --

factor_conversion_tiempo dd 1.0		; La verdad si el factor es 1, la multiplicación es media al dope. Pero dejarlo por si
					; tengo que cambiarlo.

factor_movimiento_z dd 100.0 
factor_movimiento_x dd 100.0
factor_movimiento_y dd 100.0
factor_giro_camara dd 0.1
giro_camara dd 0.0

; -- CAMARA Y LUCES (respetar el alineamiento!)


 align 16  
 	vector_camara_arriba 		dd 0x00000000,0x3f800000,0x00000000,0x3f800000   ;   xyzw: 0,1,0,1
 	vector_camara_delante		dd 0x00000000,0x00000000,0x3f800000,0x3f800000 	 ;   xyzw: 0,0,1,1
 	vector_camara_posicion		dd 0x00000000,ALTURA_PERSONAJE,0x00000000,0x3f800000   ;   xyzw: 0,1750,0,1   (1 = 1mm)
 	vector_luz			dd 0x00000000,0x3f800000,0xbf800000,0x3f800000	 ;   xyzw: 0,1,-1,1
	
	; REGLA DE LA MANO DERECHA, OJO (se cumple la misma regla para la transformación de la figura??)


 align 16
 bitmapinfo TIMES BITMAPINFO_size db 0


configuracion_proyeccion istruc PROYECCION
	
	at PROYECCION__alto_pantalla, dd ALTO_PANTALLA
	at PROYECCION__ancho_pantalla, dd ANCHO_PANTALLA
	at PROYECCION__angulo_FOV, dd ANGULO_FOV
	at PROYECCION__z_far, dd ZFAR
	at PROYECCION__z_near, dd ZNEAR

iend


;--- CLIPPING --------------------------------------

align 16 ; REQUERIDO
plano_near istruc DATOS_PLANO

	at DATOS_PLANO__normal+VECTOR4__1, dd 0x00000000 ; 0
	at DATOS_PLANO__normal+VECTOR4__2, dd 0x00000000 ; 0 
	at DATOS_PLANO__normal+VECTOR4__3, dd 0x3f800000 ; 1
	at DATOS_PLANO__normal+VECTOR4__4, dd 0x00000000 ; 0

	at DATOS_PLANO__punto+VECTOR4__1, dd 0x00000000 ; 0
	at DATOS_PLANO__punto+VECTOR4__2, dd 0x00000000 ; 0
	at DATOS_PLANO__punto+VECTOR4__3, dd ZNEAR	
	at DATOS_PLANO__punto+VECTOR4__4, dd 0x3f800000	; 1 


iend

align 16 ; REQUERIDO
plano_far istruc DATOS_PLANO


	at DATOS_PLANO__normal+VECTOR4__1, dd 0x00000000 ; 0
	at DATOS_PLANO__normal+VECTOR4__2, dd 0x00000000 ; 0 
	at DATOS_PLANO__normal+VECTOR4__3, dd 0xbf800000 ; -1
	at DATOS_PLANO__normal+VECTOR4__4, dd 0x00000000 ; 0

	at DATOS_PLANO__punto+VECTOR4__1, dd 0x00000000 ; 0
	at DATOS_PLANO__punto+VECTOR4__2, dd 0x00000000 ; 0
	at DATOS_PLANO__punto+VECTOR4__3, dd ZFAR
	at DATOS_PLANO__punto+VECTOR4__4, dd 0x3f800000	; 1 


iend


align 16 ; REQUERIDO
plano_derecho istruc DATOS_PLANO

	at DATOS_PLANO__normal+VECTOR4__1, dd 0xbf800000 ; -1
	at DATOS_PLANO__normal+VECTOR4__2, dd 0x00000000 ; 0
	at DATOS_PLANO__normal+VECTOR4__3, dd 0x00000000 ; 0
	at DATOS_PLANO__normal+VECTOR4__4, dd 0x00000000 ; 0

	at DATOS_PLANO__punto+VECTOR4__1, dd 0x3f7d70a4 ; 0.99
	at DATOS_PLANO__punto+VECTOR4__2, dd 0x00000000	; 0
	at DATOS_PLANO__punto+VECTOR4__3, dd 0x00000000	; 0
	at DATOS_PLANO__punto+VECTOR4__4, dd 0x3f800000	; 1 

iend

align 16 ; REQUERIDO
plano_izquierdo istruc DATOS_PLANO

	at DATOS_PLANO__normal+VECTOR4__1, dd 0x3f800000 ; 1
	at DATOS_PLANO__normal+VECTOR4__2, dd 0x00000000 ; 0
	at DATOS_PLANO__normal+VECTOR4__3, dd 0x00000000 ; 0
	at DATOS_PLANO__normal+VECTOR4__4, dd 0x00000000 ; 0

	at DATOS_PLANO__punto+VECTOR4__1, dd 0xbf7d70a4 ;  -0.99
	at DATOS_PLANO__punto+VECTOR4__2, dd 0x00000000	; 
	at DATOS_PLANO__punto+VECTOR4__3, dd 0x00000000	;
	at DATOS_PLANO__punto+VECTOR4__4, dd 0x3f800000	; 1 


iend


align 16 ; REQUERIDO
plano_superior istruc DATOS_PLANO

	at DATOS_PLANO__normal+VECTOR4__1, dd 0x00000000 ; 0
	at DATOS_PLANO__normal+VECTOR4__2, dd 0x3f800000 ; 1 
	at DATOS_PLANO__normal+VECTOR4__3, dd 0x00000000 ; 0
	at DATOS_PLANO__normal+VECTOR4__4, dd 0x00000000 ; 0

	at DATOS_PLANO__punto+VECTOR4__1, dd 0x00000000 ; 0
	at DATOS_PLANO__punto+VECTOR4__2, dd 0xbf7d70a4 ;  -0.99	
	at DATOS_PLANO__punto+VECTOR4__3, dd 0x00000000	; 0
	at DATOS_PLANO__punto+VECTOR4__4, dd 0x3f800000	; 1 


iend

align 16 ; REQUERIDO
plano_inferior istruc DATOS_PLANO


	at DATOS_PLANO__normal+VECTOR4__1, dd 0x00000000 ; 0
	at DATOS_PLANO__normal+VECTOR4__2, dd 0xbf800000 ; -1 
	at DATOS_PLANO__normal+VECTOR4__3, dd 0x00000000 ; 0
	at DATOS_PLANO__normal+VECTOR4__4, dd 0x00000000 ; 0

	at DATOS_PLANO__punto+VECTOR4__1, dd 0x00000000 ; 0
	at DATOS_PLANO__punto+VECTOR4__2, dd 0x3f7d70a4 ; 0.99
	at DATOS_PLANO__punto+VECTOR4__3, dd 0x00000000	; 0
	at DATOS_PLANO__punto+VECTOR4__4, dd 0x3f800000	; 1 



iend



;--- BSS --------------------------------------------------------

section .bss nobits alloc noexec write align=16


 temporizador 			resb TIMER_size
 cubo 				resb OBJETO_3D_size
 cilindro 			resb OBJETO_3D_size
 casa	 			resb OBJETO_3D_size
 array_rasterizacion		resb ARRAY_DINAMICO_size

 almohadas 			resb OBJETO_3D_size
 colchon			resb OBJETO_3D_size
 marcos				resb OBJETO_3D_size
 mesa				resb OBJETO_3D_size
 muebles			resb OBJETO_3D_size
 paredes			resb OBJETO_3D_size
 piso				resb OBJETO_3D_size
 techo				resb OBJETO_3D_size



 prueba resq 1  ; para meter los valores de los debug que haga

 puntero_DIB		resq 1

 alignb 16
 zbuffer 		resd ANCHO_PANTALLA*ALTO_PANTALLA


;;;;Revisar de todos estos cual va y cual no

 hInstance        	resq 1    
 BackgroundBrush  	resq 1
 DC_pantalla	        resq 1
 hBitmap 		resq 1        
 bmpDC 			resq 1

 hdcBuffer		resq 1
 hbmBuffer		resq 1
 hbmOldBuffer		resq 1
 hdcMem			resq 1
 hbitmap_pantalla	resq 1
 hbmOld			resq 1

;;;;; ver si van los de arriba o los de abajo
 hdc_ventana resq 1
 hdc_bitmap resq 1
 hdc_pantalla resq 1
 hMemBmp resq 1
 hOld resq 1
;;;;;;;;;; fin revisar de todos estos...



 ; Hasta que no encuentre otro método necesitaré que las siguientes tres sean globales
 ; Podría pasársela de argumento al winproc pero... me ayuda en algo? es un proceso más 
 ; que ni sé si vale la pena.


 vector_camara_X resb VECTOR4_size	
 vector_camara_Y resb VECTOR4_size	
 vector_camara_Z resb VECTOR4_size
 vector_vision   resb VECTOR4_size 




 ;Respetar el alineamiento! no funcionarán las instrucciones de SIMD sino
 	
 alignb 16
 	matriz_mundo 		resd 16
 	matriz_apuntar_camara	resd 16
 	matriz_capturar_camara	resd 16
 	matriz_proyeccion	resd 16
	matriz_identidad	resd 16
	matriz_pantalla		resd 16
 
 ;Auxiliares

 matriz_multiplicacion     	resd 16
 
  
;--- TEXT -----------------------------------------------------------
;--------------------------------------------------------------------


section .text progbits alloc exec nowrite align=16



Start:

	sub rsp, 8    		;Para alinear la pila a 16 bytes ya que eso mejora la performance
	sub rsp, SHADOWSPACE    ;32 bytes de shadow space 
	xor ecx,ecx
	call GetModuleHandleA
	mov qword [REL hInstance], rax


	add rsp, 32				 

	call WinMain       

.Exit:

	xor ecx, ecx
	call ExitProcess     


;--------------------------------------------------------------------


WinMain:


	push rbp		
	mov rbp, rsp            
	sub rsp, 136+8*PARAMETROS+SHADOWSPACE+8   ;8 para alinear
					



%define wc			rbp - 136	; 80 bytes
%define msg			rbp - 56	; 48 bytes
%define hWnd        	        rbp - 8         ; 8 bytes



;_______Preparo el temporizador para el framerate

	lea rcx, [temporizador+TIMER__frecuencia]
	call QueryPerformanceFrequency  ; esto lo necesito para setearlo


;_______Limpio de paso el zbuffer

	call Limpiar_Depth_Buffer


;_______Cargo los parámetros de nuestros objetos
;	No pasarlos a estructuras definidas globalmente porque tampoco es 
;	mi intención que los objetos sean globales. A futuro cambiaré eso

	call Inicializar_Todos_los_Objetos


	



;_______Preparo algunas bellas matrices y el array de rasterización

	mov rcx, matriz_mundo	
	call Inicializar_Matriz_Identidad

	mov rcx, array_rasterizacion
	mov rdx, TRIANGULO_size
	call Crear_Array_Dinamico


;_______Configuro la proyección inicializando la estructura pertinente para inicializar la matriz.
;	Salvo que haya un cambio, podría descartar la estructura, pero es posible que lo haya
;	si se modifica el tamaño de la ventana (no está habilitado eso aún pero podría estarlo a futuro).
	
	mov rcx, matriz_proyeccion
	mov rdx, configuracion_proyeccion
	call Inicializar_Matriz_Proyeccion


;_______Creo un brush para el color de fondo

 	mov   ecx, dword [REL BackgroundColour]
 	call  CreateSolidBrush 
 	mov   qword [REL BackgroundBrush], rax

;_______Preparo el bitmapinfo para el DIB


	mov eax, BITMAPINFOHEADER_size
	mov [bitmapinfo+BITMAPINFO__header+BITMAPINFOHEADER__size], eax
	mov eax, ANCHO_PANTALLA
	mov [bitmapinfo+BITMAPINFO__header+BITMAPINFOHEADER__width], eax
	mov eax, -ALTO_PANTALLA
	mov [bitmapinfo+BITMAPINFO__header+BITMAPINFOHEADER__height], eax
	mov ax, 1
	mov [bitmapinfo+BITMAPINFO__header+BITMAPINFOHEADER__planes], ax
	mov ax, 32  ; tamaño del RGBA
	mov [bitmapinfo+BITMAPINFO__header+BITMAPINFOHEADER__bitCount], ax
	
	


;_______Procedemos a registrar y crear la ventana


 	mov   dword [wc+WC__cbSize], 80  ; simplemente es el tamaño nomás de la estructura                  
 	mov   dword [wc+WC__style], 0 
 	lea   rax, [REL WndProc]
 	mov   qword [wc+WC__lpfnWndProc], rax              
 	mov   dword [wc+WC__cbClsExtra], NULL              
 	mov   dword [wc+WC__cbWndExtra], NULL              


 	mov rax, qword [REL hInstance]
 	mov   qword [wc+WC__hInstance], rax              

 	xor   ecx, ecx
 	mov   edx, IDI_APPLICATION
 	mov   R8D, IMAGE_ICON
 	xor   R9D, R9D
 	mov   qword [RSP + 4 * 8], NULL        
 	mov   qword [RSP + 5 * 8], LR_SHARED
 	call  LoadImageA                               ; Icono grande
 	mov   qword [wc+WC+WC__hIcon], rax                    


 	xor   ecx, ecx
 	mov   edx, IDC_ARROW
 	mov   r8d, IMAGE_CURSOR
 	xor   r9d, r9d
 	mov   qword [RSP + 4 * 8], NULL
 	mov   qword [RSP + 5 * 8], LR_SHARED
 	call  LoadImageA                               ; Cursor
 	mov   qword [wc+WC__hCursor], rax                 

 	mov   rax, qword [REL BackgroundBrush]
 	mov   qword [wc+WC__hbrBackground], rax           
 	mov   qword [wc+WC__lpszMenuName], NULL           
 	lea   rax, [REL ClassName]
 	mov   qword [wc+WC__lpszClassName], rax            

 	xor   ecx, ecx
 	mov   edx, IDI_APPLICATION
 	mov   r8d, IMAGE_ICON
 	xor   r9d, r9d
 	mov   qword [RSP + 4 * 8], NULL
 	mov   qword [RSP + 5 * 8], LR_SHARED
 	call  LoadImageA                               ; Icono chiquito
 	mov   qword [wc+WC__hIconSm], rax                 


;_______Listo, ahora puedo registrar la ventana

 	lea   rcx, [wc]                               
 	call  RegisterClassExA

                                           
;_______Meto todos los argumentos al CreateWindowsEx y creo una ventana
;	hay mucha cosa que debo volver a setear acá si lo que busco es el fullscreen, pero bueh. En 3D_5 está el procedimiento
;	anterior (no estaba mal!)


 	mov   ecx, WS_EX_COMPOSITED | 0x00040000  ; Composited evita el flickering y el otro es para que esté por encima del taskbar
 	lea   rdx, [REL ClassName]
 	lea   r8, [REL WindowName]
 	mov   r9d, 0x02000000 | WS_POPUP ; con la del clipchildren           antes, WS_OVERLAPPEDWINDOW 

 	mov   dword [RSP + 4 * 8], 0            	 ; origen x
 	mov   dword [RSP + 5 * 8], 0		 	 ; origen y
	mov   dword [RSP + 6 * 8], ANCHO_PANTALLA        ; fin x
 	mov   dword [RSP + 7 * 8], ALTO_PANTALLA         ; fin y
 	mov   qword [RSP + 8 * 8], NULL
 	mov   qword [RSP + 9 * 8], NULL
 	mov   rax, qword [REL hInstance]
 	mov   qword [RSP + 10 * 8], rax
 	mov   qword [RSP + 11 * 8], NULL
 	call  CreateWindowExA
 	mov   qword [hWnd], rax                        

 	mov   rcx, qword [hWnd]                        
 	mov   edx, SW_SHOWNORMAL
 	call  ShowWindow

 	mov   rcx, qword [hWnd]                        
 	call  UpdateWindow


.MessageLoop:


;_______Chequeo los mensajes que me envía el sistema con respecto a mi ventana

 	lea rcx, [msg]                               
 	xor edx, edx
 	xor r8d,r8d
 	xor r9d, r9d
	mov rax, 0x0000000000000001 ; PM_REMOVE (borra los mensajes una vez que se procesaron)
	mov qword [RSP + 4 * 8], rax
 	call  PeekMessageA		; antes tenía GetMessageA (just in case)		

;_______Si devuelve cero, es porque se pidió que cierre todo. Termino en ".done"

 	cmp   rax, 0			
 	je    .dibujar

	xor rax,rax
	mov eax, [msg+MSG__message]
	cmp eax, 0x0012 ; WM_QUIT
	je .terminar

;_______De lo contrario, continuamos y chequeamos si hay un DialogBox y si se procesó
;	el mismo (recordar que se queda bloqueado hasta que responda)

 	mov   rcx, qword [hWnd]                        
 	lea   rdx, [msg]                               
 	call  IsDialogMessageA                         

;_______Si el mensaje se procesó, entonces devuelve un valor distinto de cero
;	por lo que vamos al MessageLoop

 	cmp   rax, 0
 	jne   .MessageLoop                             

;_______Si no se procesó (valor igual a cero)...

 	lea   rcx, [msg]                               
 	call  TranslateMessage

 	lea   rcx, [msg]                               
 	call  DispatchMessageA
 	jmp   .MessageLoop


.dibujar:

	lea rcx, [temporizador+TIMER__tiempo_final]
	call QueryPerformanceCounter

	fild dword [temporizador+TIMER__tiempo_final]     ; carga dword por doble precisión y/o por memoria?
	fild dword [temporizador+TIMER__tiempo_inicial]
	fsubp
	fld dword [factor_conversion_tiempo]
	fmulp 
	fild dword [temporizador+TIMER__frecuencia]
	fdivp
	fstp dword [temporizador+TIMER__tiempo_transcurrido]
		
	
	


;	mov rcx, [temporizador+TIMER__tiempo_inicial]
;	mov rax, [temporizador+TIMER__tiempo_final]
;	sub rax, rcx
;	xor rdx, rdx
;	mov rcx, 1000000 
;	mul rcx
;	xor rdx, rdx
;	mov rcx, [temporizador+TIMER__frecuencia]
;	div rcx
;	mov [temporizador+TIMER__tiempo_transcurrido], rax

	lea rcx, [temporizador+TIMER__tiempo_inicial]
	call QueryPerformanceCounter


	call Actualizar_Todo

	mov rcx, [hWnd]
	mov rdx, rectangulo_pantalla
	mov r8d, FALSE
	call InvalidateRect



.continuar:

	jmp .MessageLoop
	
	
.terminar:

 	xor   eax, eax
 	mov   rsp, rbp                                 

 	pop   rbp
 	ret


;------------------------------------------------------------------------------


Inicializar_Todos_los_Objetos:



	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE


	; Objeto "Almohadas"

	mov eax, 0
	mov [almohadas+OBJETO_3D__angulo_x], eax
	mov eax, 0
	mov [almohadas+OBJETO_3D__velocidad_angular_x], eax
	mov eax, 0
	mov [almohadas+OBJETO_3D__angulo_y], eax
	mov eax, 0
	mov [almohadas+OBJETO_3D__velocidad_angular_y], eax
	mov eax, 0
	mov [almohadas+OBJETO_3D__angulo_z], eax
	mov eax, 0
	mov [almohadas+OBJETO_3D__velocidad_angular_z], eax

	mov eax, 0x00000000 
	mov [almohadas+OBJETO_3D__posicion_x], eax	
	mov eax, 0x00000000
	mov [almohadas+OBJETO_3D__posicion_y], eax	
	mov eax, 0x46c35000 ; 25000 (25 metros)
	mov [almohadas+OBJETO_3D__posicion_z], eax


	mov eax, 0x460ca000 ; puse 9000, pero deben ser 3000 ( 1 = 1mm), pasa que la altura no esta normalizada 
	mov [almohadas+OBJETO_3D__escala_general], eax	


	mov eax, 0x00d9dee5
	mov [almohadas+OBJETO_3D__color_por_defecto], eax

	mov rcx, ruta_almohadas
	mov rdx, almohadas
	call Cargar_Datos_3D

	;-------------------------------

	; Objeto "Colchon"

	mov eax, 0
	mov [colchon+OBJETO_3D__angulo_x], eax
	mov eax, 0
	mov [colchon+OBJETO_3D__velocidad_angular_x], eax
	mov eax, 0
	mov [colchon+OBJETO_3D__angulo_y], eax
	mov eax, 0
	mov [colchon+OBJETO_3D__velocidad_angular_y], eax
	mov eax, 0
	mov [colchon+OBJETO_3D__angulo_z], eax
	mov eax, 0
	mov [colchon+OBJETO_3D__velocidad_angular_z], eax

	mov eax, 0x00000000 
	mov [colchon+OBJETO_3D__posicion_x], eax	
	mov eax, 0x00000000
	mov [colchon+OBJETO_3D__posicion_y], eax	
	mov eax, 0x46c35000 ; 25000 (25 metros)
	mov [colchon+OBJETO_3D__posicion_z], eax


	mov eax, 0x460ca000 ; puse 9000, pero deben ser 3000 ( 1 = 1mm), pasa que la altura no esta normalizada 
	mov [colchon+OBJETO_3D__escala_general], eax	


	mov eax, 0x00fda96b
	mov [colchon+OBJETO_3D__color_por_defecto], eax

	mov rcx, ruta_colchon
	mov rdx, colchon
	call Cargar_Datos_3D

	;---------------------------

	; Objeto "Marcos"

	mov eax, 0
	mov [marcos+OBJETO_3D__angulo_x], eax
	mov eax, 0
	mov [marcos+OBJETO_3D__velocidad_angular_x], eax
	mov eax, 0
	mov [marcos+OBJETO_3D__angulo_y], eax
	mov eax, 0
	mov [marcos+OBJETO_3D__velocidad_angular_y], eax
	mov eax, 0
	mov [marcos+OBJETO_3D__angulo_z], eax
	mov eax, 0
	mov [marcos+OBJETO_3D__velocidad_angular_z], eax

	mov eax, 0x00000000 
	mov [marcos+OBJETO_3D__posicion_x], eax	
	mov eax, 0x00000000
	mov [marcos+OBJETO_3D__posicion_y], eax	
	mov eax, 0x46c35000 ; 25000 (25 metros)
	mov [marcos+OBJETO_3D__posicion_z], eax


	mov eax, 0x460ca000 ; puse 9000, pero deben ser 3000 ( 1 = 1mm), pasa que la altura no esta normalizada 
	mov [marcos+OBJETO_3D__escala_general], eax	


	mov eax, 0x004771b1
	mov [marcos+OBJETO_3D__color_por_defecto], eax

	mov rcx, ruta_marcos
	mov rdx, marcos
	call Cargar_Datos_3D

	;---------------------------

	; Objeto "Mesa"

	mov eax, 0
	mov [mesa+OBJETO_3D__angulo_x], eax
	mov eax, 0
	mov [mesa+OBJETO_3D__velocidad_angular_x], eax
	mov eax, 0
	mov [mesa+OBJETO_3D__angulo_y], eax
	mov eax, 0
	mov [mesa+OBJETO_3D__velocidad_angular_y], eax
	mov eax, 0
	mov [mesa+OBJETO_3D__angulo_z], eax
	mov eax, 0
	mov [mesa+OBJETO_3D__velocidad_angular_z], eax

	mov eax, 0x00000000 
	mov [mesa+OBJETO_3D__posicion_x], eax	
	mov eax, 0x00000000
	mov [mesa+OBJETO_3D__posicion_y], eax	
	mov eax, 0x46c35000 ; 25000 (25 metros)
	mov [mesa+OBJETO_3D__posicion_z], eax


	mov eax, 0x460ca000 ; puse 9000, pero deben ser 3000 ( 1 = 1mm), pasa que la altura no esta normalizada 
	mov [mesa+OBJETO_3D__escala_general], eax	


	mov eax, 0x007a491c
	mov [mesa+OBJETO_3D__color_por_defecto], eax

	mov rcx, ruta_mesa
	mov rdx, mesa
	call Cargar_Datos_3D

	;----------------

	; Objeto "Muebles"

	mov eax, 0
	mov [muebles+OBJETO_3D__angulo_x], eax
	mov eax, 0
	mov [muebles+OBJETO_3D__velocidad_angular_x], eax
	mov eax, 0
	mov [muebles+OBJETO_3D__angulo_y], eax
	mov eax, 0
	mov [muebles+OBJETO_3D__velocidad_angular_y], eax
	mov eax, 0
	mov [muebles+OBJETO_3D__angulo_z], eax
	mov eax, 0
	mov [muebles+OBJETO_3D__velocidad_angular_z], eax

	mov eax, 0x00000000 
	mov [muebles+OBJETO_3D__posicion_x], eax	
	mov eax, 0x00000000
	mov [muebles+OBJETO_3D__posicion_y], eax	
	mov eax, 0x46c35000 ; 25000 (25 metros)
	mov [muebles+OBJETO_3D__posicion_z], eax


	mov eax, 0x460ca000 ; puse 9000, pero deben ser 3000 ( 1 = 1mm), pasa que la altura no esta normalizada 
	mov [muebles+OBJETO_3D__escala_general], eax	


	mov eax, 0x00541912
	mov [muebles+OBJETO_3D__color_por_defecto], eax

	mov rcx, ruta_muebles
	mov rdx, muebles
	call Cargar_Datos_3D

	;-------------------------


	; Objeto "Paredes"

	mov eax, 0
	mov [paredes+OBJETO_3D__angulo_x], eax
	mov eax, 0
	mov [paredes+OBJETO_3D__velocidad_angular_x], eax
	mov eax, 0
	mov [paredes+OBJETO_3D__angulo_y], eax
	mov eax, 0
	mov [paredes+OBJETO_3D__velocidad_angular_y], eax
	mov eax, 0
	mov [paredes+OBJETO_3D__angulo_z], eax
	mov eax, 0
	mov [paredes+OBJETO_3D__velocidad_angular_z], eax

	mov eax, 0x00000000 
	mov [paredes+OBJETO_3D__posicion_x], eax	
	mov eax, 0x00000000
	mov [paredes+OBJETO_3D__posicion_y], eax	
	mov eax, 0x46c35000 ; 25000 (25 metros)
	mov [paredes+OBJETO_3D__posicion_z], eax


	mov eax, 0x460ca000 ; puse 9000, pero deben ser 3000 ( 1 = 1mm), pasa que la altura no esta normalizada 
	mov [paredes+OBJETO_3D__escala_general], eax	


	mov eax, 0x00FFFFFF 
	mov [paredes+OBJETO_3D__color_por_defecto], eax

	mov rcx, ruta_paredes
	mov rdx, paredes
	call Cargar_Datos_3D

	;-----------------------------------


	; Objeto "Piso"

	mov eax, 0
	mov [piso+OBJETO_3D__angulo_x], eax
	mov eax, 0
	mov [piso+OBJETO_3D__velocidad_angular_x], eax
	mov eax, 0
	mov [piso+OBJETO_3D__angulo_y], eax
	mov eax, 0
	mov [piso+OBJETO_3D__velocidad_angular_y], eax
	mov eax, 0
	mov [piso+OBJETO_3D__angulo_z], eax
	mov eax, 0
	mov [piso+OBJETO_3D__velocidad_angular_z], eax

	mov eax, 0x00000000 
	mov [piso+OBJETO_3D__posicion_x], eax	
	mov eax, 0x00000000
	mov [piso+OBJETO_3D__posicion_y], eax	
	mov eax, 0x46c35000 ; 25000 (25 metros)
	mov [piso+OBJETO_3D__posicion_z], eax


	mov eax, 0x460ca000 ; puse 9000, pero deben ser 3000 ( 1 = 1mm), pasa que la altura no esta normalizada 
	mov [piso+OBJETO_3D__escala_general], eax	


	mov eax, 0x00c5524f
	mov [piso+OBJETO_3D__color_por_defecto], eax

	mov rcx, ruta_piso
	mov rdx, piso
	call Cargar_Datos_3D


	;-------------------------------


	; Objeto "Techo"

	mov eax, 0
	mov [techo+OBJETO_3D__angulo_x], eax
	mov eax, 0
	mov [techo+OBJETO_3D__velocidad_angular_x], eax
	mov eax, 0
	mov [techo+OBJETO_3D__angulo_y], eax
	mov eax, 0
	mov [techo+OBJETO_3D__velocidad_angular_y], eax
	mov eax, 0
	mov [techo+OBJETO_3D__angulo_z], eax
	mov eax, 0
	mov [techo+OBJETO_3D__velocidad_angular_z], eax

	mov eax, 0x00000000 
	mov [techo+OBJETO_3D__posicion_x], eax	
	mov eax, 0x00000000
	mov [techo+OBJETO_3D__posicion_y], eax	
	mov eax, 0x46c35000 ; 25000 (25 metros)
	mov [techo+OBJETO_3D__posicion_z], eax


	mov eax, 0x460ca000 ; puse 9000, pero deben ser 3000 ( 1 = 1mm), pasa que la altura no esta normalizada 
	mov [techo+OBJETO_3D__escala_general], eax	


	mov eax, 0x00eaeaea
	mov [techo+OBJETO_3D__color_por_defecto], eax

	mov rcx, ruta_techo
	mov rdx, techo
	call Cargar_Datos_3D


	;-------------------



	mov rsp, rbp
	pop rbp
	ret	
