# Práctica 8
# Calculadora posfija con exepciones

# Macros generales
# Marco para imprimir cadenas
# $a0 debe contener un apuntador al inicio de la cadena
	.macro printStr
	move	$t0 $v0
	li	$v0 4
	syscall
	move	$v0 $t0
	.end_macro
	
# Marco para leer cadenas
# El apuntador al inicio se guarda en %r
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

#Marco para imprimir enteros
# %s tiene el entero a imprimir
	.macro printInt(%s)
	move	$t0 $v0
	li	$v0 1
	move	$t1 $a0
	move	$a0 %s
	syscall
	move	$v0 $t0
	move	$a0 $t1
	.end_macro
	
#Imprimir caracteres
# %s tiene el caracter a imprimir
	.macro printChar(%s)
	move	$t0 $v0
	li	$v0 11
	move	$t1 $a0
	move	$a0 %s
	syscall
	move	$v0 $t0
	move	$a0 $t1
	.end_macro
	
# Marco que revisa si la cadena en %s es "exit".
# Termina la ejecución en ese caso	
	.macro checkExit(%s)
	move	$t2 %s
	lb	$t0 ($t2)
	la	$t3 exStr
	lb	$t1 ($t3)
nCh:	beqz	$t0 chEnd
	bne	$t0 $t1 nEx
	addi	$t2 $t2 1
	lb	$t0 ($t2)
	addi	$t3 $t3 1
	lb	$t1 ($t3)
	j nCh
chEnd:	beqz	$t1 exit
nEx:	
	.end_macro
	
# Marcos que realizan las operaciones con la pila
	#Operación push, que mete números dentro de la pila
	.macro push(%s)
	sw	%s ($sp)
	addi	$sp $sp 4
	.end_macro
	#Operación pop, que saca números de la pila
	.macro pop(%s)
	subi	$sp $sp 4
	tlt	$sp $s7
	lw	%s ($sp)
	.end_macro
	
	
# Marco que parsea los números
# parsea el número si es posible, y lo agrega a la pila
	.macro getNum
	subi	$t0 $s4 '0' # obtener valor numérico del código ascii
lNum:	lb	$s4 ($s1)
	subi	$t1 $s4 '0' # obtener valor numérico del código ascii
	bgt	$s4 '9' numDone #Manda excepción de que no es número
	blt	$s4 '0' numDone #Manda excepción de que no es número
	mulo	$t0 $t0 10
	add	$t0 $t0 $t1
	addi	$s1 $s1 1
	j lNum
numDone:
	push($t0)
	.end_macro
	
# Marco que revisa que el caracter sea válido
	.macro checkChar(%s)
	beq	%s '\n' val # salto de línea, caracter que es válido
	beq	%s ' ' val # espacio, caracter que es válido
	beqz	%s val # \0, fin de cadena, que es válido
	tgei	%s 58 # caracter no válido, fuera de rango
	tlti	%s 42 # caracter no válido, fuera de rango
	teqi	%s '´'
	teqi	%s '.'
val:
	.end_macro

#Marco que realiza el parseo y la ejecución de la operación correspondiente
	.macro proccess(%s)
	#Hace el parseo
	move	$s1 %s
	move	$s7 $sp
nCh:	lb	$s4 ($s1)
	beqz	$s4 prEnd
	checkChar($s4) #Revisa los caracteres
	addi	$s1 $s1 1
	beq	$s4 '\n' nCh # salto de línea, ignorar
	beq	$s4 ' ' nCh # espacio, ignorar
	#Manda a las operaciones correspondientes
	beq	$s4 '+' sum 
	beq	$s4 '-' dif
	beq	$s4 '*' mu
	beq	$s4 '/' di
	getNum
	j nCh
#Operación suma
sum:
	pop($s2)
	pop($s3)
	add $t0 $s3 $s2
	push($t0)
	j nCh
#Operación resta
dif:
	pop($s2)
	pop($s3)
	sub $t0 $s3 $s2
	push($t0)
	j nCh
#Operación multiplicación
mu:
	pop($s2)
	pop($s3)
	mulo $t0 $s3 $s2
	push($t0)
	j nCh
#Operación división
di:
	pop($s2)
	pop($s3)
	div $t0 $s3 $s2
	push($t0)
	j nCh
#Devuelve el resultado
prEnd:	pop($s6)
	tne	$sp $s7
	.end_macro
	
# variables
	.data
bienv:	.asciiz "Calculadora posfija\n"
inst:	.asciiz "Ingrese algo\n"
end:	.asciiz "Terminando programa\n"
res:	.asciiz "Resultado: \n"
exStr:	.asciiz "exit\n"
buff:	.space 101
	
# Código de la calculadora
	.text
	#Mensajes de bienvenida
	la	$a0 bienv
	printStr
nextQ:	la	$a0 inst
	printStr
	la	$s0 buff
	readStr($s0)
	#Revisar lo que mando el usuario y procesarlo
	checkExit($s0)
	proccess($s0)
	#Devolver el resultado
	la	$a0 res
	printStr
	move	$a0 $s6
	printInt($a0)
	li	$a0 '\n' # \n
	printChar($a0)
	j nextQ
#Cuando el usuario quiere terminar el programa
exit:
	la	$a0 end
	printStr
	li	$v0 10
	syscall
	
#Macros especiales para el manejo de exepciones
#Maccro imprime la operación en la que se causó la exepción
	.macro printCurrentOp
	la	$a0 op
	printStr
	move	$a0 $s2
	printInt($a0)
	move	$a0 $s4
	printChar($a0)
	move	$a0 $s3
	printInt($a0)
	li	$a0 '\n' # \n
	printChar($a0)
	.end_macro
	
#Macro que imprime el caractér leído y su posición cuando ocurrió la exepción
	.macro printInfoChar
	la	$a0 char
	printStr
	move	$a0 $s4
	printChar($a0)
	li	$a0 '\n' # \n
	printChar($a0)
	li	$a0 ' '
	printChar($a0)
	move	$a0 $s4
	printInt($a0)
	la	$a0 pos
	printStr
	sub	$t0 $s1 $s0
	move	$a0 $t0
	printInt($a0)
	li	$a0 '\n' # \n
	printChar($a0)
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
	
# Obtenemos causa de la expeción
	mfc0	$k0 $13 # Cargar registro de causa
	andi	$k0 $k0 0x00007c # Quedarse sólo con le código de expeción
	srl	$k0 $k0 2 # Mover el código de exepción al inicio del registro
	
# Redireccionamos a donde se va a manejar ese tipo de exepción.
	beq	$k0 12 desbord # Exepción por desbordamiento
	beq	$k0 9 divzero # Exepción por división entre cero
	beq	$k0 13 invalid # Exepción por expresión inválida
	
# Otro tipo de exepciones son ignoradas
	move	$a0 $k0
	printInt($a0)
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
	
# Regresa a la ejecución normal
resume:
	la	$k0 nextQ
	mtc0	$k0 $14
	eret
