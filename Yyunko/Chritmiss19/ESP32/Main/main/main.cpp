
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
	 SG::HW::esp_evt_handler(event);
    return ESP_OK;
}

extern "C" void app_main(void)
{
    nvs_flash_init();
    tcpip_adapter_init();
    ESP_ERROR_CHECK( esp_event_loop_init(event_handler, NULL) );

    esp_timer_init();

    esp_pm_config_esp32_t power_config = {};
    power_config.max_freq_mhz = 120;
	power_config.min_freq_mhz = 120;
	power_config.light_sleep_enable = false;
    esp_pm_configure(&power_config);

    printf("Heap is %d\n", xPortGetFreeHeapSize());

    SG::HW::init();
    SG::Animator::init();

    Peripheral::Color::test_color();

    int i = 0;
    while (true) {
    	auto t = SG::HW::get_time();

        printf("Time is: %d:%02d:%02d\n", t->tm_hour, t->tm_min, t->tm_sec);
        vTaskDelay(50000);
	 }
}
