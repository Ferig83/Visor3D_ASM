;--------------------------------------------------------------------
;--- FUNCIONES ------------------------------------------------------
;--------------------------------------------------------------------


Limpiar_ZBuffer:

	mov rax, ANCHO_PANTALLA
	mov rdx, ALTO_PANTALLA
	mul rdx
	xor rdx,rdx
	mov r8d, 0x7f800000
	mov r9, [zbuffer]

.loop_relleno:

	mov [r9], r8d	

	inc rdx
	add r9, 4 ; tamaño del dword
	
	cmp rdx, rax
	jb .loop_relleno

	ret

;------------------------------------------------------------------------------

Rasterizar_Triangulo:


	; rcx = el puntero del triangulo a rasterizar

%define n_lado_b		rbp - 108	; 4 bytes
%define n_lado_a		rbp - 104	; 4 bytes
%define n_actual		rbp - 100	; 4 bytes
%define t_step			rbp - 96	; 4 bytes
%define parametro_t		rbp - 92	; 4 bytes
%define dbx_step		rbp - 88 	; 4 bytes
%define dax_step		rbp - 84	; 4 bytes
%define delta_y2		rbp - 80	; 4 bytes
%define delta_y1		rbp - 76	; 4 bytes
%define delta_x2		rbp - 72	; 4 bytes
%define delta_x1		rbp - 68 	; 4 bytes
%define triangulo 		rbp - 64    	; 64 bytes ; TRIANGULO_size
	
	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 160
	push rbx
	push r11
	push r15


	mov r15, rcx


;;;;;;;;;TEST;;;

;	mov eax, 30
;	mov [r15+TRIANGULO__vertice1+VERTICE__x], eax
;	mov eax, 30
;	mov [r15+TRIANGULO__vertice1+VERTICE__y], eax
;	mov eax, 10
;	mov [r15+TRIANGULO__vertice2+VERTICE__x], eax
;	mov eax, 60
;	mov [r15+TRIANGULO__vertice2+VERTICE__y], eax
;	mov eax, 60
;	mov [r15+TRIANGULO__vertice3+VERTICE__x], eax
;	mov eax, 60
;	mov [r15+TRIANGULO__vertice3+VERTICE__y], eax


;;;;;;;;;;;;;;;;



	
;_______Agarro los tres puntos del triángulo y los ordeno por sus "y" de menor a mayor

	; Muevo los "X" e "Y" completos en los registros de 64 y solo los "Y" en los de 32

	lea rax, [r15+TRIANGULO__vertice1+VERTICE__x]
	lea rbx, [r15+TRIANGULO__vertice2+VERTICE__x]
	lea rdx, [r15+TRIANGULO__vertice3+VERTICE__x]

	mov r8d, [r15+TRIANGULO__vertice1+VERTICE__y]
	mov r9d, [r15+TRIANGULO__vertice2+VERTICE__y]
	mov r10d, [r15+TRIANGULO__vertice3+VERTICE__y]






;_______Meto el que más arriba está en rax, seguido de rbx y luego en rdx

	; Ver si esto es lo más eficiente, porque quizás tanto evitar el "if" conlleva a un proceso más lento
	
	cmp r8d, r9d
	cmova r11, rax          
	cmova rax, rbx
	cmova rbx, r11
	cmova r11d, r8d          
	cmova r8d, r9d
	cmova r9d, r11d

	cmp r8d, r10d
	cmova r11, rax
	cmova rax, rdx
	cmova rdx, r11
	cmova r11d, r8d          
	cmova r8d, r10d
	cmova r10d, r11d

	cmp r9d, r10d
	cmova r11, rbx
	cmova rbx, rdx
	cmova rdx, r11
	cmova r11d, r9d          
	cmova r9d, r10d
	cmova r10d, r11d

	
	mov r10, [rax]
	mov [triangulo+TRIANGULO__vertice1+VERTICE__x], r10
	add rax, 8;VERTICE__z 
	mov r10, [rax]
	mov [triangulo+TRIANGULO__vertice1+VERTICE__z], r10

	mov r10, [rbx]
	mov [triangulo+TRIANGULO__vertice2+VERTICE__x], r10
	add rbx, 8;VERTICE__z 
	mov r10, [rbx]
	mov [triangulo+TRIANGULO__vertice2+VERTICE__z], r10

	mov r10, [rdx]
	mov [triangulo+TRIANGULO__vertice3+VERTICE__x], r10
	add rdx, 8;VERTICE__z 
	mov r10, [rdx]
	mov [triangulo+TRIANGULO__vertice3+VERTICE__z], r10










	
	; acá no estamos copiando el z, que más adelante va a ser importante, así 
	; que mepa que todo esto va a tener que cambiar. De hecho, no estaría mal
	; rotar los punteros de vertice1, vertico2 y vertice3 en vez de los valores


;_______Ahora están todos ordenados, pero pueden haber iguales o ser todos diferentes
;	así que verificamos.



	; Listo? ahí va (?
	

	xor rax, rax
	
	mov eax, [triangulo+TRIANGULO__vertice2+VERTICE__y]
	sub eax, [triangulo+TRIANGULO__vertice1+VERTICE__y]
	mov [delta_y1], eax

	mov eax, [triangulo+TRIANGULO__vertice2+VERTICE__x]
	sub eax, [triangulo+TRIANGULO__vertice1+VERTICE__x]
	mov [delta_x1], eax


	mov eax, [triangulo+TRIANGULO__vertice3+VERTICE__y]
	sub eax, [triangulo+TRIANGULO__vertice1+VERTICE__y]
	mov [delta_y2], eax

	mov eax, [triangulo+TRIANGULO__vertice3+VERTICE__x]
	sub eax, [triangulo+TRIANGULO__vertice1+VERTICE__x]
	mov [delta_x2], eax

	xor rax, rax
	mov [dax_step], eax
	mov [dbx_step], eax
	
	
;_______Ahora calculo los deltas


	cmp dword [delta_y1], 0
	je .delta_y1_es_cero_1
	fild dword [delta_x1]
	fild dword [delta_y1]
	fabs
	fdivp
	fstp dword [dax_step]

.delta_y1_es_cero_1:	


	cmp dword [delta_y2], 0
	je .delta_y2_es_cero_1
	fild dword [delta_x2]
	fild dword [delta_y2]
	fabs
	fdivp
	fstp dword [dbx_step]

.delta_y2_es_cero_1:	


	; Ahora vienen los loops de relleno

	cmp dword [delta_y1], 0
	je .fin_cond_1

	mov ebx, [triangulo+TRIANGULO__vertice1+VERTICE__y]
	mov eax, 0
	mov [parametro_t], eax	
	


.loop1:
	
	mov [n_actual], ebx

	fild dword [triangulo+TRIANGULO__vertice1+VERTICE__x]
	fild dword [n_actual]
	fild dword [triangulo+TRIANGULO__vertice1+VERTICE__y]
	fsubp
	fld dword [dax_step]
	fmulp
	faddp
	fistp dword [n_lado_a]

	fild dword [triangulo+TRIANGULO__vertice1+VERTICE__x]
	fild dword [n_actual]
	fild dword [triangulo+TRIANGULO__vertice1+VERTICE__y]
	fsubp
	fld dword [dbx_step]
	fmulp
	faddp
	fistp dword [n_lado_b]

		
	; Si n_lado_a  es mayor que n_lado_b, los conmuto porque
	; sino no voy a poder rasterizar de izquierda a derecha

	mov r8d, [n_lado_a]
	mov r9d, [n_lado_b]
	cmp r8d, r9d
	cmovg r10d, r9d          
	cmovg r9d, r8d
	cmovg r8d, r10d
	mov [n_lado_a], r8d
	mov [n_lado_b], r9d


	; Si son iguales irse porque vas a tener una división por cero abajo. Quizás no esté mal que 
	; de "infinito", pero por las dudas lo quito.


;	cmp r8d, r9d
;	je .fin_cond_1
	
	
	; Hago el recíproco de la pendiente

	fld1
	fild dword [n_lado_b]
	fild dword [n_lado_a]
	fsubp
	fdivp   
	fstp dword [t_step]

	mov r11d, [n_lado_a]

	
.pintar_linea_1:

	mov ecx, r11d
	mov edx, ebx	
	mov r8, r15
	call Pintar_Pixel

	inc r11d
	cmp r11d, [n_lado_b]
	jbe .pintar_linea_1
	
	inc ebx
	cmp ebx, [triangulo+TRIANGULO__vertice2+VERTICE__y]
	jbe .loop1	
	 
	fld dword [parametro_t]
	fld dword [t_step]
	faddp
	fstp dword [parametro_t]


.fin_cond_1:




;_______Ahora viene la otra parte, la que tiene la punta hacia abajo


	xor rax, rax
	
	mov eax, [triangulo+TRIANGULO__vertice3+VERTICE__y]
	sub eax, [triangulo+TRIANGULO__vertice2+VERTICE__y]
	mov [delta_y1], eax

	mov eax, [triangulo+TRIANGULO__vertice3+VERTICE__x]
	sub eax, [triangulo+TRIANGULO__vertice2+VERTICE__x]
	mov [delta_x1], eax

		
;_______Ahora calculo los deltas


	cmp dword [delta_y1], 0
	je .delta_y1_es_cero_2
	fild dword [delta_x1]
	fild dword [delta_y1]
	fabs
	fdivp
	fstp dword [dax_step]

.delta_y1_es_cero_2:	


	cmp dword [delta_y2], 0
	je .delta_y2_es_cero_2
	fild dword [delta_x2]
	fild dword [delta_y2]
	fabs
	fdivp
	fstp dword [dbx_step]

.delta_y2_es_cero_2:	

	; Ahora vienen los loops de relleno

	cmp dword [delta_y1], 0
	je .fin_cond_2

	mov ebx, [triangulo+TRIANGULO__vertice2+VERTICE__y]
	mov eax, 0
	mov [parametro_t], eax	
	
.loop2:
	
	mov [n_actual], ebx

	fild dword [triangulo+TRIANGULO__vertice2+VERTICE__x]
	fild dword [n_actual]
	fild dword [triangulo+TRIANGULO__vertice2+VERTICE__y]
	fsubp
	fld dword [dax_step]
	fmulp
	faddp
	fistp dword [n_lado_a]

	fild dword [triangulo+TRIANGULO__vertice1+VERTICE__x]
	fild dword [n_actual]
	fild dword [triangulo+TRIANGULO__vertice1+VERTICE__y]
	fsubp
	fld dword [dbx_step]
	fmulp
	faddp
	fistp dword [n_lado_b]
		
	
	; Si n_lado_a  es mayor que n_lado_b, los conmuto porque
	; sino no voy a poder rasterizar de izquierda a derecha

	mov r8d, [n_lado_a]
	mov r9d, [n_lado_b]
	cmp r8d, r9d
	cmovg r10d, r9d          
	cmovg r9d, r8d
	cmovg r8d, r10d
	mov [n_lado_a], r8d
	mov [n_lado_b], r9d

	; Si son iguales irse porque vas a tener una división por cero abajo. Quizás no esté mal que 
	; de "infinito", pero por las dudas lo quito.

;	cmp r8d, r9d
;	je .fin_cond_2
	
	
	; Hago el recíproco de la pendiente

	fld1
	fild dword [n_lado_b]
	fild dword [n_lado_a]
	fsubp
	fdivp   
	fstp dword [t_step]

	mov r11d, [n_lado_a]
	
.pintar_linea_2:

	mov ecx, r11d
	mov edx, ebx	
	mov r8, r15
	call Pintar_Pixel

	inc r11d
	cmp r11d, [n_lado_b]
	jbe .pintar_linea_2

	
	inc ebx
	cmp ebx, [triangulo+TRIANGULO__vertice3+VERTICE__y]
	jbe .loop2	
	 
	fld dword [parametro_t]
	fld dword [t_step]
	faddp
	fstp dword [parametro_t]


.fin_cond_2:



.test:


	pop r15
	pop r11
	pop rbx
	xor rax,rax
	mov rsp, rbp
	pop rbp
	ret






;------------------------------------------------------------------------------


Pintar_Pixel: 

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 32

	push rcx
	push rdx

	call Pixel_a_Offset_de_Memoria
	mov r8, [puntero_DIB]
	add r8, rax
	mov eax, [r15+TRIANGULO__color]
	mov dword [r8], eax


	pop rdx
	pop rcx
	
	mov rsp, rbp
	pop rbp
	ret



;------------------------------------------------------------------------------

Pixel_a_Offset_de_Memoria:

	; rcx = x
	; rdx = y

	; La formula es  4 [(x) + (y*(PADDING+ANCHO_PANTALLA))]
	; tomo como padding 0, luego vamos corrigiendo.

	mov rax, 0; PADDING
	add rax, ANCHO_PANTALLA
	mul edx
	add eax, ecx
	mov edx, 4
	mul edx
	ret

;------------------------------------------------------------------------------


Pintar_Triangulo_Vertices:


	; rcx: el puntero del triangulo a rasterizar

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE


	mov r8, rcx

	xor rcx, rcx
	xor rdx, rdx
	

	

	mov ecx, [r8+TRIANGULO__vertice1+VERTICE__x]
	mov edx, [r8+TRIANGULO__vertice1+VERTICE__y]
	call Pixel_a_Offset_de_Memoria
	mov r9, [puntero_DIB]
	add r9, rax
	mov dword [r9], 0x00FF0000
 

	mov ecx, [r8+TRIANGULO__vertice2+VERTICE__x]
	mov edx, [r8+TRIANGULO__vertice2+VERTICE__y]
	call Pixel_a_Offset_de_Memoria
	mov r9, [puntero_DIB]
	add r9, rax
	mov dword [r9], 0x00FF0000
 

	mov ecx, [r8+TRIANGULO__vertice3+VERTICE__x]
	mov edx, [r8+TRIANGULO__vertice3+VERTICE__y]
	call Pixel_a_Offset_de_Memoria
	mov r9, [puntero_DIB]
	add r9, rax
	mov dword [r9], 0x00FF0000
 

	mov rsp, rbp
	pop rbp

	ret


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
	add rax, TRIANGULO__vertice1+VERTICE__x
	mov edx, [rax]             
	mov rax, r15
	add rax, TRIANGULO__vertice1+VERTICE__y 
	mov r8d, [rax] 
	xor r9,r9
	call MoveToEx	

	mov rcx, rbx
	mov rax, r15
	add rax, TRIANGULO__vertice2+VERTICE__x
	mov edx, [rax]                         
	mov rax, r15		
	add rax, TRIANGULO__vertice2+VERTICE__y
	mov r8d, [rax]
	call LineTo

;--- Segunda Linea

	mov rcx, rbx
	mov rax, r15
	add rax, TRIANGULO__vertice2+VERTICE__x
	mov edx, [rax]             
	mov rax, r15
	add rax, TRIANGULO__vertice2+VERTICE__y 
	mov r8d, [rax] 
	xor r9,r9
	call MoveToEx	

	mov rcx, rbx
	mov rax, r15
	add rax, TRIANGULO__vertice3+VERTICE__x
	mov edx, [rax]                         
	mov rax, r15		
	add rax, TRIANGULO__vertice3+VERTICE__y
	mov r8d, [rax]
	call LineTo

;--- Tercera Linea
	
	mov rcx, rbx
	mov rax, r15
	add rax, TRIANGULO__vertice3+VERTICE__x
	mov edx, [rax]             
	mov rax, r15
	add rax, TRIANGULO__vertice3+VERTICE__y 
	mov r8d, [rax] 
	xor r9,r9
	call MoveToEx	

	mov rcx, rbx
	mov rax, r15
	add rax, TRIANGULO__vertice1+VERTICE__x
	mov edx, [rax]                         
	mov rax, r15		
	add rax, TRIANGULO__vertice1+VERTICE__y
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
	mov r8d, [r15+TRIANGULO__color]
	call CreatePen
	mov [hPen_triangulo], rax
	mov rcx, rbx
	mov rdx, rax
	call SelectObject
	mov [hPen_anterior] ,rax  ; la función devuelve el brush reemplazado (IQ 2000 de parte de Bill Gates)
	

	

	xor rcx,rcx
	mov ecx, [r15+TRIANGULO__color]
	call CreateSolidBrush
	mov [hBrush_color_triangulo], rax
 
	mov rcx, rbx
	mov rdx, rax
	call SelectObject
	mov [hBrush_anterior] ,rax 
	

	mov eax, [r15+TRIANGULO__vertice1+VERTICE__x]
	mov [puntos+PUNTOS__x_1], eax
	mov eax, [r15+TRIANGULO__vertice1+VERTICE__y]
	mov [puntos+PUNTOS__y_1], eax
	mov eax, [r15+TRIANGULO__vertice2+VERTICE__x]
	mov [puntos+PUNTOS__x_2], eax
	mov eax, [r15+TRIANGULO__vertice2+VERTICE__y]
	mov [puntos+PUNTOS__y_2], eax
	mov eax, [r15+TRIANGULO__vertice3+VERTICE__x]
	mov [puntos+PUNTOS__x_3], eax
	mov eax, [r15+TRIANGULO__vertice3+VERTICE__y]
	mov [puntos+PUNTOS__y_3], eax
	
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





