import serial
import time
import datetime

ser = serial.Serial('/dev/ttyUSB0', 115200) #on Ubuntu
#ser = serial.Serial('/dev/cu.usbserial',115200) #on mac


if __name__ == '__main__':
    t_start = datetime.datetime.now()
    print t_start.strftime('%Y-%m-%d %H-%M-%S') + '.txt'
    f1 = open("./"+t_start.strftime('%Y-%m-%d_%H') + '.txt', 'a')
    t = datetime.datetime.now()


    while(1):
        while(t.hour==t_start.hour):
            t = datetime.datetime.now()
            val=ser.readline()

            a = val.rstrip().rstrip('\n')
            print  str(datetime.datetime.now())+","+ a
            f1.write( str(datetime.datetime.now())+","+ a)

        f1.close()
        t_start = datetime.datetime.now()
        print t_start.strftime('%Y-%m-%d_%H') + '.txt'
        f1 = open("./"+t_start.strftime('%Y-%m-%d_%H') + '.txt', 'a')

