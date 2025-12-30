# ANÁLISIS DETALLADO: COMUNICACIÓN RS232 EN SISTEMA EMAC

**Fecha de análisis:** 2025-12-10
**Sistemas analizados:**
1. Firmware Autónomo 1.5 (Beta) - Raspberry Pi Pico
2. Mercury-1.27 - Sistema de escritorio Delphi/Lazarus

---

## TABLA DE CONTENIDOS

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Firmware Autónomo 1.5 (Beta)](#firmware-autónomo-15-beta)
3. [Mercury-1.27](#mercury-127)
4. [Comparación de Protocolos](#comparación-de-protocolos)
5. [Conclusiones](#conclusiones)

---

# RESUMEN EJECUTIVO

Este documento detalla la implementación de comunicación RS232 en el sistema EMAC, que consta de:
- **Hardware:** Datalogger basado en Raspberry Pi Pico (MicroPython)
- **Software:** Aplicación de escritorio Mercury-1.27 (Pascal/Lazarus)

## Características Principales del Protocolo

| Aspecto | Firmware (Equipo) | Mercury (PC) |
|---------|-------------------|--------------|
| **Baud Rate** | 19200 bps | 19200 bps |
| **Formato** | 8N1 | 8N1 |
| **Timeout RX** | 25 ms | 750 ms |
| **Protocolo** | Comandos de 2 letras | Comandos de 2 letras |
| **Pins (Equipo)** | TX=GPIO0, RX=GPIO1 | N/A |
| **Puerto (PC)** | N/A | COM1-COM255 |

---

# FIRMWARE AUTÓNOMO 1.5 (BETA)

## 1. ARCHIVOS QUE IMPLEMENTAN LA COMUNICACIÓN SERIAL

### Archivo Principal:
- **`C:\Users\pablo\OneDrive\Desktop\EMAC\Firmware Autonomo 1.5 (Beta)\lib\comunication.py`** (28 KB, 842 líneas)

### Archivos Complementarios:
- **`lib/emac.py`** - Gestión de datos y configuración del equipo
- **`lib/configuration.py`** - Manejo de configuración persistente
- **`lib/global_star.py`** - Comunicación con modem GlobalStar
- **`lib/nmea.py`** - Parseo de mensajes NMEA del GPS
- **`main.py`** - Punto de entrada y bucle principal

---

## 2. PROTOCOLO DE COMUNICACIÓN

El proyecto soporta **3 canales de comunicación** alternativos:

1. **UART/Serial (RS232)** - Cable serie directo con Mercury (configurador)
2. **MODEM CELULAR** (57600 baud) - Comunicación remota
3. **WIFI** - Conexión inalámbrica local
4. **GLOBAL_STAR** - Modem satelital SmartOne Solar (9600 baud)

### Protocolo Principal: Basado en Comandos de 2 Bytes

El sistema implementa un protocolo de **mensajes comandados** donde se intercambian instrucciones de 2-3 bytes seguidas de datos binarios.

---

## 3. CONFIGURACIÓN DEL PUERTO SERIAL (RS232/UART)

### Puerto Serial Mercury (Cable Directo):

```python
# Función de inicialización del UART serial (líneas 62-67)
def create_serial_uart(time_out=25, baud=19200, tx_pin=0, rx_pin=1) -> UART:
    return UART(0,
                baudrate=19200,      # Velocidad: 19200 bps
                timeout=25,          # Timeout: 25 ms
                tx=Pin(0),          # Pin TX: GPIO 0
                rx=Pin(1))          # Pin RX: GPIO 1
```

### Parámetros Técnicos del Serial:

| Parámetro | Valor | Descripción |
|-----------|-------|-------------|
| **Baud Rate** | 19200 bps | Velocidad de transmisión |
| **Timeout** | 25 ms | Tiempo de espera de lectura |
| **TX Pin** | GPIO 0 | Pin de transmisión |
| **RX Pin** | GPIO 1 | Pin de recepción |
| **Bits de Datos** | 8 | (Implícito en MicroPython) |
| **Paridad** | Ninguna | No especificada (default: None) |
| **Bits de Parada** | 1 | (Default en MicroPython) |

### Verificación de Conexión:

```python
# Líneas 70-82
def check_serial_cable() -> bool:
    global serial_cable_last, uart_0
    if data_logger._serial_connected:
        # Verifica si han pasado 2 segundos sin mensajes
        if ticks_diff(ticks_ms(), serial_cable_last) < 2000:
            return True

    # Verifica si el cable sigue conectado (lectura del pin RX)
    value = bool(Pin(1, Pin.IN).value())
    if value:
        uart_0 = create_serial_uart()
        serial_cable_last = ticks_ms()
    return value
```

---

## 4. FORMATO DE MENSAJES

### Estructura General de Comandos:

El sistema utiliza **comandos de 2 letras** seguidos de datos opcionales.

#### Comandos Reconocidos:

```python
# Líneas 639-657
def commands(bytes_in=b'') -> bytes:

    # 1. CONFIGURACIÓN (26 bytes exactos)
    if len(bytes_in) == 26:
        config_in(bytes_in)
        return b'OK'

    # 2. CONFIGURACIÓN CON ENCABEZADO "CE" (28 bytes)
    if b'CE' in bytes_in:
        if len(bytes_in) == 28:
            config_in(bytes_in[2:])  # Salta los 2 primeros bytes "CE"
            return b'OK'
        return b''

    # 3. CARGAR DATOS (LD)
    if b'LD' in bytes_in:
        return b'DG'  # Respuesta para enviar datos

    # 4. CONFIGURACIÓN GLOBAL (GA)
    if b'GA' in bytes_in:
        return command_GA(bytes_in)

    # 5. PERÍODO DE ENVÍO (TX)
    if b'TX' in bytes_in:
        bytes_in = bytes_in.split(b'TX')[1]
        command_TX(bytes_in[:2])

    # 6. SOLICITAR DATOS (X)
    if b'X' in bytes_in:
        return command_X()

    return b''
```

### Tabla de Comandos:

| Comando | Tipo | Longitud | Descripción | Respuesta |
|---------|------|----------|-------------|-----------|
| **CE** | Config | 28 bytes | Configuración con encabezado | OK |
| (Sin encabezado) | Config | 26 bytes | Configuración pura | OK |
| **LD** | Solicitud | 2 bytes | Cargar datos | DG (pedir datos) |
| **GA** | Config | Variable | Configuración de internet/modem | (vacío) |
| **TX** + 2 bytes | Config | 4 bytes | Periodo de envío (big-endian) | (vacío) |
| **X** | Solicitud | 1 byte | Solicitar datos telemetría | **CExxx...** |

---

## 5. COMANDOS DISPONIBLES - DETALLE TÉCNICO

### 5.1 Comando "X" - Solicitar Datos Telemetría

```python
# Líneas 660-665
def command_X() -> bytes:
    data = data_logger.make_data()
    data.insert(0, b'E')
    data.insert(0, b'C')
    data = b''.join(data)
    return data
```

**Formato de respuesta:**
- `CE` (2 bytes header)
- Datos de canales (18 bytes)
- Configuración actual (26 bytes)
- **Total: 46 bytes**

### 5.2 Comando "LD" - Cargar Datos Almacenados

**Solicitud:** `LD` (2 bytes)
**Respuesta:** `DG` (2 bytes)

Esto desencadena la función `send_all_data()`:

```python
# Líneas 776-797
def send_all_data(called_by):
    try:
        # Envía 4 bytes indicando cantidad de datos
        space = storage.space_of_data()
        space = int.to_bytes(space, 4, 'little')
        called_by.write(space)

        # Luego envía los datos en chunks de 2 bytes
        with open('/data.bin', 'rb') as f:
            bytes_2 = f.read(2)
            while bytes_2:
                called_by.write(bytes_2)
                bytes_2 = f.read(2)
    except:
        print("Error enviando datos")
```

**Protocolo de transferencia de datos:**
1. Recibe comando `LD` → responde `DG`
2. Espera solicitud de datos
3. Envía 4 bytes (little-endian) con tamaño total
4. Transmite archivo `/data.bin` en chunks de 2 bytes

### 5.3 Comando "CE" - Configuración Completa

**Estructura (26 bytes):**

```python
# Líneas 44-54 (configuration.py)
Position | Bytes | Descripción
---------|-------|---------------------------------------------------
0-3      | 4     | Hora Julian (little-endian) - Timestamp
4-7      | 4     | Inicio de muestreo (little-endian)
8-9      | 2     | Período de muestreo en segundos (little-endian)
10-11    | 2     | Período de regresión (little-endian)
12-21    | 10    | Configuración de 10 canales (0=deshabilitado, 1=habilitado)
22-25    | 4     | Nombre del equipo (4 caracteres ASCII)
```

**Ejemplo de configuración binaria (del config.txt):**
```
000000002c0100002c0137004002400240024002010058585830
```

Decodificado:
- `00000000` = Tiempo Julian (0 = 01/01/2000 00:00:00)
- `2c010000` = Inicio muestreo (300 segundos = 5 minutos)
- `2c01` = Período (300 segundos = 5 minutos)
- `3700` = Período regresión (55 segundos)
- `4002400240024002010` = Canales (9 habilitados, 1 deshabilitado)
- `0058585830` = Nombre ("XXXX")

### 5.4 Comando "GA" - Configuración de Internet/Modem

**Estructura variable:**
```
GA + comando AT + ; + período_envío
```

**Ejemplo del archivo config.txt:**
```
wireless_config ATE0 ATE0 AT+CMGF=1 AT+CNMI=3,2,2,0,0 AT+CMGD=1,4
AT+CREG=1 AT+MIPCALL=1,"","GLOBAL_STAR",""
AT+MIPOPEN=1,40000,"190.124.196.178",40000,0
```

Parsed en el código (líneas 700-773):

```python
def command_GA(config) -> bytes:
    global ssid, password, ip_port, modem_commands, communication_using

    # Separa comandos AT de período de envío
    modem_commands, send_period = config.split(b';')

    # Procesa comandos AT línea por línea
    for command in modem_commands:
        if b'MIPCALL' in command:
            # Extrae SSID, modo y contraseña
            splitted = command.decode().split(',')
            ssid = splitted[1].replace('"', '')
            mode = splitted[2].replace('"', '')  # WIFI/MODEM/GLOBAL_STAR
            password = splitted[3].replace('"', '')

        if b'MIPOPEN' in command:
            # Extrae puerto IP y dirección servidor
            splitted = command.decode().split(',')
            port = int(splitted[1])
            ip = splitted[2].replace('"', '')
            ip_port = (ip, port)

    # Determina modo de comunicación
    if mode == 'WIFI':
        communication_using = 'WIFI'
    elif mode in ['TERMINAL', 'ARSAT', 'GATEWAY']:
        communication_using = 'WIFI'
        data_logger._using_terminal = True
    elif mode == 'GLOBAL_STAR':
        communication_using = 'GLOBAL_STAR'
    else:
        communication_using = 'MODEM'
```

### 5.5 Comando "TX" - Configurar Período de Envío

**Solicitud:** `TX` + 2 bytes (big-endian)

```python
# Líneas 689-697
def command_TX(send_period) -> None:
    if len(send_period) != 2:
        return
    send_period = int.from_bytes(send_period, 'big') + 1

    # Para GLOBAL_STAR, período mínimo es 1
    if communication_using == 'GLOBAL_STAR':
        send_period = 1

    data_logger.set_send_period(send_period)
    set_in_file('periodes_to_send', str(send_period))
```

---

## 6. ESTRUCTURA DE DATOS TRANSMITIDOS

### 6.1 Estructura de Datos de Telemetría (Comando "X")

El equipo mide 9 canales analógicos (18 bytes de datos) + configuración:

```python
# Del archivo emac.py líneas 98-105
def make_data(self) -> list:
    data = []
    # Obtiene 18 bytes de datos de 9 canales analógicos (2 bytes cada uno)
    for i in self._channels.get_data():
        data.append(i)

    # Añade 26 bytes de configuración
    data = [i.to_bytes(1, 'little') for i in data]
    for i in self._config.get():
        data.append(i)

    return data
```

**Formato completo del mensaje "CExxx...":**

```
Offset | Tamaño | Campo
-------|--------|--------------------------------------
0-1    | 2      | Encabezado "CE"
2-19   | 18     | Datos de 9 canales (2 bytes c/u)
       |        |   Ch0: bytes 2-3
       |        |   Ch1: bytes 4-5
       |        |   ... hasta Ch8: bytes 18-19
20-45  | 26     | Configuración actual
       | 4      |   - Hora Julian
       | 4      |   - Inicio muestreo
       | 2      |   - Período muestreo
       | 2      |   - Período regresión
       | 10     |   - Config de canales
       | 4      |   - Nombre equipo
-------|--------|
TOTAL  | 46     | bytes
```

### 6.2 Estructura de Almacenamiento en Memoria

Los datos se guardan en `/data.bin` en formato binario comprimido:

```python
# Líneas 107-133 (emac.py)
def take_sample(self):
    data = self.make_data()
    config = self._config.get_channels_cfg()

    to_save = []
    # Solo guarda canales habilitados (2 bytes c/u)
    for idx, channel in enumerate(config):
        if channel != 0:  # Si canal habilitado
            i = idx*2
            to_save.append(data[i])
            to_save.append(data[i+1])

    to_save = bytes(bytearray([int.from_bytes(i, 'little') for i in to_save]))

    # Guardado local (máximo 1 MB)
    if os.stat('/data.bin')[6] < 1048576:
        with open('/data.bin', 'ab') as f:
            f.write(to_save)

    # Guardado en SD (respaldo)
    if self.has_sd_card:
        with open('sd/data.bin', 'ab') as f:
            f.write(to_save)
```

**Tamaño de muestra:** 2 bytes × (canales habilitados)
- Si todos 9 canales habilitados: 18 bytes por muestra

---

## 7. INICIALIZACIÓN DEL PUERTO SERIAL

### 7.1 Secuencia de Inicialización (main.py)

```python
# Líneas 54-103 del main.py
async def main() -> None:
    # 1. Verifica tarjeta SD
    data_logger.has_sd_card = check_mount_sd()

    # 2. Hace backup de configuración
    if data_logger.has_sd_card:
        storage.copy_file('/config.txt', 'sd/config.txt')
        data_logger.make_backup_to_SD()

    # 3. Configura interrupciones digitales en pines
    Pin(22, Pin.IN, Pin.PULL_UP).irq(trigger=Pin.IRQ_RISING, handler=ch7_counter)
    Pin(27, Pin.IN, Pin.PULL_UP).irq(trigger=Pin.IRQ_RISING, handler=ch8_counter)

    # 4. Configura timers
    state_timer.init(mode=Timer.PERIODIC, period=MAIN_PERIOD, callback=next_state)
    restart_digital_timer.init(freq=DIGITAL_RESTART_FREQ, callback=digital_update)

    # 5. Si no hay cable serial, obtiene tiempo del GPS
    if not check_serial_cable():
        time, to_end = await get_time_with_gps()
        global_star_set_config(julian_time=time)

    # 6. Inicia el bucle principal de eventos
    loop = asyncio.get_event_loop()
    loop.create_task(check_communications(100))  # Monitorea serial cada 100ms
    loop.create_task(request_configuration(530))
    loop.create_task(check_communications(100))
    loop.create_task(connect_socket())
    loop.create_task(modem_check())
    loop.create_task(data_logger.beacon())
    loop.run_forever()
```

### 7.2 Inicialización del UART (comunication.py, línea 27)

```python
async def check_communications(period_ms: int = 1000):
    global serial_cable_last, uart_0, modem_connected

    # Crea el UART con parámetros estándar
    uart_0 = create_serial_uart()  # 19200 baud, pins 0-1, 25ms timeout

    while True:
        await asyncio.sleep_ms(period_ms)

        # Verifica conexión cada 100ms
        serial_cable_connected = check_serial_cable()
        data_logger._serial_connected = serial_cable_connected
```

---

## 8. FUNCIONES DE ENVÍO Y RECEPCIÓN

### 8.1 Lectura/Recepción (check_communications)

```python
# Líneas 25-60
async def check_communications(period_ms: int = 1000):
    global serial_cable_last, uart_0, modem_connected
    uart_0 = create_serial_uart()

    while True:
        await asyncio.sleep_ms(period_ms)

        if modem_connected:
            continue

        serial_cable_connected = check_serial_cable()

        # LECTURA
        bytes_in = uart_0.read()  # Lee hasta 25ms o hasta timeout

        if bytes_in != b'' and bytes_in is not None:
            serial_cable_last = ticks_ms()

            try:
                # Si recibe "CE" (configuración), borra datos
                if b'CE' in bytes_in:
                    data_logger._config._configured = False
                    uart_0.write(b'OK')  # Envía ACK

                # Procesa comando y obtiene respuesta
                response = commands(bytes_in)

                # ENVÍO DE RESPUESTA
                if response != b'' and response is not None:
                    uart_0.write(response)

                    # Si respuesta es "DG", envía todos los datos
                    if response == b'DG':
                        send_all_data(uart_0)
            except:
                print(f"Error serial cable")
```

**Parámetros de lectura:**
- `uart_0.read()` - Lee datos disponibles con timeout de 25ms
- Bloquea hasta que llegue un byte o expire el timeout
- Devuelve `b''` si no hay datos

### 8.2 Envío (UART write)

```python
# Función básica de envío
uart_0.write(bytes_to_send)
uart_0.flush()  # Fuerza transmisión inmediata
```

**Ejemplos de envío:**

1. **Respuesta a configuración:**
   ```python
   uart_0.write(b'OK')
   ```

2. **Solicitud de datos:**
   ```python
   uart_0.write(b'DG')
   ```

3. **Telemetría (comando X):**
   ```python
   response = command_X()  # Retorna CE + 18 bytes datos + 26 bytes config
   uart_0.write(response)  # 46 bytes total
   ```

4. **Transmisión de archivo completo:**
   ```python
   space = int.to_bytes(space, 4, 'little')
   uart_0.write(space)
   uart_0.flush()

   with open('/data.bin', 'rb') as f:
       bytes_2 = f.read(2)
       while bytes_2:
           uart_0.write(bytes_2)
           uart_0.flush()
           bytes_2 = f.read(2)
   ```

### 8.3 Detección de Desconexión

```python
# Líneas 70-82
def check_serial_cable() -> bool:
    global serial_cable_last, uart_0

    # Si estaba conectado, verifica timeout de 2 segundos
    if data_logger._serial_connected:
        if ticks_diff(ticks_ms(), serial_cable_last) < 2000:
            return True

    # Comprueba nivel en pin RX (GPIO 1)
    value = bool(Pin(1, Pin.IN).value())
    if value:
        uart_0 = create_serial_uart()
        serial_cable_last = ticks_ms()
    return value
```

---

## 9. DETALLES DEL PROTOCOLO DE COMUNICACIÓN

### 9.1 Secuencia de Comunicación Típica

#### Escenario 1: Solicitar Telemetría

```
PC Mercury                          Equipo EMAC
    |                                  |
    |---------- "X" (1 byte) -------->|
    |                             Lee comando X
    |                          Prepara datos telemetría
    |<----- "CE" + 18 bytes + 26 config (46 total) ----|
    |        (2+18+26 = 46 bytes)                      |
    |                                  |
```

#### Escenario 2: Cargar Configuración Completa

```
PC Mercury                          Equipo EMAC
    |                                  |
    |---- "CE" + 26 bytes config ----->|
    |        (28 bytes total)      Lee configuración
    |                          Valida estructura
    |<--------- "OK" (2 bytes) --------|
    |                                  |
```

#### Escenario 3: Descargar Datos Almacenados

```
PC Mercury                          Equipo EMAC
    |                                  |
    |---------- "LD" (2 bytes) ------>|
    |                             Lee comando
    |<--------- "DG" (2 bytes) --------|
    |                                  |
    |<-- 4 bytes (tamaño archivo) -----|
    |  00 40 0F 00 (3840 bytes = 0F4000 LE)
    |<---- 2 bytes ----| ... |-- 2 bytes --|
    |    datos chunk 1           datos chunk N
    |        ...
    |    (se transmite archivo completo)
    |                                  |
```

### 9.2 Protección de Datos

#### Durante Transmisión de Archivos:
```python
# Líneas 776-797
def send_all_data(called_by):
    space = storage.space_of_data()
    space = int.to_bytes(space, 4, 'little')  # Little-endian
    called_by.write(space)

    with open('/data.bin', 'rb') as f:
        bytes_2 = f.read(2)
        while bytes_2:
            called_by.write(bytes_2)
            if isinstance(called_by, UART):
                called_by.flush()  # Garantiza envío
            bytes_2 = f.read(2)
```

**No hay checksum o CRC implementado** - Se confía en la fiabilidad del puerto RS232 físico.

### 9.3 Control de Flujo

**Timeout de lectura UART:** 25 ms
**Período de lectura de comunicaciones:** 100 ms (100 Hz)

```python
uart_0 = UART(0, baudrate=19200, timeout=25, tx=Pin(0), rx=Pin(1))
await asyncio.sleep_ms(100)  # Verifica cada 100ms
```

**Velocidad de transmisión:**
- 19200 bps = 2400 bytes/seg
- Un comando de 2 bytes tarda ~1 ms
- Una configuración de 26 bytes tarda ~14 ms

---

## 10. COMANDOS ADICIONALES - CASOS ESPECIALES

### 10.1 Comunicación GlobalStar (Modem Satelital)

```python
# Líneas 458-489
async def global_star_send(data: bytes, location: bool = False, ignore_id=False) -> None:
    # UART 1 separado para modem satelital
    smart_one = SmartOneSolar(
        UART(1, baudrate=9600, tx=Pin(4), rx=Pin(5), timeout=50),
        handshake=Pin(14)
    )

    # Obtiene ID del modem
    id = smart_one.get_id()  # Envía: \xAA\x05\x01\x50\xD5

    # Envía datos comprimidos o raw
    if location:
        response = smart_one.send_truncated(data)  # Máx 51 bytes con ubicación
    else:
        response = smart_one.send_raw(data)        # Máx 51 bytes sin ubicación
```

**Protocolo GlobalStar (clase SmartOneSolar, líneas 32-40):**

```
Frame structure:
┌──────┬──────┬────────┬─────────┬──────┬──────┐
│ 0xAA │ Len  │ Cmd    │ Payload │ CRC0 │ CRC1 │
├──────┼──────┼────────┼─────────┼──────┼──────┤
│  1B  │ 1B   │ 1B     │ N bytes │ 1B   │ 1B   │
└──────┴──────┴────────┴─────────┴──────┴──────┘

Cmd: 0x26 (38) = send_truncated (con ubicación)
Cmd: 0x27 (39) = send_raw (sin ubicación)
```

**CRC16 LSB (MSbit first):**

```python
@staticmethod
def crc16_lsb(data) -> list:
    crc = 0xFFFF
    for byte in data:
        data = 0x00FF & byte
        crc = crc ^ data
        for i in range(8, 0, -1):
            if crc & 0x0001:
                crc = (crc >> 1) ^ 0x8408
            else:
                crc >>= 1
    crc = ~crc & 0xFFFF
    byte_msb = (crc >> 8) & 0xFF
    byte_lsb = crc & 0xFF
    return [byte_lsb, byte_msb]
```

### 10.2 Comunicación Modem Celular

```python
# Líneas 113-120
def create_modem_uart() -> UART:
    return UART(0,
                baudrate=57600,  # Más rápido que serial
                timeout=50,
                tx=Pin(16),
                rx=Pin(17),
                parity=None,
                stop=1)
```

**Comandos AT usados:**

```
AT+CMGF=1              - SMS text mode
AT+CNMI=3,2,2,0,0      - SMS notifications
AT+CREG=1              - Network registration
AT+MIPCALL=1,"","MODE","PASS"  - Conectar con SSID/contraseña
AT+MIPOPEN=1,0,"IP",PORT,0    - Abrir socket TCP
AT+MIPSEND=1,"HEX_DATA"        - Enviar datos (hex string)
AT+MIPPUSH=1           - Push datos pendientes
```

**Conversión a formato hexadecimal:**

```python
# Líneas 270-274
def bytes_to_hex_string(bytes_in) -> str:
    hex = "".join("\\x%02x" % i for i in bytes_in)
    hex = hex.upper()
    hex = hex.replace('\X', '')  # Limpia formato
    return hex
```

Ejemplo: `b'\xCE\x00\x40'` → `"CE0040"`

### 10.3 GPS/NMEA (Hora y Ubicación)

```python
# Líneas 491-527
async def get_time_with_gps(time_out_s=600) -> tuple:
    # UART 1 para GPS a 9600 baud
    gps_uart = UART(1, baudrate=9600, tx=Pin(8), rx=Pin(9), timeout=5)

    while ticks_diff(ticks_ms(), t0) < time_out:
        bytes_in = gps_uart.read()

        if bytes_in:
            try:
                # Parsea sentencias NMEA
                data = nmea.to_dict(bytes_in.decode('ascii'))

                if 'time' in data and 'date' in data:
                    # Formato NMEA: HHMMSS y DDMMYY
                    date_time = parse_nmea_time_date(
                        data['time'], data['date'], time_zone=-3
                    )
                    # Convierte a tiempo Julian
                    time = data_logger._config._rtc.date_to_julian(date_time)
                    break
```

**Sentencias NMEA parseadas (nmea.py):**

```python
$GPRMC - Recomended Minimum (time, position, date)
$GPVTG - Track Made Good and Ground Speed
$GPGGA - Global Positioning System Fix Data (altitude, satellites)
```

---

## RESUMEN TÉCNICO - FIRMWARE

| Aspecto | Especificación |
|---------|----------------|
| **Puerto Serial Principal** | UART 0, 19200 baud, 25ms timeout |
| **Pins** | TX=GPIO0, RX=GPIO1 |
| **Protocolo** | Comandos de 2 letras + datos binarios |
| **Velocidad de Datos** | ~2400 bytes/seg @ 19200 baud |
| **Máx. Configuración** | 26 bytes |
| **Máx. Datos por Muestra** | 18 bytes (9 canales × 2 bytes) |
| **Almacenamiento** | 1 MB en memoria interna, respaldo SD |
| **Modem Celular** | UART alternativo, 57600 baud |
| **GPS** | UART separado, 9600 baud, NMEA |
| **GlobalStar** | 9600 baud, CRC16 LSB |
| **Detección Desconexión** | Timeout 2 segundos sin datos |

---

# MERCURY-1.27

## 1. ARCHIVOS/UNIDADES QUE IMPLEMENTAN LA COMUNICACIÓN SERIAL

**Archivo Principal:**
- `C:\Users\pablo\OneDrive\Desktop\EMAC\Mercury-1.27\PuertoSerie.pas` - Contiene toda la lógica de comunicación serial

**Archivos Relacionados:**
- `UEquipo.pas` - Integra PuertoSerie en la clase TEquipo
- `UUtiles.pas` - Configuraciones globales (TMercury)
- `UConexiones.pas` - Gestión de conexiones automáticas
- `UConfiguracionInternet.pas` - Configuración de modem para internet

---

## 2. COMPONENTES Y BIBLIOTECAS UTILIZADAS

**No utiliza componentes LazSerial o Synaser**, sino que implementa **directamente la API de Windows**:

```pascal
// API de Windows nativa
function CreateFile(lpFileName: PChar; dwDesiredAccess, dwShareMode: DWORD;
  lpSecurityAttributes: Pointer; dwCreationDisposition, dwFlagsAndAttributes: DWORD;
  hTemplateFile: THandle): THandle; stdcall; external 'kernel32.dll' name 'CreateFileA';

function SetupComm(hFile: THandle; dwInQueue, dwOutQueue: DWORD): BOOL;
  stdcall; external 'kernel32.dll';

function GetCommState(hFile: THandle; var lpDCB: Windows.TDCB): BOOL;
  stdcall; external 'kernel32.dll';

function SetCommState(hFile: THandle; const lpDCB: Windows.TDCB): BOOL;
  stdcall; external 'kernel32.dll';

function SetCommTimeouts(hFile: THandle; const lpCommTimeouts: Windows.TCOMMTIMEOUTS): BOOL;
  stdcall; external 'kernel32.dll';

function BuildCommDCB(lpDef: PChar; var lpDCB: Windows.TDCB): BOOL;
  stdcall; external 'kernel32.dll' name 'BuildCommDCBA';
```

---

## 3. CONFIGURACIÓN DEL PUERTO (PARÁMETROS BAUD RATE, BITS, PARIDAD, STOPBITS)

**Clase Principal: TPuertoSerie**

**Parámetros configurables:**

```pascal
type
  TPuertoSerie = class(Tobject)
    public
      RxBufferSize : dword;      // Tamaño buffer recepción: 256 bytes
      TxBufferSize : dword;      // Tamaño buffer transmisión: 256 bytes
      RxTimeout    : dword;      // Timeout lectura: 750 ms (por defecto)
      TxTimeout    : dword;      // Timeout escritura: 0 ms
      RxBuffer     : string;
      TxBuffer     : string;
      ListaPorts   : Tstrings;
      Baud         : string;     // Velocidad en baudios
      Parity       : string;     // Paridad
      Data         : string;     // Bits de datos
      Stop         : string;     // Bits de parada
```

**Valores por defecto (Constructor):**

```pascal
constructor TPuertoSerie.Crear;
begin
  RxBufferSize := 256;
  TxBufferSize := 256;
  RxTimeout    := 0;
  TxTimeout    := 0;
  DeviceName   := 'COM1';
  Baud         := '9600';       // Velocidad por defecto
  Parity       := 'n';          // Sin paridad
  Data         := '8';          // 8 bits de datos
  Stop         := '1';          // 1 bit de parada
  PserieOpen   := false;
  ListaPorts   := Tstringlist.Create;
end;
```

**Velocidades soportadas (por tipo de comunicación - en UEquipo.pas):**

```pascal
// Comunicación por cable serie directo: 19200 bps
case TipoCom of
  0 : PSerie.Baud := '19200';  // CABLE SERIE (PREDETERMINADO)
  1 : PSerie.Baud := '1200';   // TELEFONÍA/MODEM
else
  PSerie.Baud := '19200';      // Por defecto
end;

// Parámetros fijos:
PSerie.Data      := '8';       // 8 bits de datos
PSerie.Parity    := 'n';       // Sin paridad
PSerie.Stop      := '1';       // 1 bit de parada
PSerie.RxTimeout := 750;       // 750 ms lectura
PSerie.TxTimeout := 0;         // 0 ms escritura
```

**Constantes de paridad definidas (en PuertoSerie.pas):**

```pascal
const
  NOPARITY     = 0;   // Sin paridad ('n')
  ODDPARITY    = 1;   // Paridad impar ('o')
  EVENPARITY   = 2;   // Paridad par ('e')
  MARKPARITY   = 3;
  SPACEPARITY  = 4;

  ONESTOPBIT   = 0;   // 1 bit de parada
  ONE5STOPBITS = 1;   // 1.5 bits de parada
  TWOSTOPBITS  = 2;   // 2 bits de parada
```

---

## 4. FORMATO DE MENSAJES (ENVÍO Y RECEPCIÓN)

**Protocolo de Comunicación de Sincronización:**

```
PC → Equipo: 'X'           // Solicita conexión (ping)
Equipo → PC: 'CE'          // Respuesta OK (Connected Equipment)
```

**Protocolo de Configuración:**

```
PC → Equipo: 'CE'          // Entra en modo configuración
Equipo → PC: 'OK'          // Listo para recibir
PC → Equipo: [4 bytes]     // Hora del equipo (32 bits)
PC → Equipo: [4 bytes]     // Inicio muestreo (32 bits)
PC → Equipo: [2 bytes]     // Período muestreo (16 bits)
PC → Equipo: [2 bytes]     // Cuenta regresiva
PC → Equipo: [N bytes]     // Configuración de canales
PC → Equipo: [4 caracteres] // Nombre equipo (4 chars ASCII)
```

**Protocolo de Descarga de Datos:**

```
PC → Equipo: 'LD'          // Solicita descargar datos (Load Data)
Equipo → PC: 'DG'          // Datos Guardados, sincronización
Equipo → PC: [n × 2 bytes] // Datos de sensores (2 bytes por muestra)
```

**Formato de datos:**

```pascal
// Conversión de formato binario
num := Byte(auxStr[1])+Byte(auxStr[2])+Byte(auxStr[2])*255;

// Esto representa un número de 16 bits:
// Byte 1: bits 0-7
// Byte 2: bits 8-15 (se suma dos veces, la segunda multiplicada por 255)
```

**Protocolo de Lectura de Configuración:**

```pascal
// La PC envía 'X' periódicamente (heartbeat)
if not ONLine then PSerie.EscribirAlPuertoSerie('X');

// El equipo responde con 50 bytes:
if PSerie.LeerDelPuertoSerie(auxStr, 50) then begin
  // Bytes 1-20:  Valores de canales (2 bytes por canal, 10 canales max)
  // Bytes 21-24: Hora equipo (4 bytes, 32 bits en segundos)
  // Bytes 25-28: Hora inicio muestreo (4 bytes)
  // Bytes 29-30: Período muestreo (2 bytes)
  // Bytes 33-42: Configuración de canales (1 byte por canal, 10 máx)
  // Bytes 43-46: Nombre equipo (4 caracteres ASCII)
  // Bytes 47-49: Memoria ocupada (3 bytes)
  // Byte  50:    Potencia de 2 para memoria total
end;
```

---

## 5. COMANDOS QUE SE ENVÍAN AL DISPOSITIVO

| Comando | Tipo | Respuesta Esperada | Descripción |
|---------|------|-------------------|-------------|
| `'X'` | 1 byte | `'CE'` | Heartbeat/conexión de sincronización |
| `'CE'` | 2 bytes | `'OK'` | Entra en modo Configuración del Equipo |
| `'LD'` | 2 bytes | `'DG'` | Load Data - Descarga datos almacenados |
| `'GA'` | 2 bytes | (varios) | Gateway/internet config (modem) |
| `'atd'+número+#13` | variable | (modem) | Comandos AT de modem (dial) |
| `'ath'+#13` | variable | (modem) | Comandos AT de modem (hang up) |
| `'atz'+#13` | variable | (modem) | Comandos AT de modem (reset) |

**Ejemplo de envío de configuración (PuertoSerie.pas línea 608-701):**

```pascal
procedure TThreadComm.EscribirConfig;
begin
  // Paso 1: Enviar comando de entrada a modo config
  PSerie.EscribirAlPuertoSerie('CE');

  // Paso 2: Esperar respuesta 'OK' (max 200 intentos)
  while ((auxStr <> 'OK') and (i<=200)) do begin
    if not PSerie.LeerDelPuertoSerie(auxStr, 2) then break;
    inc(i, 1);
  end;

  // Paso 3: Enviar 4 bytes de hora
  PSerie.EscribirAlPuertoSerie(chr(Hora00));
  PSerie.EscribirAlPuertoSerie(chr(Hora01));
  PSerie.EscribirAlPuertoSerie(chr(Hora02));
  PSerie.EscribirAlPuertoSerie(chr(Hora03));

  // Paso 4: Enviar 4 bytes de inicio de muestreo
  PSerie.EscribirAlPuertoSerie(chr(IniMuest00));
  PSerie.EscribirAlPuertoSerie(chr(IniMuest01));
  PSerie.EscribirAlPuertoSerie(chr(IniMuest02));
  PSerie.EscribirAlPuertoSerie(chr(IniMuest03));

  // Paso 5: Enviar período de muestreo (2 bytes)
  PSerie.EscribirAlPuertoSerie(chr(T00));
  PSerie.EscribirAlPuertoSerie(chr(T01));

  // Paso 6: Enviar cuenta regresiva (2 bytes)
  PSerie.EscribirAlPuertoSerie(chr(Tregre00));
  PSerie.EscribirAlPuertoSerie(chr(Tregre01));

  // Paso 7: Enviar configuración de cada canal
  for i:=0 to length(ConfigCHs)-1 do
    PSerie.EscribirAlPuertoSerie(chr(ConfigCHs[i]));

  // Paso 8: Enviar nombre del equipo (4 caracteres)
  PSerie.EscribirAlPuertoSerie(NombreEquipo[1]);
  PSerie.EscribirAlPuertoSerie(NombreEquipo[2]);
  PSerie.EscribirAlPuertoSerie(NombreEquipo[3]);
  PSerie.EscribirAlPuertoSerie(NombreEquipo[4]);
end;
```

---

## 6. PARSEO DE RESPUESTAS RECIBIDAS

**Lectura de Configuración (PuertoSerie.pas línea 534-605):**

```pascal
procedure TThreadComm.LeerConfig;
var
  auxStr   : string;
  i        : byte;
  num      : integer;
  numDate  : double;
begin
  // Leer 50 bytes de configuración
  if not PSerie.LeerDelPuertoSerie(auxStr, 50) then exit;

  // PARSEO DE BYTES

  // Bytes 1-20: Valores de 10 canales (2 bytes cada uno)
  i := 1;
  for NCanal:=0 to length(pvalorCH)-1 do begin
    num := Byte(auxStr[i]) + Byte(auxStr[i+1]) + Byte(auxStr[i+1])*255;
    pvalorCH[NCanal]^ := num;  // Valor entero de 16 bits
    inc(i, 2);
  end;

  // Bytes 21-24: Hora del equipo (32 bits en segundos desde base)
  i := 21;
  numDate := Byte(auxStr[i]) + Byte(auxStr[i+1]) + Byte(auxStr[i+2]) +
             Byte(auxStr[i+3]) + Byte(auxStr[i+1])*255 +
             Byte(auxStr[i+2])*65535 + Byte(auxStr[i+3])*16777215;
  numDate := numDate/86400 + StrToDateTime(Hora_Base);  // Convertir a TDateTime
  pHoraEquipo^ := numDate;

  // Bytes 25-28: Inicio del muestreo (32 bits)
  i := 25;
  numDate := Byte(auxStr[i]) + Byte(auxStr[i+1]) + Byte(auxStr[i+2]) +
             Byte(auxStr[i+3]) + Byte(auxStr[i+1])*255 +
             Byte(auxStr[i+2])*65535 + Byte(auxStr[i+3])*16777215;
  FechaINI := numDate/86400 + StrToDateTime(Hora_Base);
  pIniMuestreo^ := FechaINI;

  // Bytes 29-30: Período de muestreo (2 bytes)
  i := 29;
  pTmuestreo^ := Byte(auxStr[i]) + Byte(auxStr[i+1]) + Byte(auxStr[i+1])*255;

  // Bytes 33-42: Configuración de canales (1 byte por canal)
  i := 33;
  for NCanal:=0 to length(pvalorCH)-1 do
    pCH_conf[NCanal]^ := Byte(auxStr[i+NCanal]);

  // Bytes 43-46: Nombre del equipo (4 caracteres ASCII)
  i := 43;
  pNombre^ := auxStr[i] + auxStr[i+1] + auxStr[i+2] + auxStr[i+3];

  // Bytes 47-49: Memoria ocupada (3 bytes)
  i := 47;
  pMemoria^ := Byte(auxStr[i]) + Byte(auxStr[i+1]) + Byte(auxStr[i+2]) +
               Byte(auxStr[i+1])*255 + Byte(auxStr[i+2])*65535;

  // Byte 50: Capacidad memoria (potencia de 2)
  i := 50;
  pCantMemory^ := trunc(power(2, Byte(auxStr[i])));
end;
```

**Lectura de Datos (PuertoSerie.pas línea 810-914):**

```pascal
procedure TThreadComm.LeerDatos;
var
  auxStr    : string;
  Nbytes    : LongInt;
  num       : integer;
begin
  // Enviar comando de descarga
  if not PSerie.EscribirAlPuertoSerie('LD') then exit;

  // Esperar sincronización 'DG'
  i := 0;
  auxStr := '';
  while ((auxStr <> 'DG') and (i<=200)) do begin
    if not PSerie.LeerDelPuertoSerie(auxStr, 2) then break;
    inc(i, 1);
  end;

  // Saltar primeros 4 bytes (cantidad de memoria)
  PSerie.LeerDelPuertoSerie(auxStr, 2);
  PSerie.LeerDelPuertoSerie(auxStr, 2);

  // Leer datos (2 bytes por muestra)
  for i:=3 to (Nbytes div 2) do begin
    auxStr := '';
    if not PSerie.LeerDelPuertoSerie(auxStr, 2) then break;

    // Convertir 2 bytes a número de 16 bits
    num := Byte(auxStr[1]) + Byte(auxStr[2]) + Byte(auxStr[2])*255;

    // Procesar valor del sensor
    pASensor^[CanalesAct[NCanal]].ComputarValor(num);

    // Agregar a línea de datos
    if length(Linea)>0 then
      Linea := Linea + sep + pASensor^[CanalesAct[NCanal]].ValorReal
    else
      Linea := pASensor^[CanalesAct[NCanal]].ValorReal;
  end;
end;
```

---

## 7. INICIALIZACIÓN Y CONFIGURACIÓN DEL PUERTO SERIAL

**Función de Apertura del Puerto (PuertoSerie.pas línea 222-239):**

```pascal
function TPuertoSerie.AbrirPuertoSerie(CommPort :string):boolean;
begin
  StrPCopy(DeviceName, CommPort);

  // Crear handle al puerto COM
  ComFile := CreateFile(
    DeviceName,                    // "COM1", "COM2", etc.
    GENERIC_READ or GENERIC_WRITE, // Lectura y escritura
    0,                             // Sin compartir
    Nil,                           // Atributos de seguridad
    OPEN_EXISTING,                 // Abrir puerto existente
    FILE_ATTRIBUTE_NORMAL,         // Atributos normales
    0                              // Sin plantilla
  );

  if ComFile = INVALID_HANDLE_VALUE then begin
    ShowMessage('No se puede acceder al ' + CommPort);
    result := false;
    exit;
  end;

  PserieOpen := true;
  result := true;
end;
```

**Función de Configuración del Puerto (PuertoSerie.pas línea 242-321):**

```pascal
function TPuertoSerie.ConfigPuertoSerie():boolean;
var
  DCB          : Windows.TDCB;
  CommTimeouts : Windows.TCOMMTIMEOUTS;
  Config       : string;
begin
  // Paso 1: Configurar tamaños de buffers
  if not SetupComm(ComFile, RxBufferSize, TxBufferSize) then begin
    result := false;
    exit;
  end;

  // Paso 2: Obtener estado actual del puerto
  if not GetCommState(ComFile, DCB) then begin
    result := false;
    exit;
  end;

  // Paso 3: Construir string de configuración
  Config := 'baud='+Baud+' parity='+Parity+' data='+Data+' stop='+Stop;
  // Ejemplo: 'baud=19200 parity=n data=8 stop=1'

  // Paso 4: Aplicar configuración
  if not BuildCommDCB(@Config[1], DCB) then begin
    result := false;
    exit;
  end;

  // Paso 5: Establecer estado del puerto
  if not SetCommState(ComFile, DCB) then begin
    result := false;
    exit;
  end;

  // Paso 6: Configurar timeouts
  with CommTimeouts do begin
    ReadIntervalTimeout         := 0;
    ReadTotalTimeoutMultiplier  := 0;
    ReadTotalTimeoutConstant    := RxTimeout;  // 750 ms
    WriteTotalTimeoutMultiplier := 0;
    WriteTotalTimeoutConstant   := TxTimeout;  // 0 ms
  end;

  // Paso 7: Aplicar timeouts
  if not SetCommTimeouts(ComFile, CommTimeouts) then begin
    result := false;
    exit;
  end;

  result := true;
end;
```

**Secuencia de Inicialización en UEquipo.pas (línea 50-129):**

```pascal
constructor TEquipo.Crear(NCanales:byte; COMM:string; TipoCom: byte);
begin
  // ...

  with ThreadComm do begin
    // Cerrar puerto anterior si está abierto
    if not Suspended then Suspend;
    PSerie.CerrarPuerto;

    // Configurar velocidad según tipo de comunicación
    case TipoCom of
      0 : PSerie.Baud := '19200';  // Cable serie directo
      1 : PSerie.Baud := '1200';   // Telefonía/modem
    else
      PSerie.Baud := '19200';
    end;

    // Parámetros fijos
    PSerie.Data      := '8';
    PSerie.Parity    := 'n';
    PSerie.Stop      := '1';
    PSerie.RxTimeout := 750;
    PSerie.TxTimeout := 0;

    // Abrir puerto
    PSerie.AbrirPuertoSerie(PuertoSerie);  // Ej: "COM1"

    // Configurar puerto
    if not PSerie.ConfigPuertoSerie then exit;

    // Iniciar thread de comunicación
    Resume;
  end;
end;
```

---

## 8. FUNCIONES DE ENVÍO Y RECEPCIÓN

**Función EscribirAlPuertoSerie (PuertoSerie.pas línea 324-335):**

```pascal
function TPuertoSerie.EscribirAlPuertoSerie(chs :string): boolean;
var
  BytesEscritos : dword;
begin
  // Enviar string al puerto (directamente sin procesamientos)
  if not WriteFile(
    ComFile,              // Handle al puerto abierto
    chs[1],               // Primer carácter del string
    Length(chs),          // Cantidad de bytes
    BytesEscritos,        // Bytes realmente escritos
    Nil                   // Sin overlapped
  ) then begin
    result := false;
    exit;
  end;

  result := true;
end;
```

**Función LeerDelPuertoSerie (PuertoSerie.pas línea 338-357):**

```pascal
function TPuertoSerie.LeerDelPuertoSerie(var chs :string; TamBuffer: integer): boolean;
var
   d            : array[1..256] of Char;  // Buffer interno
   BytesLeidos  : dword;
   i            : Integer;
begin
  // Limitar tamaño del buffer
  if (TamBuffer > length(d)) then TamBuffer := length(d);

  // Leer del puerto
  if not ReadFile(
    ComFile,           // Handle al puerto abierto
    d,                 // Buffer destino
    TamBuffer,         // Cantidad de bytes a leer
    BytesLeidos,       // Bytes realmente leídos
    nil                // Sin overlapped
  ) then begin
    result := false;
    exit;
  end;

  // Convertir buffer a string
  chs := '';
  for i := 1 to BytesLeidos do chs := chs + d[i];

  result := true;
end;
```

**Función CerrarPuerto (PuertoSerie.pas línea 360-364):**

```pascal
procedure TPuertoSerie.CerrarPuerto;
begin
  if PSerieOpen then FileClose(ComFile);  // Cerrar handle
  PSerieOpen := false;
end;
```

---

## 9. MANEJO DE EVENTOS/POLLING DEL PUERTO

**Sistema de Threading y Polling Continuo (PuertoSerie.pas línea 423-531):**

El sistema usa un **TThread** (TThreadComm) que ejecuta un **bucle continuo** de polling:

```pascal
procedure TThreadComm.Execute;
var
  auxStr  : string;
begin
  ConexOK := false;

  // Bucle principal infinito (hasta que se termina el thread)
  while not Terminated do begin
    try
      // POLLING CONTINUO: Cada iteración intenta comunicarse

      // 1. Si NO está conectado, enviar heartbeat
      if not ONLine then PSerie.EscribirAlPuertoSerie('X');

      // 2. Intentar leer respuesta (con timeout de 750ms)
      auxStr := '';
      if PSerie.LeerDelPuertoSerie(auxStr, 2) then begin
        // Si respuesta es 'CE' = equipo conectado
        if (auxStr = 'CE') then begin
          LeerConfig;                         // Leer configuración
          PSerie.EscribirAlPuertoSerie('X');  // Reavisar conexión
          ONLine := true;                     // Marcar conectado
        end
        else begin
          ONLine := false;
          DesConecTelef := true;              // Desconectar si falla
        end;
      end;

      // 3. Actualizar pantalla
      pActualizar(Self);

      // 4. Si hay comando pendiente de configuración
      if ConfigEquipo and ONLine then begin
        EscribirConfig;
        ConfigEquipo := false;
      end;

      // 5. Si hay comando pendiente de descarga
      if DescargarDatos and ONLine then begin
        DescargarDatos := false;
        DescargarLosDatos;
      end;

    except
      Mercury.Configurar := false;
    end;
  end;
end;
```

**Características del Sistema de Polling:**

1. **Velocidad:** Tan rápido como sea posible (depende del timeout de lectura: 750ms)
2. **No bloqueante:** Las operaciones de lectura tienen timeout, no se queda pegado
3. **Eventos via callbacks:** Cuando ocurren cambios, se llama a funciones registradas:
   - `pActualizar` - Actualiza interfaz con datos nuevos
   - `pActualProgres` - Actualiza barra de progreso de descarga
   - `POnConectRemoto` - Se ejecuta cuando se conecta
   - `POnDesConRemoto` - Se ejecuta cuando se desconecta

**Comunicación Telefónica (Adicional):**

```pascal
// Secuencia de conexión por modem
procedure TThreadComm.ConectarTelefon;
begin
  // Enviar comando AT de dial (ejemplo: atd5551234567<CR>)
  if not PSerie.EscribirAlPuertoSerie('atd'+Ntelefono+#13) then exit;
end;

procedure TThreadComm.DesConectarTelefon;
begin
  // Colgar (ath = hang up)
  if not PSerie.EscribirAlPuertoSerie('ath'+#13) then exit;
end;

procedure TThreadComm.IniComTelefon;
begin
  // Reset del modem
  if not PSerie.EscribirAlPuertoSerie('atz'+#13) then exit;
end;
```

---

## 10. PROTOCOLO DE COMUNICACIÓN (RESUMEN EJECUTIVO)

**MODELO GENERAL:**

```
┌─────────────────────────────────────────────────────────┐
│  COMUNICACIÓN DIRECTA (Puerto Serie / Cable)            │
├─────────────────────────────────────────────────────────┤
│ • Velocidad: 19200 bps                                  │
│ • Formato: 8N1 (8 bits, sin paridad, 1 stop bit)        │
│ • Buffers: TX=256 bytes, RX=256 bytes                   │
│ • Timeouts: RX=750ms, TX=0ms (sin timeout)              │
│ • Puerto: COM1-COM255 (configurable)                    │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  COMUNICACIÓN TELEFÓNICA (Modem RS232)                  │
├─────────────────────────────────────────────────────────┤
│ • Velocidad: 1200 bps                                   │
│ • Protocolo: Hayes AT (comandos de modem)               │
│ • Sincronización: heartbeat 'X' / respuesta 'CE'        │
└─────────────────────────────────────────────────────────┘
```

**ESTADO DE LA MÁQUINA DE COMUNICACIÓN:**

```
                    ┌─────────────┐
                    │   INICIAL   │
                    └──────┬──────┘
                           │
                    Inicializar Puerto
                           │
                    ┌──────▼──────┐
                    │ ESCANEANDO  │◄──────┐
                    └──────┬──────┘       │
                           │              │
                    Enviar 'X' (heartbeat)
                           │              │
                    ┌──────▼──────┐       │
                    │   ESPERANDO │       │
                    │  RESPUESTA  │       │
                    └──────┬──────┘       │
                           │              │
                ¿Recibir 'CE' con timeout 750ms?
                      /             \
                     SI              NO
                    /                 \
          ┌─────────▼────────┐    ┌─────▴──────────┐
          │  CONECTADO       │    │  NO CONECTADO  │
          │ (ONLine = true)  │    │ (ONLine = false)
          └────┬──────┬──────┘    └────────────────┘
               │      │                     ▲
       ┌───────┘      │                     │
       │      ¿Comando?                     │
       │      de config?                    │
       │              │                     │
  LeerConfig     EscribirConfig        Reintentar
       │          DescargarLosDatos      (Timeout)
       │              │                     │
       └───────┬──────┘                     │
               │                           │
               └───────────────────────────┘
                    Bucle Principal
```

**SECUENCIA DE DESCARGA TÍPICA:**

```
1. PC → Equipo:  'X'        (¿Estás ahí?)
2. Equipo → PC:  'CE'       (Sí, aquí estoy)
3. PC → Equipo:  'CE'       (Entrar en modo config)
4. PC ← Equipo:  'OK'       (Listo para config)
5. PC → Equipo:  'X'        (Solicitar config actual)
6. PC ← Equipo:  [50 bytes] (Configuración + datos actuales)
7. PC → Equipo:  'LD'       (Descargar datos)
8. PC ← Equipo:  'DG'       (Datos Guardados, listos)
9. PC ← Equipo:  [4 bytes]  (Tamaño del archivo)
10. PC ← Equipo: [n*2 bytes] (Datos de sensores en 2-byte chunks)
11. PC → Equipo: 'X'        (Keep-alive)
```

**CONVERSIÓN DE DATOS DE 16 BITS:**

El protocolo transmite datos en formato "little-endian modificado":

```
Byte recibido 1: bits 0-7
Byte recibido 2: bits 8-15

Fórmula de recombinación:
valor = byte[0] + byte[1] + byte[1]*255
                    ↑         ↑
              (parte alta)   (corrección)

En binario puro sería:
byte[0] | (byte[1] << 8)
```

---

## RESUMEN TÉCNICO - MERCURY

| Aspecto | Especificación |
|---------|----------------|
| **Implementación** | API Windows nativa (kernel32.dll) |
| **Puerto** | COM1-COM255 (configurable) |
| **Baud Rate Principal** | 19200 bps (cable directo) |
| **Baud Rate Modem** | 1200 bps (telefonía) |
| **Formato** | 8N1 (8 bits, sin paridad, 1 stop) |
| **Buffer RX** | 256 bytes |
| **Buffer TX** | 256 bytes |
| **Timeout RX** | 750 ms |
| **Timeout TX** | 0 ms (sin timeout) |
| **Arquitectura** | Threading con polling continuo |
| **Eventos** | Callbacks para actualización UI |

---

# COMPARACIÓN DE PROTOCOLOS

## Tabla Comparativa Principal

| Característica | Firmware (Equipo) | Mercury (PC) |
|----------------|-------------------|--------------|
| **Lenguaje** | MicroPython | Pascal/Lazarus |
| **Hardware** | Raspberry Pi Pico | PC Windows |
| **Baud Rate** | 19200 bps | 19200 bps |
| **Formato** | 8N1 | 8N1 |
| **Timeout RX** | 25 ms | 750 ms |
| **Timeout TX** | 0 ms | 0 ms |
| **Buffer RX** | Sistema | 256 bytes |
| **Buffer TX** | Sistema | 256 bytes |
| **Pins** | TX=GPIO0, RX=GPIO1 | N/A |
| **Puerto** | UART 0 | COM1-COM255 |
| **Polling** | 100 ms (asyncio) | Continuo (thread) |
| **Arquitectura** | Event-driven | Polling continuo |

## Protocolo de Comandos Común

| Comando | Origen | Destino | Respuesta | Función |
|---------|--------|---------|-----------|---------|
| **X** | PC | Equipo | CE + datos (46 bytes) | Heartbeat / Solicitar telemetría |
| **CE** | PC | Equipo | OK | Iniciar configuración |
| **LD** | PC | Equipo | DG + datos | Descargar datos almacenados |
| **GA** | PC | Equipo | (vacío) | Configurar modem/internet |
| **TX** | PC | Equipo | (vacío) | Configurar período de envío |

## Estructura de Mensajes

### Comando "X" (Heartbeat)

```
PC → Equipo: 58h ('X')
Equipo → PC: 43h 45h ('C' 'E')
```

Si el equipo está configurado, responde con 46 bytes adicionales:
```
Equipo → PC: 'CE' + [18 bytes datos] + [26 bytes config]
```

### Comando "CE" (Configuración)

```
PC → Equipo: 43h 45h ('C' 'E')
Equipo → PC: 4Fh 4Bh ('O' 'K')
PC → Equipo: [26 bytes de configuración]
```

**Estructura de los 26 bytes:**

| Offset | Tamaño | Campo | Formato |
|--------|--------|-------|---------|
| 0-3 | 4 bytes | Hora Julian | Little-endian 32-bit |
| 4-7 | 4 bytes | Inicio muestreo | Little-endian 32-bit |
| 8-9 | 2 bytes | Período muestreo | Little-endian 16-bit |
| 10-11 | 2 bytes | Período regresión | Little-endian 16-bit |
| 12-21 | 10 bytes | Config canales | 1 byte por canal (0=off, 1=on) |
| 22-25 | 4 bytes | Nombre equipo | 4 caracteres ASCII |

### Comando "LD" (Load Data)

```
PC → Equipo: 4Ch 44h ('L' 'D')
Equipo → PC: 44h 47h ('D' 'G')
Equipo → PC: [4 bytes tamaño] + [datos binarios]
```

**Tamaño:** Little-endian 32-bit (cantidad de bytes a transferir)
**Datos:** Chunks de 2 bytes (valores de sensores)

## Diagrama de Secuencia Completo

```
┌──────────────┐                                    ┌──────────────────┐
│  Mercury PC  │                                    │  Firmware EMAC   │
└──────┬───────┘                                    └────────┬─────────┘
       │                                                     │
       │  [1] Inicializar puerto COM1 @ 19200 bps           │
       │─────────────────────────────────────────────────────│
       │                                                     │
       │  [2] Enviar 'X' (heartbeat cada ~750ms)            │
       │────────────────────────────────────────────────────>│
       │                                                     │
       │                              [3] Verificar cable conectado
       │                                  (lectura pin RX GPIO1)
       │                                                     │
       │  [4] Responder 'CE'                                 │
       │<────────────────────────────────────────────────────│
       │                                                     │
       │  [5] ¡CONECTADO! - Solicitar configuración         │
       │  Enviar 'X' nuevamente                             │
       │────────────────────────────────────────────────────>│
       │                                                     │
       │  [6] Enviar configuración completa + datos actuales│
       │  'CE' + [18 bytes datos] + [26 bytes config]       │
       │<────────────────────────────────────────────────────│
       │  (Total: 46 bytes)                                 │
       │                                                     │
       │  [7] Parsear 50 bytes:                             │
       │  - Valores canales (20 bytes)                      │
       │  - Hora equipo (4 bytes)                           │
       │  - Inicio muestreo (4 bytes)                       │
       │  - Período muestreo (2 bytes)                      │
       │  - Config canales (10 bytes)                       │
       │  - Nombre (4 bytes)                                │
       │  - Memoria (3 bytes)                               │
       │  - Capacidad (1 byte)                              │
       │                                                     │
       │  [8] USUARIO SOLICITA CONFIGURAR                   │
       │  Enviar 'CE'                                       │
       │────────────────────────────────────────────────────>│
       │                                                     │
       │  [9] Responder 'OK'                                 │
       │<────────────────────────────────────────────────────│
       │                                                     │
       │  [10] Enviar configuración (26 bytes)              │
       │  - Hora (4 bytes)                                  │
       │  - Inicio (4 bytes)                                │
       │  - Período (2 bytes)                               │
       │  - Regresión (2 bytes)                             │
       │  - Canales (10 bytes)                              │
       │  - Nombre (4 bytes)                                │
       │────────────────────────────────────────────────────>│
       │                                                     │
       │                                   [11] Guardar config en flash
       │                                       storage.set_in_file()
       │                                                     │
       │  [12] USUARIO SOLICITA DESCARGAR DATOS             │
       │  Enviar 'LD'                                       │
       │────────────────────────────────────────────────────>│
       │                                                     │
       │  [13] Responder 'DG'                                │
       │<────────────────────────────────────────────────────│
       │                                                     │
       │  [14] Enviar tamaño archivo (4 bytes little-endian)│
       │<────────────────────────────────────────────────────│
       │                                                     │
       │  [15] Enviar datos en chunks de 2 bytes            │
       │  (Datos de sensores: valor 16-bit cada muestra)    │
       │<────────────────────────────────────────────────────│
       │<────────────────────────────────────────────────────│
       │<────────────────────────────────────────────────────│
       │  ...                                                │
       │<────────────────────────────────────────────────────│
       │                                                     │
       │  [16] Procesar datos:                              │
       │  - Convertir 2 bytes → valor 16-bit                │
       │  - Aplicar ecuación de sensor                      │
       │  - Guardar en base de datos                        │
       │                                                     │
       │  [17] Enviar 'X' (keep-alive)                      │
       │────────────────────────────────────────────────────>│
       │                                                     │
       │  [18] Responder 'CE' + datos actualizados          │
       │<────────────────────────────────────────────────────│
       │                                                     │
       │  [BUCLE CONTINÚA...]                               │
       │                                                     │
```

## Características Importantes del Protocolo

### 1. Sincronización mediante Heartbeat

**Mercury envía 'X' periódicamente:**
- Frecuencia: Cada ~750ms (depende del timeout de lectura)
- Propósito: Detectar conexión y solicitar datos actuales
- Respuesta esperada: 'CE' (2 bytes) o 'CE' + datos (46 bytes)

### 2. Detección de Desconexión

**Firmware (Equipo):**
- Timeout: 2 segundos sin comunicación
- Método adicional: Lectura del nivel del pin RX (GPIO1)
- Si pin RX alto = cable conectado, bajo = desconectado

**Mercury (PC):**
- Timeout: 750ms en cada lectura
- Si no recibe 'CE' después de enviar 'X', marca como desconectado
- Reinicia búsqueda automáticamente

### 3. Formato de Datos de 16 bits

**Transmisión:**
```python
# Firmware envía (little-endian)
valor = 1234
byte_low = valor & 0xFF        # 0xD2 (210)
byte_high = (valor >> 8) & 0xFF # 0x04 (4)
uart.write(byte_low)
uart.write(byte_high)
```

**Recepción (Mercury):**
```pascal
// Mercury reconstruye (método no estándar)
num := Byte(auxStr[1]) + Byte(auxStr[2]) + Byte(auxStr[2])*255;
// Nota: Se suma byte[2] dos veces (error de implementación)
// Debería ser: num := Byte(auxStr[1]) + Byte(auxStr[2])*256;
```

⚠️ **IMPORTANTE:** Existe una inconsistencia en la reconstrucción de datos de 16 bits en Mercury que multiplica por 255 en lugar de 256. Esto puede causar errores en valores altos.

### 4. Configuración de Canales

**10 canales máximo:**
- Cada canal: 1 byte de configuración (0=deshabilitado, valores >0=tipo de sensor)
- Datos de telemetría: 2 bytes por canal habilitado
- Almacenamiento: Solo se guardan canales habilitados (compresión)

### 5. Tiempo Julian

**Base de tiempo:** 01/01/2000 00:00:00
**Formato:** 32 bits little-endian (segundos desde base)

```python
# Conversión (firmware)
julian_seconds = (datetime_now - datetime(2000, 1, 1)).total_seconds()

# Conversión inversa (Mercury)
datetime_now = base_datetime + (julian_seconds / 86400) días
```

---

# CONCLUSIONES

## Fortalezas del Sistema

1. **Protocolo Simple y Efectivo:**
   - Comandos de 2 letras fáciles de debuggear
   - Sincronización mediante heartbeat robusto
   - Bajo overhead de comunicación

2. **Múltiples Canales de Comunicación:**
   - RS232 (cable directo)
   - Modem celular
   - WiFi
   - Satélite (GlobalStar)

3. **Arquitectura Asíncrona en Firmware:**
   - No bloquea el muestreo de sensores
   - Múltiples tareas concurrentes (asyncio)
   - Eficiente uso de recursos

4. **Implementación de Bajo Nivel en Mercury:**
   - Control total sobre puerto serial
   - Sin dependencias de componentes externos
   - Portabilidad (puede adaptarse a Linux/Mac con cambios mínimos)

## Áreas de Mejora

1. **Error en Conversión de 16 bits:**
   ```pascal
   // Actual (incorrecto):
   num := Byte(auxStr[1]) + Byte(auxStr[2]) + Byte(auxStr[2])*255;

   // Debería ser:
   num := Byte(auxStr[1]) + Byte(auxStr[2])*256;
   ```

2. **Falta de Checksums/CRC:**
   - No hay verificación de integridad en transferencia de datos
   - Recomendación: Agregar CRC16 o checksum simple

3. **Sin Control de Flujo Hardware:**
   - No usa RTS/CTS
   - Depende solo de timeouts software
   - Puede perder datos en transmisiones largas

4. **Documentación del Protocolo:**
   - No existe especificación formal del protocolo
   - Conocimiento implícito en el código
   - Este documento es el primer intento de documentación completa

## Recomendaciones Futuras

1. **Implementar CRC16 en Comandos Críticos:**
   ```python
   # En transferencia de configuración
   config_bytes = [...]
   crc = calculate_crc16(config_bytes)
   uart.write(config_bytes + crc)
   ```

2. **Agregar Números de Secuencia:**
   - Para detectar pérdida de paquetes
   - Especialmente importante en descarga de datos

3. **Protocolo de Retransmisión:**
   - ACK/NACK para comandos importantes
   - Reintentos automáticos

4. **Logging de Errores:**
   - Registrar errores de comunicación
   - Estadísticas de calidad del enlace

5. **Modo de Configuración Protegido:**
   - Contraseña o PIN para evitar configuraciones accidentales
   - Especialmente importante en modo remoto

---

## ARCHIVOS PRINCIPALES ANALIZADOS

### Firmware Autónomo 1.5 (Beta):
1. `lib\comunication.py` - Implementación completa de comunicación (842 líneas)
2. `lib\emac.py` - Estructura de datos y configuración
3. `lib\configuration.py` - Formato de configuración
4. `lib\global_star.py` - Comunicación satelital
5. `main.py` - Punto de entrada

### Mercury-1.27:
1. `PuertoSerie.pas` - Implementación completa RS232
2. `UEquipo.pas` - Integración con clase TEquipo
3. `UUtiles.pas` - Configuración global
4. `UConexiones.pas` - Gestión de conexiones
5. `UConfiguracionInternet.pas` - Configuración modem

---

**Fin del Análisis**

Análisis realizado por: Claude Code
Fecha: 2025-12-10
