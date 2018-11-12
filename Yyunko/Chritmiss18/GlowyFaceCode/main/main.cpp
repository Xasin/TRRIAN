#include "freertos/FreeRTOS.h"
#include "esp_wifi.h"
#include "esp_system.h"
#include "esp_event.h"
#include "esp_event_loop.h"
#include "nvs_flash.h"
#include "driver/gpio.h"

#include "NeoController.h"

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
	while (true) {
		level++;
		(*lightController)[level] = colors[cColor];
		lightController->fadeTransition(130000);

		if(level >= 16) {
			level = 0;
			cColor++;
			if(cColor >= 3)
				cColor = 0;
		}
	}
}
