
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

	struct ColorSet {
		Color maneTop;
		Color maneBottom;
		Color eye;
		Color upperFace;
		Color lowerFace;
	};

	ColorSet colorSets[] = {
		{
			maneTop: 	Material::CYAN,
			maneBottom: Material::BLUE,
			eye:		Material::CYAN,
			upperFace:	Material::RED,
			lowerFace:	Material::RED
	},
		{
			maneTop:	Material::YELLOW,
			maneBottom:	Material::DEEP_ORANGE,
			eye:		Material::ORANGE,
			upperFace:	Material::BLUE,
			lowerFace:	0xFFFFFF
	},	{
			maneTop:	Material::PURPLE,
			maneBottom:	Material::DEEP_PURPLE,
			eye:		Material::PURPLE,
			upperFace:	Material::GREEN,
			lowerFace:	Material::GREEN
		}
	};

	lightController->fill(0);

	ManeAnimator mane(8);
	mane.wrap = false;

	Layer tgtBackground(16);
	tgtBackground.alpha = 12;
	Layer smBackground(16);
	smBackground.fill(0xFF0000);

	Layer tgtManeForeground(8);
	tgtManeForeground.alpha = 20;

	Layer smManeForeground(8);
	smManeForeground.alpha = 180;
	Layer animManeForeground(8);
	animManeForeground.alpha = 180;

	std::function<void(void)> animatorLambda = [&]() {
		uint64_t nextBlip = xTaskGetTickCount() + esp_random()%(3000/portTICK_PERIOD_MS);

		while(true) {
			if(xTaskGetTickCount() >= nextBlip) {
				puts("Blip!");
				nextBlip = xTaskGetTickCount() + (esp_random()%(3000) + 3000)/portTICK_PERIOD_MS;

				mane.points[esp_random() % mane.points.size()].vel += 0.01;
			}

			mane.tick();

			smBackground.merge_overlay(tgtBackground);
			smManeForeground.merge_overlay(tgtManeForeground);

			animManeForeground = smManeForeground;
			animManeForeground.merge_multiply(mane.scalarPoints);

			lightController->nextColors = smBackground;
			lightController->nextColors.merge_overlay(animManeForeground, 0, true);

			lightController->apply();
			lightController->update();

			vTaskDelay(10);
		}
	};

	TaskHandle_t animatorTask;
	xTaskCreate(&lambdaCaller, "Animator Thread", 4048, &animatorLambda, 3, &animatorTask);

	uint8_t whoIs = 0;
	while (true) {
		if(++whoIs >= 3)
			whoIs = 0;

		ColorSet& currentSet = colorSets[whoIs];

		tgtBackground.fill(0, 8, 16);
		tgtBackground.alpha = 6;
		vTaskDelay(2000/portTICK_PERIOD_MS);
		tgtBackground.alpha = 12;

		for(uint8_t i=0; i<mane.points.size(); i++) {
			mane.points[i].vel += 0.003;

			tgtManeForeground[i] = currentSet.maneTop;
			tgtBackground[i] = currentSet.maneBottom;

			vTaskDelay(100/portTICK_PERIOD_MS);
		}

		tgtBackground.fill(currentSet.upperFace, 8, 11);
		tgtBackground.fill(currentSet.lowerFace, 11, 13);
		tgtBackground.fill(currentSet.upperFace, 13, 16);
		tgtBackground.alpha = 6;

		vTaskDelay(30000/portTICK_PERIOD_MS);
	}
}
