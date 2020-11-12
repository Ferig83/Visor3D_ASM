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


;------------------------------------------------------------------------------


Interseccion_Recta_Plano:

	; TODOS TIENEN QUE ESTAR ALINEADOS
	; Probarlo con una normal cualquiera y una recta cualquiera, y ver si da con [prueba]

	; rcx = El puntero de datos del plano
	; rdx = Puntero a un punto de un triángulo  (inicio)
	; r8 = Puntero a otro punto del triángulo   (final)
	; r9 = Puntero donde se va a guardar el punto intersección plano-recta 

	; Para los puntos del segmento del triángulo respetar el orden horario de puntos!



;_______Para sacar la intersección entre el plano y una recta, necesito meter en cada x,y,z
; 	de la ecuación del plano los valores de la recta en forma paramétrica.
; 	Por ejemplo   x = a - t*p  ; y = b - t*q ; z = c - t*r 
; 	Donde:
; 		a,b,c son los x,y,z de un punto cualquiera de la recta;
;		p,q,r son los x,y,z del vector director de la recta
;		t  es el parámetro (o lambda) de la recta
;
;	Necesitamos entonces encontrar cual es el valor de "t" correspondiente al punto intersección,
;	y una vez hallado, utilizarlo para meterlo en la ecuación de la recta y sacar el punto mismo.
;	Si despejo t, me queda esta fórmula:
;
;	t = D - (N*PuntoRectaInicial) / N*PuntoRectaFinal - N*PuntoRectaInicial 
;	
;	Decimos "Final" e "Inicial" porque son dos puntos que restados nos da el sentido de la recta, que
;	no es necesario pero es para ser consistentes con el orden de los puntos del triángulo (sentido
;	horario) que sí es necesario para el backface culling.

	push rbp
	mov rbp,rsp
	sub rsp, SHADOWSPACE
	

	; Sea AX + BY + CZ = D  la ecuación de un plano cualquiera, saco "D"
	; con el producto escalar de la normal y el vector del punto.

	movaps xmm0, [rcx+DATOS_PLANO__normal]
  	movaps xmm1, [rcx+DATOS_PLANO__punto]  
	dpps xmm0,xmm1,11110001b 	      



	; Saco N*PuntoRectaInicial

	movaps xmm2, [rcx+DATOS_PLANO__normal]
  	movaps xmm1, [rdx]  
	dpps xmm2,xmm1,11110001b 	      


	
	; Saco N*PuntoRectaFinal

	movaps xmm3, [rcx+DATOS_PLANO__normal]
  	movaps xmm1, [r8]  
	dpps xmm3,xmm1,11110001b 	      
	
	; Saco el vector director de la recta

	movaps xmm4, [r8]
  	movaps xmm1, [rdx]  
	subps xmm4, xmm1

	; Tengo :

	;	xmm0 : D del plano
	;	xmm2 : N*Punto_Recta_Inicial
	;	xmm3 : N*Punto_Recta_Final
	; 	xmm4 ; Vector Director de la Recta

	; Calculo el parámetro "t" y me lo quedo en xmm0, en forma de pack 

	
	subss xmm0,xmm2
	subss xmm3,xmm2
	divss xmm0,xmm3
	shufps xmm0, xmm0, 0x00
	
	; Ahora hago "PuntoInicial + t(VectorDirectorRecta)"	

	mulps xmm0, xmm4
	addps xmm0, [rdx]
	movaps [r9], xmm0


	emms ; vuelvo al estado FPU

	mov rsp,rbp
	pop rbp

	ret  


Calcular_Distancia_Signada:

	; rcx = puntero a los datos del plano
	; rdx = puntero a los datos del punto

	; Calcula la distancia entre un punto y el plano. Si es positiva, el punto
	; coincide con el lado que apunta la normal del plano. Si es negativa, está 
	; del otro lado. Si es cero, está en el plano.
	;
	; La distancia se calcula evaluando la ecuación del plano con el punto a verificar.
	


%define resultado rbp - 4 ; 4 bytes

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 16


	; Sea AX + BY + CZ + D = 0  la ecuación de un plano cualquiera, saco "D"
	; con el producto escalar de la normal y el vector del punto (N*P)
	

	movaps xmm0, [rcx+DATOS_PLANO__normal]
  	movaps xmm1, [rcx+DATOS_PLANO__punto]  
	dpps xmm0,xmm1,11110001b

	; Cargo AX+BY+CY

	movaps xmm1, [rcx+DATOS_PLANO__normal]
	movaps xmm2, [rdx]
	dpps xmm1,xmm2,11110001b

	; A lo de arriba le resto D y cargo el resultado en rax

	subps xmm1, xmm0
	
	movss [resultado], xmm1
	mov rax, [resultado]

	emms

	mov rsp, rbp
	pop rbp

%undef resultado

	ret
	


;------------------------------------------------------------------------------

Recortar_Triangulo:

	;rcx = puntero al triangulo original
	;rdx = puntero al plano el cual se va a hacer el recorte (clip)
	;r8 = direccion del triángulo donde va el primer triángulo generado
	;r9 = direccion del triángulo donde va el segundo triángulo generado


%define puntos_fuera 			rbp - 256	; 48 bytes (VERTICE_size*3) (tienen que estar alineados a 16 por SSE)
%define puntos_dentro			rbp - 208	; 48 bytes (VERTICE_size*3) (tienen que estar alineados a 16 por SSE) 
%define puntero_plano 			rbp - 160	; 8 bytes + 4 de padding (tiene que estar alineado a 16 por SSE) 	
%define puntero_triangulo 		rbp - 148	; 8 bytes 	
%define distancia_signada_punto3 	rbp - 140	; 4 bytes 	
%define distancia_signada_punto2 	rbp - 136	; 4 bytes 	
%define distancia_signada_punto1 	rbp - 132	; 4 bytes 	

;;;;;;;; Modificar estos valores porque estos de abajo ahora ocupan 8 bytes nomás

%define puntero_triangulo_generado_2 	rbp - 128 	; 64 bytes (TRIANGULO_size)
%define puntero_triangulo_generado_1 	rbp - 64  	; 64 bytes (TRIANGULO_size)

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 272

	push r13  
	push r12  	
	push rbx 


	mov [puntero_triangulo], rcx
	mov [puntero_plano], rdx
	mov [puntero_triangulo_generado_1], r8
	mov [puntero_triangulo_generado_2], r9

	

;_______Calculo las distancias de todos los puntos
	
	xor r12,r12  ; acá van a ir la cantidad de puntos que van adentro
	xor r13,r13  ; acá van a ir la cantidad de puntos que van afuera
	mov rbx, [puntero_triangulo]




	; Calculo la del primer punto

	mov rcx, [puntero_plano]
	mov rdx, [puntero_triangulo]
	add rdx, TRIANGULO__vertice1


	call Calcular_Distancia_Signada
	mov [distancia_signada_punto1], eax

	; Si la del punto es positiva, la guardo en puntos_dentro (primera posición del array)



	fldz
	fld dword [distancia_signada_punto1]
	fcomip
	fstp st0


	jb .primer_punto_fuera

.primer_punto_dentro:	

	; Calculo cuanto es el offset donde tengo que escribir en el array de puntos_dentro
	; Lo cual sería la cantidad de puntos dentro multiplicada por el tamaño de VERTICE

	mov rax, VERTICE_size
	mul r12
	lea rcx, [puntos_dentro]
	add rcx, rax

	; Ahora copio los primeros 8 bytes del triangulo, y luego los otros 8 bytes

	mov rax, [rbx]
	mov [rcx],rax
	add rbx, 8
	add rcx, 8
	mov rax, [rbx]
	mov [rcx], rax
	add rbx, 8
	;add rcx, 8

	; Incremento la cantidad de puntos dentro y listo

	inc r12
	jmp .fin_analisis_primer_punto
	
.primer_punto_fuera:

	; Calculo cuanto es el offset donde tengo que escribir en el array de puntos_dentro
	; Lo cual sería la cantidad de puntos dentro multiplicada por el tamaño de VERTICE

	mov rax, VERTICE_size
	mul r13
	lea rcx, [puntos_fuera]
	add rcx, rax

	; Ahora copio los primeros 8 bytes del triangulo, y luego los otros 8 bytes

	mov rax, [rbx]
	mov [rcx],rax
	add rbx, 8
	add rcx, 8
	mov rax, [rbx]
	mov [rcx], rax
	add rbx, 8
	;add rcx, 8

	; Incremento la cantidad de puntos fuera y listo

	inc r13
	jmp .fin_analisis_primer_punto

.fin_analisis_primer_punto:




;_______Segundo punto

	mov rcx, [puntero_plano]
	mov rdx, [puntero_triangulo]
	add rdx, TRIANGULO__vertice2
	call Calcular_Distancia_Signada
	mov [distancia_signada_punto2], eax

	; Si la del punto es positiva, la guardo en puntos_dentro (primera posición del array)

	fldz
	fld dword [distancia_signada_punto2]
	fcomip
	fstp st0
	jb .segundo_punto_fuera

.segundo_punto_dentro:	

	; Calculo cuanto es el offset donde tengo que escribir en el array de puntos_dentro
	; Lo cual sería la cantidad de puntos dentro multiplicada por el tamaño de VERTICE

	mov rax, VERTICE_size
	mul r12
	lea rcx, [puntos_dentro]
	add rcx, rax

	; Ahora copio los primeros 8 bytes del triangulo, y luego los otros 8 bytes

	mov rax, [rbx]
	mov [rcx],rax
	add rbx, 8
	add rcx, 8
	mov rax, [rbx]
	mov [rcx], rax
	add rbx, 8
	;add rcx, 8

	; Incremento la cantidad de puntos dentro y listo

	inc r12
	jmp .fin_analisis_segundo_punto
	
.segundo_punto_fuera:

	; Calculo cuanto es el offset donde tengo que escribir en el array de puntos_dentro
	; Lo cual sería la cantidad de puntos dentro multiplicada por el tamaño de VERTICE

	mov rax, VERTICE_size
	mul r13
	lea rcx, [puntos_fuera]
	add rcx, rax

	; Ahora copio los primeros 8 bytes del triangulo, y luego los otros 8 bytes

	mov rax, [rbx]
	mov [rcx],rax
	add rbx, 8
	add rcx, 8
	mov rax, [rbx]
	mov [rcx], rax
	add rbx, 8
	;add rcx, 8

	; Incremento la cantidad de puntos fuera y listo

	inc r13
	jmp .fin_analisis_segundo_punto

.fin_analisis_segundo_punto:



;_______Tercer y último punto

	mov rcx, [puntero_plano]
	mov rdx, [puntero_triangulo]
	add rdx, TRIANGULO__vertice3
	call Calcular_Distancia_Signada
	mov [distancia_signada_punto3], eax

	; Si la del punto es positiva, la guardo en puntos_dentro (primera posición del array)

	fldz
	fld dword [distancia_signada_punto3]
	fcomip
	fstp st0
	jb .tercer_punto_fuera

.tercer_punto_dentro:	

	; Calculo cuanto es el offset donde tengo que escribir en el array de puntos_dentro
	; Lo cual sería la cantidad de puntos dentro multiplicada por el tamaño de VERTICE

	mov rax, VERTICE_size
	mul r12
	lea rcx, [puntos_dentro]
	add rcx, rax

	; Ahora copio los primeros 8 bytes del triangulo, y luego los otros 8 bytes

	mov rax, [rbx]
	mov [rcx],rax
	add rbx, 8
	add rcx, 8
	mov rax, [rbx]
	mov [rcx], rax
	add rbx, 8
	;add rcx, 8

	; Incremento la cantidad de puntos dentro y listo

	inc r12
	jmp .fin_analisis_tercer_punto
	
.tercer_punto_fuera:

	; Calculo cuanto es el offset donde tengo que escribir en el array de puntos_dentro
	; Lo cual sería la cantidad de puntos dentro multiplicada por el tamaño de VERTICE

	mov rax, VERTICE_size
	mul r13
	lea rcx, [puntos_fuera]
	add rcx, rax

	; Ahora copio los primeros 8 bytes del triangulo, y luego los otros 8 bytes

	mov rax, [rbx]
	mov [rcx],rax
	add rbx, 8
	add rcx, 8
	mov rax, [rbx]
	mov [rcx], rax
	add rbx, 8
	;add rcx, 8

	; Incremento la cantidad de puntos fuera y listo

	inc r13
	jmp .fin_analisis_tercer_punto

.fin_analisis_tercer_punto:








;_______Ya tengo en r12 la cantidad de puntos que están adentro y en r13 los que están afuera



;_______Ahora comienza el proceso de verificar cómo están los puntos, 
;	si afuera o dentro de la sección separada por el plano

	cmp r12, 0   ; están todos afuera?
	je .todos_afuera
	cmp r12, 2		;  IQ = 2500, cuidado
	jb .uno_adentro
	je .dos_adentro    
	ja .todos_adentro



.todos_afuera:
	
	xor rax, rax  ; ningún triángulo generado	
	jmp .fin  ; Ningún triangulo generado. Nada que hacer. 

.todos_adentro:


	; Copio todo el triángulo a triangulo_generado_1

	mov rcx, [puntero_triangulo]
	mov r9, [puntero_triangulo_generado_1]
	xor rbx,rbx

.todos_adentro_loop_relleno:
	
	mov rax, [rcx]
	mov [r9], rax
	add rcx, 8  ; ancho de palabra
	add r9, 8   ; ancho de palabra
	add rbx, 8  ; ancho de palabra
	cmp rbx, TRIANGULO_size
	jb .todos_adentro_loop_relleno

	mov rax, 1  ; el mismo triángulo
	jmp .fin 

	
.uno_adentro:


	; Hay que clippear, por lo que paso el primer vértice al triángulo del clip.

	; Copio el primer vertice 
	
	lea rcx, [puntos_dentro+TRIANGULO__vertice1]
	mov r9, [puntero_triangulo_generado_1]
	add r9, TRIANGULO__vertice1
	mov rax, [rcx]
	mov [r9], rax
	add rcx, 8 ; ancho de palabra
	add r9, 8 ; ancho de palabra
	mov rax, [rcx]
	mov [r9], rax


	; Ahora necesito usar la función intersección recta plano para sacar cuales
	; son el resto de los puntos

	
	mov rcx, [puntero_plano]
	lea rdx, [puntos_dentro+TRIANGULO__vertice1]  
	lea r8, [puntos_fuera+TRIANGULO__vertice1]
	mov r9, [puntero_triangulo_generado_1]
	add r9, TRIANGULO__vertice2
	call Interseccion_Recta_Plano


	mov rcx, [puntero_plano]
	lea rdx, [puntos_dentro+TRIANGULO__vertice1]  
	lea r8, [puntos_fuera+TRIANGULO__vertice2]
	mov r9, [puntero_triangulo_generado_1]
	add r9, TRIANGULO__vertice3
	call Interseccion_Recta_Plano


	; Termino copiando lo del color

	mov rcx, [puntero_triangulo]
	mov rdx, [puntero_triangulo_generado_1]
	add rcx, TRIANGULO__color
	add rdx, TRIANGULO__color
	mov eax, [rcx]
	mov [rdx], eax


	mov rax, 1  ; un triángulo generado
	jmp .fin




	
.dos_adentro:


	; Primero copio el color en ambos triángulos así me lo saco de encima

	mov rcx, [puntero_triangulo]
	mov rdx, [puntero_triangulo_generado_1]
	add rcx, TRIANGULO__color
	add rdx, TRIANGULO__color
	mov eax, [rcx]
	mov [rdx], eax

	mov rcx, [puntero_triangulo]
	mov rdx, [puntero_triangulo_generado_2]
	add rcx, TRIANGULO__color
	add rdx, TRIANGULO__color
	mov eax, [rcx]
	mov [rdx], eax

	; Para el primer triángulo copio el primer vértice y el segundo
	
	lea rcx, [puntos_dentro+TRIANGULO__vertice1]
	mov r9, [puntero_triangulo_generado_1]
	add r9, TRIANGULO__vertice1
	mov rax, [rcx]
	mov [r9], rax
	add rcx, 8 ; ancho de palabra
	add r9, 8 ; ancho de palabra
	mov rax, [rcx]
	mov [r9], rax

	lea rcx, [puntos_dentro+TRIANGULO__vertice2]
	mov r9, [puntero_triangulo_generado_1]
	add r9, TRIANGULO__vertice2
	mov rax, [rcx]
	mov [r9], rax
	add rcx, 8 ; ancho de palabra
	add r9, 8 ; ancho de palabra
	mov rax, [rcx]
	mov [r9], rax

	; El tercer vértice lo saco con intersección del primero de dentro con el primero de afuera

	mov rcx, [puntero_plano]
	lea rdx, [puntos_dentro+TRIANGULO__vertice1]  
	lea r8, [puntos_fuera+TRIANGULO__vertice1]
	mov r9, [puntero_triangulo_generado_1]
	add r9, TRIANGULO__vertice3
	call Interseccion_Recta_Plano


	; Para el segundo triángulo el primer vértice es el segundo de adentro 

	lea rcx, [puntos_dentro+TRIANGULO__vertice2]
	mov r9, [puntero_triangulo_generado_2]
	add r9, TRIANGULO__vertice1
	mov rax, [rcx]
	mov [r9], rax
	add rcx, 8 ; ancho de palabra
	add r9, 8 ; ancho de palabra
	mov rax, [rcx]
	mov [r9], rax
	
	; Luego el segundo es el tercero del primer triángulo


	mov rcx, [puntero_triangulo_generado_1]
	add rcx, TRIANGULO__vertice3
	mov r9, [puntero_triangulo_generado_2]
	add r9, TRIANGULO__vertice2
	mov rax, [rcx]
	mov [r9], rax
	add rcx, 8 ; ancho de palabra
	add r9, 8 ; ancho de palabra
	mov rax, [rcx]
	mov [r9], rax

	; Y por último el tercero es intersección con el segundo de los de adentro con el primero de afuera


	mov rcx, [puntero_plano]
	lea rdx, [puntos_dentro+TRIANGULO__vertice2]  
	lea r8, [puntos_fuera+TRIANGULO__vertice1]
	mov r9, [puntero_triangulo_generado_2]
	add r9, TRIANGULO__vertice3
	call Interseccion_Recta_Plano


	mov rax, 2 ; dos triángulos generados
	jmp .fin


.fin:


	pop rbx
	pop r12
	pop r13
	mov rsp, rbp
	pop rbp
	ret













