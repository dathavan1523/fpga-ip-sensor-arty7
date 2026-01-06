#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h"
#include "xtmrctr.h"
#include "BH1750_ip.h"
#include "dht11_ip.h"


#define TMR_DEVICE_ID   XPAR_TMRCTR_0_DEVICE_ID
#define TIMER_0         0

#define RESET_VALUE     300000000


#define BH1750_BASE_ADDR XPAR_BH1750_IP_0_S00_AXI_BASEADDR
#define DHT11_BASE_ADDR  XPAR_DHT11_IP_0_S00_AXI_BASEADDR


XTmrCtr tmr;

int main()
{
    init_platform();
    int status;


    status = XTmrCtr_Initialize(&tmr, TMR_DEVICE_ID);
    if (status != XST_SUCCESS) {
        xil_printf("Timer Init Failed\r\n");
        return XST_FAILURE;
    }

    XTmrCtr_Stop(&tmr, TIMER_0);
    XTmrCtr_SetResetValue(&tmr, TIMER_0, RESET_VALUE);
    XTmrCtr_SetOptions(&tmr, TIMER_0, XTC_AUTO_RELOAD_OPTION | XTC_DOWN_COUNT_OPTION);
    XTmrCtr_Start(&tmr, TIMER_0); // Bắt đầu đếm ngay


    u32 bh_raw_data;
    u32 lux_int, lux_dec, lux_x10;
    u32 dht_temp = 0, dht_humid = 0;

    print("===========================================\n\r");
    print("   TONG HOP CAM BIEN (USE LIB HEADER)      \n\r");
    print("===========================================\n\r");

    while(1) {
     
        if (XTmrCtr_IsExpired(&tmr, TIMER_0)) {

           
            XTmrCtr_Stop(&tmr, TIMER_0);


            DHT11_IP_mWriteReg(DHT11_BASE_ADDR, DHT11_IP_S00_AXI_SLV_REG0_OFFSET, 0x01);

            
            usleep(30000);

           
            dht_temp = DHT11_IP_mReadReg(DHT11_BASE_ADDR, DHT11_IP_S00_AXI_SLV_REG2_OFFSET);

            
            dht_humid = DHT11_IP_mReadReg(DHT11_BASE_ADDR, DHT11_IP_S00_AXI_SLV_REG3_OFFSET);

            
            DHT11_IP_mWriteReg(DHT11_BASE_ADDR, DHT11_IP_S00_AXI_SLV_REG0_OFFSET, 0x00);


            
            bh_raw_data = BH1750_IP_mReadReg(BH1750_BASE_ADDR, BH1750_IP_S00_AXI_SLV_REG0_OFFSET);

           
            lux_x10 = (bh_raw_data * 100) / 12;
            lux_int = lux_x10 / 10;
            lux_dec = lux_x10 % 10;


            
            xil_printf("----------------------------------\n\r");
            xil_printf("Status: Doc sau 3 giay (Timer) \n\r");
            xil_printf("Do am (DHT11):    %lu %%\n\r", dht_humid);
            xil_printf("Nhiet do (DHT11): %lu C\n\r", dht_temp);
            xil_printf("Anh sang (BH1750): %d.%d lx\n\r", lux_int, lux_dec);

            XTmrCtr_Reset(&tmr, TIMER_0);
            XTmrCtr_Start(&tmr, TIMER_0);
        }
    }

    cleanup_platform();
    return 0;
}
