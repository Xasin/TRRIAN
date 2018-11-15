
#include <functional>

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

void lambdaCaller(void *arg) {
	(*reinterpret_cast<std::function<void(void)>*>(arg))();
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
	int fadePos = 0;
	int cColor = 0;
	uint32_t colors[]	  = {Material::CYAN, Material::YELLOW, Material::PURPLE};
	uint32_t backColors[] = {Material::BLUE, Material::AMBER, Material::DEEP_PURPLE};

	lightController->fill(Color(Material::RED, 90));

	ManeAnimator mane(8);
	mane.wrap = true;

	Layer tgtBackground(16);
	tgtBackground.alpha = 12;
	Layer smBackground(16);
	smBackground.fill(0xFF0000);

	Layer tgtManeForeground(8);
	tgtManeForeground.alpha = 40;

	Layer smManeForeground(8);
	smManeForeground.alpha = 200;
	Layer animManeForeground(8);

	std::function<void(void)> animatorLambda = [&]() {
		while(true) {
			mane.tick();

			smBackground.merge_overlay(tgtBackground);
			smManeForeground.merge_overlay(tgtManeForeground);

			animManeForeground = smManeForeground;
			animManeForeground.merge_multiply(mane.scalarPoints);

			lightController->nextColors = smBackground;
			lightController->nextColors.merge_overlay(animManeForeground, -4, true);

			lightController->apply();
			lightController->update();

			vTaskDelay(10);
		}
	};

	TaskHandle_t animatorTask;
	xTaskCreate(&lambdaCaller, "Animator Thread", 4048, &animatorLambda, 3, &animatorTask);

	while (true) {
		tgtBackground[fadePos] = backColors[cColor];
		tgtManeForeground[fadePos -4] = colors[cColor];

		vTaskDelay(20);

		level  = (esp_timer_get_time())/10000 % 300;
		if(level <= 30)
			mane.points[fadePos % mane.points.size()].vel += 0.003;

		cColor = (esp_timer_get_time())/15000000 % 3;
		fadePos = (10*16*esp_timer_get_time())/15000000;

		int shiftFadePos = (fadePos + 3) % (10*16);
		if(shiftFadePos < mane.points.size())
			mane.points[shiftFadePos].vel += 0.0012;
	}
}
