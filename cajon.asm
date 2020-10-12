; Acá vuelco funciones que dejé de utilizar pero me parecen útiles


;--------------------------------------------------------------------

; Para tomar los argumentos del command line

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
