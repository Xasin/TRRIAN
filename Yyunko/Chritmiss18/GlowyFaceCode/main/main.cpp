
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
#include "Control.h"

#include "ManeAnimator.h"

#include "MasterAction.h"

#include "WifiPasswd.h"

using namespace Peripheral;
using namespace XaI2C;

NeoController *lightController = nullptr;
TaskHandle_t mainThread = nullptr;

volatile uint8_t MQTT_whoIs = 1;
volatile bool  is_enabled = true;

volatile uint8_t whoIs = 0;

void I2CTest() {
	MasterAction::init(GPIO_NUM_25, GPIO_NUM_26);

	MasterAction testWrite = MasterAction(0b0111100);

	char cmdString[] = {0xAF, 0xA5, 0x81, 0x7F};
	testWrite.write(0x80, cmdString, 1);
	testWrite.write(0x80, cmdString+1, 1);
	testWrite.write(0x00, cmdString+2, 2);

	testWrite.execute();

	puts("CMD should be written!");
}

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

void update_current_color() {
	if(is_enabled)
		xTaskNotify(mainThread, MQTT_whoIs, eSetValueWithOverwrite);
	else
		xTaskNotify(mainThread, 4, eSetValueWithOverwrite);
}

esp_err_t mqtt_evt_handle(esp_mqtt_event_handle_t event) {

	switch(event->event_id) {
	case MQTT_EVENT_CONNECTED:
		puts("MQTT connected!");

		esp_mqtt_client_subscribe(event->client, "Personal/Yyunko/XaHead/#", 1);
		esp_mqtt_client_publish(event->client, "Personal/Yyunko/XaHead/Connected", "OK", 3, 1, true);
	break;
	case MQTT_EVENT_DATA: {
		std::string topic(event->topic, event->topic_len);
		if(topic == "Personal/Yyunko/XaHead/Who") {
			MQTT_whoIs = 0;

			std::string whoIs(event->data, event->data_len);
			if(whoIs == "Xasin")
				MQTT_whoIs = 1;
			else if(whoIs == "Neira")
				MQTT_whoIs = 2;
			else if(whoIs == "Mesh")
				MQTT_whoIs = 3;

			if(is_enabled)
				update_current_color();
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

	//I2CTest();

	ESP_ERROR_CHECK( esp_event_loop_init(event_handler, NULL) );
	wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();

	ESP_ERROR_CHECK( esp_wifi_init(&cfg) );
	ESP_ERROR_CHECK( esp_wifi_set_storage(WIFI_STORAGE_RAM) );
	ESP_ERROR_CHECK( esp_wifi_set_mode(WIFI_MODE_STA) );

	wifi_config_t wifi_cfg = {};
	wifi_sta_config_t* sta_cfg = &(wifi_cfg.sta);

	memcpy(sta_cfg->password, WIFI_PASSWD, strlen(WIFI_PASSWD));
	memcpy(sta_cfg->ssid, WIFI_SSID, strlen(WIFI_SSID));

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

	lightController = new NeoController(GPIO_NUM_14, RMT_CHANNEL_0, 20);

	struct ColorSet {
		Color maneTop;
		Color maneBottom;
		Color eye;
		Color upperFace;
		Color lowerFace;
	};

	ColorSet colorSets[] = {
		{
			maneTop:    Color(0x666666),
			maneBottom: 0,
			eye: 0, upperFace: 0, lowerFace: 0
		},
		{
			maneTop: 	Material::CYAN,
			maneBottom: Material::BLUE,
			eye:		Material::CYAN,
			upperFace:	Color(Material::RED, 100),
			lowerFace:	Color(Material::RED, 100)
	},
		{
			maneTop:	Material::YELLOW,
			maneBottom:	Material::DEEP_ORANGE,
			eye:		Material::ORANGE,
			upperFace:	Color(Material::BLUE, 110),
			lowerFace:	Color(0xFFFFFF, 87)
	},	{
			maneTop:	Material::PURPLE,
			maneBottom:	Material::DEEP_PURPLE,
			eye:		Material::PURPLE,
			upperFace:	Color(0x03FF06, 90),
			lowerFace:	Color(0x03FF06, 90)
		},
		{
			maneTop:    0,
			maneBottom: 0,
			eye: 0, upperFace: 0, lowerFace: 0
		}
	};

	lightController->fill(0);

	ManeAnimator mane(8);
	mane.wrap = false;
	mane.basePoint = 0.4;

	Layer tgtBackground(20);
	tgtBackground.alpha = 12;
	Layer smBackground(20);
	smBackground.fill(0);

	Layer tgtManeForeground(8);
	tgtManeForeground.alpha = 15;

	Layer smManeForeground(8);
	smManeForeground.alpha = 190;
	Layer animManeForeground(8);
	animManeForeground.alpha = 150;

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
			lightController->nextColors.merge_overlay(animManeForeground);

			lightController->apply();
			lightController->update();

			vTaskDelay(15);
		}
	};

	std::function<void(void)> switchLambda = []() {
		Touch::Control touchy = Touch::Control(TOUCH_PAD_NUM5);
		touchy.charDetectHandle = xTaskGetCurrentTaskHandle();

		uint32_t touchStatus = false;
		while(true) {
			vTaskDelay(100);
			printf("Switching system: %d\n", touchy.read_raw());
		}

		while(true) {
			xTaskNotifyWait(0, 0, &touchStatus, portMAX_DELAY);
			if(touchStatus) {
				is_enabled = !is_enabled;

				printf("Switching system: %d\n", touchy.read_raw());
				update_current_color();
				vTaskDelay(1000/portTICK_PERIOD_MS);
			}
		}
	};

	mainThread = xTaskGetCurrentTaskHandle();

	TaskHandle_t animatorTask;
	xTaskCreatePinnedToCore(&lambdaCaller, "Animator Thread", 6*1024, &animatorLambda, configMAX_PRIORITIES - 3, &animatorTask, 0);

	TaskHandle_t switchTask;
	xTaskCreate(&lambdaCaller, "Switch", 2048, &switchLambda, 3, &switchTask);

	unsigned int whoIsBuffer = MQTT_whoIs;

	while (true) {
		tgtBackground.fill(0, 8, 20);
		tgtBackground.alpha = 2;
		vTaskDelay(2000/portTICK_PERIOD_MS);
		tgtBackground.alpha = 12;

		whoIs = whoIsBuffer;
		ColorSet& currentSet = colorSets[whoIs];

		for(uint8_t i=0; i<mane.points.size(); i++) {
			mane.points[i].vel += 0.01;

			tgtManeForeground[i] = currentSet.maneTop;
			tgtBackground[i] = currentSet.maneBottom;

			vTaskDelay(200/portTICK_PERIOD_MS);
		}

		tgtBackground.fill(currentSet.upperFace, 8, 15);
		tgtBackground.fill(currentSet.lowerFace, 15, 18);
		if((whoIs != 0) && (whoIs != 4))
			tgtBackground.fill(0x555555, 18, 20);

		tgtBackground.alpha = 2;

		xTaskNotifyWait(0, 0, &whoIsBuffer, portMAX_DELAY);
	}
}
