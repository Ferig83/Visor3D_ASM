;--------------------------------------------------------------------
;--- FUNCIONES ------------------------------------------------------
;--------------------------------------------------------------------


Rescatar_Argumentos:       ; No estoy cumpliendo con la convención de registros volátiles. Pushearlos 


	
	%define cantidad_argumentos rbp - 16  ; 8 bytes. No hace falta tanto pero como tengo que alinear la pila...
	%define primer_argumento rbp - 8 	; 8 bytes 

	push rbx

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 16

;_______Primero recupero la cadena con el command line

	Call GetCommandLineA	
	

;_______Luego voy al final de todo, y mientras viajo, cuento cuántos argumentos hay y guardo en memoria el offset
;	del primer argumento. Cuando me topo con un espacio, voy viajando a través de todos los espacios consecutivos si los
;	hay hasta llegar al que no es espacio y sumo 1 al contador. Cuento para ver si hay algun argumento, porque si no hay, corto.

	mov rbx, 0  ; este es el contador de argumentos

.loop1:

	; Verifico si se cerró la cadena, en ese caso termina el loop1.

	cmp byte [rax], 0
	je .fin_loop1

	; Comparo si hay comillas, porque si las hay voy a tener que ignorar
	; todos los espacios que vea dentro.

	cmp byte [rax], 34;"  ; Compara si hay una comilla.
	je .loop1_hay_comillas
	jmp .loop1_sin_comillas

.loop1_hay_comillas:

	; Busco las comillas de cierre. Si hay una sola debo cortar
	; porque el argumento está mal escrito.

	inc rax
	
	; Si lo siguiente es verdadero es porque hay una sola comilla. Mal argumento, salto a error1.

	cmp byte [rax], 0   
	je .error1 

	; Verifico la comilla de cierre	

	cmp byte [rax], 34 ;"  	
	jne .loop1_hay_comillas

	; Si la encontramos, volvemos al bucle para buscar más espacios o argumentos.

	inc rax
	jmp .loop1
	
.loop1_sin_comillas:

	cmp byte [rax], 32  ; espacio
	je .loop1_recorrer_espacios
	inc rax
	jmp .loop1
	
.loop1_recorrer_espacios:

	inc rax
	cmp byte [rax], 32
	je .loop1_recorrer_espacios
	cmp byte [rax], 0
	je .loop1

	inc rbx
	cmp rbx, 1  
	je .loop1_recordar_primer_argumento
	jmp .loop1

.loop1_recordar_primer_argumento:
	
	mov [primer_argumento], rax	
	jmp .loop1
		

.fin_loop1:




	mov [cantidad_argumentos], rbx

	;Si no hay argumentos tiro error. Necesito en este caso.

	cmp rbx, 0
	je .error2

;_______Ahora me posiciono en el primer argumento y cuento cuántos caracteres tiene. Si empieza en comillas
;	busco la comilla de cierre (tiene que estar porque ya fue verificada). No lo hago esto arriba porque
;	iba a complejizar más el código. 


	xor rbx,rbx   ; Ahora rbx es mi contador de caracteres dentro del primer argumento


	mov rax, [primer_argumento]


.loop2:

	cmp byte [rax], 0
	je .fin_loop2

	cmp byte [rax], 34 ;"          ;este podríamos quitarlo y ponerlo antes del loop2
	je .loop2_hay_comillas
	inc rax
	inc rbx
	cmp byte [rax], 32
	je .fin_loop2

	jmp .loop2	

.loop2_hay_comillas:

	inc rax
	inc rbx
	cmp byte [rax], 34 ;"
	jne .loop2_hay_comillas
	inc rax
	jmp .loop2

.fin_loop2:

	inc rbx  ; esto para guardar el 0

;_______Ahora agarro el primero argumento. No sé bien como se ingresaria con comillas y si eso importa
;	pero voy a  asumir que si va con comillas funciona igual. Lo único que buscamos ahora es copiar
;	el argumento en memoria y enchufarle un cero al final. No escribo la memoria del command line
;	por si acaso. 


	call GetProcessHeap
	xor r8,r8
	mov [handle_heap_commandline], rax  	; guardo el handle para luego borrar esto
	mov rcx, rax
	mov rdx, 8       			;esto hace que limpie la memoria allocateada (?
	mov r8, rbx			 	;acá va la cantidad de bytes calculada arriba
	call HeapAlloc

;_______Ahora meto el argumento en memoria

	;Guardo el puntero del heap para devolverlo luego

	mov r8, rax
	mov rdx, [primer_argumento]
	



.loop3:

	cmp byte [rdx], 34 ; "
	je .loop3_hay_comillas

	mov cl, [rdx]
	mov [rax], cl
	inc rax
	inc rdx
	dec rbx
	cmp rbx, 1
	ja .loop3
	mov byte [rax], 0
	jmp .fin_loop3

.loop3_hay_comillas:
	
	inc rdx
	dec rbx
	jmp .loop3

.fin_loop3:

	;Listo el llopo. Enviamos el puntero a rax
	
	mov rax, r8


	mov rsp, rbp
	pop rbp

	
%undef cantidad_argumentos  
%undef primer_argumento

	pop rbx
	ret
	

.error1:

	mov rax, -1
	call Imprimir_RAX
	mov rsp, rbp
	pop rbp

	pop rbx
	ret
	


.error2:

	mov rax, -1
	call Imprimir_RAX
	mov rsp, rbp
	pop rbp

	pop rbx
	ret


;--------------------------------------------------------------------

Pintar_Triangulo_Wireframe:


	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 32

	push r15

	mov r15, rdx
	mov rbx, rcx
	
;--- Primera Linea	

	mov rcx, rbx
	mov rax, r15
	add rax, TRIANGULO+vertice1+x
	mov edx, [rax]             
	mov rax, r15
	add rax, TRIANGULO+vertice1+y 
	mov r8d, [rax] 
	xor r9,r9
	call MoveToEx	

	mov rcx, rbx
	mov rax, r15
	add rax, TRIANGULO+vertice2+x
	mov edx, [rax]                         
	mov rax, r15		
	add rax, TRIANGULO+vertice2+y
	mov r8d, [rax]
	call LineTo

;--- Segunda Linea

	mov rcx, rbx
	mov rax, r15
	add rax, TRIANGULO+vertice2+x
	mov edx, [rax]             
	mov rax, r15
	add rax, TRIANGULO+vertice2+y 
	mov r8d, [rax] 
	xor r9,r9
	call MoveToEx	

	mov rcx, rbx
	mov rax, r15
	add rax, TRIANGULO+vertice3+x
	mov edx, [rax]                         
	mov rax, r15		
	add rax, TRIANGULO+vertice3+y
	mov r8d, [rax]
	call LineTo

;--- Tercera Linea
	
	mov rcx, rbx
	mov rax, r15
	add rax, TRIANGULO+vertice3+x
	mov edx, [rax]             
	mov rax, r15
	add rax, TRIANGULO+vertice3+y 
	mov r8d, [rax] 
	xor r9,r9
	call MoveToEx	

	mov rcx, rbx
	mov rax, r15
	add rax, TRIANGULO+vertice1+x
	mov edx, [rax]                         
	mov rax, r15		
	add rax, TRIANGULO+vertice1+y
	mov r8d, [rax]
	call LineTo

	pop r15

	mov rsp, rbp	
	pop rbp

	ret

;--------------------------------------------------------------------

Pintar_Triangulo:

	%define hPen_anterior rbp - 56		; 8 bytes
	%define hPen_triangulo rbp - 48		; 8 bytes
	%define puntos rbp - 40			; 24 bytes
	%define hBrush_anterior rbp - 16 	; 8 bytes	
	%define hBrush_color_triangulo rbp - 8  ; 8 bytes

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 64

	push r15




	mov r15, rdx
	mov rbx, rcx


	xor rcx, rcx  
	mov rcx, 0  ; estilo PS_SOLID, es decir, linea común
	mov rdx, 0  ; ancho, 0 es un pixel solo
	mov r8d, [r15+TRIANGULO+color]
	call CreatePen
	mov [hPen_triangulo], rax
	mov rcx, rbx
	mov rdx, rax
	call SelectObject
	mov [hPen_anterior] ,rax  ; la función devuelve el brush reemplazado (IQ 2000 de parte de Bill Gates)
	

	

	xor rcx,rcx
	mov ecx, [r15+TRIANGULO+color]
	call CreateSolidBrush
	mov [hBrush_color_triangulo], rax
 
	mov rcx, rbx
	mov rdx, rax
	call SelectObject
	mov [hBrush_anterior] ,rax 
	

	mov eax, [r15+TRIANGULO+vertice1+x]
	mov [puntos+PUNTOS+x_1], eax
	mov eax, [r15+TRIANGULO+vertice1+y]
	mov [puntos+PUNTOS+y_1], eax
	mov eax, [r15+TRIANGULO+vertice2+x]
	mov [puntos+PUNTOS+x_2], eax
	mov eax, [r15+TRIANGULO+vertice2+y]
	mov [puntos+PUNTOS+y_2], eax
	mov eax, [r15+TRIANGULO+vertice3+x]
	mov [puntos+PUNTOS+x_3], eax
	mov eax, [r15+TRIANGULO+vertice3+y]
	mov [puntos+PUNTOS+y_3], eax
	
	mov rcx, rbx
	lea rdx, [puntos]
	mov r8, 3
	call Polygon
	
	mov rcx, rbx
	mov rdx, [hBrush_anterior]
	call SelectObject
	mov rcx, [hBrush_color_triangulo]
	call DeleteObject

	mov rcx, rbx
	mov rdx, [hPen_anterior]
	call SelectObject
	mov rcx, [hPen_triangulo]
	call DeleteObject

	
	pop r15

	mov rsp, rbp	
	pop rbp

	ret

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


%define GENERIC_READ 10000000000000000000000000000000b   ;si lo lee en little endian esto esta mal, deberia valer 1 nomas
%define GENERIC_WRITE 01000000000000000000000000000000b   
%define INVALID_HANDLE_VALUE -1	
%define OPEN_EXISTING 3
%define CREATE_ALWAYS 2
%define FILE_ATTRIBUTE_NORMAL 0x80


	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 32

;_______Recupero el argumento del command line

	call Rescatar_Argumentos
	
;_______Abrimos el archivo

	mov rcx, rax
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

;;;;;;;;;;;;;; CHEQUEAR;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	mov rcx, r13
;	call HeapDestroy  ; El HeapFree también se me cuelga, por qué?
;	xor r13,r13
;	xor r14,r14
;	xor r15,r15


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
	mov rbx, 36      
	div rbx
	mov [cantidad_triangulos_objeto], rax


	
	xor rbx,rbx
	xor rax,rax
	xor rdx,rdx

;_______Ahora sí, dada la cantidad de triángulos, sólo necesito multiplicarlos por el tamaño de cada triángulo de los míos
;	y tengo el espacio para cuatro coordenadas más el color. Luego el resultado habrá que multiplicarlo
;	por dos para obtener el inicial y el transformado. Así que multiplicamos por TRIANGULO_size*2 y listo.

	mov eax, [cantidad_triangulos_objeto]
	mov ebx, (TRIANGULO_size*2) 		
	mul ebx 
	mov ebx, eax 				; el resultado es rdx:rax pero creo que ni hace falta tomar rdx


	; IMPORTANTE!! la reserva de memoria de los triangulos a rasterizar va a estar separada, porque aun
	; queda el temita del clipping, y de hasta ver si se rasterizan o no, y quizás de un millón se 
	; rasterizan menos o al reves, de 50 se rasterizan más por el clipping.


	call GetProcessHeap
	mov [handle_heap_objeto3d], rax   	; me lo guarrrrdo
	mov rcx, rax
	mov rdx, 8       			;esto hace que limpie la memoria allocateada (?
	mov r8d, ebx			 	;acá va la cantidad de bytes
	
	call HeapAlloc
	mov [puntero_objeto3d_original], rax

;	ATENCION : Es posible que acá necesite sumar más, tipo objeto_3d_camara y objeto_3d_proyeccion, o algo así
;	pero hacerlo sobre la marcha cuando se necesite.


;_______Ahora calculo donde debería estar el proyectado

	xor rbx, rbx
	mov eax, [cantidad_triangulos_objeto]
	mov ebx, TRIANGULO_size 				
	mul ebx 
	mov ebx, eax 				; el resultado es rdx:rax pero creo que ni hace falta tomar rdx
	mov rax, [puntero_objeto3d_original]
	add rax, rbx
	mov [puntero_objeto3d_mundo], rax

	;Si necesito agregar más necesito alojar más memoria (multiplicar TRIANGULO_size por 3 y no por 2, por ejemplo)
	;y TRIANGULO_sizex0 seria el offset del primero, TRIANGULO_sizex1 el del segundo, TRIANGULO_sizex3 el del tercero y así


;_______Leemos el archivo, pero solo tenemos que leer los primero 12 bytes y luego agregar 4 bytes como = 0x3f800000
;	para introducir la coordenada "w" igual a 1. Así que vamos a tener que hacer un loop.


	push r15
	push r14
	push r13

	xor rax,rax
	mov r15, [cantidad_triangulos_objeto] 
	mov r14, [puntero_objeto3d_original]
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

	add r14, 4 ; muevo dos bytes extra para ir al offset del color
	mov edx, 0xB0DAF0
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






