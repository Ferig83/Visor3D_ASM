 	
Inicializar_Matriz_Proyeccion:


	; en RCX va el puntero a la matriz a rellenar
	; en RDX va el puntero a la estructura PROYECCION con todos los valores
 
	%define angulo_vision rbp - 20		;  4 bytes
	%define znear rbp - 16			;  4 bytes
	%define zfar rbp - 12			;  4 bytes 
	%define matriz_ancho_pantalla rbp - 8	;  4 bytes  
	%define matriz_alto_pantalla rbp - 4 	;  4 bytes

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 32  ; 20 de pila y el resto alinea

;_______Muevo mis datos a la pila así libero el rdx

	mov eax, [rdx+PROYECCION__alto_pantalla]
	mov [matriz_alto_pantalla], eax
	mov eax, [rdx+PROYECCION__ancho_pantalla]
	mov [matriz_ancho_pantalla], eax
	mov eax, [rdx+PROYECCION__angulo_FOV]
	mov [angulo_vision], eax
	mov eax, [rdx+PROYECCION__z_far]
	mov [zfar], eax
	mov eax, [rdx+PROYECCION__z_near]
	mov [znear], eax



;_______Cargo los relativos al aspect ratio y el angulo FOV (field of view)

	; Divido el ángulo por dos, le saco la tangente y hago el recíproco
	
	fld dword [angulo_vision]
	fld1
	fld1
	faddp
	fdivp
	fptan
	fdivrp
	
	; Saco el aspect ratio (alto/ancho) y cargo los valores en la matriz

	fst dword [rcx+MATRIZ__22]
	fild dword [matriz_alto_pantalla]
	fild dword [matriz_ancho_pantalla]
	fdivp
	fmulp
	fstp dword [rcx+MATRIZ__11]
	
		

;_______Cargo los relativos a Zfar y ZNear

; -- Código para que Z esté entre 0 y 1

	fld dword [zfar]
	fld dword [zfar]
	fld dword [znear]
	fsubp
	fdivp
	fst dword [rcx+MATRIZ__33]
	fld dword [znear]
	fchs
	fmulp
	fstp dword [rcx+MATRIZ__43]




; -- Código para que Z esté entre -1 y 1
;	
;	fld dword [zfar]
;	fld dword [znear]
;	faddp
;	fld dword [zfar]
;	fld dword [znear]
;	fsubp
;	fdivp
;	fstp dword [rcx+MATRIZ__33]
;
;
;	fld dword [zfar]
;	fld dword [znear]
;	fmulp
;	fld dword [zfar]
;	fld dword [znear]
;	fsubp
;	fdivp
;	fchs
;	fld1
;	fld1
;	faddp
;	fmulp
;	fstp dword [rcx+MATRIZ__43]

;_______Cargo un 1 	
	
	fld1
	fstp dword [rcx+MATRIZ__34]

;_______Relleno con ceros el resto de las posiciones

	mov eax, 0
	mov [rcx+MATRIZ__12], eax
	mov [rcx+MATRIZ__13], eax
	mov [rcx+MATRIZ__14], eax
	mov [rcx+MATRIZ__21], eax
	mov [rcx+MATRIZ__23], eax
	mov [rcx+MATRIZ__24], eax
	mov [rcx+MATRIZ__31], eax
	mov [rcx+MATRIZ__32], eax
	mov [rcx+MATRIZ__41], eax
	mov [rcx+MATRIZ__42], eax
	mov [rcx+MATRIZ__44], eax

	%undef angulo_vision 
	%undef znear
	%undef zfar 
	%undef matriz_ancho_pantalla   
	%undef matriz_alto_pantalla 


	mov rsp, rbp
	pop rbp
		
	ret


Inicializar_Matriz_Rotacion_X:
	
	; En RCX va el puntero de la matriz a llenar
	; En EDX va el angulo en float 


	%define auxiliar rbp - 4 	; 4 bytes  (es para pasar de registro float a registro común)
	%define angulo rbp - 4 		; 4 bytes
	
	push rbp
	mov rbp, rsp	
	sub rsp, SHADOWSPACE + 32
	
	push rbx
	push r11


	mov [angulo], edx	

	fld dword [angulo]
	fcos
	fld dword [angulo]
	fsin
	fst dword [auxiliar]
	mov eax, [auxiliar]
	fchs
	fstp dword [auxiliar]
	mov r8d, [auxiliar]
	fstp dword [auxiliar]
	mov edx, [auxiliar]

	mov ebx, 0x00000000
	mov r11d, 0x3f800000

	; Con esto ahora tengo que 
	; En EDX va el coseno del angulo
	; En EAX va el seno del angulo
	; y en R8d va el -seno del angulo
	; ebx es 0
	; r11d es 1


	;Relleno la matriz
	
	mov [rcx+(MATRIZ__11)], r11d	; 1
	mov [rcx+(MATRIZ__21)], ebx	; 0
	mov [rcx+(MATRIZ__31)], ebx	; 0
	mov [rcx+(MATRIZ__41)], ebx	; 0

	mov [rcx+(MATRIZ__12)], ebx	; 0
	mov [rcx+(MATRIZ__22)], edx	; COS(tita) 
	mov [rcx+(MATRIZ__32)], r8d	; -SEN(tita)
	mov [rcx+(MATRIZ__42)], ebx	; 0
		
	mov [rcx+(MATRIZ__13)], ebx	; 0
	mov [rcx+(MATRIZ__23)], eax	; SEN(tita) 
	mov [rcx+(MATRIZ__33)], edx	; COS(tita)
	mov [rcx+(MATRIZ__43)], ebx	; 0
		
	mov [rcx+(MATRIZ__14)], ebx	; 0 
	mov [rcx+(MATRIZ__24)], ebx	; 0
	mov [rcx+(MATRIZ__34)], ebx	; 0
	mov [rcx+(MATRIZ__44)], r11d	; 1


	%undef auxiliar
	%undef angulo

	pop r11
	pop rbx

	mov rsp, rbp
	pop rbp
			
	ret
		


;----------------------------------------------------------------------------------------


Inicializar_Matriz_Rotacion_Y:
	
	; En RCX va el puntero de la matriz a llenar
	; En EDX va el angulo en float 


	%define auxiliar rbp - 4 	; 4 bytes  (es para pasar de registro float a registro común)
	%define angulo rbp - 4 		; 4 bytes
	
	push rbp
	mov rbp, rsp	
	sub rsp, SHADOWSPACE + 32
	
	push rbx
	push r11


	mov [angulo], edx	

	fld dword [angulo]
	fcos
	fld dword [angulo]
	fsin
	fst dword [auxiliar]
	mov eax, [auxiliar]
	fchs
	fstp dword [auxiliar]
	mov r8d, [auxiliar]
	fstp dword [auxiliar]
	mov edx, [auxiliar]

	mov ebx, 0x00000000
	mov r11d, 0x3f800000

	; Con esto ahora tengo que 
	; En EDX va el coseno del angulo
	; En EAX va el seno del angulo
	; y en R8d va el -seno del angulo
	; ebx es 0
	; r11d es 1


	;Relleno la matriz
	
	mov [rcx+(MATRIZ__11)], edx	; COS(tita) 
	mov [rcx+(MATRIZ__21)], ebx	; 0
	mov [rcx+(MATRIZ__31)], eax	; SEN(tita)
	mov [rcx+(MATRIZ__41)], ebx	; 0

	mov [rcx+(MATRIZ__12)], ebx	; 0
	mov [rcx+(MATRIZ__22)], r11d	; 1 
	mov [rcx+(MATRIZ__32)], ebx	; 0
	mov [rcx+(MATRIZ__42)], ebx	; 0
		
	mov [rcx+(MATRIZ__13)], r8d	; -SEN(tita)
	mov [rcx+(MATRIZ__23)], ebx	; 0 
	mov [rcx+(MATRIZ__33)], edx	; COS(tita)
	mov [rcx+(MATRIZ__43)], ebx	; 0
		
	mov [rcx+(MATRIZ__14)], ebx	; 0 
	mov [rcx+(MATRIZ__24)], ebx	; 0
	mov [rcx+(MATRIZ__34)], ebx	; 0
	mov [rcx+(MATRIZ__44)], r11d	; 1


	%undef auxiliar
	%undef angulo

	pop r11
	pop rbx

	mov rsp, rbp
	pop rbp
			
	ret
		





;----------------------------------------------------------------------------------------

Inicializar_Matriz_Rotacion_Z:
	
	; En RCX va el puntero de la matriz a llenar
	; En EDX va el angulo en float 


	%define auxiliar rbp - 4 	; 4 bytes  (es para pasar de registro float a registro común)
	%define angulo rbp - 4 		; 4 bytes
	
	push rbp
	mov rbp, rsp	
	sub rsp, SHADOWSPACE + 32
	
	push rbx
	push r11


	mov [angulo], edx	

	fld dword [angulo]
	fcos
	fld dword [angulo]
	fsin
	fst dword [auxiliar]
	mov eax, [auxiliar]
	fchs
	fstp dword [auxiliar]
	mov r8d, [auxiliar]
	fstp dword [auxiliar]
	mov edx, [auxiliar]

	mov ebx, 0x00000000
	mov r11d, 0x3f800000

	; Con esto ahora tengo que 
	; En EDX va el coseno del angulo
	; En EAX va el seno del angulo
	; y en R8d va el -seno del angulo
	; ebx es 0
	; r11d es 1


	;Relleno la matriz
	
	mov [rcx+(MATRIZ__11)], edx	; COS(tita) 
	mov [rcx+(MATRIZ__21)], r8d	; -SEN(tita)
	mov [rcx+(MATRIZ__31)], ebx	; 0
	mov [rcx+(MATRIZ__41)], ebx	; 0

	mov [rcx+(MATRIZ__12)], eax	; SEN(tita)
	mov [rcx+(MATRIZ__22)], edx	; COS(tita) 
	mov [rcx+(MATRIZ__32)], ebx	; 0
	mov [rcx+(MATRIZ__42)], ebx	; 0
		
	mov [rcx+(MATRIZ__13)], ebx	; 0
	mov [rcx+(MATRIZ__23)], ebx	; 0 
	mov [rcx+(MATRIZ__33)], r11d	; 1
	mov [rcx+(MATRIZ__43)], ebx	; 0
		
	mov [rcx+(MATRIZ__14)], ebx	; 0 
	mov [rcx+(MATRIZ__24)], ebx	; 0
	mov [rcx+(MATRIZ__34)], ebx	; 0
	mov [rcx+(MATRIZ__44)], r11d	; 1


	%undef auxiliar
	%undef angulo

	pop r11
	pop rbx

	mov rsp, rbp
	pop rbp
			
	ret
		




Inicializar_Matriz_Escalamiento:

	; en RCX va el puntero a la matriz
	; en edx el escalamiento en X
	; en r8d el escalamiento en Y
	; en r9d el escalamiento en Z
	
	

	push rbx
	push r11

	mov ebx, 0x00000000
	mov r11d, 0x3f800000
			
	mov [rcx+(MATRIZ__11)], edx  ; Sx
	mov [rcx+(MATRIZ__21)], ebx  ; 0
	mov [rcx+(MATRIZ__31)], ebx  ; 0
	mov [rcx+(MATRIZ__41)], ebx  ; 0

	mov [rcx+(MATRIZ__12)], ebx  ; 0
	mov [rcx+(MATRIZ__22)], r8d  ; Sy
	mov [rcx+(MATRIZ__32)], ebx  ; 0
	mov [rcx+(MATRIZ__42)], ebx  ; 0
		
	mov [rcx+(MATRIZ__13)], ebx  ; 0
	mov [rcx+(MATRIZ__23)], ebx  ; 0 
	mov [rcx+(MATRIZ__33)], r9d  ; Sz
	mov [rcx+(MATRIZ__43)], ebx  ; 0
		
	mov [rcx+(MATRIZ__14)], ebx  ; 0 
	mov [rcx+(MATRIZ__24)], ebx  ; 0
	mov [rcx+(MATRIZ__34)], ebx  ; 0
	mov [rcx+(MATRIZ__44)], r11d ; 1

	pop r11
	pop rbx


	ret



Inicializar_Matriz_Traslacion:


	; en RCX va el puntero a la matriz
	; en edx la traslacion en X
	; en r8d la traslacion en Y
	; en r9d la traslacion en Z

	push rbx
	push r11


	mov ebx, 0x00000000
	mov r11d, 0x3f800000

		
	mov [rcx+(MATRIZ__11)], r11d ; 1
	mov [rcx+(MATRIZ__21)], ebx  ; 0
	mov [rcx+(MATRIZ__31)], ebx  ; 0
	mov [rcx+(MATRIZ__41)], edx  ; Tx

	mov [rcx+(MATRIZ__12)], ebx  ; 0
	mov [rcx+(MATRIZ__22)], r11d ; 1 
	mov [rcx+(MATRIZ__32)], ebx  ; 0
	mov [rcx+(MATRIZ__42)], r8d  ; Ty
		
	mov [rcx+(MATRIZ__13)], ebx  ; 0
	mov [rcx+(MATRIZ__23)], ebx  ; 0 
	mov [rcx+(MATRIZ__33)], r11d ; 1
	mov [rcx+(MATRIZ__43)], r9d  ; Tz
		
	mov [rcx+(MATRIZ__14)], ebx  ; 0 
	mov [rcx+(MATRIZ__24)], ebx  ; 0
	mov [rcx+(MATRIZ__34)], ebx  ; 0
	mov [rcx+(MATRIZ__44)], r11d ; 1

	pop r11
	pop rbx


	ret


Inicializar_Matriz_Identidad:

	; en rcx el puntero de la matriz a inicializar

	mov eax, 0x00000000
	mov edx, 0x3f800000
		
	mov [rcx+(MATRIZ__11)], edx  ; 1
	mov [rcx+(MATRIZ__21)], eax  ; 0
	mov [rcx+(MATRIZ__31)], eax  ; 0
	mov [rcx+(MATRIZ__41)], eax  ; 0

	mov [rcx+(MATRIZ__12)], eax  ; 0
	mov [rcx+(MATRIZ__22)], edx  ; 1 
	mov [rcx+(MATRIZ__32)], eax  ; 0
	mov [rcx+(MATRIZ__42)], eax  ; 0
		
	mov [rcx+(MATRIZ__13)], eax  ; 0
	mov [rcx+(MATRIZ__23)], eax  ; 0 
	mov [rcx+(MATRIZ__33)], edx  ; 1
	mov [rcx+(MATRIZ__43)], eax  ; 0
		
	mov [rcx+(MATRIZ__14)], eax  ; 0 
	mov [rcx+(MATRIZ__24)], eax  ; 0
	mov [rcx+(MATRIZ__34)], eax  ; 0
	mov [rcx+(MATRIZ__44)], edx  ; 1

	ret


;--------------------------------------------------------------------


Inicializar_Matriz_Apuntar_Camara:

	; En rcx el puntero de la matriz donde van volcados los datos
	; En rdx el puntero de la cámara del vector que señala la parte de adelante
	; En r8 el puntero de la cámara del vector que señala donde está la parte de arriba
	; En r9 el puntero de la cámara del vector que da la posición


	%define vector_camara_derecha rbp - 16   ; 16 bytes

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 32

	push rbx

	; Hago el producto vectorial entre arriba y delante para sacar la derecha
 
	lea rbx, [vector_camara_derecha]
	
	fld dword [r8+VECTOR4__2]
	fld dword [rdx+VECTOR4__3]
	fmulp
	fld dword [r8+VECTOR4__3]
	fld dword [rdx+VECTOR4__2]
	fmulp
	fsubp
	fstp dword [rbx+VECTOR4__1]


	fld dword [r8+VECTOR4__3]
	fld dword [rdx+VECTOR4__1]
	fmulp
	fld dword [r8+VECTOR4__1]
	fld dword [rdx+VECTOR4__3]
	fmulp
	fsubp
	fstp dword [rbx+VECTOR4__2]


	fld dword [r8+VECTOR4__1]
	fld dword [rdx+VECTOR4__2]
	fmulp
	fld dword [r8+VECTOR4__2]
	fld dword [rdx+VECTOR4__1]
	fmulp
	fsubp
	fstp dword [rbx+VECTOR4__3]

	fld1
	fstp dword [rbx+VECTOR4__4]



	; Y ahora relleno la matriz como corresponde
	; r8 arriba, r9 posicion, rdx delante, rbx derecha


	mov eax, [rbx+VECTOR4__1]
	mov [rcx+(MATRIZ__11)], eax  ; coord x de vector de derecha

	mov eax, [r8+VECTOR4__1]
	mov [rcx+(MATRIZ__21)], eax  ; coord x de vector de arriba

	mov eax, [rdx+VECTOR4__1]
	mov [rcx+(MATRIZ__31)], eax  ; coord x de vector de delante

	mov eax, [r9+VECTOR4__1]
	mov [rcx+(MATRIZ__41)], eax  ; coord x de vector de posicion


	;;;;


	mov eax, [rbx+VECTOR4__2]
	mov [rcx+(MATRIZ__12)], eax  ; coord y de vector de derecha

	mov eax, [r8+VECTOR4__2]
	mov [rcx+(MATRIZ__22)], eax  ; coord y de vector de arriba

	mov eax, [rdx+VECTOR4__2]
	mov [rcx+(MATRIZ__32)], eax  ; coord y de vector de delante

	mov eax, [r9+VECTOR4__2]
	mov [rcx+(MATRIZ__42)], eax  ; coord y de vector de posicion


	;;;;
	

	mov eax, [rbx+VECTOR4__3]
	mov [rcx+(MATRIZ__13)], eax  ; coord z de vector de derecha

	mov eax, [r8+VECTOR4__3]	
	mov [rcx+(MATRIZ__23)], eax  ; coord z de vector de arriba

	mov eax, [rdx+VECTOR4__3]
	mov [rcx+(MATRIZ__33)], eax  ; coord z de vector de delante

	mov eax, [r9+VECTOR4__3]
	mov [rcx+(MATRIZ__43)], eax  ; coord z de vector de posicion
	

	;;;;


	mov eax, 0x00000000
	mov [rcx+(MATRIZ__14)], eax  ; 0

	mov eax, 0x00000000
	mov [rcx+(MATRIZ__24)], eax  ; 0

	mov eax, 0x00000000
	mov [rcx+(MATRIZ__34)], eax  ; 0


	mov eax, 0x3f800000
	mov [rcx+(MATRIZ__44)], eax  ; 1


	;;;;

	pop rbx

	%undef vector_camara_derecha 


	mov rsp, rbp
	pop rbp
	ret


;--------------------------------------------------------------------


Inicializar_Matriz_Capturar_Camara:


	; en rcx el puntero de la matriz apuntar camara
	; en rdx el puntero de la matriz capturar camara
	

	mov eax, [rdx+MATRIZ__11]
	mov [rcx+(MATRIZ__11)], eax  ; coord x de vector de derecha

	mov eax, [rdx+MATRIZ__12]
	mov [rcx+(MATRIZ__21)], eax  ; coord y de vector de derecha

	mov eax, [rdx+MATRIZ__13]
	mov [rcx+(MATRIZ__31)], eax  ; coord z de vector de derecha


	fld dword [rdx+MATRIZ__41] 
	fld dword [rcx+MATRIZ__11]
	fmulp
	fld dword [rdx+MATRIZ__42]
	fld dword [rcx+MATRIZ__21]
	fmulp
	fld dword [rdx+MATRIZ__43]
	fld dword [rcx+MATRIZ__31]
	fmulp 
	faddp
	faddp
	fchs
	fstp dword [rcx+(MATRIZ__41)]  ; Producto escalar de -POSICION . DERECHA

	;;;;


	mov eax, [rdx+MATRIZ__21]
	mov [rcx+(MATRIZ__12)], eax  ; coord x de vector de arriba

	mov eax, [rdx+MATRIZ__22]
	mov [rcx+(MATRIZ__22)], eax  ; coord y de vector de arriba

	mov eax, [rdx+MATRIZ__23]
	mov [rcx+(MATRIZ__32)], eax  ; coord z de vector de arriba

	fld dword [rdx+MATRIZ__41] 
	fld dword [rcx+MATRIZ__12]
	fmulp
	fld dword [rdx+MATRIZ__42]
	fld dword [rcx+MATRIZ__22]
	fmulp
	fld dword [rdx+MATRIZ__43]
	fld dword [rcx+MATRIZ__32]
	fmulp 
	faddp
	faddp
	fchs
	fstp dword [rcx+(MATRIZ__42)]  ; Producto escalar de -POSICION . ARRIBA



	;;;;
	

	mov eax, [rdx+MATRIZ__31]
	mov [rcx+(MATRIZ__13)], eax  ; coord x de vector de delante

	mov eax, [rdx+MATRIZ__32]	
	mov [rcx+(MATRIZ__23)], eax  ; coord y de vector de delante

	mov eax, [rdx+MATRIZ__33]
	mov [rcx+(MATRIZ__33)], eax  ; coord z de vector de delante


	fld dword [rdx+MATRIZ__41] 
	fld dword [rcx+MATRIZ__13]
	fmulp
	fld dword [rdx+MATRIZ__42]
	fld dword [rcx+MATRIZ__23]
	fmulp
	fld dword [rdx+MATRIZ__43]
	fld dword [rcx+MATRIZ__33]
	fmulp 
	faddp
	faddp
	fchs
	fstp dword [rcx+(MATRIZ__43)]  ; Producto escalar de -POSICION . DELANTE


	;;;;


	mov eax, 0x00000000
	mov [rcx+(MATRIZ__14)], eax  ; 0

	mov eax, 0x00000000
	mov [rcx+(MATRIZ__24)], eax  ; 0

	mov eax, 0x00000000
	mov [rcx+(MATRIZ__34)], eax  ; 0


	mov eax, 0x3f800000
	mov [rcx+(MATRIZ__44)], eax  ; 1


	ret


;--------------------------------------------------------------------

Multiplicar_Matriz_Matriz:



	; rcx = rcx * rdx     CUIDADO QUE LA MATRIZ EN RCX SE SOBREESCRIBE. 
	; es para transformaciones


;_______Este algoritmo no es el típico para multiplicar matrices. Creo que es más rápido
;	que el típico. La idea es cargar las filas de la segunda matriz, luego cargar
;	vectores con cada valor de A, repetidos (ej: si la posición a11 de A es 5, el vector es (5;5;5;5).
;	Multiplico y voy sumando. Teóricamente se requieren menos operaciones.
;
;	La anterior que hice con FPU está en los backups, en 3D_3. Si es más rápida esa, 
;	usar esa (me extrañaría).


	movaps xmm0, [rcx+MATRIZ__11]	 ; primera columna de A
	movss xmm1, [rdx+MATRIZ__11]	 ; Valor a11 de B 
	shufps xmm1, xmm1, 0x00    		 ; esto llena xmm1 con el valor de arriba
	mulps xmm1,xmm0		   		 ; Multiplico y queda lista para la suma.

	movss xmm2, [rdx+MATRIZ__12]	 ; Valor de a12 de B y se repite hasta llenar todas de xmm1 a xmm4 
	shufps xmm2, xmm2, 0x00    	
	mulps xmm2,xmm0		   
 
	movss xmm3, [rdx+MATRIZ__13]
	shufps xmm3, xmm3, 0x00    
	mulps xmm3,xmm0		   

	movss xmm4, [rdx+MATRIZ__14] 
	shufps xmm4, xmm4, 0x00    
	mulps xmm4,xmm4		   

;_______Ahora hago lo mismo con la segunda columna de A hasta llegar a la cuarta 
;	y voy sumando cada vez.

	movaps xmm0, [rcx+MATRIZ__12]
	movss xmm5, [rdx+MATRIZ__21]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm1,xmm5

	movss xmm5, [rdx+MATRIZ__22]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm2,xmm5

	movss xmm5, [rdx+MATRIZ__23]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm3,xmm5

	movss xmm5, [rdx+MATRIZ__24]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm4,xmm5
	

	movaps xmm0, [rcx+MATRIZ__13]
	movss xmm5, [rdx+MATRIZ__31]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm1,xmm5

	movss xmm5, [rdx+MATRIZ__32]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm2,xmm5

	movss xmm5, [rdx+MATRIZ__33]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm3,xmm5

	movss xmm5, [rdx+MATRIZ__34]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm4,xmm5
	
	movaps xmm0, [rcx+MATRIZ__14]
	movss xmm5, [rdx+MATRIZ__41]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm1,xmm5

	movss xmm5, [rdx+MATRIZ__42]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm2,xmm5

	movss xmm5, [rdx+MATRIZ__43]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm3,xmm5

	movss xmm5, [rdx+MATRIZ__44]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm4,xmm5
	
;_______Y ahora muevo todo a cada parte

	movaps [rcx+MATRIZ__11], xmm1
	movaps [rcx+MATRIZ__12], xmm2
	movaps [rcx+MATRIZ__13], xmm3
	movaps [rcx+MATRIZ__14], xmm4

	emms
	ret




;--------------------------------------------------------------------

Multiplicar_Vector_Matriz:

	; vector destino (r8) = vector origen (rcx) * matriz (rdx)
	
	; Acá hago uso de la tecnología SIMD (we!)
	; Los datos necesitan estar alineados a 16 bytes (o sea, que la dirección de memoria
	; sea divisible por 16). Si no podés alinear usar movdqu en vez de movaps, pero es más lento.
	; Tuve que darle un relleno a los triángulos para que queden en tamaño múltiplos de 16 bytes y
	; estén alineados (lo que tiene que estar alineada es la dirección de memoria, pero si están
	; uno al lado del otro, para que queden alineados todos necesito que ocupen un múltiplo de 16)

	; Para DPPS:  (producto escalar en paralelo)
	;
	; El tercer operando en dpps especifica dos nibbles:
	; el primer nibble dice en qué parte del registro va el resultado. 0001b sería en la primera parte
	; el segundo nibble indica qué se multiplica, 0001b sería solo la primera parte, 1111b sería todo.

	; Leí que el dpps medio que no ofrece mayor performance con respecto a otros métodos, pero bueh,
	; lo dejamos así. La versión sin SIMD está en el 3D_3. Si es más rápida, se usará esa y se conservará
	; esta para futuras referencias.
	
	movaps xmm0, [rdx+MATRIZ__11]   ; Con estas dos instrucciones cargo en los registros el vector entero
	movaps xmm1, [rcx]		      ; y la primera columna de la matriz

	dpps xmm0,xmm1,11110001b 	      ; Hago el producto escalar y guardo el resultado en la parte más baja del xmm0
	movss [r8+VECTOR4__1], xmm0     ; Guardo el resultado (que está en la parte baja) en el vector destino. 

	movaps xmm0, [rdx+MATRIZ__12]
	dpps xmm0,xmm1,11110001b
	movss [r8+VECTOR4__2], xmm0	

	movaps xmm0, [rdx+MATRIZ__13]
	dpps xmm0,xmm1, 11110001b   
	movss [r8+VECTOR4__3], xmm0

	movaps xmm0, [rdx+MATRIZ__14]
	dpps xmm0,xmm1, 11110001b  
	movss [r8+VECTOR4__4], xmm0

	emms ; vuelvo al estado FPU

	ret  ; PD: más comentarios que código! :P

