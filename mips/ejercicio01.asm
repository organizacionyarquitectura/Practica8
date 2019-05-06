# Práctica 8
# Calculadora posfija con exepciones

# macros generales

# Imprimir cadenas
# $a0 bede contener un apuntador al inicio de la cadena
	.macro printStr
	move	$t0 $v0
	li	$v0 4
	syscall
	move	$v0 $t0
	.end_macro
	
# Leer cadenas
# el apuntador al inicio se guarda en %r
	.macro readStr(%r)
	move	$t0 $v0
	move	$t1 $a0
	move	$t2 $a1
	li 	$v0 8
	move 	$a0 %r
	li 	$a1 100
	syscall
	move	%r $a0
	move	$v0 $t0
	move	$a0 $t1 
	move	$a1 $t2
	.end_macro

#Imprimir enteros
# %s tiene en entero a imprimir
	.macro printInt(%s)
	move	$t0 $v0
	li	$v0 1
	move	$t1 $a0
	move	$a0 %s
	syscall
	move	$v0 $t0
	move	$a0 $t1
	.end_macro
	
#Imprimir caractéres
# %s tiene el caractés a imprimir
	.macro printChar(%s)
	move	$t0 $v0
	li	$v0 11
	move	$t1 $a0
	move	$a0 %s
	syscall
	move	$v0 $t0
	move	$a0 $t1
	.end_macro
	
# Revisa si la cadena en %s es "exit".
# Termina la ejecución en ese caso	
	.macro checkExit(%s)
	lw	$t0 (%s)
	la	$t1 exStr
	lw	$t1 ($t1)
nCh:	beqz	$t0 chEnd
	bne	$t0 $t1 nEx
	addi	$t0 $t0 1
	addi	$t1 $t0 1
	j nCh
chEnd:	beqz	$t1 exit
nEx:	
	.end_macro
	
# operaciones con la pila

	.macro push(%s)
	addi	$sp $sp 4
	sw	%s ($sp)
	.end_macro
	
	.macro pop(%s)
	teq	$sp $s7
	lw	%s ($sp)
	subi	$sp $sp 4
	.end_macro
# parseo de números
# parsea el número si es posible, y lo agrega a la pila
	.macro getNum
	subi	$t0 $s4 48 # obtener valor numérico del código ascii
	addi	$s1 $s1 1
lNum:	lw	$s4 ($s1)
	bge	$s4 58 numDone # no número
	ble	$s4 47 numDone # no número
	subi	$t1 $s4 48 # obtener valor numérico del código ascii
	mulo	$t0 $t0 10
	add	$t0 $t0 $t1
	addi	$s1 $s1 1
	j lNum
numDone:
	push($t0)
	.end_macro
	
# revisa que el caracter sea válido
	.macro checkChar(%s)
	beq	%s 32, val # espacio, caracter que es válido
	tgei	%s 58 # caracter no válido, fuera de rango
	tlti	%s 42 # caracter no válido, fuera de rango
	teqi	%s 44 # ´ 
	teqi	%s 47 # /
val:
	.end_macro

# Realiza el parseo y la ejecución de la operación
	.macro proccess(%s)
	move	$s1 %s
	move	$s7 $sp
nCh:	lw	$s4 ($s1)
	beqz	$s4 prEnd
	checkChar($s4)
	addi	$s1 $s1 1
	beq	$s4 43 sum # +
	beq	$s4 45 dif # -
	beq	$s4 42 mu # *
	beq	$s4 47 di # /
	getNum
	j nCh
sum:
	pop($s2)
	pop($s3)
	add $t0 $s2 $s3
	push($t0)
dif:
	pop($s2)
	pop($s3)
	sub $t0 $s2 $s3
	push($t0)
mu:
	pop($s2)
	pop($s3)
	mulo $t0 $s2 $s3
	push($t0)
di:
	pop($s2)
	pop($s3)
	div $t0 $s2 $s3
	push($t0)
	j nCh
prEnd:	pop($v0)
	tne	$sp $s7
	.end_macro
	
# variables
	.data
bienv:	.asciiz "Calculadora posfija\n"
inst:	.asciiz "Ingrese algo\n"
end:	.asciiz "Terminando programa\n"
res:	.asciiz "Resultado: \n"
exStr:	.ascii "exit"
buff:	.space 101
	
# cadigo de la calculadora
	.text
	
	la	$a0 bienv
	printStr
nextQ:	la	$a0 inst
	printStr
	la	$s0 buff
	readStr($s0)
	
	checkExit($s0)
	proccess($s0)
	
	la	$a0 res
	printStr
	printInt($v0)
	j nextQ
	

exit:
	la	$a0 end
	printStr
	li	$a0 10
	syscall
	
# macros especiales para el manejo de exepciones

# imprime la operación en la que se causó la exepción
	.macro printCurrentOp
	la	$a0 op
	printStr
	printInt($s2)
	printChar($s4)
	printInt($s3)
	li	$t0 '\n'
	printChar($t0)
	.end_macro
	
# imprime el caractér leído y su posición cuando ocurrió la exepción
	.macro printInfoChar
	la	$a0 char
	printStr
	printChar($s4)
	la	$a0 pos
	printStr
	sub	$t0 $s1 $s0
	printInt($t0)
	li	$t0 10 # \n
	printChar($t0)
	.end_macro

# Variables utilizadas en manejo de exepciones
	.kdata
# Texto a imprimir en exepciones
exDes:	.asciiz	"Error: desbordamiento aritmético\n"
exZero:	.asciiz "Error: división por cero\n"
exInv:	.asciiz "Error: expresión inválida\n"
op:	.asciiz "Operación: "
char:	.asciiz "Caracter: "
pos:	.asciiz "Posición: "

# Código para manejo de exepciones
	.ktext 0x80000180
	
# Obtener causa de la expeción
	mfc0	$k0 $13 # Cargar registro de causa
	andi	$k0 $k0 0x00007c # Quedarse sólo con le código de expeción
	srl	$k0 $k0 2 # Mover el código de exepción al inicio del registro
	
# Redireccionar a donde se va a manejar ese tipo de exepción.
	beq	$k0 12 desbord # Exepción por desbordamiento
	beq	$k0 9 divzero # Exepción por división entre cero
	beq	$k0 13 invalid # Exepción por expresión inválida
	
# Otro tipo de exepciones son ignoradas
	j	resume

# Exepción por desbordamiento
# Imprime mensaje de error y operación que la causó
desbord:
	la	$a0 exDes
	printStr
	printCurrentOp
	j resume
	
# Exepción por divisón entre cero
# Imprime mensaje de error y operación que la causó
divzero:
	la	$a0 exZero
	printStr
	printCurrentOp
	j resume
	
# Exepción por expresión inválida
# Imprime mensaje de error y caracter que la causó
invalid:
	la	$a0 exInv
	printStr
	printInfoChar
	j resume
	
# Regresar a la ejecución normal
resume:
	la	$k0 nextQ
	mtc0	$k0 $14
	eret
