
;--- ENCABEZADO -----------------------------------------------------

global Start

%include 'encabezado.asm'
%include 'winproc.asm'
%include 'funciones.asm'
%include 'actualizar.asm'
%include 'pintar.asm'
%include 'matrices.asm'

;--- DATA -----------------------------------------------------------

section .data progbits alloc noexec write align=16       

MitadAnchoPantalla dd FSP_MITAD_ANCHO_PANTALLA   ; 683 en float 32
MitadAltoPantalla  dd FSP_MITAD_ALTO_PANTALLA    ; 384 en float 32

rectangulo_pantalla dd 0,0,ANCHO_PANTALLA,ALTO_PANTALLA

BackgroundColour dd 0xFFFFFF      		               ; Color de fondo, le puse blanco y va en little endian (0xBBGGRR)
WindowName 	 db "Virtual Rigantity", 0                     ; Título de la ventana (nombre de la app)
ClassName        db "Ventana", 0	                       ; Nombre de la clase de la ventana (identificador choto)
ExitText         db "¿Está seguro de que quiere salir?", 0   ; Texto del mensaje de Salir 

click_izquierdo  dd 0


; -- CADENAS DE ERRORES --

error1 db 'Fallo en el CreateFile de origen',0
error2 db 'Fallo en el read file de origen',0
error3 db 'Fallo en el create file de destino',0
error4 db 'Fallo en el read file de destino',0
titulo_error db 'Error',0


; -- ANGULOS DE ROTACION --

tita_rotacion_x dd 0.0
tita_rotacion_y dd 0.0
tita_rotacion_z dd 0.0

factor_velocidad_rotacion_x dd 2.0
factor_velocidad_rotacion_z dd 0.0;4.0
factor_conversion_tiempo dd 1.0		; La verdad si el factor es 1, la multiplicación es media al dope. Pero dejarlo por si
					; tengo que cambiarlo.
factor_movimiento_z dd 0.1
factor_movimiento_x dd 0.1


; -- CAMARA Y LUCES (respetar el alineamiento!)

 align 16  
 	vector_camara_arriba 		dd 0x00000000,0x3f800000,0x00000000,0x3f800000   ;   xyzw: 0,1,0,1
 	vector_camara_delante		dd 0x00000000,0x00000000,0x3f800000,0x3f800000 	 ;   xyzw: 0,0,1,1
 	vector_camara_posicion		dd 0x00000000,0x00000000,0x00000000,0x3f800000   ;   xyzw: 0,0,0,1
 	vector_luz			dd 0x00000000,0x00000000,0xbf800000,0x3f800000	 ;   xyzw: 0,0,-1,1
	
	; REGLA DE LA MANO DERECHA, OJO (se cumple la misma regla para la transformación de la figura??)
 	

;--- BSS --------------------------------------------------------

section .bss nobits alloc noexec write align=16

; Estas son para la macro Imprimir_RAX. No la estoy usando la verdad
; cadena_auxiliar resb 20
; cadena_impresion resb 20


 temporizador resb TIMER_size

 prueba resq 1  ; para meter los valores de los debug que haga

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


 ; Hasta que no encuentre otro método necesitaré que las siguientes tres sean globales
 ; Podría pasársela de argumento al winproc pero... me ayuda en algo? es un proceso más 
 ; que ni sé si vale la pena.


 ancho_pantalla_real resq 1


 vector_camara_X resb VECTOR4_size	
 vector_camara_Y resb VECTOR4_size	
 vector_camara_Z resb VECTOR4_size
 vector_vision   resb VECTOR4_size 




 ;Respetar el alineamiento! no funcionarán las instrucciones de SIMD sino

 alignb 16 
 	puntero_objeto3d_original	resq 1

 alignb 16
 	puntero_objeto3d_mundo			resq 1  ; cambiar nombre a "puntero_objeto3d_a_rasterizar"
 	cantidad_triangulos_objeto		resq 1
 	cantidad_triangulos_a_rasterizar 	resq 1	
 	handle_heap_objeto3d			resq 1
 	handle_heap_commandline 		resq 1
 	handle_archivo_objeto3d		resq 1	
 	tamanio_archivo_objeto3d 		resq 1 

 alignb 16
 	matriz_mundo 		resd 16
 	matriz_camara		resd 16
 	matriz_vista		resd 16
 	matriz_proyeccion	resd 16
	matriz_identidad	resd 16
	matriz_pantalla		resd 16
 
 ;Auxiliares

 matriz_A   		resd 16   ; esta creo que no la estoy usando
 matriz_B     		resd 16
 	 
 triangulo_a_analizar 	resb TRIANGULO_size ; 64 bytes  
 


  
;--- TEXT -----------------------------------------------------------


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



WinMain:


	push rbp		
	mov rbp, rsp            
	sub rsp, 136+8*PARAMETROS+SHADOWSPACE+8  
							;136 bytes para variables locales  (esto lo personalizo yo en mis tablas)
							;64 (8*8) para parámetros (debe ser así porque quizas tienen un máximo de 8 argumentos de 64 bits cada 							; uno)
							;32 del shadow space  (SIEMPRE usar esto, ya que es para guardar primeros cuatro argumentos: 8*4=32)
							;8 para alinear
							;Queda en multiplos de 16 para las funciones de la API 


%define wc                 RBP - 136            ; WNDCLASSEX, 80 bytes
%define wc.cbSize          RBP - 136            ; 4 bytes. 
%define wc.style           RBP - 132            ; 4 bytes
%define wc.lpfnWndProc     RBP - 128            ; 8 bytes
%define wc.cbClsExtra      RBP - 120            ; 4 bytes
%define wc.cbWndExtra      RBP - 116            ; 4 bytes
%define wc.hInstance       RBP - 112            ; 8 bytes
%define wc.hIcon           RBP - 104            ; 8 bytes
%define wc.hCursor         RBP - 96             ; 8 bytes
%define wc.hbrBackground   RBP - 88             ; 8 bytes
%define wc.lpszMenuName    RBP - 80             ; 8 bytes
%define wc.lpszClassName   RBP - 72             ; 8 bytes
%define wc.hIconSm         RBP - 64             ; 8 bytes 

%define msg                RBP - 56             ; MSG, 48 bytes
%define msg.hwnd           RBP - 56             ; 8 bytes
%define msg.message        RBP - 48             ; 4 bytes
%define msg.Padding1       RBP - 44             ; 4 bytes
%define msg.wParam         RBP - 40             ; 8 bytes
%define msg.lParam         RBP - 32             ; 8 bytes
%define msg.time           RBP - 24             ; 4 bytes
%define msg.py.x           RBP - 20             ; 4 bytes
%define msg.pt.y           RBP - 16             ; 4 bytes
%define msg.Padding2       RBP - 12             ; 4 bytes. padding

%define hWnd               RBP - 8              ; 8 bytes


;--- Fin tabla ---


;_______Primero cargo los datos del archivo .3D y preparo el temporizador

	lea rcx, [temporizador+frecuencia]
	call QueryPerformanceFrequency  ; esto lo necesito para setearlo
	call Cargar_Datos_3D

;_______Preparo algunas bellas matrices

	
	mov rcx, matriz_mundo	
	call Inicializar_Matriz_Identidad

;TODO   ; ATENCION:
	; Esta matriz de abajo está buggeada.
	; o es un error de pila o algo pasa
	; Estoy armando la matriz sin argumentos, con
	; los valores estandar.
	;mov rcx, matriz_proyeccion
	;mov edx, 768
	;mov r8d, 1366
	;mov r9d, 0x3fc90fdb ; pi/2
	;mov   qword [RSP + 4 * 8], 0x447a0000        
	;mov   qword [RSP + 5 * 8], 0x3dcccccd
	;call Inicializar_Matriz_Proyeccion
	
	;voy a llamar a esta matriz hardcodeada, con los argumentos de arriba
	
	mov rcx, matriz_proyeccion
	call Inicializar_Matriz_Proyeccion_FAKE


;_______Creo un brush para el color de fondo

 	mov   ecx, dword [REL BackgroundColour]
 	call  CreateSolidBrush 
 	mov   qword [REL BackgroundBrush], rax


;_______Procedemos a registrar y crear la ventana


 	mov   dword [wc.cbSize], 80  ; simplemente es el tamaño nomás de la estructura                  
 	mov   dword [wc.style], 0 
 	lea   rax, [REL WndProc]
 	mov   qword [wc.lpfnWndProc], rax              
 	mov   dword [wc.cbClsExtra], NULL              
 	mov   dword [wc.cbWndExtra], NULL              


 	mov rax, qword [REL hInstance]
 	mov   qword [wc.hInstance], rax              

 	xor   ecx, ecx
 	mov   edx, IDI_APPLICATION
 	mov   R8D, IMAGE_ICON
 	xor   R9D, R9D
 	mov   qword [RSP + 4 * 8], NULL        
 	mov   qword [RSP + 5 * 8], LR_SHARED
 	call  LoadImageA                               ; Icono grande
 	mov   qword [wc.hIcon], rax                    


 	xor   ECX, ECX
 	mov   EDX, IDC_ARROW
 	mov   R8D, IMAGE_CURSOR
 	xor   R9D, R9D
 	mov   qword [RSP + 4 * 8], NULL
 	mov   qword [RSP + 5 * 8], LR_SHARED
 	call  LoadImageA                               ; Cursor
 	mov   qword [wc.hCursor], RAX                 

 	mov   RAX, qword [REL BackgroundBrush]
 	mov   qword [wc.hbrBackground], RAX           
 	mov   qword [wc.lpszMenuName], NULL           
 	lea   RAX, [REL ClassName]
 	mov   qword [wc.lpszClassName], RAX            

 	xor   ECX, ECX
 	mov   EDX, IDI_APPLICATION
 	mov   R8D, IMAGE_ICON
 	xor   R9D, R9D
 	mov   qword [RSP + 4 * 8], NULL
 	mov   qword [RSP + 5 * 8], LR_SHARED
 	call  LoadImageA                               ; Icono chiquito
 	mov   qword [wc.hIconSm], RAX                 


;_______Listo, ahora puedo registrar la ventana

 	lea   rcx, [wc]                               
 	call  RegisterClassExA

                                           
;_______Meto todos los argumentos al CreateWindowsEx y creo una ventana
;	hay mucha cosa que debo volver a setear acá si lo que busco es el fullscreen, pero bueh. En 3D_5 está el procedimiento
;	anterior (no estaba mal!)


 	mov   ECX, WS_EX_COMPOSITED | 0x00040000  ; Composited evita el flickering y el otro es para que esté por encima del taskbar
 	lea   RDX, [REL ClassName]
 	lea   R8, [REL WindowName]
 	mov   R9D, 0x02000000 | WS_POPUP ; con la del clipchildren           antes, WS_OVERLAPPEDWINDOW 

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
 	mov   qword [hWnd], RAX                        

 	mov   RCX, qword [hWnd]                        
 	mov   EDX, SW_SHOWNORMAL
 	call  ShowWindow

 	mov   RCX, qword [hWnd]                        
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
	mov eax, [msg.message]
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

	lea rcx, [temporizador+tiempo_final]
	call QueryPerformanceCounter

	fild dword [temporizador+tiempo_final]     ; carga dword por doble precisión y/o por memoria?
	fild dword [temporizador+tiempo_inicial]
	fsubp
	fld dword [factor_conversion_tiempo]
	fmulp 
	fild dword [temporizador+frecuencia]
	fdivp
	fstp dword [temporizador+tiempo_transcurrido]
		
	
	


;	mov rcx, [temporizador+tiempo_inicial]
;	mov rax, [temporizador+tiempo_final]
;	sub rax, rcx
;	xor rdx, rdx
;	mov rcx, 1000000 
;	mul rcx
;	xor rdx, rdx
;	mov rcx, [temporizador+frecuencia]
;	div rcx
;	mov [temporizador+tiempo_transcurrido], rax

	lea rcx, [temporizador+tiempo_inicial]
	call QueryPerformanceCounter


	; Se lo quité y parece que no es necesario, igual me lo quedo (?
	;mov rcx, [hWnd]
	;mov rdx, rectangulo_pantalla
	;call ValidateRect 


	call Actualizar


	mov rcx, [hWnd]
	mov rdx, rectangulo_pantalla
	mov r8d, FALSE
	call InvalidateRect

	; No parece que sea necesario
	;mov rcx, [hWnd]
	;mov rdx, 0x0010
	;call UpdateWindow



.continuar:

	jmp .MessageLoop
	
	
.terminar:

 	xor   eax, eax
 	mov   rsp, rbp                                 ; Desarmo la pila que hice

 	pop   rbp
 	ret

