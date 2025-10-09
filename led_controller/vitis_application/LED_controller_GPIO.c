
int main()
{

init_platform();
XGpioPs xgpiops;
XGpioPs_Config *config;
u32 sw0, sw1;
u32 and, or, xor_, xnor_;
config = XGpioPs_LookupConfig(XPAR_GPIO_BASEADDR); 
if (config)
{
    xil_printf("Config lookup failed");
    return XST_FAILURE;
}

XGpioPs_CfgInitialize(&xgpiops, config, config-> BaseAddr);
xil_printf("Initialized");

XGpioPs_SetDirectionPin(&xgpiops, 78, 0);
XGpioPs_SetDirectionPin(&xgpiops, 79, 0);
XGpioPs_SetDirectionPin(&xgpiops, 80, 1);
XGpioPs_SetDirectionPin(&xgpiops, 81, 1);
XGpioPs_SetDirectionPin(&xgpiops, 82, 1);
XGpioPs_SetDirectionPin(&xgpiops, 83, 1);

XGpioPs_SetOutputEnablePin(&xgpiops, 80, 1); 
XGpioPs_SetOutputEnablePin(&xgpiops, 81, 1); 
XGpioPs_SetOutputEnablePin (&xgpiops, 82, 1); 
XGpioPs_SetOutputEnablePin(&xgpiops, 83, 1);
while(1)
    sw0 = XGpioPs_ReadPin(&xgpiops, 78);
    sw1 = XGpioPs_ReadPin(&xgpiops, 79);
    
    and_=  swe & sw1;
    or = sw0 ❘ sw1;
    xor = sw0 ^ sw1;
    xnor= ~(sw0 ^ sw1);
    XGpioPs_WritePin(&xgpiops, 80, sw0 & sw1);
    XGpioPs_WritePin(&xgpiops, 81, swe | sw1);
    XGpioPs_WritePin(&xgpiops, 82, sw0 ^ sw1);
    XGpioPs_WritePin(&xgpiops, 83, ~(sw0 ^ sw1));
    xil_printf("AND: %d ... OR: %d XOR: %d ... XNOR: %d", and_, or_, xor_, xnor_);
    cleanup_platform();
    return 0;
}