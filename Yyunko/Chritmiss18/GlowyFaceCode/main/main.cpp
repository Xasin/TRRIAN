
#include <functional>
#include <string.h>

#include "freertos/FreeRTOS.h"
#include "esp_wifi.h"
#include "esp_system.h"
#include "esp_event.h"
#include "esp_event_loop.h"
#include "nvs_flash.h"
#include "driver/gpio.h"

#include "mqtt_client.h"


#include "NeoController.h"

#include "ManeAnimator.h"

using namespace Peripheral;

NeoController *lightController = nullptr;
TaskHandle_t mainThread = nullptr;

volatile uint8_t whoIs = 0;

esp_err_t event_handler(void *ctx, system_event_t *event)
{
	switch(event->event_id) {
    case SYSTEM_EVENT_STA_START:
	puts("WiFi STA started!");
        esp_wifi_connect();
        break;
    case SYSTEM_EVENT_STA_GOT_IP:
    	puts("WiFi connected!");
    	break;
    case SYSTEM_EVENT_STA_DISCONNECTED:
    	puts("WiFi disconnected!");
    	esp_wifi_connect();
    	break;
    default:  break;
	}

	return ESP_OK;
}

esp_err_t mqtt_evt_handle(esp_mqtt_event_handle_t event) {

	switch(event->event_id) {
	case MQTT_EVENT_CONNECTED:
		puts("MQTT connected!");

		esp_mqtt_client_subscribe(event->client, "Personal/Yyunko/XaHead/#", 1);
		esp_mqtt_client_publish(event->client, "Personal/Yyunko/XaHead/Connected", "OK", 3, 1, true);
	break;
	case MQTT_EVENT_DATA: {
		puts("MQTT got data!");

		std::string topic(event->topic, event->topic_len);
		if(topic == "Personal/Yyunko/XaHead/Who") {
			uint8_t whoIsNum = 0;

			std::string whoIs(event->data, event->data_len);
			if(whoIs == "Xasin")
				whoIsNum = 1;
			else if(whoIs == "Neira")
				whoIsNum = 2;
			else if(whoIs == "Mesh")
				whoIsNum = 3;
			else if(whoIs == "Mixed")
				whoIsNum = 4;

			xTaskNotify(mainThread, whoIsNum, eSetValueWithOverwrite);
		}
	}
	break;
	default: break;
	}

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

	wifi_config_t wifi_cfg = {};
	wifi_sta_config_t* sta_cfg = &(wifi_cfg.sta);

	memcpy(sta_cfg->password, "f36eebda48\0", 11);
	memcpy(sta_cfg->ssid, "TP-LINK_84CDC2\0", 15);

	ESP_ERROR_CHECK( esp_wifi_set_config(ESP_IF_WIFI_STA, &wifi_cfg) );
	ESP_ERROR_CHECK( esp_wifi_start() );
	//ESP_ERROR_CHECK( esp_wifi_connect() );

	esp_mqtt_client_config_t mqtt_cfg = {};
	mqtt_cfg.event_handle = mqtt_evt_handle;
	mqtt_cfg.uri = "mqtt://iot.eclipse.org";

	mqtt_cfg.lwt_topic = "Personal/Yyunko/XaHead/Connected";
	mqtt_cfg.lwt_msg_len = 0;
	mqtt_cfg.lwt_retain = true;

	auto mqtt_handle = esp_mqtt_client_init(&mqtt_cfg);
	esp_mqtt_client_start(mqtt_handle);

	lightController = new NeoController(GPIO_NUM_14, RMT_CHANNEL_0, 16);

	struct ColorSet {
		Color maneTop;
		Color maneBottom;
		Color eye;
		Color upperFace;
		Color lowerFace;
	};

	ColorSet colorSets[] = {
		{
			maneTop:    Color(0x333333),
			maneBottom: 0,
			eye: 0, upperFace: 0, lowerFace: 0
		},
		{
			maneTop: 	Material::CYAN,
			maneBottom: Material::BLUE,
			eye:		Material::CYAN,
			upperFace:	Color(Material::RED, 110),
			lowerFace:	Color(Material::RED, 110)
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
		},
		{
			maneTop:	0xFFFFFF,
			maneBottom: 0xFFFFFF,
			eye:		0xFFFFFF,
			upperFace:	0xFFFFFF,
			lowerFace:	0xFFFFFF,
		}
	};

	lightController->fill(0);

	ManeAnimator mane(8);
	mane.wrap = false;

	Layer tgtBackground(16);
	tgtBackground.alpha = 12;
	Layer smBackground(16);
	smBackground.fill(0);

	Layer tgtManeForeground(8);
	tgtManeForeground.alpha = 20;

	Layer smManeForeground(8);
	smManeForeground.alpha = 230;
	Layer animManeForeground(8);
	animManeForeground.alpha = 230;

	std::function<void(void)> animatorLambda = [&]() {
		uint64_t nextBlip = xTaskGetTickCount() + esp_random()%(3000/portTICK_PERIOD_MS);

		while(true) {
			if(xTaskGetTickCount() >= nextBlip) {
				puts("Blip!");
				nextBlip = xTaskGetTickCount() + (esp_random()%(3000) + 1000)/portTICK_PERIOD_MS;

				mane.points[esp_random() % mane.points.size()].vel += 0.016;
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

	mainThread = xTaskGetCurrentTaskHandle();

	TaskHandle_t animatorTask;
	xTaskCreate(&lambdaCaller, "Animator Thread", 4048, &animatorLambda, 10, &animatorTask);

	unsigned int whoIsBuffer = 1;
	while (true) {
		tgtBackground.fill(0, 8, 16);
		tgtBackground.alpha = 6;
		vTaskDelay(2000/portTICK_PERIOD_MS);
		tgtBackground.alpha = 12;

		whoIs = whoIsBuffer;
		ColorSet& currentSet = colorSets[whoIs];

		for(uint8_t i=0; i<mane.points.size(); i++) {
			mane.points[i].vel += 0.01;

			tgtManeForeground[i] = currentSet.maneTop;
			tgtBackground[i] = currentSet.maneBottom;

			vTaskDelay(100/portTICK_PERIOD_MS);
		}

		tgtBackground.fill(currentSet.upperFace, 8, 11);
		tgtBackground.fill(currentSet.lowerFace, 11, 13);
		tgtBackground.fill(currentSet.upperFace, 13, 16);
		tgtBackground.alpha = 6;

		xTaskNotifyWait(0, 0, &whoIsBuffer, portMAX_DELAY);
	}
}
