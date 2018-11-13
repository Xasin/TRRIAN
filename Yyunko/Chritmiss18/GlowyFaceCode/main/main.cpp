#include "freertos/FreeRTOS.h"
#include "esp_wifi.h"
#include "esp_system.h"
#include "esp_event.h"
#include "esp_event_loop.h"
#include "nvs_flash.h"
#include "driver/gpio.h"

#include "NeoController.h"

#include "ManeAnimator.h"

using namespace Peripheral;

NeoController *lightController = nullptr;

esp_err_t event_handler(void *ctx, system_event_t *event)
{
return ESP_OK;
}

extern "C" void app_main(void)
{
	nvs_flash_init();
	tcpip_adapter_init();
	ESP_ERROR_CHECK( esp_event_loop_init(event_handler, NULL) );
	wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();

	ESP_ERROR_CHECK( esp_wifi_init(&cfg) );
	ESP_ERROR_CHECK( esp_wifi_set_storage(WIFI_STORAGE_RAM) );
	ESP_ERROR_CHECK( esp_wifi_set_mode(WIFI_MODE_STA) );

	// ESP_ERROR_CHECK( esp_wifi_set_config(WIFI_IF_STA, &sta_config) );
	// ESP_ERROR_CHECK( esp_wifi_start() );
	// ESP_ERROR_CHECK( esp_wifi_connect() );

	lightController = new NeoController(GPIO_NUM_14, RMT_CHANNEL_0, 16);

	lightController->fill(Color(Material::DEEP_PURPLE, 80));
	lightController->fadeTransition(1000000);

	int level = 0;
	int cColor = 0;

	uint32_t colors[] = {Material::RED, Material::GREEN, Material::BLUE};

	lightController->fill(Color(Material::RED, 90));

	ManeAnimator mane(16);

	Layer bLayer(16);
	bLayer.alpha = 100;
	Layer dimLayer(16);

	Layer cTargetLayer(16);
	cTargetLayer.alpha = 4;
	Layer cActualLayer(16);

	dimLayer.fill(0x222222);
	dimLayer.alpha = 10;

	while (true) {

		bLayer.fill(Color(Material::CYAN, 80));
		bLayer.merge_multiply(mane.scalarPoints);

//		cTargetLayer[level] = colors[cColor];
//		cActualLayer.merge_overlay(cTargetLayer);
//
//		lightController->nextColors = cActualLayer;
		lightController->fill(Color(Material::CYAN, 40));
		lightController->nextColors.merge_overlay(bLayer);

		mane.tick();

		lightController->apply();
		lightController->update();

		vTaskDelay(10);


		level  = (16*esp_timer_get_time())/1000000 % 32;
		if(level == 0)
			mane.points[0].pos = 1;
		cColor = (esp_timer_get_time())/1000000 % 3;
	}
}
