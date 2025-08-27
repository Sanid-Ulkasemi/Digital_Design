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


#include <stdio.h>
#include <xstatus.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xspips.h"
#include "xscugic.h"
#include "xinterrupt_wrap.h"
#include "xparameters.h"

int main()
{
    printf("Begin\n");
    printf("S POSEDGE: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x30));
    printf("S NEGEDTE: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x34));
    printf("SCLK EDGE: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x38));
    init_platform();

    XSpiPs_Config *config;
    XSpiPs spiPs;
    // u8 transmit[4] = {11, 120, 96, 51};
    // u8 receive[4] = {0, 0, 0, 0};
    // u32 byte_countr = 4;


    config = XSpiPs_LookupConfig(XPAR_SPI0_BASEADDR);
    printf("SPI-PS: Lookup configuration complete\n");
    XSpiPs_CfgInitialize(&spiPs, config, XPAR_SPI0_BASEADDR);
    //XSpiPs_SetOptions(&spiPs, XSPIPS_MASTER_OPTION);
    XSpiPs_SetClkPrescaler(&spiPs, XSPIPS_CLK_PRESCALE_8);

    Xil_Out32(XPAR_APB_M_0_BASEADDR, 25);
    Xil_Out32(XPAR_APB_M_0_BASEADDR, 115);
    Xil_Out32(XPAR_APB_M_0_BASEADDR, 98);
    Xil_Out32(XPAR_APB_M_0_BASEADDR, 49);
    Xil_Out32(XPAR_APB_M_0_BASEADDR, 28);
    Xil_Out32(XPAR_APB_M_0_BASEADDR, 117);
    Xil_Out32(XPAR_APB_M_0_BASEADDR, 91);
    Xil_Out32(XPAR_APB_M_0_BASEADDR, 41);
    Xil_Out32(XPAR_APB_M_0_BASEADDR, 59);
    Xil_Out32(XPAR_APB_M_0_BASEADDR, 19);

    Xil_Out32(XPAR_APB_M_0_BASEADDR + 0x14, 3);

    //Setting PS side CPOL CPHA
    Xil_Out32(XPAR_SPI0_BASEADDR, Xil_In32(XPAR_SPI0_BASEADDR) | 0x00000006);
    
    //XSpiPs_Transfer(&spiPs, transmit, receive, byte_countr);

    Xil_Out32(XPAR_SPI0_BASEADDR + XSPIPS_TXD_OFFSET, 101);
    Xil_Out32(XPAR_SPI0_BASEADDR + XSPIPS_TXD_OFFSET, 91);
    Xil_Out32(XPAR_SPI0_BASEADDR + XSPIPS_TXD_OFFSET, 88);
    Xil_Out32(XPAR_SPI0_BASEADDR + XSPIPS_TXD_OFFSET, 33);
    Xil_Out32(XPAR_SPI0_BASEADDR + XSPIPS_TXD_OFFSET, 103);
    Xil_Out32(XPAR_SPI0_BASEADDR + XSPIPS_TXD_OFFSET, 77);
    Xil_Out32(XPAR_SPI0_BASEADDR + XSPIPS_TXD_OFFSET, 81);
    Xil_Out32(XPAR_SPI0_BASEADDR + XSPIPS_TXD_OFFSET, 37);
    Xil_Out32(XPAR_SPI0_BASEADDR + XSPIPS_TXD_OFFSET, 17);
    Xil_Out32(XPAR_SPI0_BASEADDR + XSPIPS_TXD_OFFSET, 111);

    
    XSpiPs_Enable(&spiPs);
    Xil_Out32(XPAR_APB_M_0_BASEADDR + 0x10, 0x508);     //Master mode 0x108, slave mode 0x010

    printf("S RX FIFO STAT: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x18));
    printf("S TX FIFO STAT: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x2C));
    printf("S POSEDGE: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x30));
    printf("S NEGEDTE: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x34));
    printf("SCLK EDGE: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x38));
   
    Xil_Out32(XPAR_APB_M_0_BASEADDR + 0x14, 3);
    


    printf("Transmitting.........................\n");

    for(int i = 0;i < 5000000;i++);

    printf("S RX FIFO STAT: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x18));
    printf("S TX FIFO STAT: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x2C));
    for(int i = 0;i < 10;i++)printf("Master FIFO: %u\n", Xil_In32(XPAR_SPI0_BASEADDR + XSPIPS_RXD_OFFSET));
    printf("\n\n");

    for(int i = 0;i < 10;i++)printf("Slave FIFO: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR));

    printf("After read..................\n");
    
    printf("S RX FIFO STAT: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x18));
    printf("S TX FIFO STAT: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x2C));
    printf("S POSEDGE: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x30));
    printf("S NEGEDTE: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x34));
    printf("SCLK EDGE: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x38));
    cleanup_platform();
    return 0;
}
