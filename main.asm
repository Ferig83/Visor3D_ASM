
;--- ENCABEZADO -----------------------------------------------------

global Start

%include 'encabezado.asm'
%include 'winproc.asm'
%include 'funciones.asm'
%include 'actualizar.asm'
%include 'pintar.asm'
%include 'macros.asm'
%include 'matrices.asm'

;--- DATA -----------------------------------------------------------

section .data        

AnchoPantalla	   dd 1366
AltoPantalla	   dd 768
MitadAnchoPantalla dd 0x442ac000   ; 683 en float 32
MitadAltoPantalla  dd 0x43c00000   ; 384 en float 32
rectangulo_pantalla dd 0,0,1366,768


BackgroundColour dd 0xFFFFFF      		               ; Color de fondo, le puse blanco y va en little endian (0xBBGGRR)
WindowName 	 db "Virtual Reality", 0                     ; Título de la ventana (nombre de la app)
ClassName        db "Ventana", 0	                       ; Nombre de la clase de la ventana (identificador choto)
ExitText         db "¿Estás seguro de que quiere salir?", 0   ; Texto del mensaje de Salir 

click_izquierdo  dd 0
handle_ventana   dq 0  ;lo necesito global para el invalidateRect, sino es un bardo


; -- CADENAS DE ERRORES --

error1 db 'Fallo en el CreateFile de origen',0
error2 db 'Fallo en el read file de origen',0
error3 db 'Fallo en el create file de destino',0
error4 db 'Fallo en el read file de destino',0
titulo_error db 'Error',0


; -- ANGULOS DE ROTACION --
tita_rotacion_x dd 0.0  ; roto un misero radian
tita_rotacion_y dd 0.0
tita_rotacion_z dd 0.0
delta_rotacion_x dd 0.05
delta_rotacion_z dd 0.1


; -- CAMARA Y LUCES --

vector_camara_arriba 		dd 0x00000000,0x3f800000,0x00000000,0x3f800000   ;   xyzw: 0,1,0,1
vector_camara_delante		dd 0x00000000,0x00000000,0x3f800000,0x3f800000 	 ;   xyzw: 0,0,1,1
vector_camara_derecha		dd 0x3f800000,0x00000000,0x00000000,0x3f800000	 ;   xyzw: 1,0,0,1
vector_camara_posicion		dd 0x00000000,0x00000000,0x00000000,0x3f800000   ;   xyzw: 0,0,0,1
vector_luz			dd 0x00000000,0x00000000,0xbf800000,0x3f800000	 ;   xyzw: 0,0,-1,1

;--- BSS --------------------------------------------------------

section .bss 


; cadena_auxiliar resb 32;20  ;estas dos son para las macros de imprimir EAX
; cadena_impresion resb 32; 20


 alignb 8                  ;esto es para forzar que se aliñe todo de 8 en 8 bytes y se llene
			   ;con espacios vacios lo que sobra. Teoricamente mejora el rendimiento


 prueba resq 1  ; para meter los valores de los test que haga

 hInstance        	resq 1    ;necesario para el blit
 BackgroundBrush  	resq 1
 DC_pantalla	        resq 1


 ;esto mepa que se va a la basura... no sé si guardarlo para las texturas

 hBitmap 		resq 1         ; este es el HBITMAP que necesitamos para casi todo lo que es blitteo
 bmpDC 			resq 1


 ; Hasta que no encuentre otro método necesitaré que las siguientes tres sean globales
 ; Podría pasársela de argumento al winproc pero... me ayuda en algo? es un proceso más 
 ; que ni sé si vale la pena.

 puntero_objeto3d_original	resq 1
 puntero_objeto3d_mundo		resq 1  ; cambiar nombre a "puntero_objeto3d_a_rasterizar"

 cantidad_triangulos_objeto		resq 1
 cantidad_triangulos_a_rasterizar 	resq 1	
 handle_heap_objeto3d			resq 1
 handle_heap_commandline 		resq 1
 handle_archivo_objeto3d		resq 1	
 tamanio_archivo_objeto3d 		resq 1 

 matriz_mundo 		resd 16
 matriz_camara		resd 16
 matriz_vista		resd 16
 matriz_proyeccion	resd 16
 
 ;auxiliares
 matriz_A   		resd 16   ; esta creo que no la estoy usando
 matriz_B     		resd 16
 
 triangulo_a_analizar 	resb TRIANGULO_size ; 52 bytes  
 

 ancho_pantalla_real resq 1

  
;--- TEXT -----------------------------------------------------------


section .text

Start:

	sub rsp, 8    ;Para alinear la pila a 16 bytes ya que eso mejora la performance
	sub rsp, SHADOWSPACE    ;32 bytes de shadow space (para GetModuleHandleA?)
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
	sub rsp, 184+8*PARAMETROS+SHADOWSPACE+8    
							;160 bytes para variables locales  (esto lo personalizo yo en mis tablas)
							;64 (8*8) para parámetros (debe ser así porque quizas tienen un máximo de 8 argumentos de 64 bits cada 							; uno)
							;32 del shadow space  (SIEMPRE usar esto, ya que es para guardar primeros cuatro argumentos: 8*4=32)
							;8 para alinear
							;Queda en multiplos de 16 para las funciones de la API 


%define temporizador       RBP - 184		; 8 bytes	

%define Screen.Width       RBP - 160            ; 4 bytes
%define Screen.Height      RBP - 156            ; 4 bytes

%define ClientArea         RBP - 152            ; RECT structure. 16 bytes
%define ClientArea.left    RBP - 152            ; 4 bytes. Start on a 4 byte boundary
%define ClientArea.top     RBP - 148            ; 4 bytes
%define ClientArea.right   RBP - 144            ; 4 bytes
%define ClientArea.bottom  RBP - 140            ; 4 bytes. 

%define wc                 RBP - 136            ; WNDCLASSEX, 80 bytes
%define wc.cbSize          RBP - 136            ; 4 bytes. 
%define wc.style           RBP - 132            ; 4 bytes
%define wc.lpfnWndProc     RBP - 128            ; 8 bytes
%define wc.cbClsExtra      RBP - 120            ; 4 bytes
%define wc.cbWndExtra      RBP - 116            ; 4 bytes
%define wc.hInstance       RBP - 112            ; 8 bytes
%define wc.hIcon           RBP - 104            ; Icono grande (8 bytes)
%define wc.hCursor         RBP - 96             ; Cursor (8 bytes)
%define wc.hbrBackground   RBP - 88             ; 8 bytes
%define wc.lpszMenuName    RBP - 80             ; 8 bytes
%define wc.lpszClassName   RBP - 72             ; 8 bytes
%define wc.hIconSm         RBP - 64             ; Icono chiquito 

%define msg                RBP - 56             ; MSG, 48 bytes
%define msg.hwnd           RBP - 56             ; 8 bytes
%define msg.message        RBP - 48             ; 4 bytes
%define msg.Padding1       RBP - 44             ; 4 bytes
%define msg.wParam         RBP - 40             ; 8 bytes
%define msg.lParam         RBP - 32             ; 8 bytes
%define msg.time           RBP - 24             ; 4 bytes
%define msg.py.x           RBP - 20             ; 4 bytes
%define msg.pt.y           RBP - 16             ; 4 bytes
%define msg.Padding2       RBP - 12             ; 4 bytes. Structure length padding

%define hWnd               RBP - 8              ; 8 bytes


;--- Fin tabla ---





	lea rcx, [temporizador+frecuencia]
	call QueryPerformanceFrequency  ; esto lo necesito para setearlo

	call Cargar_Datos_3D







 	mov   ecx, dword [REL BackgroundColour]
 	call  CreateSolidBrush 
 	mov   qword [REL BackgroundBrush], rax

 	mov   dword [wc.cbSize], 80                    
 	mov   dword [wc.style], CS_HREDRAW | CS_VREDRAW | CS_BYTEALIGNWINDOW 
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



;_______Saco los valores del monitor, para el fullscreen, y luego los meto en el clientarea

 	mov   ecx, SM_CXSIZE  			       ; Tamaño de la pantalla en X
 	call  GetSystemMetrics                         ; Recupero el ancho de la pantalla
 	mov   dword [Screen.Width], eax                
	mov   dword [ancho_pantalla_real], eax         ; Esto es para la mascara, aprovecho hacerlo acá

 	mov   ecx, SM_CYSIZE			       ; Tamaño de la pantalla en Y
 	call  GetSystemMetrics                         ; Recupero el alto de la pantalla
 	mov   dword [Screen.Height], eax               

 	mov   dword [ClientArea.left], 0             
 	mov   dword [ClientArea.top], 0                
	mov   eax, dword [Screen.Width]
 	mov   dword [ClientArea.right], eax    	       
	mov eax, dword [Screen.Height]
 	mov   dword [ClientArea.bottom], eax  	       

;_______Saco el valor de la ventana (total, con el frame incluido), habiendo sacado el client area (la parte de adentro)

 	lea   RCX, [ClientArea]                        
 	mov   EDX, WS_POPUP | WS_VISIBLE               ;antes: WS_OVERLAPPEDWINDOW ; Window Style
 	xor   R8D, R8D
 	mov   R9D, WS_EX_COMPOSITED                    
 	call  AdjustWindowRectEx                       
                                                      
 	
;_______Con esto tengo el tamaño de la VENTANA en la estructura de ClientArea (o sea, la estructura
;	tiene el nombre del client area pero la estoy usando ahora para guardar la de la ventana)
;	Lo que voy a hacer ahora es hacer la diferencia entre bottom y top, y entre right y left, para
;	obtener la altura real. Si estás usando fullscreen no es necesario todo esto.  

	mov   EAX, dword [ClientArea.bottom]          
 	sub   EAX, dword [ClientArea.top]              ; Altura = ClientArea.bottom - ClientArea.top
 	mov   dword [ClientArea.bottom], EAX           

 	mov   EAX, dword [ClientArea.right]            
 	sub   EAX, dword [ClientArea.left]             ; Width = ClientArea.right - ClientArea.left
 	mov   dword [ClientArea.right], EAX            


;_______Meto todos los argumentos al CreateWindowsEx y creo una ventana
;	hay mucha cosa que debo volver a setear acá si lo que busco es el fullscreen, pero bueh

 	mov   ECX, WS_EX_COMPOSITED
 	lea   RDX, [REL ClassName]
 	lea   R8, [REL WindowName]
 	mov   R9D, WS_POPUP | WS_VISIBLE;   le saqué el WS_OVERLAPPEDWINDOW para que se vea fullscreen real

 	xor   R10D, R10D
 	mov   EAX, dword [Screen.Width]                
 	sub   EAX, dword [ClientArea.right]            ; Ancho de ventana corregido
 	cmovs EAX, R10D                                ; CMOVS (conditional move). Mueve si el signo es 1
						       ; (hay varios cmov, pero este es el de signo)
						       ; Lo muevo a cero si es negativo (R10D = 0)

 	shr   EAX, 1                                   ; EAX = (Screen.Width - window height) / 2
						       ; shr es un shift right, o sea que se pierde el bit menos significativo
						       ; que a fines prácticos es como dividir por dos. CLEVER SHIT, probalo papá
							; esto lo hago para centrarlo 


 	mov   dword [RSP + 4 * 8], EAX                 ; Posición X, centrada
 	mov   EAX, dword [Screen.Height]               ; [RBP - 156]
 	sub   EAX, dword [ClientArea.bottom]           ; Altitud de la ventana corregida  [RBP - 140]
 	cmovs EAX, R10D                                ; Cero si es negativo (fuerza a arriba de todo)
 	shr   EAX, 1                                   ; EAX = (Screen.Height - window height) / 2
 	mov   dword [RSP + 5 * 8], EAX                 ; Posición Y, ya centrada.

 	mov   EAX, dword [ClientArea.right]            
 	mov   dword [RSP + 6 * 8], EAX                 ; Ancho

 	mov   EAX, dword [ClientArea.bottom]           
 	mov   dword [RSP + 7 * 8], EAX                 ; Alto

 	mov   qword [RSP + 8 * 8], NULL
 	mov   qword [RSP + 9 * 8], NULL

 	mov   RAX, qword [REL hInstance]
 	mov   qword [RSP + 10 * 8], RAX

 	mov   qword [RSP + 11 * 8], NULL
 	call  CreateWindowExA
 	mov   qword [hWnd], RAX                        
	mov   qword [handle_ventana], rax  	       ; lo necesito global



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
 	call  PeekMessageA		; antesGetMessageA		

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

	lea rcx, [temporizador+tiempo_inicial]
	call QueryPerformanceCounter

	
;;;;;todo esto es un bloquecito

.esperar:

	lea rcx, [temporizador+tiempo_final]
	call QueryPerformanceCounter
	mov rcx, [temporizador+tiempo_inicial]
	mov rax, [temporizador+tiempo_final]
	sub rax, rcx
	xor rdx, rdx
	mov rcx, 1000000  
	mul rcx
	xor rdx, rdx
	mov rcx, [temporizador+frecuencia]
	div rcx
	mov [temporizador+tiempo_transcurrido], rax


	; Arranco el cronometro acá,
	; chequeo y si paso menos de un segundo salto a continuar
	; sino, actualizo

	cmp rax, 18000  ; 60 fps
	jle .esperar

	
	fld dword [tita_rotacion_x]
	fld dword [delta_rotacion_x]
	faddp
	fstp dword [tita_rotacion_x]
	fld dword [tita_rotacion_z]
	fld dword [delta_rotacion_z]
	faddp
	fstp dword [tita_rotacion_z]


	call Actualizar
	mov rcx, [hWnd]
	mov rdx, rectangulo_pantalla
	mov r8d, TRUE
	call InvalidateRect
	mov rcx, [hWnd]
	call UpdateWindow


;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; ACA SE DIBUJARIA.  Estoy llamando a tirar WM_PAINTs con el UpdateWindows...voy a tener que cambiarlo
;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;call Pintar	

.continuar:

	jmp .MessageLoop
	
	
.terminar:

 	xor   eax, eax
 	mov   rsp, rbp                                 ; Quito la pila que hice

 	pop   rbp
 	ret

