/******************************************************************************
Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
SPDX-License-Identifier: MIT
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

#include "xparameters.h"
#include <stdio.h>
#include "platform.h"
#include "xil_io.h"

// int main()
// {
//     init_platform();

//     printf("Writing value\n");
//     Xil_Out32(XPAR_APB_M0_BASEADDR , 1);
//     Xil_Out32(XPAR_APB_M0_BASEADDR + 0x00000004, 7);
//     Xil_Out32(XPAR_APB_M0_BASEADDR + 0x00000008, 5);
//     Xil_Out32(XPAR_APB_M0_BASEADDR + 0x0000000C, 1);
//     printf("Writing done\n");

//     cleanup_platform();
//     return 0;
// }

int main()
{
    int inputType;
    u32 value = 15;
    u32 addOffset = 0x00000004;
    init_platform();

    while(1){
        printf("Enter op type. 0 to write, 1 to read\n");
        scanf("%d", &inputType);
        if(inputType == 0) 
        {
            for(int k = 0;k < 4;k++){
                printf("\nEnter value for address: %x\n", XPAR_APB_M_0_BASEADDR + addOffset*k);
                scanf("%u", &value);
                Xil_Out32(XPAR_APB_M_0_BASEADDR + addOffset*k, value);
            }
        }
        else if(inputType == 1)
        {
            printf("\nRead values:\n");
            for(int k = 0;k < 4;k++){
                value = Xil_In32(XPAR_APB_M_0_BASEADDR + addOffset*k);
                printf("value @ %x %u\n",XPAR_APB_M_0_BASEADDR + addOffset*k, value);
            }
        }
        inputType = -1;
    }

    cleanup_platform();
    return 0;
}