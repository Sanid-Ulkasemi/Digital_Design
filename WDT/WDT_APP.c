
#include <stdio.h>
#include <xparameters.h>
#include <xstatus.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xscugic.h"
#include "xinterrupt_wrap.h"


#define LOCK 0xC00
#define LOAD 0x00
#define VALUE 0x04
#define CTL 0x08
#define MIS 0x14
#define ICR 0x0C
#define UNLOCK 0x1ACCE551

XScuGic gic;

void WDT_RST()
{

}

void WDT_ISR()
{
    printf("\n\nLOCK: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + LOCK));
    printf("MIS: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + MIS));

    Xil_Out32(XPAR_APB_M_0_BASEADDR + LOCK, UNLOCK);
    Xil_Out32(XPAR_APB_M_0_BASEADDR + ICR, 0x0000FFFF);
    
    printf("UNLOCK: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + LOCK));
    printf("MIS CLR: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + MIS));
    
    Xil_Out32(XPAR_APB_M_0_BASEADDR + LOCK, 0x102);
    printf("LOCKED: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + LOCK));
}

s32 setupIntpt()
{
    XStatus status;
    u32 ID;
    status = XGetEncodedIntrId(0x079, 0x01, 0x00, 0x00, &ID);
    if (status != XST_SUCCESS) print("Interrupt Setup: FAILED@ Encoding ID\n\r");
    else print("Interrupt setup: Encoded ID\n");
    
    status = XSetupInterruptSystem(&gic,(XInterruptHandler)WDT_ISR, 
            ID, XPAR_XSCUGIC_0_BASEADDR, XINTERRUPT_DEFAULT_PRIORITY);
    
    if (status != XST_SUCCESS) print("Interrupt Setup: FAILED@ Setting up interrupt system\n\r");
    else print("Interrupt setup: Setup interrupt complete\n");

    return XST_SUCCESS;
}

int main()
{
    u32 temp;
    init_platform();


    printf("........Begin........\n\r");
    scanf("%u", &temp);
    printf("Setting up interrupt\n");
    u32 status = setupIntpt();
    if(status == XST_SUCCESS)printf("Interrupt setup successful\n\r");
    else printf("Interrupt setup failed\n\r");

    printf("Configuring WDT\n\r");
    //Unlock the WDT
    Xil_Out32(XPAR_APB_M_0_BASEADDR + LOCK, UNLOCK);
    //Load the value register
    Xil_Out32(XPAR_APB_M_0_BASEADDR , 200000000);
    //Enable it
    Xil_Out32(XPAR_APB_M_0_BASEADDR + CTL, 0x01);
    //Lock it back
    Xil_Out32(XPAR_APB_M_0_BASEADDR + LOCK, 0x00);

    for(int offset = 0; offset < 22; offset += 4){
        printf("0x%02x : %u\n", offset, Xil_In32(XPAR_APB_M_0_BASEADDR + offset));
    }
    printf("0x%02x : %u\n", 0xC00, Xil_In32(XPAR_APB_M_0_BASEADDR + 0xc00));
    printf("........DONE........\n\r");

    // u32 time;
    // while(1)
    // {
    //     time++;
    //     if(Xil_In32(XPAR_APB_M_0_BASEADDR + MIS))
    //     {   
    //         printf("Interrutp occured @ TIME: %u\n", time);
    //         Xil_Out32(XPAR_APB_M_0_BASEADDR + LOCK, UNLOCK);
    //         Xil_Out32(XPAR_APB_M_0_BASEADDR + ICR, 0x001);
    //         printf("After clerar: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + MIS));
    //         Xil_Out32(XPAR_APB_M_0_BASEADDR + LOCK, 0x00);
    //         time = 0;
    //     }
    // }
    while(1);
    cleanup_platform(); 
    return 0;
}
