; Esto no es para librería, sino diseñado para el programa que estoy haciendo nomás
; así que no me voy a gastar en controles ni nada

; Creas un vector con una estructura, tipo

struc ARRAY_DINAMICO

	ARRAY_DINAMICO__handle_del_heap			resq 1
	ARRAY_DINAMICO__puntero_del_heap		resq 1
	ARRAY_DINAMICO__cantidad_elementos		resq 1
	ARRAY_DINAMICO__tamanio_elementos		resq 1   ; Ponerlo como multiplo de 8
	ARRAY_DINAMICO__tamanio_array			resq 1

endstruc




%define TAMANIO_ARRAY_PREDETERMINADO TRIANGULO_size*100000   ; espacio inicial para 100000 triangulos
%define TAMANIO_EXTRA_AGREGADO TRIANGULO_size*100000	    ; espacio agregado para 100000 triangulos más 


; Funciones:
;--------------


Crear_Array_Dinamico:

	;En rcx va el puntero del array 
	;En rdx debería ir el tamaño de los elementos	



	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE
	push rbx

	mov rbx, rcx
	mov [rbx+ARRAY_DINAMICO__tamanio_elementos], rdx

	mov rcx, 0
	mov rdx, 0
	mov r8, 0
	call HeapCreate
	
	mov [rbx+ARRAY_DINAMICO__handle_del_heap], rax
	mov rcx, rax
	mov rdx, 0
	mov r8, TAMANIO_ARRAY_PREDETERMINADO
	call HeapAlloc
	mov [rbx+ARRAY_DINAMICO__puntero_del_heap], rax 
	
	mov rcx, TAMANIO_ARRAY_PREDETERMINADO
	mov [rbx+ARRAY_DINAMICO__tamanio_array], rcx
	xor rcx, rcx
	mov [rbx+ARRAY_DINAMICO__cantidad_elementos], rcx



	pop rbx
	mov rsp, rbp
	pop rbp
	ret


;------------------------------------------------------------------------------


Pushback_Array_Dinamico:

	; en rcx va el puntero del array
	; en rdx va el puntero del valor que estoy metiendo
	

	push rbp
	mov rbp, rsp
	sub rsp, SHADOWSPACE + 64  ; hago mucho push, porsia
	push rbx
	push r10
	push r13
	push r12



	mov r13, rcx

	mov r10, rdx
	xor rdx,rdx
	mov rbx, [r13+ARRAY_DINAMICO__puntero_del_heap]
	mov r8, [r13+ARRAY_DINAMICO__tamanio_elementos]
	mov r12, [r13+ARRAY_DINAMICO__cantidad_elementos]

	; Primero voy a donde me indica "cantidad * tamanio_elementos"

	mov rax, r12
	mul r8
	add rbx, rax
	

	; Verifico si (cantidad+1)*tamanio_elementos < tamanio_array    
	
	inc r12
	mov rax, r12
	mul r8
	

	; Si no se cumple, necesito reubicar más memoria
	
	
	cmp rax, [r13+ARRAY_DINAMICO__tamanio_array]
	jb .relleno

	mov rcx, [r13+ARRAY_DINAMICO__handle_del_heap]
	xor rdx, rdx ; sin flags
	mov r8, [r13+ARRAY_DINAMICO__puntero_del_heap]
	mov r9, [r13+ARRAY_DINAMICO__tamanio_array]
	add r9, TAMANIO_EXTRA_AGREGADO
	mov [r13+ARRAY_DINAMICO__tamanio_array], r9
	call HeapReAlloc
	mov [r13+ARRAY_DINAMICO__puntero_del_heap],rax
	mov rbx, rax

	mov r8, [r13+ARRAY_DINAMICO__tamanio_elementos]
	mov rax, [r13+ARRAY_DINAMICO__cantidad_elementos]
	mul r8
	add rbx, rax
	mov rcx, r13


	; Ahora cargo los valores (multiplos de 8, acordate)

.relleno:

	xor r13, r13

.loop_relleno:

	cmp r13, [rcx+ARRAY_DINAMICO__tamanio_elementos]
	jae .fin_loop_relleno


	mov rax, [r10]
	mov [rbx], rax
	add r13, 8
	add r10, 8
	add rbx, 8
	jmp .loop_relleno
	
.fin_loop_relleno:
	
	inc r12
	mov [rcx+ARRAY_DINAMICO__cantidad_elementos], r12


	pop r12
	pop r13	
	pop r10
	pop rbx
	mov rsp, rbp
	pop rbp
	ret

%undef TAMANIO_ARRAY_PREDETERMINADO	
%undef TAMANIO_EXTRA_AGREGADO	
















