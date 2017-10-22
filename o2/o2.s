.thumb
.syntax unified

.include "gpio_constants.s"     // Register-adresser og konstanter for GPIO
.include "sys-tick_constants.s" // Register-adresser og konstanter for SysTick

.text
	.global Start

Start:
	// Set up LOAD
	ldr r1, =FREQUENCY / 10
	ldr r0, =SYSTICK_BASE + SYSTICK_LOAD
	str r1, [r0]

	// Set up VAL
	ldr r0, =SYSTICK_BASE + SYSTICK_VAL
	str r1, [r0]

	// Set up clock
	ldr r0, =SYSTICK_BASE + SYSTICK_CTRL
	ldr r1, =SysTick_CTRL_CLKSOURCE_Msk
	orr r1, SysTick_CTRL_TICKINT_Msk
	str r1, [r0]

	// Set up GPIO button interrupt
	ldr r0, =GPIO_BASE + GPIO_EXTIPSELH
	ldr r1, [r0]
	and r1, ~(0b1111 << 4)
	orr r1, 0b0001 << 4
	str r1, [r0]

	ldr r0, =GPIO_BASE+GPIO_EXTIFALL
	ldr r1, [r0]
	orr r1, 1 << BUTTON_PIN
	str r1, [r0]

	ldr r0, =GPIO_BASE+GPIO_IEN
	ldr r1, [r0]
	orr r1, 1 << BUTTON_PIN
	str r1, [r0]

Loop:
	wfi
	b Loop

IncMins:
	str r2, [r5]

IncSecs:
	str r1, [r4]

IncTenths:
	str r0, [r3]
	bx lr		//hvorfor? funker ikke uten

.global SysTick_Handler
.thumb_func
SysTick_Handler:
	//10-deler
	ldr r3, =tenths
	ldr r0, [r3]
	add r0, #1
	cmp r0, #10
	bne IncTenths
	ldr r0, =0 //overflow

	// led toggle
	ldr r6, =GPIO_BASE + LED_PORT * PORT_SIZE + GPIO_PORT_DOUTTGL
	ldr r7, =1
	lsl r7, LED_PIN
	str r7, [r6]
	
	//sekunder
	ldr r4, =seconds
	ldr r1, [r4]
	add r1, #1
	cmp r1, #60
	bne IncSecs
	ldr r1, =0 //overflow

	//minutter
	ldr r5, =minutes
	ldr r2, [r5]
	add r2, #1
	cmp r2, #60
	bne IncMins
	ldr r2, =0 //overflow


.global GPIO_ODD_IRQHandler
.thumb_func
GPIO_ODD_IRQHandler:
	//toggle
	ldr r8, =SYSTICK_BASE + SYSTICK_CTRL
	ldr r9, [r8]
	eor r9, #SysTick_CTRL_ENABLE_Msk
	str r9, [r8]

	//reset flag
	ldr r8, =GPIO_BASE+GPIO_IFC
	ldr r9, =1
	lsl r9, 9
	str r9, [r8]

	bx lr


NOP // Behold denne på bunnen av fila
