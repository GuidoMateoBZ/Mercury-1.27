import serial
import struct
import time

# --- CONFIGURACIÓN ---
PORT = 'COM7'
BAUD = 9600
NOMBRE_EQUIPO = b'TEST'
CANALES_CONFIG = [58, 2, 3, 4, 5, 6, 7, 8, 9, 10]
INTERVALO_MUESTREO = 60

def generar_respuesta_CE():
    respuesta = bytearray(50)
    for i in range(10):
        valor = 1000 + i * 100
        struct.pack_into('<H', respuesta, i*2, valor) 
    
    hora = int(time.time()) - 946684800
    struct.pack_into('<I', respuesta, 20, hora)
    struct.pack_into('<I', respuesta, 24, hora)
    struct.pack_into('<H', respuesta, 28, INTERVALO_MUESTREO)
    
    for i, config in enumerate(CANALES_CONFIG):
        respuesta[32 + i] = config
    
    respuesta[42:46] = NOMBRE_EQUIPO
    respuesta[46] = 64 # Memoria ocupada ejemplo
    respuesta[49] = 16 # Capacidad 2^16
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