; Vamos a estudiar el tema bien. Lo que sería recontracopado es hacer funciones para cada matriz, pero  me parece que 
; de momento mejor ir a lo individual, porque total lo que lleva más tiempo es tener que multiplicar el mismo vertice
; por cada matriz, y no el obtener la matriz.
 	
	; Las estructuras son MATRIZ, VECTOR3 y VECTOR4. Bastante cutre. Quizás los nombres debería cambiarlos
	; por algo menos riesgoso, como VECTOR_R3 y VECTOR_R4	.

Inicializar_Matriz_Proyeccion_FAKE:


	; Esta todo todo hardcodeado

	mov eax, 0x3f0fee02
	mov [rcx+MATRIZ+matriz_11], eax
	mov eax, 0
	mov [rcx+MATRIZ+matriz_21], eax
	mov eax, 0
	mov [rcx+MATRIZ+matriz_31], eax
	mov eax, 0
	mov [rcx+MATRIZ+matriz_41], eax

	mov eax, 0
	mov [rcx+MATRIZ+matriz_12], eax
	mov eax, 0x3f800000
	mov [rcx+MATRIZ+matriz_22], eax
	mov eax, 0
	mov [rcx+MATRIZ+matriz_32], eax
	mov eax, 0
	mov [rcx+MATRIZ+matriz_42], eax

	mov eax, 0
	mov [rcx+MATRIZ+matriz_13], eax
	mov eax, 0
	mov [rcx+MATRIZ+matriz_23], eax
	mov eax, 0xbf800347			; -q
	mov [rcx+MATRIZ+matriz_33], eax		
	mov eax, 0xbf800000			; -1
	mov [rcx+MATRIZ+matriz_43], eax

	mov eax, 0
	mov [rcx+MATRIZ+matriz_14], eax
	mov eax, 0
	mov [rcx+MATRIZ+matriz_24], eax
	mov eax, 0xbdccd20b			; -znear*q
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
	mov [rcx+(MATRIZ+matriz_32)], eax	; SEN(tita)
	mov [rcx+(MATRIZ+matriz_42)], ebx	; 0
		
	mov [rcx+(MATRIZ+matriz_13)], ebx	; 0
	mov [rcx+(MATRIZ+matriz_23)], r8d	; -SEN(tita) 
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
	mov [rcx+(MATRIZ+matriz_21)], eax	; SEN(tita)
	mov [rcx+(MATRIZ+matriz_31)], ebx	; 0
	mov [rcx+(MATRIZ+matriz_41)], ebx	; 0

	mov [rcx+(MATRIZ+matriz_12)], r8d	; -SEN(tita)
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
			
	mov [rcx+(MATRIZ+matriz_11)], edx ; Sx
	mov [rcx+(MATRIZ+matriz_21)], ebx ; 0
	mov [rcx+(MATRIZ+matriz_31)], ebx ; 0
	mov [rcx+(MATRIZ+matriz_41)], ebx ; 0

	mov [rcx+(MATRIZ+matriz_12)], ebx ; 0
	mov [rcx+(MATRIZ+matriz_22)], r8d ; Sy
	mov [rcx+(MATRIZ+matriz_32)], ebx ; 0
	mov [rcx+(MATRIZ+matriz_42)], ebx ; 0
		
	mov [rcx+(MATRIZ+matriz_13)], ebx ; 0
	mov [rcx+(MATRIZ+matriz_23)], ebx ; 0 
	mov [rcx+(MATRIZ+matriz_33)], r9d ; Sz
	mov [rcx+(MATRIZ+matriz_43)], ebx ; 0
		
	mov [rcx+(MATRIZ+matriz_14)], ebx ; 0 
	mov [rcx+(MATRIZ+matriz_24)], ebx ; 0
	mov [rcx+(MATRIZ+matriz_34)], ebx ; 0
	mov [rcx+(MATRIZ+matriz_44)], r11d; 1

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

		
	mov [rcx+(MATRIZ+matriz_11)], r11d; 1
	mov [rcx+(MATRIZ+matriz_21)], ebx ; 0
	mov [rcx+(MATRIZ+matriz_31)], ebx ; 0
	mov [rcx+(MATRIZ+matriz_41)], ebx ; 0

	mov [rcx+(MATRIZ+matriz_12)], ebx ; 0
	mov [rcx+(MATRIZ+matriz_22)], r11d; 1 
	mov [rcx+(MATRIZ+matriz_32)], ebx ; 0
	mov [rcx+(MATRIZ+matriz_42)], ebx ; 0
		
	mov [rcx+(MATRIZ+matriz_13)], ebx ; 0
	mov [rcx+(MATRIZ+matriz_23)], ebx ; 0 
	mov [rcx+(MATRIZ+matriz_33)], r11d; 1
	mov [rcx+(MATRIZ+matriz_43)], ebx ; 0
		
	mov [rcx+(MATRIZ+matriz_14)], edx ; Tx 
	mov [rcx+(MATRIZ+matriz_24)], r8d ; Ty
	mov [rcx+(MATRIZ+matriz_34)], r9d ; Tz
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
	mov [rcx+(MATRIZ+matriz_44)], edx ; 1

	ret


Inicializar_Matriz_Vista:





	; en rcx el puntero de la matriz a inicializar
	; en rdx el puntero al vector que apunta hacia adelante de la cámara
	; en r8 el puntero al vector que apunta hacia a la derecha de la cámara
	; en r9 el puntero al vector que apunta hacia arriba de la cámara
	; en [rbp + 48] el puntero al vector posicion de la cámara



%define traslacion_z rbp - 12  ; 4 bytes
%define traslacion_y rbp - 8   ; 4 bytes
%define traslacion_x rbp - 4   ; 4 bytes

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 128

	push rbx

	mov rax, [rbp + 48]
	mov ebx, [rax]
	mov [traslacion_x], ebx
	add rax, 4
	mov ebx, [rax]
	mov [traslacion_y], ebx
	add rax, 4
	mov ebx, [rax]
	mov [traslacion_z], ebx
	fld dword [traslacion_z]
	fchs
	fstp dword [traslacion_z]
	xor rax,rax
	 

	mov eax, [r8+VECTOR4+vector_1]
	mov [rcx+(MATRIZ+matriz_11)], eax  ; coord x de vector de derecha

	mov eax, [r9+VECTOR4+vector_1]
	mov [rcx+(MATRIZ+matriz_21)], eax  ; coord x de vector de arriba

	mov eax, [rdx+VECTOR4+vector_1]
	mov [rcx+(MATRIZ+matriz_31)], eax  ; coord x de vector de delante

	mov eax, 0
	mov [rcx+(MATRIZ+matriz_41)], eax  ; 0 

	;;;;


	mov eax, [r8+VECTOR4+vector_2]
	mov [rcx+(MATRIZ+matriz_12)], eax  ; coord y de vector de derecha

	mov eax, [r9+VECTOR4+vector_2]
	mov [rcx+(MATRIZ+matriz_22)], eax  ; coord y de vector de arriba

	mov eax, [rdx+VECTOR4+vector_2]
	mov [rcx+(MATRIZ+matriz_32)], eax  ; coord y de vector de delante

	mov eax, 0
	mov [rcx+(MATRIZ+matriz_42)], eax  ; 0 

	;;;;
	

	mov eax, [r8+VECTOR4+vector_3]
	mov [rcx+(MATRIZ+matriz_13)], eax  ; coord z de vector de derecha

	mov eax, [r9+VECTOR4+vector_3]	
	mov [rcx+(MATRIZ+matriz_23)], eax  ; coord z de vector de arriba

	mov eax, [rdx+VECTOR4+vector_3]
	mov [rcx+(MATRIZ+matriz_33)], eax  ; coord z de vector de delante

	mov eax, 0
	mov [rcx+(MATRIZ+matriz_43)], eax  ; 0 

	;;;;

;BUG;;;; OJO QUE ESTOS NO LOS MODIFIQUE, y debo hacerlos tal cual la dice la página de openGL.
	; funciona porque no estoy moviendo la cámara...

	fld dword [r8+VECTOR4+vector_1] 
	fld dword [traslacion_x]
	fmulp
	fld dword [r8+VECTOR4+vector_2]
	fld dword [traslacion_y]
	fmulp
	fld dword [r8+VECTOR4+vector_3]
	fld dword [traslacion_z]
	fmulp 
	faddp
	faddp
	fchs
	fstp dword [rcx+(MATRIZ+matriz_14)]  ; Producto escalar de -POSICION . ADELANTE


	fld dword [r9+VECTOR4+vector_1] 
	fld dword [traslacion_x]
	fmulp
	fld dword [r9+VECTOR4+vector_2]
	fld dword [traslacion_y]
	fmulp
	fld dword [r9+VECTOR4+vector_3]
	fld dword [traslacion_z]
	fmulp 
	faddp
	faddp
	fchs
	fstp dword [rcx+(MATRIZ+matriz_24)]  ; Producto escalar de -POSICION . DERECHA

 

	fld dword [rdx+VECTOR4+vector_1] 
	fld dword [traslacion_x]
	fmulp
	fld dword [rdx+VECTOR4+vector_2]
	fld dword [traslacion_y]
	fmulp
	fld dword [rdx+VECTOR4+vector_3]
	fld dword [traslacion_z]
	fmulp 
	faddp
	faddp
	fchs
	fstp dword [rcx+(MATRIZ+matriz_34)]  ; Producto escalar de -POSICION . ARRIBA

	mov eax, 0x3f800000
	mov [rcx+(MATRIZ+matriz_44)], eax  ; 1

	pop rbx

	%undef traslacion_z ; 4 bytes
	%undef traslacion_y  ; 4 bytes
	%undef traslacion_x  ; 4 bytes


	mov rsp, rbp
	pop rbp
	ret




Multiplicar_Matriz_Matriz:



;;; OPTIMIZABLE: usar SIMD, pero una vez aprenda a alinear los datos ;;;



	; rdx = rdx * rcx     CUIDADO QUE LA MATRIZ EN RDX SE SOBREESCRIBE.
	; es para transformaciones


	%define matriz_resultado rbp - 64 ; 64 bytes
	
	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 64


	;__a11__
	
	fld dword [rcx+(MATRIZ+matriz_11)]
	fld dword [rdx+(MATRIZ+matriz_11)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_12)]
	fld dword [rdx+(MATRIZ+matriz_21)]
	fmulp 
	fld dword [rcx+(MATRIZ+matriz_13)]
	fld dword [rdx+(MATRIZ+matriz_31)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_14)]
	fld dword [rdx+(MATRIZ+matriz_41)]
	fmulp

	faddp
	faddp
	faddp

	fstp dword [matriz_resultado+(MATRIZ+matriz_11)]

	;__a12__
	
	fld dword [rcx+(MATRIZ+matriz_11)]
	fld dword [rdx+(MATRIZ+matriz_12)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_12)]
	fld dword [rdx+(MATRIZ+matriz_22)]
	fmulp 
	fld dword [rcx+(MATRIZ+matriz_13)]
	fld dword [rdx+(MATRIZ+matriz_32)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_14)]
	fld dword [rdx+(MATRIZ+matriz_42)]
	fmulp

	faddp
	faddp
	faddp
	fstp dword [matriz_resultado+(MATRIZ+matriz_12)]


	;__a13__

	fld dword [rcx+(MATRIZ+matriz_11)]
	fld dword [rdx+(MATRIZ+matriz_13)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_12)]
	fld dword [rdx+(MATRIZ+matriz_23)]
	fmulp 
	fld dword [rcx+(MATRIZ+matriz_13)]
	fld dword [rdx+(MATRIZ+matriz_33)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_14)]
	fld dword [rdx+(MATRIZ+matriz_43)]
	fmulp

	faddp
	faddp
	faddp
	fstp dword [matriz_resultado+(MATRIZ+matriz_13)]

	;__a14__

	fld dword [rcx+(MATRIZ+matriz_11)]
	fld dword [rdx+(MATRIZ+matriz_14)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_12)]
	fld dword [rdx+(MATRIZ+matriz_24)]
	fmulp 
	fld dword [rcx+(MATRIZ+matriz_13)]
	fld dword [rdx+(MATRIZ+matriz_34)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_14)]
	fld dword [rdx+(MATRIZ+matriz_44)]
	fmulp

	faddp
	faddp
	faddp
	fstp dword [matriz_resultado+(MATRIZ+matriz_14)]

	;;;;;;;;;;


	;__a21__
	
	fld dword [rcx+(MATRIZ+matriz_21)]
	fld dword [rdx+(MATRIZ+matriz_11)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_22)]
	fld dword [rdx+(MATRIZ+matriz_21)]
	fmulp 
	fld dword [rcx+(MATRIZ+matriz_23)]
	fld dword [rdx+(MATRIZ+matriz_31)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_24)]
	fld dword [rdx+(MATRIZ+matriz_41)]
	fmulp

	faddp
	faddp
	faddp
	fstp dword [matriz_resultado+(MATRIZ+matriz_21)]

	;__a22__
	
	fld dword [rcx+(MATRIZ+matriz_21)]
	fld dword [rdx+(MATRIZ+matriz_12)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_22)]
	fld dword [rdx+(MATRIZ+matriz_22)]
	fmulp 
	fld dword [rcx+(MATRIZ+matriz_23)]
	fld dword [rdx+(MATRIZ+matriz_32)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_24)]
	fld dword [rdx+(MATRIZ+matriz_42)]
	fmulp

	faddp
	faddp
	faddp
	fstp dword [matriz_resultado+(MATRIZ+matriz_22)]


	;__a23__

	fld dword [rcx+(MATRIZ+matriz_21)]
	fld dword [rdx+(MATRIZ+matriz_13)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_22)]
	fld dword [rdx+(MATRIZ+matriz_23)]
	fmulp 
	fld dword [rcx+(MATRIZ+matriz_23)]
	fld dword [rdx+(MATRIZ+matriz_33)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_24)]
	fld dword [rdx+(MATRIZ+matriz_43)]
	fmulp

	faddp
	faddp
	faddp
	fstp dword [matriz_resultado+(MATRIZ+matriz_23)]

	;__a24__

	fld dword [rcx+(MATRIZ+matriz_21)]
	fld dword [rdx+(MATRIZ+matriz_14)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_22)]
	fld dword [rdx+(MATRIZ+matriz_24)]
	fmulp 
	fld dword [rcx+(MATRIZ+matriz_23)]
	fld dword [rdx+(MATRIZ+matriz_34)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_24)]
	fld dword [rdx+(MATRIZ+matriz_44)]
	fmulp

	faddp
	faddp
	faddp
	fstp dword [matriz_resultado+(MATRIZ+matriz_24)]


	;;;;;;;;;;;;;

	;__a31__
	
	fld dword [rcx+(MATRIZ+matriz_31)]
	fld dword [rdx+(MATRIZ+matriz_11)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_32)]
	fld dword [rdx+(MATRIZ+matriz_21)]
	fmulp 
	fld dword [rcx+(MATRIZ+matriz_33)]
	fld dword [rdx+(MATRIZ+matriz_31)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_34)]
	fld dword [rdx+(MATRIZ+matriz_41)]
	fmulp

	faddp
	faddp
	faddp
	fstp dword [matriz_resultado+(MATRIZ+matriz_31)]

	;__a32__
	
	fld dword [rcx+(MATRIZ+matriz_31)]
	fld dword [rdx+(MATRIZ+matriz_12)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_32)]
	fld dword [rdx+(MATRIZ+matriz_22)]
	fmulp 
	fld dword [rcx+(MATRIZ+matriz_33)]
	fld dword [rdx+(MATRIZ+matriz_32)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_34)]
	fld dword [rdx+(MATRIZ+matriz_42)]
	fmulp

	faddp
	faddp
	faddp
	fstp dword [matriz_resultado+(MATRIZ+matriz_32)]


	;__a33__

	fld dword [rcx+(MATRIZ+matriz_31)]
	fld dword [rdx+(MATRIZ+matriz_13)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_32)]
	fld dword [rdx+(MATRIZ+matriz_23)]
	fmulp 
	fld dword [rcx+(MATRIZ+matriz_33)]
	fld dword [rdx+(MATRIZ+matriz_33)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_34)]
	fld dword [rdx+(MATRIZ+matriz_43)]
	fmulp

	faddp
	faddp
	faddp
	fstp dword [matriz_resultado+(MATRIZ+matriz_33)]

	;__a34__

	fld dword [rcx+(MATRIZ+matriz_31)]
	fld dword [rdx+(MATRIZ+matriz_14)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_32)]
	fld dword [rdx+(MATRIZ+matriz_24)]
	fmulp 
	fld dword [rcx+(MATRIZ+matriz_33)]
	fld dword [rdx+(MATRIZ+matriz_34)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_34)]
	fld dword [rdx+(MATRIZ+matriz_44)]
	fmulp

	faddp
	faddp
	faddp
	fstp dword [matriz_resultado+(MATRIZ+matriz_34)]


	;;;;;;;;;;;;;

	;__a41__
	
	fld dword [rcx+(MATRIZ+matriz_41)]
	fld dword [rdx+(MATRIZ+matriz_11)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_42)]
	fld dword [rdx+(MATRIZ+matriz_21)]
	fmulp 
	fld dword [rcx+(MATRIZ+matriz_43)]
	fld dword [rdx+(MATRIZ+matriz_31)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_44)]
	fld dword [rdx+(MATRIZ+matriz_41)]
	fmulp

	faddp
	faddp
	faddp
	fstp dword [matriz_resultado+(MATRIZ+matriz_41)]

	;__a42__
	
	fld dword [rcx+(MATRIZ+matriz_41)]
	fld dword [rdx+(MATRIZ+matriz_12)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_42)]
	fld dword [rdx+(MATRIZ+matriz_22)]
	fmulp 
	fld dword [rcx+(MATRIZ+matriz_43)]
	fld dword [rdx+(MATRIZ+matriz_32)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_44)]
	fld dword [rdx+(MATRIZ+matriz_42)]
	fmulp

	faddp
	faddp
	faddp
	fstp dword [matriz_resultado+(MATRIZ+matriz_42)]


	;__a43__

	fld dword [rcx+(MATRIZ+matriz_41)]
	fld dword [rdx+(MATRIZ+matriz_13)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_42)]
	fld dword [rdx+(MATRIZ+matriz_23)]
	fmulp 
	fld dword [rcx+(MATRIZ+matriz_43)]
	fld dword [rdx+(MATRIZ+matriz_33)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_44)]
	fld dword [rdx+(MATRIZ+matriz_43)]
	fmulp

	faddp
	faddp
	faddp
	fstp dword [matriz_resultado+(MATRIZ+matriz_43)]

	;__a44__

	fld dword [rcx+(MATRIZ+matriz_41)]
	fld dword [rdx+(MATRIZ+matriz_14)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_42)]
	fld dword [rdx+(MATRIZ+matriz_24)]
	fmulp 
	fld dword [rcx+(MATRIZ+matriz_43)]
	fld dword [rdx+(MATRIZ+matriz_34)]
	fmulp
	fld dword [rcx+(MATRIZ+matriz_44)]
	fld dword [rdx+(MATRIZ+matriz_44)]
	fmulp

	faddp
	faddp
	faddp
	fstp dword [matriz_resultado+(MATRIZ+matriz_44)]

	
	; Copio ahora la matriz. 

	mov eax, [matriz_resultado+(MATRIZ+matriz_11)]
	mov [rcx+(MATRIZ+matriz_11)], eax
	mov eax, [matriz_resultado+(MATRIZ+matriz_21)]
	mov [rcx+(MATRIZ+matriz_21)], eax
	mov eax, [matriz_resultado+(MATRIZ+matriz_31)]
	mov [rcx+(MATRIZ+matriz_31)], eax
	mov eax, [matriz_resultado+(MATRIZ+matriz_41)]
	mov [rcx+(MATRIZ+matriz_41)], eax
	mov eax, [matriz_resultado+(MATRIZ+matriz_12)]
	mov [rcx+(MATRIZ+matriz_12)], eax
	mov eax, [matriz_resultado+(MATRIZ+matriz_22)]
	mov [rcx+(MATRIZ+matriz_22)], eax
	mov eax, [matriz_resultado+(MATRIZ+matriz_32)]
	mov [rcx+(MATRIZ+matriz_32)], eax
	mov eax, [matriz_resultado+(MATRIZ+matriz_42)]
	mov [rcx+(MATRIZ+matriz_42)], eax
	mov eax, [matriz_resultado+(MATRIZ+matriz_13)]
	mov [rcx+(MATRIZ+matriz_13)], eax
	mov eax, [matriz_resultado+(MATRIZ+matriz_23)]
 	mov [rcx+(MATRIZ+matriz_23)], eax
	mov eax, [matriz_resultado+(MATRIZ+matriz_33)]
	mov [rcx+(MATRIZ+matriz_33)], eax
	mov eax, [matriz_resultado+(MATRIZ+matriz_43)]
	mov [rcx+(MATRIZ+matriz_43)], eax
	mov eax, [matriz_resultado+(MATRIZ+matriz_14)]
	mov [rcx+(MATRIZ+matriz_14)], eax
	mov eax, [matriz_resultado+(MATRIZ+matriz_24)]
	mov [rcx+(MATRIZ+matriz_24)], eax
	mov eax, [matriz_resultado+(MATRIZ+matriz_34)]
	mov [rcx+(MATRIZ+matriz_34)], eax
	mov eax, [matriz_resultado+(MATRIZ+matriz_44)]
	mov [rcx+(MATRIZ+matriz_44)], eax


	%undef matriz_resultado

	mov rsp, rbp
	pop rbp
	ret


Multiplicar_Matriz_Vector:

	; vector destino (r8) = matriz(rcx)*vector origen (rdx)
	; r8 = rcx * rdx  


;;;OPTIMIZABLE;;;

	; Acá hago uso de la tecnología SIMD (we!)
	; Los datos necesitan estar alineados a 16 bytes (o sea, que la dirección de memoria
	; sea divisible por 16). Si no podés usar movdqu en vez de movaps, pero es más lento.


	; Para DPPS:  (producto escalar en paralelo)
	;
	; El tercer operando en dpps especifica dos nibbles:
	; el primer nibble (1) dice en qué parte del registro va el resultado. 0001b sería en la primera parte
	; el segundo nibble (F) indica qué se multiplica, 0001b sería solo la primera parte, 1111b sería todo.


	; Leí que el dpps medio que no ofrece mayor performance con respecto a otros métodos, pero bueh,
	; lo dejamos así. La versión sin SIMD está en el 3D_3. Si es más rápida, se usará esa.
	

	movaps xmm0, [rcx+MATRIZ+matriz_11]   ; Con estas dos instrucciones cargo en los registros la fila de la matriz
	movaps xmm1, [rdx]                    ; (o los vectores)
	dpps xmm0,xmm1,11110001b 	      ; Hago el producto escalar y guardo el resultado en la parte más baja del xmm0
	movss [r8+VECTOR4+vector_1], xmm0     ; Guardo el resultado (que está en la parte baja) en el vector destino. 

	movaps xmm0, [rcx+MATRIZ+matriz_21]
	movaps xmm1, [rdx]
	dpps xmm0,xmm1,11110001b
	movss [r8+VECTOR4+vector_2], xmm0	

	movaps xmm0, [rcx+MATRIZ+matriz_31]
	movaps xmm1, [rdx]
	dpps xmm0,xmm1, 11110001b   
	movss [r8+VECTOR4+vector_3], xmm0

	movaps xmm0, [rcx+MATRIZ+matriz_41]
	movaps xmm1, [rdx]
	dpps xmm0,xmm1, 11110001b  
	movss [r8+VECTOR4+vector_4], xmm0

	emms ; vuelvo al estado FPU

	ret

