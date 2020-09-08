;LISTO! Funciona, solo tenemos que hacer lo siguiente:

;poner "conversor nombrearchivo.tga"
;y luego deberíamos poner "ren mascara.msk nombrearchivo.msk" o algo asi
;ya que todos se van a llamar mascara.msk

;Ahora viene lo grande... pensar qué tamaño debe tener 
;el espacio para hacer la mascara...


;----------------------------------------------------------

%define FALSO 0
%define VERDADERO 1
%define NULL 0

extern GetCommandLineA
extern CloseHandle
extern ExitProcess
extern ReadFile
extern CreateFileA
extern WriteFile
extern MessageBoxA


GENERIC_READ	     EQU 10000000000000000000000000000000b   ;si lo lee en little endian esto esta mal, deberia valer 1 nomas
GENERIC_WRITE	     EQU 01000000000000000000000000000000b   

;GENERIC_READ EQU 1
;GENERIC_WRITE EQU 2

INVALID_HANDLE_VALUE EQU -1


OPEN_EXISTING equ 3
CREATE_ALWAYS equ 2
FILE_ATTRIBUTE_NORMAL EQU 0x80

;--------------------------------------------------------------------


%define ESPACIO_VIRTUAL 1366*768

%define TAMANO_ARCHIVO ((ESPACIO_VIRTUAL*4)+18+4)   ;es lo que mide el TGA de prueba * 4 porque es de 32 bits cada pixel
					;más el offset del TGA (18) y más 4 changui porque no sé

%define TAMANO_BUFFER ESPACIO_VIRTUAL


global Start


;--------------------------------------------------------------------

section .data

ruta_origen db 'prueba.tga',0
ruta_destino db 'mascara.msk',0

error1 db 'Fallo en el CreateFile de origen',0
error2 db 'Fallo en el read file de origen',0
error3 db 'Fallo en el create file de destino',0
error4 db 'Fallo en el read file de destino',0

titulo_error db 'Error',0


;--------------------------------------------------------------------

section .bss

buffer_origen resb TAMANO_ARCHIVO
buffer_destino resb TAMANO_BUFFER
handle_archivo resq 1


;-----------------------------------------------------------------
section .text


Start:


;_______Recuperamos el argumento (a ver si es como el linux)

	
	push rbp
	mov rbp, rsp
	sub rsp, 8 + 32 + 64 + 8   ; alineamiento + shadowspace + arg + mult. 16 
	

	call GetCommandLineA

	add rax, 11    ;esto es una negrada.Como todo me lo tira a una cadena, 
        		;sumo 11 que son las letras de la palabra conversor mas dos posiciones
	mov rcx, rax

	
;_______Abrimos el archivo

	mov rdx, GENERIC_READ
	mov r8, 0 ; NULL, evita que otros procesos operen el archivo (no hay "share")
	mov r9, 0 ; NULL
	mov qword [RSP + 4 * 8], OPEN_EXISTING
	mov qword [RSP + 5 * 8], FILE_ATTRIBUTE_NORMAL
	mov qword [RSP + 6 * 8], NULL
	call CreateFileA

	cmp rax, INVALID_HANDLE_VALUE
	je _error1
	mov [handle_archivo], rax		




;_______Leemos el archivo y ponemos todo en buffer_origen

	xor r9, r9
	xor r8, r8


	mov rcx, [handle_archivo]
	mov rdx, buffer_origen
	mov r8d, TAMANO_ARCHIVO
	mov r9, NULL 			; es para el overlapped, no lo necesito.
	mov qword [RSP + 4 * 8], NULL   ; idem
	call ReadFile

	
;_______Cerramos el archivo

	mov rcx, [handle_archivo]
	call CloseHandle


;_______Creamos un archivo nuevo, reemplazando el que ya hubiese

	xor r9, r9
	xor r8, r8


	mov rcx, ruta_destino
	mov rdx, GENERIC_WRITE
	mov r8, 0 ; NULL, evita que otros procesos operen el archivo (no hay "share")
	mov r9, 0 ; NULL
	mov qword [RSP + 4 * 8], CREATE_ALWAYS
	mov qword [RSP + 5 * 8], FILE_ATTRIBUTE_NORMAL
	mov qword [RSP + 6 * 8], NULL
	call CreateFileA

	cmp rax, INVALID_HANDLE_VALUE
	je _error2
	mov [handle_archivo], rax



;_______Volcamos el buffer ahi. De momento vamos a usar unos pocos bytes, solo para ver cómo queda.

	mov r12, buffer_origen+18   ; 12 es el offset del TGA
	mov r13, buffer_destino
	mov rbx, 0   ; pensarla bien, igual debería recuperar esta info

ciclo:
	
	mov eax, [r12]			; Copio un bloque de 32 bits lo que está en r12
	mov [r13], al			; Solo copio el primer bit (FF si es blanco, otro si es mascara)
	
	add r12, 4			; sumo 4 bytes / 32 bits
	add r13, 1
	inc rbx	

	cmp rbx, TAMANO_BUFFER
	jne ciclo

;_______Escribo en el archivo


	xor r9, r9
	xor r8, r8

	mov rcx, [handle_archivo]
	mov rdx, buffer_destino
	mov r8d, TAMANO_BUFFER
	mov r9d, 0
	mov qword [RSP + 4 * 8], NULL
	call WriteFile

	

;_______Cierro el archivo

	mov rcx, [handle_archivo]
	call CloseHandle

;_______Salimos

	xor rax, rax
	mov rsp, rbp
	pop rbp

	call ExitProcess  





_test:

	mov rcx, 0
	mov r8, titulo_error
	mov r9d, 0
	call MessageBoxA	
	call ExitProcess



_error1:

	mov rcx, 0            ;uso el desktop
	mov rdx, error1
	mov r8, titulo_error
	mov r9d, 0
	call MessageBoxA
	call ExitProcess

	
_error2:


	mov rcx, 0            ;uso el desktop
	mov rdx, error2
	mov r8, titulo_error
	mov r9d, 0
	call MessageBoxA
	call ExitProcess	

_error3:


	mov rcx, 0            ;uso el desktop
	mov rdx, error3
	mov r8, titulo_error
	mov r9d, 0
	call MessageBoxA
	call ExitProcess

_error4:

	mov rcx, 0            ;uso el desktop
	mov rdx, error4
	mov r8, titulo_error
	mov r9d, 0
	call MessageBoxA
	call ExitProcess