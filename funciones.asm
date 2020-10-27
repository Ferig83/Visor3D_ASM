;--------------------------------------------------------------------
;--- FUNCIONES ------------------------------------------------------
;--------------------------------------------------------------------


Imprimir_RAX: 

%define cadena_auxiliar rbp - 64 ; 32 bytes
%define cadena_impresion rbp - 32 ; 32 bytes

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 192

        push rax 
	push rbx 
	push rcx 
	push rdx
	push r8
	push r9

;_______Agregamos "10" a la cadena

        mov byte [cadena_auxiliar], 0   ; antes era 10, pero pongamos cero porque asi quiere el messagebox
        lea rbx, [cadena_auxiliar]
        inc rbx
        mov rcx, 10 ; para dividir o multiplicar
        
.macroloop:

        xor rdx, rdx    ; limpio RDX para que no concatene y ahí vaya el resto
        div rcx 	; divido por 10 el contenido de RAX
        add dl, 48      ; agrego 48 para transformarlo en numero bajo el ASCII  

        mov [rbx], dl
        inc rbx
        cmp rax, 0
        jne .macroloop

;Listo, se metieron los datos, pero al reves ( tipo 10,unidades,decenas, centenas, etc)
;Ahora falta meter los datos bien en cadena_impresion.

        lea rdx, [cadena_impresion]
        dec rbx

.macroloop2:


        mov rcx, [rbx]
        mov [rdx], rcx
        dec rbx
        inc rdx
        cmp byte [rbx], 0
        jne .macroloop2


        mov byte [rdx], 0

	
 	mov   rcx, qword [hWnd]                 ; [RBP + 16]
	lea   rdx, [REL cadena_impresion]		
	lea   r8, [REL WindowName]
 	mov   r9d, NULL ; es el ok solo. Antes: MB_YESNO | MB_DEFBUTTON2           
 	call  MessageBoxA
	

	pop r9
	pop r8
        pop rdx 
	pop rcx 
	pop rbx 
	pop rax

	mov rsp, rbp
	pop rbp
	ret


;--------------------------------------------------------------------

Cargar_Datos_3D:

; Argumentos:  rcx : puntero al path de OBJETO_3D. 
; 	       rdx : puntero a la estructura del objeto

; Ojo!! pongo la cadena por separado, hay que pensar si incluir o no
; el puntero a la cadena que contiene el path del archivo en la estructura OBJETO_3D,
; porque no sé si es realmente necesario que lo tenga. De ser así, el cambio es muy simple 
; así que tampoco pasa nada.


%define GENERIC_READ 10000000000000000000000000000000b   ;si lo lee en little endian esto esta mal, deberia valer 1 nomas
%define GENERIC_WRITE 01000000000000000000000000000000b   
%define INVALID_HANDLE_VALUE -1	
%define OPEN_EXISTING 3
%define CREATE_ALWAYS 2
%define FILE_ATTRIBUTE_NORMAL 0x80

%define tamanio_archivo_objeto3d	rbp - 24  ; 8 bytes
%define handle_archivo_objeto3d		rbp - 16  ; 8 bytes
%define puntero_estructura		rbp - 8   ; 8 bytes

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 32

	mov [puntero_estructura], rdx
	
;_______Abrimos el archivo. Ya tengo el path en rcx

	mov rdx, GENERIC_READ
	mov r8, 0 ; NULL, evita que otros procesos operen el archivo (no hay "share")
	mov r9, 0 ; NULL
	mov qword [rsp + 4 * 8], OPEN_EXISTING
	mov qword [rsp + 5 * 8], FILE_ATTRIBUTE_NORMAL
	mov qword [rsp + 6 * 8], NULL
	call CreateFileA


;_______Verifico que haya errores al abrir el archivo

	cmp rax, INVALID_HANDLE_VALUE
	je .error1                              
	mov [handle_archivo_objeto3d], rax		


;_______Recupero el tamaño del archivo ya que necesito asignar memoria
	
	mov rcx, rax
	lea rdx, [tamanio_archivo_objeto3d]
	call GetFileSizeEx
		
	;NOTA: Teoricamente esto devuelve un numero tocho para el cual se necesita
	;una estructura tipo _LARGE_INTEGER_ definida en la WinApi. La primera primera parte (un dword)
	;es la parte baja de ese big integer, y como no voy a enchufar un archivo que rompa
	;el dword, me conformo con tomar ese pedacito.


;_______Ya con el tamaño asigno memoria pero como se agrega una coordenada más, voy a necesitar
;	sumarle más tamaño. Igual antes aprovecho y veo cuantos triángulos tiene 
;	el objeto, y lo guardo

	xor rax, rax
	xor rbx, rbx
	xor r8,r8



	mov eax, [tamanio_archivo_objeto3d]

	xor rdx, rdx
	mov rbx, 36  ; Tamaño en bytes de cada triángulo sin el color ni la coordenada w, que es lo que hay en el archivo    
	div rbx
	mov rbx, [puntero_estructura]
	mov [rbx+OBJETO_3D__cantidad_triangulos], eax

	xor rax,rax
	xor rdx,rdx

;_______Ahora sí, dada la cantidad de triángulos, sólo necesito multiplicarlos por el tamaño de cada triángulo de los míos
;	y tengo el espacio para cuatro coordenadas más el color. 

	mov eax, [rbx+OBJETO_3D__cantidad_triangulos]
	xor rbx, rbx
	mov ebx, TRIANGULO_size 		
	mul ebx 
	mov ebx, eax 				; el resultado es rdx:rax pero creo que ni hace falta tomar rdx

	
	mov rcx,0 ; sin flags
	mov rdx, 0  ; sin espacio inicial inamovible
	mov r8, 0 ;  Para que sea growable
	call HeapCreate
	
	mov r8d, ebx			 	;acá va la cantidad de bytes
	mov rbx, [puntero_estructura]
	mov [rbx+OBJETO_3D__handle_memoria], rax   	; me lo guarrrrdo
	mov rcx, rax
	mov rdx, 8       			;esto hace que limpie la memoria allocateada (?
	call HeapAlloc
	mov rcx, [puntero_estructura]
	mov [rcx+OBJETO_3D__puntero_triangulos], rax


;_______Leemos el archivo, pero solo tenemos que leer los primero 12 bytes y luego agregar 4 bytes como = 0x3f800000
;	para introducir la coordenada "w" igual a 1. Así que vamos a tener que hacer un loop.


	push r15
	push r14
	push r13

	xor rax,rax
	mov rbx, [puntero_estructura]
	mov r15d, [rbx+OBJETO_3D__cantidad_triangulos] 
	mov r14, [rbx+OBJETO_3D__puntero_triangulos]
	xor r13,r13
	


.loop_carga_archivo_a_memoria:


	; Esto lo tengo que hacer tres veces porque el color me está complicando el asunto

	xor rdx, rdx
	mov rcx, [handle_archivo_objeto3d]
	mov edx, r13d ; OFFSET
	mov r8, 0
	mov r9, 0	; desde el inicio
	call SetFilePointer
	;
	xor r8,r8
	mov rcx, [handle_archivo_objeto3d]
	mov rdx, r14
	mov r8d, 12  ; Leo 12 bytes que es el tamaño de cada vértice (terna de dwords)
	mov r9, NULL 			        ; es para el overlapped, no lo necesito.
	mov qword [RSP + 4 * 8], NULL 	   	; idem
	call ReadFile
	;
	add r14, 12  ; Me posiciono al final del vértice 			
	mov edx, 0x3f800000 ; 1.0
	mov [r14], edx   		; Agrego el 1.0 del "w" 
	add r14, 4		 	; Sumo 4 para pasar al final de w (inicio del color) 
	;
	add r13, 12			; Le agrego el offset para que mueva el cursor en la próxima del siguiente vértice


	xor rdx, rdx
	mov rcx, [handle_archivo_objeto3d]
	mov edx, r13d ; OFFSET
	mov r8, 0
	mov r9, 0	; desde el inicio
	call SetFilePointer
	;
	xor r8,r8
	mov rcx, [handle_archivo_objeto3d]
	mov rdx, r14
	mov r8d, 12  ; Leo 12 bytes que es el tamaño de cada vértice (terna de dwords)
	mov r9, NULL 			        ; es para el overlapped, no lo necesito.
	mov qword [RSP + 4 * 8], NULL 	   	; idem
	call ReadFile
	;
	add r14, 12  ; Me posiciono al final del vértice 			
	mov edx, 0x3f800000 ; 1.0
	mov [r14], edx   		; Agrego el 1.0 del "w" 
	add r14, 4		 	; Sumo 4 para pasar al final de w (inicio del color) 
	;
	add r13, 12			; Le agrego el offset para que mueva el cursor en la próxima del siguiente vértice


	xor rdx, rdx
	mov rcx, [handle_archivo_objeto3d]
	mov edx, r13d ; OFFSET
	mov r8, 0
	mov r9, 0	; desde el inicio
	call SetFilePointer
	;
	xor r8,r8
	mov rcx, [handle_archivo_objeto3d]
	mov rdx, r14
	mov r8d, 12  ; Leo 12 bytes que es el tamaño de cada vértice (terna de dwords)
	mov r9, NULL 			        ; es para el overlapped, no lo necesito.
	mov qword [RSP + 4 * 8], NULL 	   	; idem
	call ReadFile
	;
	add r14, 12  ; Me posiciono al final del vértice 			
	mov edx, 0x3f800000 ; 1.0
	mov [r14], edx   		; Agrego el 1.0 del "w" 
	
;Chanchada begins ----

	add r14, 4 ; muevo cuatro bytes extra para ir al offset del color
	mov rcx, [puntero_estructura]
	mov edx, [rcx+OBJETO_3D__color_por_defecto]
	mov [r14], edx
	add r14, COLOR_size+12 ; muevo los dos bytes restantes + el padding para que quede alineado a 16 (requerido para SSE 4.1)	

;end of chanchada ----
;previo a la chanchada:	add r14, 4+COLOR_size		; Sumo 4 para pasar al final de w (inicio del color). OJO! Acá sí agrego el colorsize. 
	;
	add r13, 12			; Le agrego el offset para que mueva el cursor en la próxima del siguiente vértice


	dec r15
	cmp r15, 0
	ja .loop_carga_archivo_a_memoria

	
	pop r13
	pop r14
	pop r15	


;_______Ya pasamos todo a memoria, por lo que cerramos el archivo

	mov rcx, [handle_archivo_objeto3d]
	call CloseHandle


	xor rax, rax

	mov rsp, rbp
	pop rbp

	ret
	

.error1:

	mov rcx, 0            ;uso el desktop
	mov rdx, error1
	mov r8, titulo_error
	mov r9d, 0
	call MessageBoxA
	call ExitProcess

	
.error2:


	mov rcx, 0            ;uso el desktop
	mov rdx, error2
	mov r8, titulo_error
	mov r9d, 0
	call MessageBoxA
	call ExitProcess	

.error3:


	mov rcx, 0            ;uso el desktop
	mov rdx, error3
	mov r8, titulo_error
	mov r9d, 0
	call MessageBoxA
	call ExitProcess

.error4:

	mov rcx, 0            ;uso el desktop
	mov rdx, error4
	mov r8, titulo_error
	mov r9d, 0
	call MessageBoxA
	call ExitProcess


%undef tamanio_archivo_objeto3d	
%undef handle_archivo_objeto3d	
%undef puntero_estructura	





