; --- Constantes básicas de Windows (Extendidas, 64 bits , v1.04) ---

; Todo lo que pongas ya sean mensajes, recursos a usar y demás, lo
; tenés que meter acá.

%define FALSO 0
%define VERDADERO 1

%define IMAGE_BITMAP 0
%define LR_LOADFROMFILE 0x00000010
%define LR_CREATEDIBSECTION 0x00001000
%define SRCCOPY 0xCC0020

%define ANCHO_MASCARA 1366    ; Coincide con el ancho de pantalla pero no necesariamente debe ser así
%define OFFSET_TGA 18         ; No sirve para nada ahora pero por las dudas lo mantengo

%define SHADOWSPACE 32
%define PARAMETROS 8


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



OUT_DEFAULT_PRECIS   EQU 0

WS_CHILD             EQU 40000000h
WS_EX_COMPOSITED     EQU 2000000h
WS_OVERLAPPEDWINDOW  EQU 0CF0000h
WS_TABSTOP           EQU 10000h
WS_VISIBLE           EQU 10000000h
WS_POPUP             EQU 80000000h



;--- Constantes propias ---------------------------------------------

WindowWidth          EQU 640
WindowHeight         EQU 170
FullScreenWidth      EQU 1366
FullScreenHeight     EQU 768


;--- NIPU -----------------------------------------------------------

; Esto es del programa en sí 

Static1ID            EQU 100
Static2ID            EQU 101
Edit1ID              EQU 102
Edit2ID              EQU 103

;--- SIMBOLOS EXTERNOS (Funciones de WIN API) -----------------------

extern AdjustWindowRectEx                       ; Import external symbols
extern BeginPaint                               ; Windows API functions, not decorated
extern BitBlt
extern CloseHandle
extern CreateCompatibleDC
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
extern GetProcessHeap
extern GetSystemMetrics
extern HeapAlloc
extern HeapDestroy
extern HeapFree
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


struc BITMAP

	bmType resq 1
	bmWidth resq 1
	bmHeight resq 1
	bmWidthBytes resq 1
	bmPlanes resd 1
	bmBitsPixel resd 1
	bmBits resq 1

endstruc

;----------------------------


align 16
struc VERTICE
	
	x resd 1    ; Estos cuatro son floats de precisión simple
	y resd 1    	
	z resd 1
	w resd 1

endstruc  ; esto pesaría 16 bytes


;----------------------------


struc COLOR
	
	alfa    resb 1
	rojo 	resb 1
	verde 	resb 1
	azul 	resb 1

endstruc  ; esto pesaría 4 bytes

;----------------------------


struc TRIANGULO
	
	vertice1 resb VERTICE_size
	vertice2 resb VERTICE_size
	vertice3 resb VERTICE_size
	color resb COLOR_size
	padding resb 12  	;esto es para que estén alineados a 16 bytes

endstruc  ; esto pesaría 64 bytes, y siempre debe ocupar un múltiplo de 16


;----------------------------

struc PROYECCION

	alto_pantalla resd 1
	ancho_pantalla resd 1
	angulo_FOV resd 1
	z_far resd 1
	z_near resd 1

endstruc  ; pesa 20 bytes

;----------------------------


struc MATRIZ
	
	matriz_11 resd 1
	matriz_12 resd 1
	matriz_13 resd 1
	matriz_14 resd 1
	matriz_21 resd 1
	matriz_22 resd 1
	matriz_23 resd 1
	matriz_24 resd 1
	matriz_31 resd 1
	matriz_32 resd 1
	matriz_33 resd 1
	matriz_34 resd 1
	matriz_41 resd 1
	matriz_42 resd 1
	matriz_43 resd 1
	matriz_44 resd 1

	

endstruc  ; esto pesa 64, y está como row-major

;----------------------------


struc VECTOR4

	vector_1 resd 1
	vector_2 resd 1
	vector_3 resd 1
	vector_4 resd 1

endstruc


;----------------------------

struc TIMER
	frecuencia resq 1
	tiempo_inicial resq 1
	tiempo_final resq 1
	tiempo_transcurrido resq 1
endstruc

;----------------------------

struc PUNTOS

	x_1 resd 1
	y_1 resd 1
	x_2 resd 1
	y_2 resd 1
	x_3 resd 1
	y_3 resd 1

endstruc
