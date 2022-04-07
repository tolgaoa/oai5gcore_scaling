import socket
import numpy as np
from time import sleep
import sys

print("The client sending to:", sys.argv[1], " on port:" , sys.argv[2])

datain = np.loadtxt("processedin.txt", dtype=int)
dataout = np.loadtxt("processedout.txt", dtype=int)

# Scale here if necessary
datain=datain
dataout=dataout
print(datain.size)

msgFromClient       = "Hello UDP Server"
bytesToSend         = str.encode(msgFromClient)
serverAddressPort   = (sys.argv[1], int(sys.argv[2]))
bufferSize          = 1024

# Create a UDP socket at client side
UDPClientSocket = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM) 

useddata=datain
# Send to server using created UDP socket
while(True):
    for x in useddata:
        if x != 0:
            UDPClientSocket.sendto(bytearray([1] * x), serverAddressPort)
            sleep(0.001)
        else:
            sleep(0.001)

msgFromServer = UDPClientSocket.recvfrom(bufferSize)
msg = "Message from Server {}".format(msgFromServer[0])
