%define puntero_triangulo_a_pintar      RBP - 96 	    ; 8 bytes
%define Pintar.hWnd 	  	 	RBP - 88            ; 8 bytes
%define ps                  		RBP - 80            ; PAINTSTRUCT structure. 72 bytes
%define ps.hdc              		RBP - 80            ; 8 bytes. Start on an 8 byte boundary
%define ps.fErase           		RBP - 72            ; 4 bytes
%define ps.rcPaint.left     		RBP - 68            ; 4 bytes
%define ps.rcPaint.top      		RBP - 64            ; 4 bytes
%define ps.rcPaint.right    		RBP - 60            ; 4 bytes
%define ps.rcPaint.bottom   		RBP - 56            ; 4 bytes
%define ps.Restore          		RBP - 52            ; 4 bytes
%define ps.fIncUpdate       		RBP - 48            ; 4 bytes
%define ps.rgbReserved      		RBP - 44            ; 32 bytes
%define ps.Padding          		RBP - 12            ; 4 bytes. Structure length padding
%define hdc                 		RBP - 8             ; 8 bytes


;--------------------------------------------------------------------

Pintar_WMPAINT:


;; esto esta copiado tal cual está en 3D_pruebas con el agregado de Pintar_Triangulo_Vertices nada más

	push rbp
	mov rbp,rsp
	sub rsp, SHADOWSPACE + 256 ; hay 8*10 parametros, ojo

	push r13

	mov [Pintar.hWnd], rcx
	mov [puntero_triangulo_a_pintar], rdx	

;---------------

	mov   rcx, qword [Pintar.hWnd]                        
	lea   rdx, [ps]                                
 	call  BeginPaint

	mov rcx, [ps.hdc]
	call CreateCompatibleDC
	mov [hdcBuffer],rax
		
	mov rcx, [hdcBuffer]
	mov rdx, [hBitmap]
	call SelectObject
	mov [hbmOld], rax

	mov rcx, [ps.hdc]
	call CreateCompatibleDC
	mov [hdcMem], rax

	mov rcx, [hdcMem]
	mov rdx, [hbitmap_pantalla]    ;; DE DONDE SALIO ESTE
	call SelectObject
	mov [hbmOld], rax		

	mov  rcx, [hdcBuffer]
	lea  rdx, [ps.rcPaint.left]
	mov  r8, [BackgroundBrush]
	call FillRect

;_______Limpio el Depth Buffer

	call Limpiar_Depth_Buffer


;_______Armo la rasterización


	mov r13,0


.loop1:

	cmp dword r13d, [array_rasterizacion+ARRAY_DINAMICO__cantidad_elementos]
	jae .fin_loop1 

	xor rdx,rdx
	xor rcx,rcx
	mov rax, TRIANGULO_size
	mul r13
	
	mov rcx, [puntero_triangulo_a_pintar]
	add rcx, rax
	call Rasterizar_Triangulo 

	inc r13
	jmp .loop1



.fin_loop1:

;_______Bliteo

	mov rcx, [hdcBuffer]
	mov rdx, 0;10
	mov r8, 0;10
	mov r9, ANCHO_PANTALLA
	mov qword [rsp + 4*8], ALTO_PANTALLA
	mov rax, [hdcMem]
	mov qword [rsp + 5*8], rax 
	mov qword [rsp + 6*8], 0
	mov qword [rsp + 7*8], 0
	mov qword [rsp + 9*8], 0x00cc0020 ;SCRCOPY
	call BitBlt
	

 
 	mov rcx, [ps.hdc]     
    	mov rdx, 0
    	mov r8, 0
    	mov r9, ANCHO_PANTALLA
    	mov qword [RSP + 4 * 8], ALTO_PANTALLA
    	mov rax, [hdcBuffer]
    	mov qword [RSP + 5 * 8], rax
    	mov qword [RSP + 6 * 8], 0
    	mov qword [RSP + 7 * 8], 0
    	mov qword [RSP + 8 * 8], 0x00CC0020; SCRCOPY
 	call BitBlt


 	;SelectObject(hdcMem, hbmOld);
	mov rcx, [hdcMem]
	mov rdx, [hbmOld]
	call SelectObject
	

    	;DeleteDC(hdcMem);
	mov rcx, [hdcMem]
	call DeleteDC


    	;SelectObject(hdcBuffer, hbmOldBuffer);
	mov rcx, [hdcBuffer]
	mov rdx, [hbmOldBuffer]
	call SelectObject

    	;DeleteDC(hdcBuffer);
	mov rcx, [hdcBuffer]
	call DeleteDC
   

 	;DeleteObject(hbmBuffer);
	mov rcx, [hbmBuffer]
	call DeleteObject

 	mov   rcx, qword [Pintar.hWnd]                        
 	lea   rdx, [ps]                                
 	call  EndPaint



	pop r13

	mov rsp, rbp
	pop rbp

	ret


;------------------------------------------------------------------------------

Limpiar_Depth_Buffer:

	; Simplemente es un bucle para llenar el Depth Buffer a cero

	mov rax, ANCHO_PANTALLA
	mov rdx, ALTO_PANTALLA
	mul rdx
	xor rdx,rdx
	mov r8d, 0x7f800000;infinito   
	mov r9, zbuffer

.loop_relleno:

	mov [r9], r8d	
	add r9, 4 ; tamaño del dword
	
	inc rdx
	
	cmp rdx, rax
	jb .loop_relleno

	ret

;------------------------------------------------------------------------------

Rasterizar_Triangulo:


	; rcx = el puntero del triangulo a rasterizar

%define valor_x_zbuffer		rbp - 152	; 4 bytes
%define valor_z			rbp - 148	; 4 bytes
%define valor_y_zbuffer		rbp - 144 	; 4 bytes
%define incremento_w2		rbp - 140	; 4 bytes
%define incremento_w1		rbp - 136	; 4 bytes
%define valor_zbuffer		rbp - 132	; 4 bytes
%define w_inicial		rbp - 128	; 4 bytes
%define w_final			rbp - 124 	; 4 bytes
%define w_actual		rbp - 120	; 4 bytes
%define delta_w2		rbp - 116	; 4 bytes
%define delta_w1		rbp - 112	; 4 bytes
%define n_lado_b		rbp - 108	; 4 bytes
%define n_lado_a		rbp - 104	; 4 bytes
%define fila_actual		rbp - 100	; 4 bytes
%define incremento_t		rbp - 96	; 4 bytes
%define parametro_t		rbp - 92	; 4 bytes
%define incremento_b		rbp - 88 	; 4 bytes
%define incremento_a		rbp - 84	; 4 bytes
%define delta_y2		rbp - 80	; 4 bytes
%define delta_y1		rbp - 76	; 4 bytes
%define delta_x2		rbp - 72	; 4 bytes
%define delta_x1		rbp - 68 	; 4 bytes
%define triangulo 		rbp - 64    	; 64 bytes ; TRIANGULO_size
	
	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 256
	push rbx
	push r11
	push r15


	mov r15, rcx


	
;_______Agarro los tres puntos del triángulo y los ordeno por sus "y" de menor a mayor, 
;	es decir desde el que está más arriba de la pantalla hasta el más abajo.

	; Primero rescato los punteros de cada vertice

	lea rax, [r15+TRIANGULO__vertice1]
	lea rbx, [r15+TRIANGULO__vertice2]
	lea rdx, [r15+TRIANGULO__vertice3]

	; Y también los valores de "Y" de cada uno

	mov r8d, [r15+TRIANGULO__vertice1+VERTICE__y]
	mov r9d, [r15+TRIANGULO__vertice2+VERTICE__y]
	mov r10d, [r15+TRIANGULO__vertice3+VERTICE__y]


	; Meto el menor en rax, seguido de rbx y luego en rdx
	; Hago las comparaciones y voy mudando tanto los valores de los punteros como los de "Y"

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

	; Ya los tengo ordenados en rax, rbx y rdx. Utilizo los punteros para guardar
	; los valores de "x", "y", "z" y "w"  (16 bits en total, en dos partes)
	
	mov r10, [rax]
	mov [triangulo+TRIANGULO__vertice1+VERTICE__x], r10
	add rax, 8 ; VERTICE__z  
	mov r10, [rax]
	mov [triangulo+TRIANGULO__vertice1+VERTICE__z], r10

	mov r10, [rbx]
	mov [triangulo+TRIANGULO__vertice2+VERTICE__x], r10
	add rbx, 8 ; VERTICE__z 
	mov r10, [rbx]
	mov [triangulo+TRIANGULO__vertice2+VERTICE__z], r10

	mov r10, [rdx]
	mov [triangulo+TRIANGULO__vertice3+VERTICE__x], r10
	add rdx, 8 ; VERTICE__z 
	mov r10, [rdx]
	mov [triangulo+TRIANGULO__vertice3+VERTICE__z], r10



;_______Ahora están todos ordenados, y les llamaré "y1", "y2" e "y3" (menor a mayor). Mi objetivo ahora
;	es pintar el triángulo con segmentos horizontales, de arriba para abajo. Para ello, necesito saber desde dónde
;	parten cada uno de esos segmentos y dónde terminan. La idea entonces es dividir el triángulo en dos partes: corto
;	el triángulo con una linea horizontal que va desde "y2" a su lado opuesto, y obtengo entonces un triángulo superior
;	y otro inferior. Para el superior saco dos interpolaciones: una desde "y1" a "y2" y otra desde "y1" hasta "y3". 
;	Itero desde y1 hasta y2 y evaluó ambas interpolaciiones con esa iteración para sacar los puntos de partida y 
;	los de llegada de cada segmento. Para la otra parte del triángulo, saco una interpolación entre "y2" e "y3" y
;	utilizo la segunda interpolación del proceso anterior. Esto funciona con cualquier tipo de triángulo. 


	; Preparo los delta de las interpolaciones lineales que van a formar las pendientes de las rectas
	; Los nombres son "delta_y1" y "delta_x1" para la primera interpolación, y "delta_y2" y "delta_x2" para la segunda,
	; tal como se explica arriba.
	
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

	fld dword [triangulo+TRIANGULO__vertice2+VERTICE__w]
	fld dword [triangulo+TRIANGULO__vertice1+VERTICE__w]
	fsubp
	fstp dword [delta_w1]

	fld dword [triangulo+TRIANGULO__vertice3+VERTICE__w]
	fld dword [triangulo+TRIANGULO__vertice1+VERTICE__w]
	fsubp
	fstp dword [delta_w2]

	xor rax,rax
	mov [incremento_w1], eax
	mov [incremento_w2], eax
		
	
;_______Ahora calculo los incrementos (pendiente de la recta, que recordemos que es su derivada) y esto
;	se hace dividiento los "delta X" por los "delta Y"  ya que la variable independiente acá es Y, no X.
;	Sin embargo puede pasar que los delta Y me den cero, lo que significa que los vértices están a la misma
;	altura. En ese caso no dibujo nada en esa división del triángulo, pero debo chequearlo para evitar 
;	divisiones por cero.

; 	IMPORTANTE: Etiqueto el código con 1 y 2 al final para referirme a la parte superior e
; 	inferior del triángulo.


	cmp dword [delta_y1], 0
	je .fin_condicion_delta_y1_cero_1

	fild dword [delta_x1]
	fild dword [delta_y1]
	fabs
	fdivp
	fstp dword [incremento_a]

	fld dword [delta_w1]
	fild dword [delta_y1]
	fabs
	fdivp
	fstp dword [incremento_w1]

	
.fin_condicion_delta_y1_cero_1:	


	cmp dword [delta_y2], 0
	je .fin_condicion_delta_y2_cero_1	


	fild dword [delta_x2]
	fild dword [delta_y2]
	fabs
	fdivp
	fstp dword [incremento_b]


	fld dword [delta_w2]
	fild dword [delta_y2]
	fabs
	fdivp
	fstp dword [incremento_w2]


.fin_condicion_delta_y2_cero_1:	

	
	; Verifico si los incrementos son iguales. Si lo son, no hay nada que dibujar

	mov eax, [incremento_a] 
	cmp eax, dword [incremento_b]
	je .fin_cond_1  
	

;_______Ahora vienen los loops de relleno, en el cual itero usando las interpolaciones para sacar los 
; 	extremos de cada segmento que rellena el triángulo.


	; Verifico otra vez que y1 e y2 no sean iguales, porque si lo son no hay nada que dibujar.
	
	cmp dword [delta_y1], 0
	je .fin_cond_1

	; Preparo la iteración, que va de y1 hasta y2

	mov ebx, [triangulo+TRIANGULO__vertice1+VERTICE__y]
	mov eax, 0

align 16	
.loop_iterar_filas_1:

	; "fila_actual" es la iteración que representa cada segmento
	
	mov [fila_actual], ebx

	; Primera interpolación entre y1 e y2. Con esto saco el inicio del segmento ("n_lado_a")

	fild dword [triangulo+TRIANGULO__vertice1+VERTICE__x]
	fild dword [fila_actual]
	fild dword [triangulo+TRIANGULO__vertice1+VERTICE__y]
	fsubp
	fld dword [incremento_a]
	fmulp
	faddp
	fistp dword [n_lado_a]

	; Segunda interpolación entre y1 e y3. Con esto saco el final del segmento ("n_lado_a")

	fild dword [triangulo+TRIANGULO__vertice1+VERTICE__x]
	fild dword [fila_actual]
	fild dword [triangulo+TRIANGULO__vertice1+VERTICE__y]
	fsubp
	fld dword [incremento_b]
	fmulp
	faddp
	fistp dword [n_lado_b]

	; Primera interpolación para sacar el w inicial

	fld dword [triangulo+TRIANGULO__vertice1+VERTICE__w]
	fild dword [fila_actual]
	fild dword [triangulo+TRIANGULO__vertice1+VERTICE__y]
	fsubp
	fld dword [incremento_w1]
	fmulp
	faddp
	fstp dword [w_inicial]

	; Segunda interpolación para sacar el w final


	fld dword [triangulo+TRIANGULO__vertice1+VERTICE__w]
	fild dword [fila_actual]
	fild dword [triangulo+TRIANGULO__vertice1+VERTICE__y]
	fsubp
	fld dword [incremento_w2]
	fmulp
	faddp
	fstp dword [w_final]



	
	; Pero existe un problema: el triángulo puede estar formado de manera tal que lo que 
	; saqué con la primera interpolación sea el final del segmento y lo que saqué con la segunda
	; interpolación sea el inicio del segmento. Por eso, tengo que verificar cual es el menor (el inicio)
	; y cual es el mayor (el final) ya que lo voy a llenar de izquierda a derecha. Si están al revés, los cambio
		

	mov r8d, [n_lado_a]
	mov r9d, [n_lado_b]
	cmp r8d, r9d
	cmovg r10d, r9d          
	cmovg r9d, r8d
	cmovg r8d, r10d
	mov [n_lado_a], r8d
	mov [n_lado_b], r9d

	; Aprovecho el flag y conmuto el w_inicial y el w_final 

	mov r8d, [w_inicial]
	mov r9d, [w_final]
	cmovg r10d, r9d          
	cmovg r9d, r8d
	cmovg r8d, r10d
	mov [w_inicial], r8d
	mov [w_actual], r8d
	mov [w_final], r9d
	



	; Listo! ahora itero entre "n_lado_a" y "n_lado_b" para pintar el segmento


	fld1
	fild dword [n_lado_b]
	fild dword [n_lado_a]
	fsubp
	fdivp
	fstp dword [incremento_t]
	xor r9,r9
	mov [parametro_t], r9d
	
	
	mov r11d, [n_lado_a]
	mov [valor_y_zbuffer], ebx  ; para el ZBuffer

align 16	
.loop_pintar_segmento_1:


;_______Loop principal de rasterización (scanlines)

	; Recupero el offset de memoria del zbuffer	

	mov [valor_x_zbuffer], r11d

	mov ecx, r11d
	mov edx, ebx
	call Pixel_a_Offset_de_Memoria
	mov rcx, zbuffer
	add rcx, rax
	mov edx, [rcx]               
	mov [valor_zbuffer], edx

	mov r8, [puntero_DIB]
	add r8, rax


	; Ahora cargo el valor de w a comparar con el zbuffer

	fld1
	fld dword [parametro_t]
	fsubp
	fld dword [w_inicial]
	fmulp
	fld dword [parametro_t]
	fld dword [w_final]
	fmulp
	faddp
	fst dword [w_actual]

	; Ya tengo el Z' en st0

	fld dword [valor_zbuffer]
	fcomip
	fstp st0
	

	; Cargo el valor al depth buffer

	mov edx, [rcx]
	cmova edx, [w_actual] 
	mov [rcx], edx
	
	; Pinto el pixel si se cumple la condición, y sino repinto con el anterior
	; así lo hago branchless

	mov eax, [r8]
	cmova eax, [r15+TRIANGULO__color]
	mov [r8], eax


	fld dword [parametro_t]
	fld dword [incremento_t]
	faddp
	fstp dword [parametro_t]

	inc r11d
	cmp r11d, [n_lado_b]
	jbe .loop_pintar_segmento_1
	
	inc ebx
	cmp ebx, [triangulo+TRIANGULO__vertice2+VERTICE__y]
	jbe .loop_iterar_filas_1	
	 


.fin_cond_1:




;_______Ahora tenemos que hacer lo mismo con la parte inferior del triángulo, con la diferencia de que 
;	la pendiente de la segunda interpolación ya la tengo. Solo necesito sacar los datos de la primera
;	interpolación


	xor rax, rax
	
	mov eax, [triangulo+TRIANGULO__vertice3+VERTICE__y]
	sub eax, [triangulo+TRIANGULO__vertice2+VERTICE__y]
	mov [delta_y1], eax

	mov eax, [triangulo+TRIANGULO__vertice3+VERTICE__x]
	sub eax, [triangulo+TRIANGULO__vertice2+VERTICE__x]
	mov [delta_x1], eax


	fld dword [triangulo+TRIANGULO__vertice3+VERTICE__w]
	fld dword [triangulo+TRIANGULO__vertice2+VERTICE__w]
	fsubp
	fstp dword [delta_w1]



;_______Ahora calculo los deltas

	cmp dword [delta_y1], 0
	je .fin_condicion_delta_y1_cero_2
	fild dword [delta_x1]
	fild dword [delta_y1]
	fabs
	fdivp
	fstp dword [incremento_a]

	fld dword [delta_w1]
	fild dword [delta_y1]
	fabs
	fdivp
	fstp dword [incremento_w1]


.fin_condicion_delta_y1_cero_2:

	cmp dword [delta_y2], 0
	je .fin_condicion_delta_y2_cero_2
	fild dword [delta_x2]
	fild dword [delta_y2]
	fabs
	fdivp
	fstp dword [incremento_b]


.fin_condicion_delta_y2_cero_2: 	


	; Verifico si los incrementos son iguales. Si lo son, no hay nada que dibujar

	mov eax, [incremento_a] 
	cmp eax, dword [incremento_b]
	je .fin_cond_2  


	; Ahora vienen los loops de relleno

	cmp dword [delta_y1], 0
	je .fin_cond_2

	mov ebx, [triangulo+TRIANGULO__vertice2+VERTICE__y]

align 16	
.loop_iterar_filas_2:
	
	mov [fila_actual], ebx


	; Armo las interpolaciones de x

	fild dword [triangulo+TRIANGULO__vertice2+VERTICE__x]
	fild dword [fila_actual]
	fild dword [triangulo+TRIANGULO__vertice2+VERTICE__y]
	fsubp
	fld dword [incremento_a]
	fmulp
	faddp
	fistp dword [n_lado_a]

	fild dword [triangulo+TRIANGULO__vertice1+VERTICE__x]
	fild dword [fila_actual]
	fild dword [triangulo+TRIANGULO__vertice1+VERTICE__y]
	fsubp
	fld dword [incremento_b]
	fmulp
	faddp
	fistp dword [n_lado_b]
		

	; Primera interpolación para sacar el w inicial

	fld dword [triangulo+TRIANGULO__vertice2+VERTICE__w]
	fild dword [fila_actual]
	fild dword [triangulo+TRIANGULO__vertice2+VERTICE__y]
	fsubp
	fld dword [incremento_w1]
	fmulp
	faddp
	fstp dword [w_inicial]

	; Segunda interpolación para sacar el w final


	fld dword [triangulo+TRIANGULO__vertice1+VERTICE__w]
	fild dword [fila_actual]
	fild dword [triangulo+TRIANGULO__vertice1+VERTICE__y]
	fsubp
	fld dword [incremento_w2]
	fmulp
	faddp
	fstp dword [w_final]


	

	; Si n_lado_a es mayor que n_lado_b, los conmuto porque
	; sino no voy a poder rasterizar de izquierda a derecha

	mov r8d, [n_lado_a]
	mov r9d, [n_lado_b]
	cmp r8d, r9d
	cmovg r10d, r9d          
	cmovg r9d, r8d
	cmovg r8d, r10d
	mov [n_lado_a], r8d
	mov [n_lado_b], r9d

	; Aprovecho el flag y conmuto el w_inicial y el w_final 

	mov r8d, [w_inicial]
	mov r9d, [w_final]
	cmovg r10d, r9d          
	cmovg r9d, r8d
	cmovg r8d, r10d
	mov [w_inicial], r8d
	mov [w_actual], r8d
	mov [w_final], r9d

	; Cargo los datos de parametro t y su incremento

	fld1
	fild dword [n_lado_b]
	fild dword [n_lado_a]
	fsubp
	fdivp
	fstp dword [incremento_t]
	xor r9,r9
	mov [parametro_t], r9d
	
	mov r11d, [n_lado_a]
	mov [valor_y_zbuffer], ebx  ; para el ZBuffer

align 16	
.loop_pintar_segmento_2:


;_______Loop principal de rasterización (scanlines), parte 2

	; Recupero el offset de memoria del zbuffer	

	mov [valor_x_zbuffer], r11d

	mov ecx, r11d
	mov edx, ebx
	call Pixel_a_Offset_de_Memoria
	mov rcx, zbuffer
	add rcx, rax
	mov edx, [rcx]               
	mov [valor_zbuffer], edx

	mov r8, [puntero_DIB]
	add r8, rax


	; Ahora cargo el valor de w a comparar con el zbuffer

	fld1
	fld dword [parametro_t]
	fsubp
	fld dword [w_inicial]
	fmulp
	fld dword [parametro_t]
	fld dword [w_final]
	fmulp
	faddp
	fst dword [w_actual]

	; Ya tengo el Z' en st0

	fld dword [valor_zbuffer]
	fcomip
	fstp st0
	

	; Cargo el valor al depth buffer

	mov edx, [rcx]
	cmova edx, [w_actual] 
	mov [rcx], edx
	
	; Pinto el pixel si se cumple la condición, y sino repinto con el anterior
	; así lo hago branchless

	mov eax, [r8]
	cmova eax, [r15+TRIANGULO__color]
	mov [r8], eax

	fld dword [parametro_t]
	fld dword [incremento_t]
	faddp
	fstp dword [parametro_t]



	inc r11d
	cmp r11d, [n_lado_b]
	jbe .loop_pintar_segmento_2

	
	inc ebx
	cmp ebx, [triangulo+TRIANGULO__vertice3+VERTICE__y]
	jbe .loop_iterar_filas_2	
	 


.fin_cond_2:



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

	



;;;;;;;;;; BASURA ;;;;;;;;;;;;;;;;;;;

; del zbuffer

;;;;;;;;;;;;;;;;;; Lo armo según wikipedia ;;;;;;;;;;;;;;;;;
;
; OJO!! aca falta interpolar Z. Estoy todo haciendolo bajo un Z 
;
;1.00020002 + 1/z * (-0.200020002)
;0x3f80068e           0xbe4cd20b
;
;
;

;mov edx, 0x3f80068e
;mov [valor_z], edx   ; dice valor z pero son los far y near
;fld dword [valor_z]
;mov edx, 0xbe4cd20b  
;mov [valor_z], edx   ; idem
;fld dword [valor_z]
;
;fld1
;fld dword [triangulo+TRIANGULO__vertice1+VERTICE__z]
;
;fdivp
;fmulp
;faddp
;fst dword [valor_z]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

