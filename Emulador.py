import serial
import struct
import time

# --- CONFIGURACIÓN ---
PORT = 'COM7'
BAUD = 9600
NOMBRE_EQUIPO = b'TEST'
CANALES_CONFIG = [58, 0, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]
INTERVALO_MUESTREO = 60

def generar_respuesta_CE():
    pos = 0
    respuesta = bytearray(len(CANALES_CONFIG)*3+18)

    for i in range(len(CANALES_CONFIG)):
        valor = 1000 + i * 100
        struct.pack_into('<H', respuesta, i*2, valor) 
    pos+=len(CANALES_CONFIG)*2

    hora = int(time.time()) - 946684800
    struct.pack_into('<I', respuesta, pos, hora)
    struct.pack_into('<I', respuesta, pos+4, hora)
    struct.pack_into('<H', respuesta, pos+8, INTERVALO_MUESTREO)
    
    pos+=10 #Los 10 bytes de hora, fecha e intervalo de muestreo
    for i, config in enumerate(CANALES_CONFIG):
        respuesta[pos + i] = config
    pos+=len(CANALES_CONFIG)
    
    respuesta[pos:pos+4] = NOMBRE_EQUIPO
    respuesta[pos+4] = 64 # Memoria ocupada ejemplo
    respuesta[pos+5] = 16 # Capacidad 2^16
    return bytes(respuesta)

def generar_datos_muestras():
    canales_activos = [i for i, c in enumerate(CANALES_CONFIG) if c > 0]
    num_canales = len(canales_activos)
    if num_canales == 0: return bytes(4)
    
    num_muestras = 10
    total_bytes = 4 + (num_canales * 2 * num_muestras)
    datos = bytearray(total_bytes)
    
    struct.pack_into('<I', datos, 0, total_bytes)
    
    pos = 4
    for muestra in range(num_muestras):
        for canal in canales_activos:
            valor = 500 + (canal * 100) + (muestra * 10)
            struct.pack_into('<H', datos, pos, valor)
            pos += 2
    return bytes(datos)

# --- FLUJO PRINCIPAL ---
try:
    ser = serial.Serial(PORT, BAUD, timeout=0.1) # Timeout bajo para no bloquear el script
    print(f"Simulador iniciado en {PORT}. Esperando comandos...")

    while True:
        data = ser.read(1)
        
        if data == b'X':
            print("Recibido: X (heartbeat)")
            ser.write(b'CE')
            ser.write(generar_respuesta_CE())
            ser.flush() # Asegura el envío
            print("Enviado: CE + 50 bytes")
        
        elif data == b'L':
            next_byte = ser.read(1)
            if next_byte == b'D':
                print("Recibido: LD (solicitud de datos)")
                ser.write(b'DG')
                ser.write(generar_datos_muestras())
                ser.flush()
                print("Datos de muestras enviados.")

except serial.SerialException as e:
    print(f"Error al abrir el puerto: {e}")
except KeyboardInterrupt:
    print("\nSimulador detenido.")
finally:
    if 'ser' in locals() and ser.is_open:
        ser.close()