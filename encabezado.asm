; --- Constantes básicas de Windows (Extendidas, 64 bits , v1.04) ---

; Todo lo que pongas ya sean mensajes, recursos a usar y demás, lo
; tenés que meter acá.

%define FALSO 0
%define VERDADERO 1

%define IMAGE_BITMAP 0
%define LR_LOADFROMFILE 0x00000010
%define LR_CREATEDIBSECTION 0x00001000
%define SRCCOPY 0xCC0020

%define OFFSET_TGA 18         ; No sirve para nada ahora pero por las dudas lo mantengo

%define SHADOWSPACE 32
%define PARAMETROS 8

ULTIMO_PLANO_PREPROYECCION equ 2
ULTIMO_PLANO_POSTPROYECCION equ 7



;Lo siguiente son las constantes usadas en las funciones del winapi


ANSI_CHARSET         EQU 0                      
BLACKNESS            EQU 42h
CLIP_DEFAULT_PRECIS  EQU 0
CS_BYTEALIGNWINDOW   EQU 2000h
CS_HREDRAW           EQU 2
CS_VREDRAW           EQU 1
DEFAULT_PITCH        EQU 0
ES_AUTOHSCROLL       EQU 80h
ES_CENTER            EQU 1
FALSE                EQU 0
FILE_ATTRIBUTE_NORMAL EQU 0x80
GRAY_BRUSH           EQU 2
GENERIC_READ	     EQU 10000000000000000000000000000000b   ;si lo lee en little endian esto esta mal, deberia valer 1 nomas
IDC_ARROW            EQU 7F00h
IDI_APPLICATION      EQU 7F00h
IDNO                 EQU 7
IMAGE_CURSOR         EQU 2
IMAGE_ICON           EQU 1
LR_SHARED            EQU 8000h
MB_DEFBUTTON2        EQU 100h
MB_YESNO             EQU 4
NULL                 EQU 0
NULL_BRUSH           EQU 5
OPAQUE               EQU 2
OPEN_EXISTING 	     EQU 3
PROOF_QUALITY        EQU 2
SM_CXFULLSCREEN      EQU 10h
SM_CYFULLSCREEN      EQU 11h
SM_CXSIZE	     equ 0     ; este es el valor de la pantalla posta, el fullscreen es medio verso
SM_CYSIZE 	     equ 1	; idem, para la altura
SS_CENTER            EQU 1
SS_NOTIFY            EQU 100h
SW_SHOWNORMAL        EQU 1
TRUE                 EQU 1

;--- Mensajes -------------------------------------------------------

WM_CLOSE             EQU 10h
WM_COMMAND           EQU 111h
WM_CREATE            EQU 1
WM_CTLCOLOREDIT      EQU 133h
WM_CTLCOLORSTATIC    EQU 138h
WM_DESTROY           EQU 2
WM_LBUTTONDOWN       EQU 0x201
WM_PAINT             EQU 0Fh
WM_SETFONT           EQU 30h
WM_TIMER	     EQU 0x0113
WM_KEYDOWN	     EQU 0x0100



OUT_DEFAULT_PRECIS   EQU 0

WS_CHILD             EQU 40000000h
WS_EX_COMPOSITED     EQU 2000000h
WS_OVERLAPPEDWINDOW  EQU 0CF0000h
WS_TABSTOP           EQU 10000h
WS_VISIBLE           EQU 10000000h
WS_POPUP             EQU 80000000h


;--- Teclas ---------------------------------------------------------

VK_A equ 0x41
VK_D equ 0x44
VK_S equ 0x53
VK_W equ 0x57
VK_R equ 0x52
VK_F equ 0x46
VK_Q equ 0x51
VK_E equ 0x45




;--- SIMBOLOS EXTERNOS (Funciones de WIN API, no decoradas) ---------

extern AdjustWindowRectEx                    
extern BeginPaint                              
extern BitBlt
extern CloseHandle
extern CreateCompatibleDC
extern CreateCompatibleBitmap
extern CreateDIBSection
extern CreateFileA
extern CreateFileW
extern CreateFontA
extern CreatePen
extern CreateSolidBrush
extern CreateWindowExA
extern DefWindowProcA
extern DeleteDC
extern DeleteObject
extern DestroyWindow
extern DispatchMessageA
extern EndPaint
extern ExitProcess
extern FillRect
extern GetClientRect
extern GetCommandLineW
extern GetCommandLineA
extern GetDCEx
extern GetDC
extern GetDlgCtrlID
extern GetFileSizeEx
extern GetStockObject
extern GetMessageA
extern GetModuleHandleA
extern GetModuleFileNameW
extern GetObjectA
extern GetSystemMetrics
extern HeapAlloc
extern HeapCreate
extern HeapDestroy
extern HeapFree
extern HeapReAlloc
extern HeapSize
extern InvalidateRect
extern IsDialogMessageA
extern LineTo
extern LocalFree
extern LockWindowUpdate
extern MoveToEx
extern LoadImageA
extern LoadBitmapA
extern MessageBoxA
extern PeekMessageA
extern Polygon
extern PostQuitMessage
extern QueryPerformanceCounter
extern QueryPerformanceFrequency
extern ReadFile
extern ReadFileEx
extern RedrawWindow
extern RegisterClassExA
extern ReleaseDC
extern SelectObject
extern SendMessageA
extern SetBkColor
extern SetBkMode
extern SetFilePointerEx
extern SetFilePointer
extern SetTextColor
extern SetTimer
extern KillTimer
extern ShowWindow
extern TranslateMessage
extern UpdateWindow
extern ValidateRect



;----------------------------;
;------- ESTRUCTURAS --------;
;----------------------------;

struc WC

	WC__cbSize		resb 4
	WC__style		resb 4
	WC__lpfnWndProc		resb 8
	WC__cbClsExtra 		resb 4
	WC__cbWndExtra		resb 4
	WC__hInstance		resb 8
	WC__hIcon		resb 8
	WC__hCursor		resb 8
	WC__hbrBackground	resb 8
	WC__lpszMenuName	resb 8
	WC__lpszClassName	resb 8
	WC__hIconSm		resb 8

endstruc

;----------------------------

struc MSG

	MSG__hwnd		resb 8
	MSG__message		resb 4
	MSG__Padding1		resb 4
	MSG__wParam		resb 8
	MSG__lParam		resb 8
	MSG__time		resb 4
	MSG__py.x		resb 4
	MSG__pt.y		resb 4
	MSG__Padding2		resb 4

endstruc



;----------------------------

struc BITMAP

	BITMAP__bmType resq 1
	BITMAP__bmWidth resq 1
	BITMAP__bmHeight resq 1
	BITMAP__bmWidthBytes resq 1
	BITMAP__bmPlanes resd 1
	BITMAP__bmBitsPixel resd 1
	BITMAP__bmBits resq 1

endstruc

;----------------------------


align 16
struc VERTICE
	
	VERTICE__x resd 1    ; Estos cuatro son floats de precisión simple
	VERTICE__y resd 1    	
	VERTICE__z resd 1
	VERTICE__w resd 1

endstruc  ; esto pesaría 16 bytes


;----------------------------


struc COLOR
	
	COLOR__rojo 	resb 1
	COLOR__verde 	resb 1
	COLOR__azul 	resb 1
	COLOR__alfa     resb 1


endstruc  ; esto pesaría 4 bytes

;----------------------------


struc TRIANGULO
	
	TRIANGULO__vertice1 	resb VERTICE_size
	TRIANGULO__vertice2 	resb VERTICE_size
	TRIANGULO__vertice3 	resb VERTICE_size
	TRIANGULO__color 	resb COLOR_size
	TRIANGULO__normal_x	resb 4
	TRIANGULO__normal_y	resb 4
	TRIANGULO__normal_z	resb 4

endstruc  ; esto pesaría 64 bytes, y siempre debe ocupar un múltiplo de 16


;----------------------------

struc PROYECCION

	PROYECCION__alto_pantalla resd 1
	PROYECCION__ancho_pantalla resd 1
	PROYECCION__angulo_FOV resd 1
	PROYECCION__z_far resd 1
	PROYECCION__z_near resd 1

endstruc  ; pesa 20 bytes

;----------------------------


struc MATRIZ
	
	MATRIZ__11 resd 1
	MATRIZ__21 resd 1
	MATRIZ__31 resd 1
	MATRIZ__41 resd 1
	MATRIZ__12 resd 1
	MATRIZ__22 resd 1
	MATRIZ__32 resd 1
	MATRIZ__42 resd 1
	MATRIZ__13 resd 1
	MATRIZ__23 resd 1
	MATRIZ__33 resd 1
	MATRIZ__43 resd 1
	MATRIZ__14 resd 1
	MATRIZ__24 resd 1
	MATRIZ__34 resd 1
	MATRIZ__44 resd 1

endstruc  ; esto pesa 64, y está como column-major

;----------------------------


struc VECTOR4

	VECTOR4__1 resd 1
	VECTOR4__2 resd 1
	VECTOR4__3 resd 1
	VECTOR4__4 resd 1

endstruc


;----------------------------

struc TIMER

	TIMER__frecuencia resq 1
	TIMER__tiempo_inicial resq 1
	TIMER__tiempo_final resq 1
	TIMER__tiempo_transcurrido resq 1

endstruc

;----------------------------

struc PUNTOS

	PUNTOS__x_1 resd 1
	PUNTOS__y_1 resd 1
	PUNTOS__x_2 resd 1
	PUNTOS__y_2 resd 1
	PUNTOS__x_3 resd 1
	PUNTOS__y_3 resd 1

endstruc


;----------------------------

struc OBJETO_3D

	OBJETO_3D__handle_memoria		resq 1	
	OBJETO_3D__activado			resb 1
	OBJETO_3D__color_por_defecto		resq 1   ; Pensar esto porque la estructura triangulo ya tiene color
						 	 ;  y es mejor que cada triangulo tenga el suyo y hacer efectos copados... o no 
	OBJETO_3D__puntero_triangulos		resq 1   
	OBJETO_3D__cantidad_triangulos		resq 1
	OBJETO_3D__posicion_x			resd 1
	OBJETO_3D__posicion_y			resd 1
	OBJETO_3D__posicion_z			resd 1
	OBJETO_3D__velocidad_x			resd 1   ; fijarse porque puede que haya puesto 64 bits
	OBJETO_3D__velocidad_y			resd 1
	OBJETO_3D__velocidad_z			resd 1
	OBJETO_3D__angulo_x			resd 1
	OBJETO_3D__angulo_y			resd 1
	OBJETO_3D__angulo_z			resd 1
	OBJETO_3D__velocidad_angular_x		resd 1   ; fijarse porque puede que haya puesto 64 bits.
	OBJETO_3D__velocidad_angular_y		resd 1
	OBJETO_3D__velocidad_angular_z		resd 1
	OBJETO_3D__escala_general		resd 1

	; podemos meter acá los colisionadores, pero ver bien eso porque dependerán de cada objeto y creo que podríamos
	; utilizar cubos o esferas hechas con el blender mismo. Verlo bien, pero más adelante
	; Lo que es importante acá es usar muy fielmente el _size

endstruc	

;-----------------------------


struc RASTERIZACION
 
	RASTERIZACION__handle_del_heap		resq 1
	RASTERIZACION__espacio_maximo_requerido	resd 1
	RASTERIZACION__puntero_inicio		resq 1
	RASTERIZACION__puntero_escritura 	resq 1   ; el puntero que uso para escribir los triangulos de todos los objetos
	RASTERIZACION__cantidad 		resq 1 

endstruc


;----------------------------

struc BITMAPINFOHEADER

	BITMAPINFOHEADER__size	 		resd 1
	BITMAPINFOHEADER__width 		resd 1
	BITMAPINFOHEADER__height		resd 1
	BITMAPINFOHEADER__planes		resw 1
	BITMAPINFOHEADER__bitCount		resw 1
	BITMAPINFOHEADER__compression		resd 1
	BITMAPINFOHEADER__sizeImage		resd 1
	BITMAPINFOHEADER__xPelsPerMeter		resd 1
	BITMAPINFOHEADER__yPelsPerMeter		resd 1
	BITMAPINFOHEADER__clrUsed		resd 1
	BITMAPINFOHEADER__clrImportant		resd 1

endstruc

;----------------------------

struc RGBQUAD
	
	RGBQUAD__blue		resb 1
	RGBQUAD__green		resb 1
	RGBQUAD__red		resb 1
	RGBQUAD__reservado	resb 1

endstruc

;----------------------------

struc BITMAPINFO

	BITMAPINFO__header	resb BITMAPINFOHEADER_size
	BITMAPINFO__colors	resb RGBQUAD_size*2	

endstruc

;----------------------------

struc DATOS_PLANO

	DATOS_PLANO__normal 	resb VECTOR4_size
	DATOS_PLANO__punto 	resb VECTOR4_size 

endstruc

;----------------------------

struc PLANOS_PREPROYECCION

	PLANOS_PREPROYECCION__puntero_near resq 1 
	PLANOS_PREPROYECCION__puntero_far resq 1
	PLANOS_PREPROYECCION__puntero_fin resq 1

endstruc

;----------------------------

struc PLANOS_POSTPROYECCION

	PLANOS_POSTPROYECCION__puntero_derecho resq 1 
	PLANOS_POSTPROYECCION__puntero_izquierdo resq 1
	PLANOS_POSTPROYECCION__puntero_arriba resq 1
	PLANOS_POSTPROYECCION__puntero_abajo resq 1
	PLANOS_POSTPROYECCION__puntero_fin resq 1

endstruc







