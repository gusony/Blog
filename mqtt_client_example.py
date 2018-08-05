import serial
import time
import datetime
import paho.mqtt.client as paho

broker="140.113.199.198"

send_data = ""
rece_data = ""
new_recv = False


def is_number(s):
    try:
        int(s)
        return True
    except ValueError:
        return False

def on_message(client, userdata, message):
    time.sleep(0.001)
    #rece_data = str(message.payload.decode("utf-8"))
    #print str(message.payload.decode("utf-8"))
    print str(datetime.datetime.now())+","+str(message.payload.decode("utf-8"))
    f1.write(str(datetime.datetime.now())+","+str(message.payload.decode("utf-8")))

def on_connect(client, userdata, flags, rc):
    client.subscribe("iottalk/esm/de3993f7-b880-48b7-8097-187de4d4fbb1")


def signal_handler(sig, frame):
    f1.close()
    sys.exit(0)

client= paho.Client("client-001")
client.on_connect = on_connect
client.on_message = on_message
client.connect(broker)


time.sleep(0.1)


if __name__ == '__main__':
    f1 = open("./"+datetime.datetime.now().strftime('%Y-%m-%d_%H') + '.txt', 'a')
    client.loop_forever()


