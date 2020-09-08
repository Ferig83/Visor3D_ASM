
;--- WINPROC --------------------------------------------------------
;--------------------------------------------------------------------

; Sugerencia de optimizacion. Meter cosas aca en la pila como parte de WndProc no tiene sentido. La pila
; se vacia con cada procesamiento de mensaje, por lo que todo esto debería ir en donde van los mensajes



WndProc:

	
	push  rbp                            
	mov   rbp, rsp
	sub   rsp, 24 + 10*PARAMETROS + SHADOWSPACE + 8      ; 80 bytes para las variables locales
                                             	             ; + 80 (10 * 8 bytes) para los parámetros que es un 
							     ;  numero medio random porque no hay nada que necesite tanto
                                           	             ; + 32 shadow space (obligatorio)
                                           		     ; Todo multiplo de 16 para las funciones de la API


;_______Acá está la lista de las direcciones de la pila

;	Acá se ve el uso del shadowspace, ya que las siguientes pertenecen a los argumentos
;	que se usan desde winmain. Recordar que pasé los primeros cuatro argumentos del registro a la pila
;	y que además hay 8 bytes que son del RET que acá no se ponen pero es la razón por la cual todas
;	tienen un offset de 8 bytes (ej: hWnd debería ser RBP + 8 pero es +16 porque el RBP + 8 corresponde
;	al RET


%define hWnd                RBP + 16            ; Meto los argumentos en el shadowspace
%define uMsg                RBP + 24            ; porque los voy a necesitar
%define wParam              RBP + 32		 
%define lParam              RBP + 40		 


;_______Liberamos los registros pasando los 4 argumentos al shadow space (pila)
;	(ahora se pueden acceder por el nombre que es más práctico). Total: 32 bytes.


	mov   qword [hWnd], rcx   
	mov   qword [uMsg], rdx   
 	mov   qword [wParam], r8  
	mov   qword [lParam], r9


;_______Ahora viene el switch de los mensajes del windows que recibimos

	; El usuario pidió salir?

	cmp   qword [uMsg], WM_CLOSE	
 	je    WMCLOSE

	; El usuario realizó alguna acción?

	cmp   qword [uMsg], WM_COMMAND          
	je    WMCOMMAND

	; Se creó la ventana por primera vez?

	cmp   qword [uMsg], WM_CREATE           
	je    WMCREATE


	;El sistema (no el usuario) dice que hay que salir ?

 	cmp   qword [uMsg], WM_DESTROY         
 	je    WMDESTROY

	;El GDI autorizó la rasterización?

  	cmp   qword [uMsg], WM_PAINT                  
	je    WMPAINT

	;El usuario cliqueó en algún lugar?

	cmp   qword [uMsg], WM_LBUTTONDOWN
	je    WMLBUTTONDOWN


;_______Función para tratar los mensajes ignorados

DefaultMessage:


	mov   rcx, qword [hWnd]                     
	mov   rdx, qword [uMsg]                       
	mov   r8, qword [wParam]                      
	mov   r9, qword [lParam]                      
	call  DefWindowProcA

	jmp   Return


;_______Ahora definimos las subrutinas para cada mensaje: 


;--------------------------------------------------------------------

	
WMCLOSE:

	;Muestro el cartelito de si quiere salir

 	mov   rcx, qword [hWnd]                
 	lea   rdx, [REL ExitText]		
	lea   r8, [REL WindowName]
 	mov   r9d, MB_YESNO | MB_DEFBUTTON2           
 	call  MessageBoxA

	;El usuario seleccionó "no" ?

 	cmp   rax, IDNO			
 	je    Return.WM_Processed		; Confirmación de que se procesó el mensaje

	;El usuario tocó "si" ?

 	mov   RCX, qword [hWnd]                 
 	call  DestroyWindow                     ; Manda un WM_DESTROY
 	jmp   Return.WM_Processed		 


;--------------------------------------------------------------------

WMCOMMAND:

;_______Vacío, no se hace nada. Es para la barra de comandos

	jmp Return.WM_Processed

	
;--------------------------------------------------------------------

WMCREATE:




;_______Ahora quedaría inicializar la pantalla y crear el timer
	

;;;;;;;;Este es el DC pero mepa que hay que usar un CompatibleDC o algo así...

	; OJO! habilitar el de destroy si habilitás esto
	;mov rcx, [hWnd]
	;mov rdx, 0  			
	;mov r8, 0x00000020; | 0x00000002		; DCX_PARENTCLIP | DCX_CACHE
	;call GetDCEx
	;mov [DC_pantalla], rax
	

	call Actualizar

	xor rax, rax


 	jmp   Return.WM_Processed




;--------------------------------------------------------------------

WMDESTROY:


;_______Acá hay que hacer un control SERIO de qué cosas usé y qué cosas debo liberar

	;Borro la memoria asignada (no se si es necesario el HeapFree antes o si cambia algo)

	mov rcx, [handle_heap_objeto3d]
	call HeapDestroy

	
	;Borro el brush del fondo

 	mov rcx, qword [REL BackgroundBrush]
 	call  DeleteObject

	mov rcx, [hBitmap]
	call DeleteObject

	mov rcx, 1
	call KillTimer


;;;;;;;;;;;;;;;;;;;;TEST;;;;;;;;;;;;;;;;;
	;mov rcx, [hWnd]
	;mov rdx, [DC_pantalla]
	;call ReleaseDC


 	xor   ecx, ecx
 	call  PostQuitMessage
 	jmp   Return.WM_Processed

;--------------------------------------------------------------------

WMPAINT:


	mov rcx, [hWnd]
	mov rdx, [puntero_objeto3d_mundo]
	call Pintar_WMPAINT
	xor rax,rax

 	jmp   Return.WM_Processed

 	
;--------------------------------------------------------------------

Return.WM_Processed:
 
	xor   eax, eax                                 ; El WM_ ya se procesó, devolvé 0

Return:
 	
	mov   rsp, rbp                                 ; Limpiá el stack frame 
 	pop   rbp
 	ret

;--------------------------------------------------------------------


WMLBUTTONDOWN:




;_______Guardo los parametros del mensaje en los registros

	
	xor rcx, rcx
	xor rdx, rdx
	mov cx, word [lParam]
	mov dx, word [lParam+2]


	mov rax, [prueba]
	call Imprimir_RAX

;________No hace nada de momento	



	xor rax, rax
	jmp Return.WM_Processed

	
;--------------------------------------------------------------------	