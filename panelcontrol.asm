

;--- Figura ---------------------------------------------------------

;COLOR_FIGURA 			equ 0x00B0DAF0   ; RGBA, en little endian (AABBGGRR). Dejar el Alpha en 00


ALTURA_PERSONAJE equ 0x44dac000


;--- Configuración de ventana ---------------------------------------

ANCHO_PANTALLA       		equ 1366
ALTO_PANTALLA        		equ 768
ANCHO_PANTALLA_FLOAT		equ 0x44aac000
ALTO_PANTALLA_FLOAT		equ 0x44400000

FSP_MITAD_ANCHO_PANTALLA 	equ 0x442ac000   ; 683 en float 32
FSP_MITAD_ALTO_PANTALLA  	equ 0x43c00000   ; 384 en float 32

;--- Configuración 3D -----------------------------------------------

ANGULO_FOV	 equ 0x3fc90fdb  ;0x3f490fdb   ; Ojo! que el angulo es pi/4. Luego divido por dos en la función, resultando en pi/8
ZFAR 	 	 equ 0x47c35000 ; 100000 ;0x49742400   ; 1000000 ;  ANTES: 0x447a0000   ; 1000
ZNEAR 		 equ 0x3f800000   ; 1 ; 0x3dcccccd	  ; 0.1 


; NOTA SOBRE EL ANGULO FOV:
;----------------------------

; Me funciona mejor con pi/4 que con pi/2. Lo veo más realista... Le dejé el pi/4 

; Algunos para probar:  0x3f490fdb  (pi/4)
;			0x3fc90fdb  (pi/2)

; No usar pi que da infinito! 


;--------------------------------------------------------------------