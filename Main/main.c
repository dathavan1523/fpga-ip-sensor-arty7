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

    // --- KHỞI TẠO TIMER ---
    status = XTmrCtr_Initialize(&tmr, TMR_DEVICE_ID);
    if (status != XST_SUCCESS) {
        xil_printf("Timer Init Failed\r\n");
        return XST_FAILURE;
    }

    XTmrCtr_Stop(&tmr, TIMER_0);
    XTmrCtr_SetResetValue(&tmr, TIMER_0, RESET_VALUE);
    XTmrCtr_SetOptions(&tmr, TIMER_0, XTC_AUTO_RELOAD_OPTION | XTC_DOWN_COUNT_OPTION);
    XTmrCtr_Start(&tmr, TIMER_0); // Bắt đầu đếm ngay

    // --- BIẾN DỮ LIỆU ---
    u32 bh_raw_data;
    u32 lux_int, lux_dec, lux_x10;
    u32 dht_temp = 0, dht_humid = 0;

    print("===========================================\n\r");
    print("   TONG HOP CAM BIEN (USE LIB HEADER)      \n\r");
    print("===========================================\n\r");

    while(1) {
        // Kiểm tra Timer đã đếm hết 3 giây chưa
        if (XTmrCtr_IsExpired(&tmr, TIMER_0)) {

            // 1. Dừng Timer để xử lý
            XTmrCtr_Stop(&tmr, TIMER_0);

            // ============================================
            // BẮT ĐẦU ĐỌC CẢM BIẾN
            // ============================================

            // --- BƯỚC 1: ĐỌC DHT11 (Dùng macro từ dht11_ip.h) ---

            // Gửi tín hiệu Start (Ghi 1 vào REG0)
            DHT11_IP_mWriteReg(DHT11_BASE_ADDR, DHT11_IP_S00_AXI_SLV_REG0_OFFSET, 0x01);

            // Chờ 30ms cho cảm biến phản hồi
            usleep(30000);

            // Đọc Nhiệt độ (REG2 - Offset 8)
            dht_temp = DHT11_IP_mReadReg(DHT11_BASE_ADDR, DHT11_IP_S00_AXI_SLV_REG2_OFFSET);

            // Đọc Độ ẩm (REG3 - Offset 12)
            dht_humid = DHT11_IP_mReadReg(DHT11_BASE_ADDR, DHT11_IP_S00_AXI_SLV_REG3_OFFSET);

            // Reset tín hiệu điều khiển (Ghi 0 vào REG0)
            DHT11_IP_mWriteReg(DHT11_BASE_ADDR, DHT11_IP_S00_AXI_SLV_REG0_OFFSET, 0x00);


            // --- BƯỚC 2: ĐỌC BH1750 (Dùng macro từ BH1750_ip.h) ---
            bh_raw_data = BH1750_IP_mReadReg(BH1750_BASE_ADDR, BH1750_IP_S00_AXI_SLV_REG0_OFFSET);

            // Tính toán Lux
            lux_x10 = (bh_raw_data * 100) / 12;
            lux_int = lux_x10 / 10;
            lux_dec = lux_x10 % 10;


            // --- BƯỚC 3: HIỂN THỊ KẾT QUẢ ---
            xil_printf("----------------------------------\n\r");
            xil_printf("Status: Doc sau 3 giay (Timer) \n\r");
            xil_printf("Do am (DHT11):    %lu %%\n\r", dht_humid);
            xil_printf("Nhiet do (DHT11): %lu C\n\r", dht_temp);
            xil_printf("Anh sang (BH1750): %d.%d lx\n\r", lux_int, lux_dec);

            // ============================================
            // RESET & START LẠI TIMER
            // ============================================
            XTmrCtr_Reset(&tmr, TIMER_0);
            XTmrCtr_Start(&tmr, TIMER_0);
        }
    }

    cleanup_platform();
    return 0;
}
