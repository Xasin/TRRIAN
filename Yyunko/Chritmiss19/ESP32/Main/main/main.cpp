
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_event.h"
#include "esp_event_loop.h"
#include "esp_pm.h"
#include "esp_timer.h"
#include "esp32/pm.h"
#include "nvs_flash.h"
#include "driver/gpio.h"
#include "driver/rtc_io.h"

#include "hw_def.h"
#include "animator.h"

esp_err_t event_handler(void *ctx, system_event_t *event)
{
    return ESP_OK;
}

extern "C" void app_main(void)
{
    nvs_flash_init();
    tcpip_adapter_init();
    ESP_ERROR_CHECK( esp_event_loop_init(event_handler, NULL) );

    esp_timer_init();

    esp_pm_config_esp32_t power_config = {};
    power_config.max_freq_mhz = 80;
	power_config.min_freq_mhz = 80;
	power_config.light_sleep_enable = false;
    esp_pm_configure(&power_config);

    printf("Heap is %d\n", xPortGetFreeHeapSize());

    SG::Animator::init();

    printf("Heap is %d\n", xPortGetFreeHeapSize());

    int i = 0;
    while (true) {
    	while(SG::Animator::tgt_chevron_pos != -1) {
    		vTaskDelay(1);
    	}
    	if(i == 4) {
    		SG::Animator::all_chevrons_soft();
    		vTaskDelay(3000);
    		SG::Animator::clear_chevrons();
    		i = 0;
    	}
    	vTaskDelay(500);

    	SG::Animator::tgt_chevron_pos = esp_random() % 16;
    	printf("TGT Chevron at %d\n", SG::Animator::tgt_chevron_pos);
    	i++;
    }
}

