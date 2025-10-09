#include <stdio.h>
#include <xiicps_hw.h>
#include <xil_io.h>
#include <xstatus.h>
#include "platform.h"
#include "xparameters.h"
#include "xiicps.h"
#include "xil_printf.h"
#include "xscugic.h"
#include "xinterrupt_wrap.h"

#define SLAVE_ADDR 9

void SetupIntpt(XScuGic *scugic, void *handler);
int setup_ps_interrupts(XScuGic *GicInst, XIicPs *IicPsInst);
void SlaveStatusHandler(void *CallBackRef, u32 StatusEvent);
int SetupInterruptSystem(XIicPs *Iic, XScuGic *IntcInstance);


static XIicPs iicps;
static XScuGic scugic;

u8 pl2ps[2];
u8 ps2pl[2];


void printBin(u32 val) {
    for (int i = 31; i >= 0; i--) {
        printf((val & (1u << i)) ? "1" : "0");

        if (i % 4 == 0 && i != 0) { 
            printf("_");  // add separator every 4 bits, but not after last group
        }
    }
    printf("\n");
}


void IicHandler(void *CallBackRef, u32 Event) {
    if (Event & XIICPS_EVENT_COMPLETE_RECV) {
        xil_printf("I2C Receive complete\n");
    } else if (Event & XIICPS_EVENT_COMPLETE_SEND) {
        xil_printf("I2C Send complete\n");
    } else if (Event & XIICPS_EVENT_ERROR) {
        xil_printf("I2C Error!\n");
    } else if (Event & XIICPS_EVENT_TIME_OUT){
        xil_printf("I2C Timeout!\n");
        //Xil_Out32(XPAR_I2C1_BASEADDR + 0x10, 0x8);
    }
}

//PS side I2C init
void iicPs_init()
{
    XIicPs_Config *config;
    s32 status;

    printf("IIC-PS : Initializing\n");
    config = XIicPs_LookupConfig(XPAR_I2C1_BASEADDR);
    status = XIicPs_CfgInitialize(&iicps, config, config->BaseAddress);
    if(status == XST_SUCCESS)printf("IIC-PS : Configuration loopkup done\n");
    else printf("IIC-PS : Configuration loopkup failed\n");

    printf("IIC-PS : Resetting device\n");
    XIicPs_Reset(&iicps);

    status = XIicPs_SelfTest(&iicps);
    if(status == XST_SUCCESS)printf("IIC-PS : Self test successful\n");
    else printf("IIC-PS : Selftest falied\n");

    //XIicPs_SetupSlave(&iicps, 66);
    XIicPs_SetSClk(&iicps, 5000);
    XIicPs_SetOptions(&iicps, XIICPS_7_BIT_ADDR_OPTION);

    //printf("IIC-PS : Slave addr: %u\n", Xil_In32(XPAR_I2C1_BASEADDR+XIICPS_ADDR_OFFSET));
    //SetupInterruptSystem(&iicps, &scugic);
    //XIicPs_SetStatusHandler(&iicps, (void *)&iicps, IicHandler);
    //XIicPs_EnableInterrupts(config->BaseAddress, XIICPS_IXR_ALL_INTR_MASK);

    if(status == XST_SUCCESS)printf("IIC-PS : Interrupt set successful\n");
    else printf("IIC-PS : Interrupt setup falied\n");

    // Register your callback function with the driver.
    //XIicPs_SetStatusHandler(iicps, (void *)iicps, SlaveStatusHandler);

    

    printf("IIC-PS : PS Slave interrupt setup complete\n");
    printf("IIC-PS : CTRL reg: %u\n", Xil_In32(XPAR_I2C1_BASEADDR+XIICPS_CR_OFFSET));
    printf("IIC-PS : Initialization complete\n");
}


int main()
{
    u32 temp;
    ps2pl[0] = 0x19;
    pl2ps[0] = 0x2B;

    init_platform();

    //Setting slave address
    printf("\n\n..............Write slave address................\n"); 
    scanf("%u", &temp);
    Xil_Out32(XPAR_APB_M_0_BASEADDR + 0x08, SLAVE_ADDR);
    printf("PL Slave addr: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR+0x08));

    iicPs_init();
    //XIicPs_SlaveRecv(&IIPS, RecvBuffer, 1);
    //SetupIntpt(&scugic, (XInterruptHandler)&isr);
    while(1){

        u32 txCount = 10;
        printf("\n\n..............BEGIN................\n");       
        scanf("%u", &temp);
        printf("\n");
        while(txCount > 0){
            ps2pl[0] += txCount;
            printf("IIC-PS: Sending: %u\n", ps2pl[0]);
            XIicPs_MasterSendPolled(&iicps, ps2pl, 1, SLAVE_ADDR);
            
            //wait a bit
            for(int i = 0;i < 50000;i++);

            printf("IIC-PL: Received: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR));

            printf("IIC-PL: Sending: %u\n", txCount*3);
            Xil_Out32(XPAR_APB_M_0_BASEADDR + 0x04, txCount*3);
            XIicPs_MasterRecvPolled(&iicps, pl2ps, 1, SLAVE_ADDR);
            
            //wait a bit
            for(int i = 0;i < 50000;i++);
            printf("IIC-PS: Received: %u\n", pl2ps[0]);
            printf("\n\n");
            txCount--;
        }
        printf("All done\n");
    }
    
    cleanup_platform();
    return 0;
}


int SetupInterruptSystem(XIicPs *Iic, XScuGic *IntcInstance) {
    
    XScuGic_Config *IntcConfig;
    int Status;
    // Init GIC
    IntcConfig = XScuGic_LookupConfig(XPAR_SCUGIC_SINGLE_DEVICE_ID);
    Status = XScuGic_CfgInitialize(IntcInstance,
                                    IntcConfig,
                                    IntcConfig->CpuBaseAddress);
    
    if (Status != XST_SUCCESS) return XST_FAILURE;


    // Connect PS I2C interrupt to GIC
    Status = XScuGic_Connect(IntcInstance, 
                             XPAR_XIICPS_1_INTR,
                             (Xil_InterruptHandler)XIicPs_MasterInterruptHandler,
                             (void *)Iic);
    if (Status != XST_SUCCESS) return XST_FAILURE;

    //Enable PS interrupt
    XScuGic_Enable(IntcInstance, XPAR_XIICPS_1_INTR);

    // Enable exceptions
    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
                                 (Xil_ExceptionHandler)XScuGic_InterruptHandler,
                                 IntcInstance);
    Xil_ExceptionEnable();
   

    return XST_SUCCESS;
}
