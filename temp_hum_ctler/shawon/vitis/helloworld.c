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

#define LOCK 0xC00
#define LOAD 0x00
#define VALUE 0x04
#define CTL 0x08
#define MIS 0x14
#define ICR 0x0C
#define UNLOCK 0x1ACCE551
#define IIC_SLAVE_ADDR      0x0
#define IIC_SCLK_RATE       100000


#define HEATER_PIN                  78
#define FAN_PIN                     79
#define HUMIDIFIER_PIN              80
#define DEHUMIDIFIER_PIN            81
#define DEFAULT_TEMP_LED_PIN        82
#define DEFAULT_HUMIDITY_LED_PIN    83
//........................................................................................

#define UART_RBR 0xC1C  
#define UART_THR 0xC1C
#define UART_IER 0xC20
#define UART_IIR 0xC24
#define UART_FCR 0xC24
#define UART_LCR 0xC28
#define UART_LSR 0xC2C
#define UART_DLL 0xC30
#define UART_DLH 0xC34
#define UART_PWM 0xC38




// //..............................................NEW print..................
void amaderPrint(const char* string, ...)
{
    int i=0;
    va_list args;
    va_start(args, string);

    char buffer[256];
    vsprintf(buffer, string, args);
    printf("np : %s", buffer);

    while (i < 255 && buffer[i] != '\0')
    {
        Xil_Out32(XPAR_APB_M_0_0_BASEADDR + UART_THR, buffer[i]);
        if((Xil_In32(XPAR_APB_M_0_0_BASEADDR + UART_LSR) & 2) == 0)i++;
    }

    va_end(args);
}

// //..................Configuration functions.................

// //........................................SETUP UART.............................................
s32 SETUP_UART()
{
    printf("UART-PL : Initializing\n");
    //Xil_Out32(XPAR_APB_M_1_0_BASEADDR + UART_IER, 0x0000000F);
    printf("UART-PL : Interrupt set complete\n");
    Xil_Out32(XPAR_APB_M_0_0_BASEADDR + UART_FCR, 0x01);
    Xil_Out32(XPAR_APB_M_0_0_BASEADDR + UART_LCR, 0x03);

    printf("UART-PL : Line Configuration complete\n");

    Xil_Out32(XPAR_APB_M_0_0_BASEADDR + UART_DLL, 55);
    //Xil_Out32(XPAR_APB_M_1_0_BASEADDR + UART_DLH, 0);
    Xil_Out32(XPAR_APB_M_0_0_BASEADDR + UART_PWM, 0xFFFFFFFF);

    printf("UART-PL : Configuration done\n");
    return XST_SUCCESS;
}



XGpioPs xgpiops;
XScuGic gic;
XGpioPs_Config * gpio_config;

XSpiPs spips;
XSpiPs_Config *config1;

XIicPs iicps;
XIicPs_Config* iic_config;

u8 pl2ps[2];
u8 iic_enable=0;

//......................................WDT INTERRUPT SERVICE ROUTINE..................
void WDT_ISR()
{


    Xil_Out32(XPAR_APB_M_0_BASEADDR + LOCK, UNLOCK);
    Xil_Out32(XPAR_APB_M_0_BASEADDR + ICR, 0x0000FFFF);
    

    
    Xil_Out32(XPAR_APB_M_0_BASEADDR + LOCK, 0x102);

    printf("WDT: INTPT.......\n");
    //printf("TEMP @ reg: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x18));
    //printf("HMDT @ reg: %u\n", Xil_In32(XPAR_APB_M_0_BASEADDR + 0x1C));
    iic_enable = 1;


}

//....................................TEST FUNCTIONS..................................
//Writes a random value in the LOAD register and tries to read it. 
void WDT_TEST()
{
    printf("Testing WDT\n");
    Xil_Out32(XPAR_APB_M_0_BASEADDR + LOCK, UNLOCK);
    Xil_Out32(XPAR_APB_M_0_BASEADDR, 0x1DCD6500);
    if(Xil_In32(XPAR_APB_M_0_BASEADDR) != 0x1DCD6500)
    {
        printf("WDT test FAILED\n");
        return;
    }
    Xil_Out32(XPAR_APB_M_0_BASEADDR + 0x08, 0x01);
    Xil_Out32(XPAR_APB_M_0_BASEADDR + LOCK, 0x123);
    printf("WDT test PASSED\n");
}


//Configures GPIO pins for the LEDs
s32 INIT_GPIO()
{
    printf("Initializing XGPIOPS\n");
    gpio_config = XGpioPs_LookupConfig(XPAR_GPIO_BASEADDR);
    if(gpio_config == NULL)
    {
        printf("XGPIOPS: Config lookup failed\n");
        return XST_FAILURE;
    }

    XGpioPs_CfgInitialize(&xgpiops, gpio_config, gpio_config-> BaseAddr);
    printf("XGPIOPS: Lookup configuration complete\n");

    XGpioPs_SetDirectionPin(&xgpiops, 78, 1);
    XGpioPs_SetDirectionPin(&xgpiops, 79, 1);
    XGpioPs_SetDirectionPin(&xgpiops, 80, 1);
    XGpioPs_SetDirectionPin(&xgpiops, 81, 1);
    XGpioPs_SetDirectionPin(&xgpiops, 82, 1);
    XGpioPs_SetDirectionPin(&xgpiops, 83, 1);
    
    XGpioPs_SetOutputEnablePin(&xgpiops, 78, 1);
    XGpioPs_SetOutputEnablePin(&xgpiops, 79, 1);
    XGpioPs_SetOutputEnablePin(&xgpiops, 80, 1);
    XGpioPs_SetOutputEnablePin(&xgpiops, 81, 1);
    XGpioPs_SetOutputEnablePin(&xgpiops, 82, 1);
    XGpioPs_SetOutputEnablePin(&xgpiops, 83, 1);

    XGpioPs_WritePin(&xgpiops, 78, 0);
    XGpioPs_WritePin(&xgpiops, 79, 0);
    XGpioPs_WritePin(&xgpiops, 80, 0);
    XGpioPs_WritePin(&xgpiops, 81, 0);
    XGpioPs_WritePin(&xgpiops, 82, 0);
    XGpioPs_WritePin(&xgpiops, 83, 0);

    printf("XGPIOPS: Configuration complete\n");
    return XST_SUCCESS;
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

    XIicPs_SetupSlave(&iicps, IIC_SLAVE_ADDR);
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




int main()
{
    init_platform();

    printf(".....Initializing.....\n\r");
    
    //Setup stuff
    INIT_GPIO();
    SETUP_INTPT();
    SETUP_IIC();
    SETUP_SPIPS();
    SETUP_UART();
    //Test the watchdog and also enables it
    WDT_TEST();
    
    Xil_Out32(XPAR_APB_M_0_BASEADDR + 0xC04, 0x01);
    printf("PL SPI set\n");
    printf("PL SPI Check : %u\n", (Xil_In32(XPAR_APB_M_0_BASEADDR + 0xC04)));

    Xil_Out32(XPAR_APB_M_0_0_BASEADDR + UART_DLL, 55);
    printf("written");
    printf("DLL Check : %u\n", (Xil_In32(XPAR_APB_M_0_0_BASEADDR + UART_DLL)));

 //Keep on doing what you do
    while(1)
    {
        if(iic_enable)
        {
            u32 temp;
            u32 humidity;
            
            Xil_Out32(XPAR_XSPIPS_0_BASEADDR + XSPIPS_TXD_OFFSET, 123);
            XIicPs_MasterRecvPolled(&iicps, pl2ps, 1, IIC_SLAVE_ADDR);
            usleep(50);

            humidity = pl2ps[0];
            temp = Xil_In32(XPAR_XSPIPS_0_BASEADDR + XSPIPS_RXD_OFFSET);
            //printf("TEMP @SPI: %u\n", temp);
            //printf("IIC-PS: Received %u\n\n", pl2ps[0]);
            amaderPrint("T %u\n", temp);
            amaderPrint("H %u\n\n", humidity);
            
            //temperature too high, turn FAN ON, HEATER OFF.
            if(temp > 40)
            {
                XGpioPs_WritePin(&xgpiops, 79, 1);
                XGpioPs_WritePin(&xgpiops, 78, 0);
                XGpioPs_WritePin(&xgpiops, 82, 0);
            }

            //temperature too high, turn FAN OFF, HEATER ON.
            else if (temp < 15)
            {
                XGpioPs_WritePin(&xgpiops, 79, 0);
                XGpioPs_WritePin(&xgpiops, 78, 1);
                XGpioPs_WritePin(&xgpiops, 82, 0);
            }

            //turn both off
            else if ((temp<=25) & (temp>=20)){
                XGpioPs_WritePin(&xgpiops, 79, 0);
                XGpioPs_WritePin(&xgpiops, 78, 0);
                XGpioPs_WritePin(&xgpiops, 82, 1);
            }

            else {
                XGpioPs_WritePin(&xgpiops, 79, 0);
                XGpioPs_WritePin(&xgpiops, 78, 0);
                XGpioPs_WritePin(&xgpiops, 82, 0);
            }

            if(humidity > 70) { // Too humid
                XGpioPs_WritePin(&xgpiops, DEHUMIDIFIER_PIN, 1);
                XGpioPs_WritePin(&xgpiops, HUMIDIFIER_PIN, 0);
                XGpioPs_WritePin(&xgpiops, DEFAULT_HUMIDITY_LED_PIN, 0);
            } else if (humidity < 30) { // Too dry
                XGpioPs_WritePin(&xgpiops, DEHUMIDIFIER_PIN, 0);
                XGpioPs_WritePin(&xgpiops, HUMIDIFIER_PIN, 1);
                XGpioPs_WritePin(&xgpiops, DEFAULT_HUMIDITY_LED_PIN, 0);
            } else if ((humidity<=50) & (humidity>=46)) { // Just right
                XGpioPs_WritePin(&xgpiops, DEHUMIDIFIER_PIN, 0);
                XGpioPs_WritePin(&xgpiops, HUMIDIFIER_PIN, 0);
                XGpioPs_WritePin(&xgpiops, DEFAULT_HUMIDITY_LED_PIN, 1);
            }

            else { // Just right
                XGpioPs_WritePin(&xgpiops, DEHUMIDIFIER_PIN, 0);
                XGpioPs_WritePin(&xgpiops, HUMIDIFIER_PIN, 0);
                XGpioPs_WritePin(&xgpiops, DEFAULT_HUMIDITY_LED_PIN, 0);
            }
            iic_enable = 0;

        }
    }

    cleanup_platform();
    return 0;
}
