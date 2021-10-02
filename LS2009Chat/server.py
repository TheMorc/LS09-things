import socket
import threading
import queue
import sys
import random
import os
import time

def RecvData(sock,recvPackets):
    while True:
        data,addr = sock.recvfrom(1024)
        recvPackets.put((data,addr))

def RunServer():
    host = socket.gethostbyname(socket.gethostname())
    port = 2009
    print('LS2009Chat Server: '+str(host))
    s = socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
    s.bind((host,port))
    clients = set()
    recvPackets = queue.Queue()

    threading.Thread(target=RecvData,args=(s,recvPackets)).start()

    while True:
        while not recvPackets.empty():
            data,addr = recvPackets.get()
            if addr not in clients:
                clients.add(addr)
                continue
            clients.add(addr)
            data = data.decode('utf-8')
            print(str(addr)+data)
            for c in clients:
                if c!=addr:
                    s.sendto(data.encode('utf-8'),c)
        time.sleep(0.001)
    s.close()

if __name__ == '__main__':
    if len(sys.argv)==1:
        RunServer()
