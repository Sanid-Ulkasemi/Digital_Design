/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

// #include <stdio.h>
// #include "platform.h"
// #include "xil_printf.h"


// int main()
// {
//     init_platform();

//     print("Hello World\n\r");
//     print("Successfully ran Hello World application");
//     cleanup_platform();
//     return 0;
// }


#include <stdio.h>
#include <xparameters.h>
#include <xstatus.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xgpiops.h"
#include "sleep.h"
#include "xspips.h"
#include "xiicps.h"
#include "xscugic.h"
#include "xinterrupt_wrap.h"

//WDT REGISTER OFFSETS
#define LOCK 0xC00
#define LOAD 0x00
#define VALUE 0x04
#define CTL 0x08
#define MIS 0x14
#define ICR 0x0C
#define UNLOCK 0x1ACCE551

//I2C REGISTER OFFSETS
#define IIC_SLVADR      0x08
#define IIC_CTL         0x0C
#define IIC_DATA        0x04

//SPI REGISTER OFFSETS
#define SPI_DATA      0x00
#define SPI_CTL       0x08


#define IIC_SCLK_RATE   100000


XScuGic gic;

XSpiPs spips;
XSpiPs_Config *config1;

XIicPs iicps;
XIicPs_Config* iic_config;

u8 pl2ps[2];
u8 go=0;

void WDT_ISR();

//..................Configuration functions.................

//Configures GPIO pins for the LEDs

//--------------------------------------- PL SPI Initialize -------------------------------------
void SETUP_SPIPL()
{
    Xil_Out32(XPAR_APB_M_1_BASEADDR + SPI_CTL, 0x1);
    if(Xil_In32(XPAR_APB_M_1_BASEADDR) + SPI_CTL == 0x1){
         printf("PL SPI Initialization completed successfully");
         return;
    }
    printf("PL SPI Initialization failed");
   
}

//....................................... PS SPI CONFIGURATION...................................

s32 SETUP_SPIPS()
{
    // Configure SPI0 as Master
    printf("SPI-PS: STARTING SETUP\n");
    config1 = XSpiPs_LookupConfig(XPAR_XSPIPS_0_BASEADDR);
    if (config1 == NULL) {
        printf("SPI-PS: LookupConfig for SPI0 failed\n");
        return XST_FAILURE;
    }

    XSpiPs_CfgInitialize(&spips, config1, config1->BaseAddress);
    XSpiPs_SetOptions(&spips, XSPIPS_MASTER_OPTION);
    XSpiPs_SetClkPrescaler(&spips, XSPIPS_CLK_PRESCALE_8);
    XSpiPs_Enable(&spips);
    printf("SPI-PS: SETUP COMPLETE\n\n");
    return XST_SUCCESS;
}

//........................................PS IIC CONFIGURATION...................................
s32 SETUP_IIC()
{
    s32 status;
    printf("IIC-PS : Initializing\n");
    iic_config = XIicPs_LookupConfig(XPAR_I2C0_BASEADDR);
    status = XIicPs_CfgInitialize(&iicps, iic_config, iic_config->BaseAddress);
    if(status == XST_SUCCESS)printf("IIC-PS : Configuration loopkup done\n");
    else printf("IIC-PS : Configuration loopkup failed\n");

    printf("IIC-PS : Resetting device\n");
    XIicPs_Reset(&iicps);

    status = XIicPs_SelfTest(&iicps);
    if(status == XST_SUCCESS)printf("IIC-PS : Self test successful\n");
    else printf("IIC-PS : Selftest falied\n");

    XIicPs_SetupSlave(&iicps, IIC_SLVADR);  //***************************************************
    XIicPs_SetSClk(&iicps, 5000);
    XIicPs_SetOptions(&iicps, XIICPS_7_BIT_ADDR_OPTION);
    printf("IIC-PS : SETUP COMPLETE\n");
    return XST_FAILURE;
}

//........................................SCU GIC CONFIGURATION...................................
s32 SETUP_INTPT()
{
    XStatus status;
    u32 ID;
    status = XGetEncodedIntrId(0x079, 0x01, 0x00, 0x00, &ID);
    if (status != XST_SUCCESS) print("Interrupt Setup: FAILED@ Encoding ID\n\r");
    else print("WDT INTPT : SETUP Encoded ID\n");
    
    status = XSetupInterruptSystem(&gic,(XInterruptHandler)WDT_ISR, 
            ID, XPAR_XSCUGIC_0_BASEADDR, XINTERRUPT_DEFAULT_PRIORITY);
    
    if (status != XST_SUCCESS) print("Interrupt Setup: FAILED@ Setting up interrupt system\n\r");
    else print("WDT INTPT: SETUP INTPT\n\n");

    return XST_SUCCESS;
}


//....................................TEST FUNCTIONS..................................
//Writes a random value in the LOAD register and tries to read it. 
void WDTPL_INIT()
{
    printf("Testing WDT\n");
    Xil_Out32(XPAR_APB_M_0_BASEADDR, 0x1DCD6500);
    if(Xil_In32(XPAR_APB_M_0_BASEADDR) != 0x1DCD6500)
    {
        printf("WDT Initialization FAILED\n");
        return;
    }
    Xil_Out32(XPAR_APB_M_0_BASEADDR + 0x08, 0x01); // watchdog timer enable. inten = 1
    printf("WDT Initialization completed successfully \n");
}


//......................................WDT INTERRUPT SERVICE ROUTINE..................
void WDT_ISR()
{

    Xil_Out32(XPAR_APB_M_0_BASEADDR + ICR, 0x0000FFFF); // Interrupt Clear

    printf("WDT: INTPT\n");
    printf("PL-SIDE..............\n");
    printf("Temparature  : %u\n", Xil_In32(XPAR_APB_M_1_BASEADDR + SPI_DATA)); // Reading the value of temperature from the PL register
    printf("Humidity     : %u\n", Xil_In32(XPAR_APB_M_2_BASEADDR + IIC_DATA)); // // Reading the value of humidity from the PL register
    printf(".....................\n\n");
    go = 1;
   
}

void trigger_hum( u32  hum  )
{
    
    if(hum > 70) // high_hum
    { 
        Xil_Out32(XPAR_APB_M_2_BASEADDR + IIC_CTL, 0x5);
    }

    else if (hum > 50 ) // still_high_hum
    {
        Xil_Out32(XPAR_APB_M_2_BASEADDR + IIC_CTL, 0x4);
    }

    else if (hum < 30) // low-hum
    {
        
        Xil_Out32(XPAR_APB_M_2_BASEADDR + IIC_CTL, 0x10);
    }

    else if (hum < 49) // still low-hum
    {
        Xil_Out32(XPAR_APB_M_2_BASEADDR + IIC_CTL, 0x8);
    }

    else { // normal condition
        Xil_Out32(XPAR_APB_M_1_BASEADDR + SPI_CTL, 0x0);
    }
}

void trigger_temp( u32  temp  )
{
    
    if(temp > 40) // high_temp
    {
     
        Xil_Out32(XPAR_APB_M_1_BASEADDR + SPI_CTL, 0x29);
    }

    else if (temp > 25 ) // still_high_temp
    {
        Xil_Out32(XPAR_APB_M_1_BASEADDR + SPI_CTL, 0x21);
    }

    else if (temp < 15) // low-temp
    {
        
        Xil_Out32(XPAR_APB_M_1_BASEADDR + SPI_CTL, 0x51);
    }
    else if (temp < 24) // still low-temp
    {
        Xil_Out32(XPAR_APB_M_1_BASEADDR + SPI_CTL, 0x41);
    }

    else { // normal condition
        Xil_Out32(XPAR_APB_M_1_BASEADDR + SPI_CTL, 0x1);
    }
}


int main()
{
    init_platform();

    printf(".....Initializing.....\n\r");

    SETUP_SPIPL();
    SETUP_SPIPS();
    SETUP_INTPT();
    SETUP_IIC();
    

    //Test the watchdog and also enables it
    WDTPL_INIT();

    //Keep on doing what you do
    while(1)
    {
        /*
        int x;
        printf("Temperature :   %u\n", Xil_In32(XPAR_APB_M_1_BASEADDR + SPI_DATA)); // Reading the value of temperature from the PL register
        printf("Humidity    :   %u\n", Xil_In32(XPAR_APB_M_2_BASEADDR + IIC_DATA)); // // Reading the value of humidity from the PL register
        scanf("%d",&x);
        */
       
        if(go)
        {
            u32 sampled_temp;
            u32 sampled_hum;

            Xil_Out32(XPAR_XSPIPS_0_BASEADDR + XSPIPS_TXD_OFFSET, 123); // initialize spi transfer
            XIicPs_MasterRecvPolled(&iicps, pl2ps, 1, 0);
            printf("PS Side................................\n");
            printf("IIC-PS: Received %u\n", pl2ps[0]);
            usleep(50);
            sampled_hum = pl2ps[0];

            trigger_hum(sampled_hum);
            printf("IIC CTL : %x\n",Xil_In32(XPAR_APB_M_2_BASEADDR + IIC_CTL));

            sampled_temp = Xil_In32(XPAR_XSPIPS_0_BASEADDR + XSPIPS_RXD_OFFSET);
            
            printf("TEMP @SPI: %u\n", sampled_temp);
            printf("HUMD @I2C: %u\n", sampled_hum);
            printf("...................................\n\n\n");

            trigger_temp(sampled_temp);

            //printf("SPI CTL : %x\n\n",Xil_In32(XPAR_APB_M_1_BASEADDR + SPI_CTL));

            go = 0;

        }
    }


    cleanup_platform();
    return 0;
}