
#include "LittleConsole.h"
#include "SSD1306.h"
#include <functional>
#include <string.h>

#include "freertos/FreeRTOS.h"
#include "esp_wifi.h"
#include "esp_system.h"
#include "esp_log.h"
#include "esp_event.h"
#include "esp_event_loop.h"
#include "nvs_flash.h"
#include "driver/gpio.h"

#include "mqtt_client.h"

#include "NeoController.h"
#include "Control.h"

#include "DrawBox.h"

#include "SSegDisplay.h"

#include "ManeAnimator.h"

#include "WifiPasswd.h"

struct FaceConfig {
	int totalLength;
	int maneEnd;
	int upperFaceEnd;
	int lowerFaceEnd;
};

const FaceConfig faces[] = {
		{
				20,
				8,
				15,
				18,
		},
		{
				14,
				7,
				11,
				13
		}
};

FaceConfig currentFace = faces[FACE_NUM];

using namespace Peripheral;
using namespace XaI2C;

NeoController *lightController = nullptr;
TaskHandle_t mainThread = nullptr;

volatile uint8_t MQTT_whoIs = 1;
volatile bool  is_enabled = true;

volatile uint8_t whoIs = 0;

OLED::SSD1306 screen = OLED::SSD1306();
OLED::DrawBox *testBox = nullptr;

SSegDisplay testSegment(screen);

OLED::DrawBox testBattery = OLED::DrawBox(8, 6, &screen);
OLED::LittleConsole *console;


char *vsprintfBuffer = new char[255];

uint8_t drawBatVal = 0;
void drawBattery() {
	testBattery.draw_box(1, 0, 7, 6, false);
	testBattery.draw_line(0, 1, 4, 1);

	for(uint8_t i=0; i<(4*5); i++) {
		testBattery.set_pixel(6 - i/4, 1+(i%4), i<drawBatVal);
	}
	drawBatVal = (drawBatVal+1) % (4*5);

	testSegment.draw_number((drawBatVal/10), 0);
	testSegment.draw_number((drawBatVal % 10), 1);
}

int vprintf_like(const char *input, va_list args) {
	int printedLength = vsprintf(vsprintfBuffer, input, args);

	console->printf(vsprintfBuffer + 8);
	return printedLength;
}

void I2CTest() {
	XaI2C::MasterAction::init(GPIO_NUM_25, GPIO_NUM_26);

	testBattery.offsetX = 110;
	testBattery.onRedraw = drawBattery;

	testBox = new OLED::DrawBox(100, 32, &screen);
	testBox->visible = false;
	console = new OLED::LittleConsole(*testBox);

	screen.initialize();

	for(uint8_t i=0; i<11; i++) {
		console->printf("Test no. %d!\n", i);

		vTaskDelay(200);
	}

	esp_log_set_vprintf(vprintf_like);

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

		esp_mqtt_client_subscribe(event->client, (std::string("Personal/") + FACE_NAME + "/XaHead/#").data(), 1);
		esp_mqtt_client_publish(event->client, (std::string("Personal/") + FACE_NAME + "/XaHead/Connected").data(), "OK", 3, 1, true);
	break;
	case MQTT_EVENT_DATA: {
		std::string topic(event->topic, event->topic_len);
		if(topic == std::string("Personal/") + FACE_NAME "/XaHead/Who") {
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

	mqtt_cfg.lwt_topic = (std::string("Personal/") + FACE_NAME + "/XaHead/Connected").data();
	mqtt_cfg.lwt_msg_len = 0;
	mqtt_cfg.lwt_retain = true;

	auto mqtt_handle = esp_mqtt_client_init(&mqtt_cfg);
	esp_mqtt_client_start(mqtt_handle);

	//I2CTest();

	lightController = new NeoController(GPIO_NUM_14, RMT_CHANNEL_0, currentFace.totalLength);

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

	ManeAnimator mane(currentFace.maneEnd);
	mane.wrap = false;
	mane.basePoint = 0.4;

	Layer tgtBackground(currentFace.totalLength);
	tgtBackground.alpha = 12;
	Layer smBackground(currentFace.totalLength);
	smBackground.fill(0);

	Layer tgtManeForeground(currentFace.maneEnd);
	tgtManeForeground.alpha = 15;

	Layer smManeForeground(currentFace.maneEnd);
	smManeForeground.alpha = 190;
	Layer animManeForeground(currentFace.maneEnd);
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
		tgtBackground.fill(0, currentFace.maneEnd, currentFace.totalLength);
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

		tgtBackground.fill(currentSet.upperFace, currentFace.maneEnd, currentFace.upperFaceEnd);
		tgtBackground.fill(currentSet.lowerFace, currentFace.upperFaceEnd, currentFace.lowerFaceEnd);
		if((whoIs != 0) && (whoIs != 4))
			tgtBackground.fill(0x606060, currentFace.lowerFaceEnd, currentFace.totalLength);

		tgtBackground.alpha = 2;

		xTaskNotifyWait(0, 0, &whoIsBuffer, portMAX_DELAY);
	}
}
