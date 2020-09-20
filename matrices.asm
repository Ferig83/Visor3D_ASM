 	
	; Las estructuras son MATRIZ, VECTOR3 y VECTOR4. Bastante cutre. Quizás los nombres debería cambiarlos
	; por algo menos riesgoso, como VECTOR_R3 y VECTOR_R4	.

Inicializar_Matriz_Proyeccion_FAKE:


	; Esta todo todo hardcodeado

	mov eax, 0x3f0fee02			; hardcodeadisimo
	mov [rcx+MATRIZ+matriz_11], eax
	mov eax, 0
	mov [rcx+MATRIZ+matriz_21], eax
	mov eax, 0
	mov [rcx+MATRIZ+matriz_31], eax
	mov eax, 0
	mov [rcx+MATRIZ+matriz_41], eax

	mov eax, 0
	mov [rcx+MATRIZ+matriz_12], eax
	mov eax, 0x3f800000			; 1, hardcodeado si tita es pi/2
	mov [rcx+MATRIZ+matriz_22], eax
	mov eax, 0
	mov [rcx+MATRIZ+matriz_32], eax
	mov eax, 0
	mov [rcx+MATRIZ+matriz_42], eax

	mov eax, 0
	mov [rcx+MATRIZ+matriz_13], eax
	mov eax, 0
	mov [rcx+MATRIZ+matriz_23], eax
	mov eax, 0x3f800347			; q
	mov [rcx+MATRIZ+matriz_33], eax		
	mov eax, 0xbdccd20b			; -znear*q
	mov [rcx+MATRIZ+matriz_43], eax

	mov eax, 0
	mov [rcx+MATRIZ+matriz_14], eax
	mov eax, 0
	mov [rcx+MATRIZ+matriz_24], eax
	mov eax, 0x3f800000			; 1
	mov [rcx+MATRIZ+matriz_34], eax
	mov eax, 0
	mov [rcx+MATRIZ+matriz_44], eax


	ret




Inicializar_Matriz_Proyeccion:

	; en RCX va el puntero a la matriz a rellenar
	; en edx va el alto de la pantalla (entero)
	; en r8d va el ancho de la pantalla (entero)
	; en r9d va el angulo (float)
	; en PILA1 va el zfar
	; en PILA2 va el znear

	%define variable_r rbp - 48	;  4 bytes
	%define variable_axf rbp - 44	;  4 bytes
	%define variable_f rbp - 40	;  4 bytes
	%define variable_q rbp - 36	;  4 bytes
	%define variable_a rbp - 32	;  4 bytes 
	%define angulo_vision rbp - 28	;  4 bytes
	%define znear rbp - 24		;  8 bytes
	%define zfar rbp - 16		;  8 bytes 
	%define ancho_pantalla rbp - 8	;  4 bytes  
	%define alto_pantalla rbp - 4 	;  4 bytes

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 64 

	mov [alto_pantalla], edx
	mov [ancho_pantalla],r8d
	mov [angulo_vision],r9d
	mov rax, [rbp + 56]          ; con el push use esto  [rbp + 16]
	mov [znear], rax
	mov rax, [rbp + 48]          ; idem del push : [rbp + 24]
	mov [zfar], rax



	; Cargo "a" (aspect ratio, que es alto/ancho) en edx 

	fild dword [alto_pantalla]
	fild dword [ancho_pantalla]
	fdivp
	fstp dword [variable_a]

	; Cargo "f" (1/tan(angulo/2)) en rd8 	


	;Con lo siguiente divido tita por 2 (tita es el angulo de visión)

	fld1 
	fld dword [angulo_vision]
	fld1
	fld1
	faddp
	fdivp
	
	;Con lo siguiente esto hago 1/tan(tita/2)

	fptan
	fdivp 
	fstp dword [variable_f]


	; Ahora cargo "Q" que es (Zfar/(Zfar-Znear))

	fld dword [zfar]
	fld dword [zfar]
	fld dword [znear]
	fsubp
	fdivp
	fstp dword [variable_q]


	
	; Ahora cargo a*f

	fld dword [variable_a]
	fld dword [variable_f]
	fmulp
	fstp dword [variable_axf]

	; Y por último cargo r que es -znear*q
	
	fld dword [variable_q]
	fld dword [znear]
	fchs
	fmulp 
	fstp dword [variable_r]

	
	mov r8d, 0x00000000     ; 0.0
	mov edx, 0x3f800000     ; 1.0



	;Listo, relleno la matriz
	
	mov eax, [variable_axf]
	mov [rcx+(MATRIZ+matriz_11)], eax	; af
	mov [rcx+(MATRIZ+matriz_21)], r8d	; 0
	mov [rcx+(MATRIZ+matriz_31)], r8d 	; 0
	mov [rcx+(MATRIZ+matriz_41)], r8d	; 0

	mov [rcx+(MATRIZ+matriz_12)], r8d 	; 0
	mov eax, [variable_f]
	mov [rcx+(MATRIZ+matriz_22)], eax	; f 
	mov [rcx+(MATRIZ+matriz_32)], r8d 	; 0
	mov [rcx+(MATRIZ+matriz_42)], r8d 	; 0
		
	mov [rcx+(MATRIZ+matriz_13)], r8d 	; 0
	mov [rcx+(MATRIZ+matriz_23)], r8d 	; 0
	mov eax, [variable_q] 
	mov [rcx+(MATRIZ+matriz_33)], eax	; q
	mov [rcx+(MATRIZ+matriz_43)], edx	; 1	
	
	mov [rcx+(MATRIZ+matriz_14)], r8d 	; 0 
	mov [rcx+(MATRIZ+matriz_24)], r8d 	; 0
	mov eax, [variable_r]
	mov [rcx+(MATRIZ+matriz_34)], eax 	; -znear * q
	mov [rcx+(MATRIZ+matriz_44)], r8d 	; 0


	%undef variable_r 
	%undef variable_axf 
	%undef variable_f 
	%undef variable_q 
	%undef variable_a  
	%undef angulo_vision 
	%undef znear
	%undef zfar 
	%undef ancho_pantalla   
	%undef alto_pantalla 


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
	
	mov [rcx+(MATRIZ+matriz_11)], r11d	; 1
	mov [rcx+(MATRIZ+matriz_21)], ebx	; 0
	mov [rcx+(MATRIZ+matriz_31)], ebx	; 0
	mov [rcx+(MATRIZ+matriz_41)], ebx	; 0

	mov [rcx+(MATRIZ+matriz_12)], ebx	; 0
	mov [rcx+(MATRIZ+matriz_22)], edx	; COS(tita) 
	mov [rcx+(MATRIZ+matriz_32)], r8d	; -SEN(tita)
	mov [rcx+(MATRIZ+matriz_42)], ebx	; 0
		
	mov [rcx+(MATRIZ+matriz_13)], ebx	; 0
	mov [rcx+(MATRIZ+matriz_23)], eax	; SEN(tita) 
	mov [rcx+(MATRIZ+matriz_33)], edx	; COS(tita)
	mov [rcx+(MATRIZ+matriz_43)], ebx	; 0
		
	mov [rcx+(MATRIZ+matriz_14)], ebx	; 0 
	mov [rcx+(MATRIZ+matriz_24)], ebx	; 0
	mov [rcx+(MATRIZ+matriz_34)], ebx	; 0
	mov [rcx+(MATRIZ+matriz_44)], r11d	; 1


	%undef auxiliar
	%undef angulo

	pop r11
	pop rbx

	mov rsp, rbp
	pop rbp
			
	ret
		



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
	
	mov [rcx+(MATRIZ+matriz_11)], edx	; COS(tita) 
	mov [rcx+(MATRIZ+matriz_21)], r8d	; -SEN(tita)
	mov [rcx+(MATRIZ+matriz_31)], ebx	; 0
	mov [rcx+(MATRIZ+matriz_41)], ebx	; 0

	mov [rcx+(MATRIZ+matriz_12)], eax	; SEN(tita)
	mov [rcx+(MATRIZ+matriz_22)], edx	; COS(tita) 
	mov [rcx+(MATRIZ+matriz_32)], ebx	; 0
	mov [rcx+(MATRIZ+matriz_42)], ebx	; 0
		
	mov [rcx+(MATRIZ+matriz_13)], ebx	; 0
	mov [rcx+(MATRIZ+matriz_23)], ebx	; 0 
	mov [rcx+(MATRIZ+matriz_33)], r11d	; 1
	mov [rcx+(MATRIZ+matriz_43)], ebx	; 0
		
	mov [rcx+(MATRIZ+matriz_14)], ebx	; 0 
	mov [rcx+(MATRIZ+matriz_24)], ebx	; 0
	mov [rcx+(MATRIZ+matriz_34)], ebx	; 0
	mov [rcx+(MATRIZ+matriz_44)], r11d	; 1


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
			
	mov [rcx+(MATRIZ+matriz_11)], edx  ; Sx
	mov [rcx+(MATRIZ+matriz_21)], ebx  ; 0
	mov [rcx+(MATRIZ+matriz_31)], ebx  ; 0
	mov [rcx+(MATRIZ+matriz_41)], ebx  ; 0

	mov [rcx+(MATRIZ+matriz_12)], ebx  ; 0
	mov [rcx+(MATRIZ+matriz_22)], r8d  ; Sy
	mov [rcx+(MATRIZ+matriz_32)], ebx  ; 0
	mov [rcx+(MATRIZ+matriz_42)], ebx  ; 0
		
	mov [rcx+(MATRIZ+matriz_13)], ebx  ; 0
	mov [rcx+(MATRIZ+matriz_23)], ebx  ; 0 
	mov [rcx+(MATRIZ+matriz_33)], r9d  ; Sz
	mov [rcx+(MATRIZ+matriz_43)], ebx  ; 0
		
	mov [rcx+(MATRIZ+matriz_14)], ebx  ; 0 
	mov [rcx+(MATRIZ+matriz_24)], ebx  ; 0
	mov [rcx+(MATRIZ+matriz_34)], ebx  ; 0
	mov [rcx+(MATRIZ+matriz_44)], r11d ; 1

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

		
	mov [rcx+(MATRIZ+matriz_11)], r11d ; 1
	mov [rcx+(MATRIZ+matriz_21)], ebx  ; 0
	mov [rcx+(MATRIZ+matriz_31)], ebx  ; 0
	mov [rcx+(MATRIZ+matriz_41)], edx  ; Tx

	mov [rcx+(MATRIZ+matriz_12)], ebx  ; 0
	mov [rcx+(MATRIZ+matriz_22)], r11d ; 1 
	mov [rcx+(MATRIZ+matriz_32)], ebx  ; 0
	mov [rcx+(MATRIZ+matriz_42)], r8d  ; Ty
		
	mov [rcx+(MATRIZ+matriz_13)], ebx  ; 0
	mov [rcx+(MATRIZ+matriz_23)], ebx  ; 0 
	mov [rcx+(MATRIZ+matriz_33)], r11d ; 1
	mov [rcx+(MATRIZ+matriz_43)], r9d  ; Tz
		
	mov [rcx+(MATRIZ+matriz_14)], ebx  ; 0 
	mov [rcx+(MATRIZ+matriz_24)], ebx  ; 0
	mov [rcx+(MATRIZ+matriz_34)], ebx  ; 0
	mov [rcx+(MATRIZ+matriz_44)], r11d ; 1

	pop r11
	pop rbx


	ret


Inicializar_Matriz_Identidad:

	; en rcx el puntero de la matriz a inicializar

	mov eax, 0x00000000
	mov edx, 0x3f800000
		
	mov [rcx+(MATRIZ+matriz_11)], edx  ; 1
	mov [rcx+(MATRIZ+matriz_21)], eax  ; 0
	mov [rcx+(MATRIZ+matriz_31)], eax  ; 0
	mov [rcx+(MATRIZ+matriz_41)], eax  ; 0

	mov [rcx+(MATRIZ+matriz_12)], eax  ; 0
	mov [rcx+(MATRIZ+matriz_22)], edx  ; 1 
	mov [rcx+(MATRIZ+matriz_32)], eax  ; 0
	mov [rcx+(MATRIZ+matriz_42)], eax  ; 0
		
	mov [rcx+(MATRIZ+matriz_13)], eax  ; 0
	mov [rcx+(MATRIZ+matriz_23)], eax  ; 0 
	mov [rcx+(MATRIZ+matriz_33)], edx  ; 1
	mov [rcx+(MATRIZ+matriz_43)], eax  ; 0
		
	mov [rcx+(MATRIZ+matriz_14)], eax  ; 0 
	mov [rcx+(MATRIZ+matriz_24)], eax  ; 0
	mov [rcx+(MATRIZ+matriz_34)], eax  ; 0
	mov [rcx+(MATRIZ+matriz_44)], edx  ; 1

	ret


;--------------------------------------------------------------------


Inicializar_Matriz_Camara:

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
	
	fld dword [r8+VECTOR4+vector_2]
	fld dword [rdx+VECTOR4+vector_3]
	fmulp
	fld dword [r8+VECTOR4+vector_3]
	fld dword [rdx+VECTOR4+vector_2]
	fmulp
	fsubp
	fstp dword [rbx+VECTOR4+vector_1]


	fld dword [r8+VECTOR4+vector_3]
	fld dword [rdx+VECTOR4+vector_1]
	fmulp
	fld dword [r8+VECTOR4+vector_1]
	fld dword [rdx+VECTOR4+vector_3]
	fmulp
	fsubp
	fstp dword [rbx+VECTOR4+vector_2]


	fld dword [r8+VECTOR4+vector_1]
	fld dword [rdx+VECTOR4+vector_2]
	fmulp
	fld dword [r8+VECTOR4+vector_2]
	fld dword [rdx+VECTOR4+vector_1]
	fmulp
	fsubp
	fstp dword [rbx+VECTOR4+vector_3]

	fld1
	fstp dword [rbx+VECTOR4+vector_4]



	; Y ahora relleno la matriz como corresponde
	; r8 arriba, r9 posicion, rdx delante, rbx derecha


	mov eax, [rbx+VECTOR4+vector_1]
	mov [rcx+(MATRIZ+matriz_11)], eax  ; coord x de vector de derecha

	mov eax, [r8+VECTOR4+vector_1]
	mov [rcx+(MATRIZ+matriz_21)], eax  ; coord x de vector de arriba

	mov eax, [rdx+VECTOR4+vector_1]
	mov [rcx+(MATRIZ+matriz_31)], eax  ; coord x de vector de delante

	mov eax, [r9+VECTOR4+vector_1]
	mov [rcx+(MATRIZ+matriz_41)], eax  ; coord x de vector de posicion


	;;;;


	mov eax, [rbx+VECTOR4+vector_2]
	mov [rcx+(MATRIZ+matriz_12)], eax  ; coord y de vector de derecha

	mov eax, [r8+VECTOR4+vector_2]
	mov [rcx+(MATRIZ+matriz_22)], eax  ; coord y de vector de arriba

	mov eax, [rdx+VECTOR4+vector_2]
	mov [rcx+(MATRIZ+matriz_32)], eax  ; coord y de vector de delante

	mov eax, [r9+VECTOR4+vector_2]
	mov [rcx+(MATRIZ+matriz_42)], eax  ; coord y de vector de posicion


	;;;;
	

	mov eax, [rbx+VECTOR4+vector_3]
	mov [rcx+(MATRIZ+matriz_13)], eax  ; coord z de vector de derecha

	mov eax, [r8+VECTOR4+vector_3]	
	mov [rcx+(MATRIZ+matriz_23)], eax  ; coord z de vector de arriba

	mov eax, [rdx+VECTOR4+vector_3]
	mov [rcx+(MATRIZ+matriz_33)], eax  ; coord z de vector de delante

	mov eax, [r9+VECTOR4+vector_3]
	mov [rcx+(MATRIZ+matriz_43)], eax  ; coord z de vector de posicion
	

	;;;;


	mov eax, 0x00000000
	mov [rcx+(MATRIZ+matriz_14)], eax  ; 0

	mov eax, 0x00000000
	mov [rcx+(MATRIZ+matriz_24)], eax  ; 0

	mov eax, 0x00000000
	mov [rcx+(MATRIZ+matriz_34)], eax  ; 0


	mov eax, 0x3f800000
	mov [rcx+(MATRIZ+matriz_44)], eax  ; 1


	;;;;

	pop rbx

	%undef vector_camara_derecha 


	mov rsp, rbp
	pop rbp
	ret


;--------------------------------------------------------------------


Inicializar_Matriz_Vista:


	; en rcx el puntero de la matriz vista
	; en rdx el puntero de la matriz camara
	

	mov eax, [rdx+MATRIZ+matriz_11]
	mov [rcx+(MATRIZ+matriz_11)], eax  ; coord x de vector de derecha

	mov eax, [rdx+MATRIZ+matriz_12]
	mov [rcx+(MATRIZ+matriz_21)], eax  ; coord y de vector de derecha

	mov eax, [rdx+MATRIZ+matriz_13]
	mov [rcx+(MATRIZ+matriz_31)], eax  ; coord z de vector de derecha


	fld dword [rdx+MATRIZ+matriz_41] 
	fld dword [rcx+MATRIZ+matriz_11]
	fmulp
	fld dword [rdx+MATRIZ+matriz_42]
	fld dword [rcx+MATRIZ+matriz_21]
	fmulp
	fld dword [rdx+MATRIZ+matriz_43]
	fld dword [rcx+MATRIZ+matriz_31]
	fmulp 
	faddp
	faddp
	fchs
	fstp dword [rcx+(MATRIZ+matriz_41)]  ; Producto escalar de -POSICION . DERECHA

	;;;;


	mov eax, [rdx+MATRIZ+matriz_21]
	mov [rcx+(MATRIZ+matriz_12)], eax  ; coord x de vector de arriba

	mov eax, [rdx+MATRIZ+matriz_22]
	mov [rcx+(MATRIZ+matriz_22)], eax  ; coord y de vector de arriba

	mov eax, [rdx+MATRIZ+matriz_23]
	mov [rcx+(MATRIZ+matriz_32)], eax  ; coord z de vector de arriba

	fld dword [rdx+MATRIZ+matriz_41] 
	fld dword [rcx+MATRIZ+matriz_12]
	fmulp
	fld dword [rdx+MATRIZ+matriz_42]
	fld dword [rcx+MATRIZ+matriz_22]
	fmulp
	fld dword [rdx+MATRIZ+matriz_43]
	fld dword [rcx+MATRIZ+matriz_32]
	fmulp 
	faddp
	faddp
	fchs
	fstp dword [rcx+(MATRIZ+matriz_42)]  ; Producto escalar de -POSICION . ARRIBA



	;;;;
	

	mov eax, [rdx+MATRIZ+matriz_31]
	mov [rcx+(MATRIZ+matriz_13)], eax  ; coord x de vector de delante

	mov eax, [rdx+MATRIZ+matriz_32]	
	mov [rcx+(MATRIZ+matriz_23)], eax  ; coord y de vector de delante

	mov eax, [rdx+MATRIZ+matriz_33]
	mov [rcx+(MATRIZ+matriz_33)], eax  ; coord z de vector de delante


	fld dword [rdx+MATRIZ+matriz_41] 
	fld dword [rcx+MATRIZ+matriz_13]
	fmulp
	fld dword [rdx+MATRIZ+matriz_42]
	fld dword [rcx+MATRIZ+matriz_23]
	fmulp
	fld dword [rdx+MATRIZ+matriz_43]
	fld dword [rcx+MATRIZ+matriz_33]
	fmulp 
	faddp
	faddp
	fchs
	fstp dword [rcx+(MATRIZ+matriz_43)]  ; Producto escalar de -POSICION . DELANTE


	;;;;


	mov eax, 0x00000000
	mov [rcx+(MATRIZ+matriz_14)], eax  ; 0

	mov eax, 0x00000000
	mov [rcx+(MATRIZ+matriz_24)], eax  ; 0

	mov eax, 0x00000000
	mov [rcx+(MATRIZ+matriz_34)], eax  ; 0


	mov eax, 0x3f800000
	mov [rcx+(MATRIZ+matriz_44)], eax  ; 1


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


	movaps xmm0, [rcx+MATRIZ+matriz_11]	 ; primera columna de A
	movss xmm1, [rdx+MATRIZ+matriz_11]	 ; Valor a11 de B 
	shufps xmm1, xmm1, 0x00    		 ; esto llena xmm1 con el valor de arriba
	mulps xmm1,xmm0		   		 ; Multiplico y queda lista para la suma.

	movss xmm2, [rdx+MATRIZ+matriz_12]	 ; Valor de a12 de B y se repite hasta llenar todas de xmm1 a xmm4 
	shufps xmm2, xmm2, 0x00    	
	mulps xmm2,xmm0		   
 
	movss xmm3, [rdx+MATRIZ+matriz_13]
	shufps xmm3, xmm3, 0x00    
	mulps xmm3,xmm0		   

	movss xmm4, [rdx+MATRIZ+matriz_14] 
	shufps xmm4, xmm4, 0x00    
	mulps xmm4,xmm4		   

;_______Ahora hago lo mismo con la segunda columna de A hasta llegar a la cuarta 
;	y voy sumando cada vez.

	movaps xmm0, [rcx+MATRIZ+matriz_12]
	movss xmm5, [rdx+MATRIZ+matriz_21]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm1,xmm5

	movss xmm5, [rdx+MATRIZ+matriz_22]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm2,xmm5

	movss xmm5, [rdx+MATRIZ+matriz_23]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm3,xmm5

	movss xmm5, [rdx+MATRIZ+matriz_24]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm4,xmm5
	

	movaps xmm0, [rcx+MATRIZ+matriz_13]
	movss xmm5, [rdx+MATRIZ+matriz_31]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm1,xmm5

	movss xmm5, [rdx+MATRIZ+matriz_32]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm2,xmm5

	movss xmm5, [rdx+MATRIZ+matriz_33]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm3,xmm5

	movss xmm5, [rdx+MATRIZ+matriz_34]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm4,xmm5
	
	movaps xmm0, [rcx+MATRIZ+matriz_14]
	movss xmm5, [rdx+MATRIZ+matriz_41]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm1,xmm5

	movss xmm5, [rdx+MATRIZ+matriz_42]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm2,xmm5

	movss xmm5, [rdx+MATRIZ+matriz_43]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm3,xmm5

	movss xmm5, [rdx+MATRIZ+matriz_44]
	shufps xmm5, xmm5, 0x00
	mulps xmm5,xmm0
	addps xmm4,xmm5
	
;_______Y ahora muevo todo a cada parte

	movaps [rcx+MATRIZ+matriz_11], xmm1
	movaps [rcx+MATRIZ+matriz_12], xmm2
	movaps [rcx+MATRIZ+matriz_13], xmm3
	movaps [rcx+MATRIZ+matriz_14], xmm4

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
	
	movaps xmm0, [rdx+MATRIZ+matriz_11]   ; Con estas dos instrucciones cargo en los registros el vector entero
	movaps xmm1, [rcx]		      ; y la primera columna de la matriz

	dpps xmm0,xmm1,11110001b 	      ; Hago el producto escalar y guardo el resultado en la parte más baja del xmm0
	movss [r8+VECTOR4+vector_1], xmm0     ; Guardo el resultado (que está en la parte baja) en el vector destino. 

	movaps xmm0, [rdx+MATRIZ+matriz_12]
	dpps xmm0,xmm1,11110001b
	movss [r8+VECTOR4+vector_2], xmm0	

	movaps xmm0, [rdx+MATRIZ+matriz_13]
	dpps xmm0,xmm1, 11110001b   
	movss [r8+VECTOR4+vector_3], xmm0

	movaps xmm0, [rdx+MATRIZ+matriz_14]
	dpps xmm0,xmm1, 11110001b  
	movss [r8+VECTOR4+vector_4], xmm0

	emms ; vuelvo al estado FPU

	ret  ; PD: más comentarios que código! :P

