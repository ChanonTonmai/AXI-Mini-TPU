#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xaxidma.h"
#include "xil_exception.h"
#include "xdebug.h"
#include "xil_io.h"
#include "xscugic.h"
#include "xuartps.h"

//#define BUFFER_SIZE 				2048*4
//#define BUFFER_SIZE_DWORDS			(BUFFER_SIZE/4)
#define RESET_TIMEOUT_COUNTER 10000
#define RX_INTR_ID		XPAR_FABRIC_AXI_DMA_0_S2MM_INTROUT_INTR
#define TX_INTR_ID		XPAR_FABRIC_AXI_DMA_0_MM2S_INTROUT_INTR
#define INTC_DEVICE_ID  XPAR_SCUGIC_SINGLE_DEVICE_ID
#define MAX_PKT_LEN		16*4
#define DMA_DEV_ID		XPAR_AXIDMA_0_DEVICE_ID
#define INTC		XScuGic
#define INTC_HANDLER	XScuGic_InterruptHandler
#define NUMBER_OF_TRANSFERS	1
#define MEM_BASE_ADDR		0x01000000
#define RX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00300000)
/************************** Constant Definitions *****************************/

static XAxiDma AxiDma;		/* Instance of the XAxiDma */

static INTC Intc;	/* Instance of the Interrupt Controller */

/*
 * Flags interrupt handlers use to notify the application context the events.
 */
volatile int RxDone;
volatile int Error;

static void RxIntrHandler(void *Callback);

#define ADDR 0x43C00000

int main()
{
    init_platform();
    int Status;
    print("Hello Matrix Mul\n\r");

	/* Loop forever blinking the LED */
	u32 *RxBufferPtr;

	RxBufferPtr = (u32 *)RX_BUFFER_BASE;

    int BUFFER_SIZE = 64;
    int BUFFER_SIZE_DWORDS = 16;

//	Xil_Out32(0x40400030, 0x00000001); // something about dma idk
//	Xil_Out32(0x40400058, 0x00000010);

	Xil_Out32(0x43C00000, 0x00000001); // tick en up
	Xil_Out32(0x43C00000, 0x00000001);
	Xil_Out32(0x43C00000, 0x00000003); // weight enable
	Xil_Out32(0x43C00004, 0x8000A261); // D0 D1  1
	Xil_Out32(0x43C00004, 0x0000A4B5); // D2 D3
	Xil_Out32(0x43C00004, 0x8001A7B6); // D0 D1  2
	Xil_Out32(0x43C00004, 0x0001A908); // D2 D3
	Xil_Out32(0x43C00004, 0x8002AB0A); // D0 D1  3
	Xil_Out32(0x43C00004, 0x0002ADBC); // D2 D3
	Xil_Out32(0x43C00004, 0x8003AFBE); // D0 D1  4
	Xil_Out32(0x43C00004, 0x0003A1B3); // D2 D3

	Xil_Out32(0x43C00004, 0x8004A261); // D0 D1  1
	Xil_Out32(0x43C00004, 0x0004A4B5); // D2 D3
	Xil_Out32(0x43C00004, 0x8005A7B6); // D0 D1  2
	Xil_Out32(0x43C00004, 0x0005A908); // D2 D3
	Xil_Out32(0x43C00004, 0x8006AB0A); // D0 D1  3
	Xil_Out32(0x43C00004, 0x0006ADBC); // D2 D3
	Xil_Out32(0x43C00004, 0x8007AFBE); // D0 D1  4
	Xil_Out32(0x43C00004, 0x0007A1B3); // D2 D3

	Xil_Out32(0x43C00004, 0x8008A261); // D0 D1  1
	Xil_Out32(0x43C00004, 0x0008A4B5); // D2 D3
	Xil_Out32(0x43C00004, 0x8009A7B6); // D0 D1  2
	Xil_Out32(0x43C00004, 0x0009A908); // D2 D3
	Xil_Out32(0x43C00004, 0x800AAB0A); // D0 D1  3
	Xil_Out32(0x43C00004, 0x000AADBC); // D2 D3
	Xil_Out32(0x43C00004, 0x800BAFBE); // D0 D1  4
	Xil_Out32(0x43C00004, 0x000BA1B3); // D2 D3

	Xil_Out32(0x43C00004, 0x800CA261); // D0 D1  1
	Xil_Out32(0x43C00004, 0x000CA4B5); // D2 D3
	Xil_Out32(0x43C00004, 0x800DA7B6); // D0 D1  2
	Xil_Out32(0x43C00004, 0x000DA908); // D2 D3
	Xil_Out32(0x43C00004, 0x800EAB0A); // D0 D1  3
	Xil_Out32(0x43C00004, 0x000EADBC); // D2 D3
	Xil_Out32(0x43C00004, 0x800FAFBE); // D0 D1  4
	Xil_Out32(0x43C00004, 0x000FA1B3); // D2 D3


	Xil_Out32(0x43C00000, 0x00000011); // tick weight enable down

	Xil_Out32(0x43C00000, 0x00000005); // unified buffer enable
	Xil_Out32(0x43C00008, 0x80000F0F); // D0 D1  1
	Xil_Out32(0x43C00008, 0x00000E0E); // D2 D3
	Xil_Out32(0x43C00008, 0x80010C0C); // D0 D1  2
	Xil_Out32(0x43C00008, 0x00010D08); // D2 D3
	Xil_Out32(0x43C00008, 0x80020B0A); // D0 D1  3
	Xil_Out32(0x43C00008, 0x00020D0F); // D2 D3
	Xil_Out32(0x43C00008, 0x8003010E); // D0 D1  4
	Xil_Out32(0x43C00008, 0x00030F03); // D2 D3

	Xil_Out32(0x43C00008, 0x80040F0F); // D0 D1  1
	Xil_Out32(0x43C00008, 0x00040E0E); // D2 D3
	Xil_Out32(0x43C00008, 0x80050C0C); // D0 D1  2
	Xil_Out32(0x43C00008, 0x00050D08); // D2 D3
	Xil_Out32(0x43C00008, 0x80060B0A); // D0 D1  3
	Xil_Out32(0x43C00008, 0x00060D0F); // D2 D3
	Xil_Out32(0x43C00008, 0x8007010E); // D0 D1  4
	Xil_Out32(0x43C00008, 0x00070F03); // D2 D3

	Xil_Out32(0x43C00008, 0x80080F0F); // D0 D1  1
	Xil_Out32(0x43C00008, 0x00080E0E); // D2 D3
	Xil_Out32(0x43C00008, 0x80090C0C); // D0 D1  2
	Xil_Out32(0x43C00008, 0x00090D08); // D2 D3
	Xil_Out32(0x43C00008, 0x800A0B0A); // D0 D1  3
	Xil_Out32(0x43C00008, 0x000A0D0F); // D2 D3
	Xil_Out32(0x43C00008, 0x800B010E); // D0 D1  4
	Xil_Out32(0x43C00008, 0x000B0F03); // D2 D3

	Xil_Out32(0x43C00008, 0x800C0F0F); // D0 D1  1
	Xil_Out32(0x43C00008, 0x000C0E0E); // D2 D3
	Xil_Out32(0x43C00008, 0x800D0C0C); // D0 D1  2
	Xil_Out32(0x43C00008, 0x000D0D08); // D2 D3
	Xil_Out32(0x43C00008, 0x800E0B0A); // D0 D1  3
	Xil_Out32(0x43C00008, 0x000E0D0F); // D2 D3
	Xil_Out32(0x43C00008, 0x800F010E); // D0 D1  4
	Xil_Out32(0x43C00008, 0x000F0F03); // D2 D3


	Xil_Out32(0x43C00000, 0x00000011); // tick weight enable down

	Xil_Out32(0x43C0000C, 0x08080808); //





	xil_printf("Initial values at buffer\n\r");

	XAxiDma_Config *Config;


	Config = XAxiDma_LookupConfig(DMA_DEV_ID);
	if (!Config) {
		xil_printf("No config found for %d\r\n", DMA_DEV_ID);
		return XST_FAILURE;
	}

	/* Initialize DMA engine */
	Status = XAxiDma_CfgInitialize(&AxiDma, Config);
	if (Status != XST_SUCCESS) {
		xil_printf("DMA Initialization failed %d\r\n", Status);
		return XST_FAILURE;
	}

	if(XAxiDma_HasSg(&AxiDma)){
		xil_printf("Device configured as SG mode \r\n");
		return XST_FAILURE;
	}

	XScuGic_Config *IntcConfig;
	IntcConfig = XScuGic_LookupConfig(INTC_DEVICE_ID);
	if (NULL == IntcConfig) {
		xil_printf("Interrupt Initialization failed %d\r\n", Status);
		return XST_FAILURE;
	}

	INTC* IntcInstancePtr;
	IntcInstancePtr = &Intc;
	Status = XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig,
					IntcConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS) {
		xil_printf("Interrupt Configuration failed %d\r\n", Status);
		return XST_FAILURE;
	}

	XScuGic_SetPriorityTriggerType(IntcInstancePtr, RX_INTR_ID, 0xA0, 0x3);

	Status = XScuGic_Connect(IntcInstancePtr, RX_INTR_ID,
				(Xil_InterruptHandler)RxIntrHandler,
				&AxiDma);
	if (Status != XST_SUCCESS) {
		xil_printf("RX Interrupt connection failed %d\r\n", Status);
		return Status;
	}

	XScuGic_Enable(IntcInstancePtr, RX_INTR_ID);

	/* Enable interrupts from the hardware */
	Xil_ExceptionInit();
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
			(Xil_ExceptionHandler)INTC_HANDLER,
			(void *)IntcInstancePtr);

	Xil_ExceptionEnable();


	XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK,
				XAXIDMA_DEVICE_TO_DMA);


	XAxiDma_IntrEnable(&AxiDma, XAXIDMA_IRQ_ALL_MASK,
							XAXIDMA_DEVICE_TO_DMA);

	/* Initialize flags before start transfer test  */
	RxDone = 0;
	Error = 0;

	int i;
	for(i = 0; i < BUFFER_SIZE_DWORDS; i++)
	{
		RxBufferPtr[i] = 0;
	}
	xil_printf("RX buffer finish\r\n");

	int idx = 0;
	Xil_DCacheFlushRange((UINTPTR)RxBufferPtr, MAX_PKT_LEN);

	for(int i=0; i < 10000; i++) {
		//delay
	}

	while(1) {


		Xil_Out32(0x43C00000, 0x00000019); // matrix start enable


		Xil_DCacheFlushRange((UINTPTR)RxBufferPtr, MAX_PKT_LEN);
		Status = XAxiDma_SimpleTransfer(&AxiDma,(UINTPTR) RxBufferPtr,
				BUFFER_SIZE, XAXIDMA_DEVICE_TO_DMA);

		if (Status != XST_SUCCESS) {
			xil_printf("RX transfer failed %d\r\n", Status);
			return XST_FAILURE;
		}
		xil_printf("Prepare DMA send\r\n");
		while ((!RxDone) && !Error) {
					/* NOP */
		}


		xil_printf("Successfully ran AXI DMA interrupt Example\r\n");
		RxDone = 0;
		Error = 0;



		for(i = 0; i < BUFFER_SIZE_DWORDS; i++)
		{
		  xil_printf("%d\r\n",RxBufferPtr[i]);
		}

		for(i = 0; i < BUFFER_SIZE_DWORDS; i++)
		{
			RxBufferPtr[i] = 0;
		}
		idx = idx+1;
//		Xil_Out32(0x43C00000,0x00000000);

	}

	Xil_Out32(0x43C00000, 0x00000001);
	/* Disable TX and RX Ring interrupts and return success */
	XScuGic_Disconnect(IntcInstancePtr, RX_INTR_ID);


	cleanup_platform();
	return 0;
}

static void RxIntrHandler(void *Callback)
{

	xil_printf("RX IRQ\n\r");
	u32 IrqStatus;
	int TimeOut;
	XAxiDma *AxiDmaInst = (XAxiDma *)Callback;

	/* Read pending interrupts */
	IrqStatus = XAxiDma_IntrGetIrq(AxiDmaInst, XAXIDMA_DEVICE_TO_DMA);

	/* Acknowledge pending interrupts */
	XAxiDma_IntrAckIrq(AxiDmaInst, IrqStatus, XAXIDMA_DEVICE_TO_DMA);

	/*
	 * If no interrupt is asserted, we do not do anything
	 */
	if (!(IrqStatus & XAXIDMA_IRQ_ALL_MASK)) {
		return;
	}

	/*
	 * If error interrupt is asserted, raise error flag, reset the
	 * hardware to recover from the error, and return with no further
	 * processing.
	 */
	if ((IrqStatus & XAXIDMA_IRQ_ERROR_MASK)) {

		Error = 1;

		/* Reset could fail and hang
		 * NEED a way to handle this or do not call it??
		 */
		XAxiDma_Reset(AxiDmaInst);

		TimeOut = RESET_TIMEOUT_COUNTER;

		while (TimeOut) {
			if(XAxiDma_ResetIsDone(AxiDmaInst)) {
				break;
			}

			TimeOut -= 1;
		}

		return;
	}

	/*
	 * If completion interrupt is asserted, then set RxDone flag
	 */
	if ((IrqStatus & XAXIDMA_IRQ_IOC_MASK)) {

		RxDone = 1;
	}
}
