import serial
import time

# Configuration
SERIAL_PORT = '/dev/ttyUSB0' 
BAUD_RATE = 9600
TIMEOUT = 1

def send_command(ser, command):
    """Encodes string to bytes and adds a newline before sending."""
    message = command + "\r\n"
    ser.write(message.encode('utf-8'))
    print(f"Sent: {command}")

def main():
    try:
        with serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=TIMEOUT) as ser:
            print(f"Connected to {SERIAL_PORT}")
            
            # Example: Send a command immediately upon connection
            send_command(ser, "HELLO")

            while True:
                # 1. Check for incoming data
                if ser.in_waiting > 0:
                    line = ser.readline().decode('utf-8', errors='replace').rstrip()
                    print(f"Received: {line}")
                
                # 2. Optional: Add logic here to send data based on events
                # For example, sending 'PING' every 5 seconds
                
                time.sleep(0.1)

    except serial.SerialException as e:
        print(f"Error: {e}")
    except KeyboardInterrupt:
        print("\nExiting...")

if __name__ == "__main__":
    main()