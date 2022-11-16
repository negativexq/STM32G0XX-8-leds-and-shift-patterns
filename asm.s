/*
* asm.s
*
* author:
* Omer Faruk KOC
* description: Connect 8 LEDs and 1 button to the board, andimplement a shift pattern
*
*/
.syntax unified
.cpu cortex-m0
.fpu softvfp
.thumb
/* make linker see this */
.global Reset_Handler
/* get these from linker script */
.word _sdata
.word _edata
.word _sbss
.word _ebss
/* define peripheral addresses from RM0444 page 57, Tables 3-4 */
.equ RCC_BASE, (0x40021000) // RCC base address
.equ RCC_IOPENR, (RCC_BASE + (0x34)) // RCC IOPENR register offset

.equ GPIOA_BASE,       (0x50000000)          // GPIOA base address
.equ GPIOA_MODER,      (GPIOA_BASE + (0x00)) // GPIOA MODER register offset
.equ GPIOA_ODR,        (GPIOA_BASE + (0x14)) // GPIOA ODR register offset
.equ GPIOA_IDR,        (GPIOA_BASE + (0x10)) // GPIOA IDR register

.equ GPIOB_BASE, (0x50000400) // GPIOC base address
.equ GPIOB_MODER, (GPIOB_BASE + (0x00)) // GPIOC MODER register offset
.equ GPIOB_ODR, (GPIOB_BASE + (0x14)) // GPIOC ODR register offset
.equ GPIOB_IDR, (GPIOB_BASE + (0x10))
/* vector table, +1 thumb mode */
.section .vectors
vector_table:
.word _estack /* Stack pointer */
.word Reset_Handler +1 /* Reset handler */
.word Default_Handler +1 /* NMI handler */
.word Default_Handler +1 /* HardFault handler */
/* add rest of them here if needed */
/* reset handler */
.section .text
Reset_Handler:
/* set stack pointer */
ldr r0, =_estack
mov sp, r0
/* initialize data and bss
* not necessary for rom only code
* */
bl init_data
/* call main */
bl main
/* trap if returned */
b .
/* initialize data and bss sections */
.section .text
init_data:
/* copy rom to ram */
ldr r0, =_sdata
ldr r1, =_edata
ldr r2, =_sidata
movs r3, #0
b LoopCopyDataInit
CopyDataInit:
ldr r4, [r2, r3]
str r4, [r0, r3]
adds r3, r3, #4
LoopCopyDataInit:
adds r4, r0, r3
cmp r4, r1
bcc CopyDataInit
/* zero bss */
ldr r2, =_sbss
ldr r4, =_ebss
movs r3, #0
b LoopFillZerobss
FillZerobss:
str r3, [r2]
adds r2, r2, #4
LoopFillZerobss:
cmp r2, r4
bcc FillZerobss
bx lr
/* default handler */
.section .text
Default_Handler:
b Default_Handler
/* main function */
.section .text
main:

/* enable GPIOB clock, bit1 on IOPENR */
ldr r6, =RCC_IOPENR
ldr r5, [r6]
/* movs expects imm8, so this should be fine */
movs r4, 0x2
orrs r5, r5, r4
str r5, [r6]

/* i choose b1-b2-b4-b5-B6-B7-B8-B9 */
/* setup to output mode for b1-b2-b4-b5-B6 b7 b8 b9 b0 input */
/* 1111_1111_1111_0011_1111 */
ldr r6, =GPIOB_MODER
ldr r5, [r6]
ldr r4, =0xFFF3F
mvns r4, r4
ands r5, r5, r4
ldr r4, =0x55514
orrs r5, r5, r4
str r5, [r6]
ldr r0, =GPIOB_ODR
ldr r1, [r0]
/*B0 is the button pin*/
/* led1=b1 led2=b2 led3=b4 led4=b5 led5=b6 led6=b7*/
/* led7=b8 led8=b9*/
 /* */
 /* enable GPIOA clock, bit0 on IOPENR */
	ldr r6, =RCC_IOPENR
	ldr r5, [r6]
	/* movs expects imm8, so this should be fine */
	movs r4, 0x1
	orrs r5, r5, r4
	str r5, [r6]

	/* setup PA6 for led 01 for bits 12-13 in MODER */
	ldr r6, =GPIOA_MODER
	ldr r5, [r6]
	/* cannot do with movs, so use pc relative */
	movs r4,0x3
	lsls r4, r4, #12	// When r4 = 0x3, bits 12 and 13 will be set and r4 = 0x3000
	bics r5, r5, r4	// ~r4 = FFFF CFFF Set bits cleared r5 = 0xFFFF CFFF
	movs r4, 0x1
	lsls r4, r4, #12	// When r4 = 0x1, 12 bits will be shifted to the left and the 12th bit will be set and r4 = 0x1000
	orrs r5, r5, r4	// When r5 = 0xFFFF CFFF or is set r5 = 0x1000
	str r5,[r6]
        ldr r6, =GPIOA_MODER
	ldr r5, [r6]




t8:
bl led1_reset
bl led2_reset
bl led3_reset
bl led4_reset
bl led5_reset
bl led6_reset
bl led7_set
bl led8_reset
bl delay
ldr r5, =0x1
bl button_press
CMP r3, r5
BEQ t8
b t1

t0:
bl led1_reset
bl led2_reset
bl led3_reset
bl led4_reset
bl led5_reset
bl led6_reset
bl led7_reset
bl led8_reset
bl delay
ldr r5, =0x1
bl button_press
CMP r3, r5
BEQ t8
b t1

button_press:
ldr r2, =GPIOB_IDR
ldr r3, [r2]
movs r4,0x1
ands r3,r3,r4
bx lr


t1:
bl led1_reset
bl led2_reset
bl led3_reset
bl led4_set
bl led5_reset
bl led6_reset
bl led7_reset
bl led8_reset
bl delay
ldr r5, =0x1
bl button_press
CMP r3, r5
BEQ t0
b t2

t2:
bl led1_reset
bl led2_reset
bl led3_set
bl led4_set
bl led5_set
bl led6_reset
bl led7_reset
bl led8_reset
bl delay
ldr r5, =0x1
bl button_press
CMP r3, r5
BEQ t0
b t3

t7:
bl led1_reset
bl led2_reset
bl led3_reset
bl led4_set
bl led5_reset
bl led6_reset
bl led7_reset
bl led8_reset
bl delay
ldr r5, =0x1
bl button_press
CMP r3, r5
BEQ t0
b t0

t3:
bl led1_reset
bl led2_set
bl led3_set
bl led4_set
bl led5_set
bl led6_set
bl led7_reset
bl led8_reset
bl delay
ldr r5, =0x1
bl button_press
CMP r3, r5
BEQ t0
b t4

t4:
bl led1_set
bl led2_set
bl led3_set
bl led4_set
bl led5_set
bl led6_set
bl led7_reset
bl led8_set
bl delay
ldr r5, =0x1
bl button_press
CMP r3, r5
BEQ t2
b t5


t5:
bl led1_reset
bl led2_set
bl led3_set
bl led4_set
bl led5_set
bl led6_set
bl led7_reset
bl led8_reset
bl delay
ldr r5, =0x1
bl button_press
CMP r3, r5
BEQ t2
b t6

t6:
bl led1_reset
bl led2_reset
bl led3_set
bl led4_set
bl led5_set
bl led6_reset
bl led7_reset
bl led8_reset
bl delay
ldr r5, =0x1
bl button_press
CMP r3, r5
BEQ t3
b t7

led1_set:
ldr r4, =0x2
orrs r1, r1, r4
str r1, [r0]
bx lr

led1_reset:
ldr r4, =0x2
mvns r4,r4
ands r1,r1,r4
str r1, [r0]
bx lr

led2_set:
ldr r4, =0x4
orrs r1, r1, r4
str r1, [r0]
bx lr

led2_reset:
ldr r4, =0x4
mvns r4,r4
ands r1,r1,r4
str r1, [r0]
bx lr

led3_set:
ldr r4, =0x10
orrs r1, r1, r4
str r1, [r0]
bx lr
led3_reset:
ldr r4, =0x10
mvns r4,r4
ands r1,r1,r4
str r1, [r0]
bx lr
led4_set:
ldr r4, =0x20
orrs r1, r1, r4
str r1, [r0]
bx lr
led4_reset:
ldr r4, =0x20
mvns r4,r4
ands r1,r1,r4
str r1, [r0]
bx lr
led5_set:
ldr r4, =0x40
orrs r1, r1, r4
str r1, [r0]
bx lr
led5_reset:
ldr r4, =0x40
mvns r4,r4
ands r1,r1,r4
str r1, [r0]
bx lr
led6_set:
ldr r4, =0x80
orrs r1, r1, r4
str r1, [r0]
bx lr
led6_reset:
ldr r4, =0x80
mvns r4,r4
ands r1,r1,r4
str r1, [r0]
bx lr

led7_set:
/* turn on led connected to PA6 in ODR */
	ldr r6, =GPIOA_ODR
	ldr r5, [r6]	//reset value r5=0x0000 0000
	movs r4, 0x40	// A value of 1 has been sent to the PA6 pin so that the LED lights up (r4 = 0x0000 0040)
	orrs r5, r5, r4	// The appropriate value has been assigned to the register that holds the signal that the LED will light
	str r5, [r6]
bx lr

led7_reset:
ldr r6, =GPIOA_ODR
	ldr r5, [r6]		//reset value r5=0x0000 0000
	movs r4, #0x40		// A value of 1 has been sent to the PA6 pin so that the LED lights up (r4 = 0x0000 0040)
	mvns r4,r4			//r4=0xFFFF FFCF
	ands r5, r5, r4		// The register holding the signal that the led will turn off has been assigned an appropriate value
	str r5, [r6]

bx lr

led8_set:
ldr r4, =0x200
orrs r1, r1, r4
str r1, [r0]
bx lr

led8_reset:
ldr r4, =0x200
mvns r4,r4
ands r1,r1,r4
str r1, [r0]
bx lr

delay:
ldr r7,=0x61A80

loop:
subs r7,0x1
cmp r7, 0x0
BNE loop
bx lr

/* for(;;); */

b .

/* this should never get executed */
nop
