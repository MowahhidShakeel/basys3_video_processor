import cv2
import serial
import argparse
import time

def main():
    # Parse arguments
    parser = argparse.ArgumentParser(description="Stream Webcam over UART")
    parser.add_argument("--camera_index", type=int, default=0, help="Camera index (default 0)")
    parser.add_argument("--port", type=str, default="COM3", help="UART port")
    # Note: 300,000 baud is ~0.4 FPS for 320x240. Increase if possible (e.g., 2,000,000).
    parser.add_argument("--baudrate", type=int, default=300000, help="UART baud rate") 
    args = parser.parse_args()

    # 1. Open Webcam
    cap = cv2.VideoCapture(args.camera_index)
    if not cap.isOpened():
        print(f"Error: Could not open camera {args.camera_index}.")
        return

    # 2. Setup UART
    try:
        ser = serial.Serial(args.port, args.baudrate, timeout=1)
        print(f"Connected to {args.port} at {args.baudrate} baud.")
    except serial.SerialException as e:
        print(f"Error opening serial port: {e}")
        cap.release()
        return

    print("Streaming... Press 'q' to quit.")
    
    width, height = 320, 240
    frame_count = 0

    try:
        while True:
            # Capture frame
            ret, frame = cap.read()
            if not ret:
                print("Error: Failed to capture frame.")
                break

            # Process: Resize -> Grayscale
            resized = cv2.resize(frame, (width, height))
            gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)

            # 3. Display locally
            cv2.imshow("PC Preview (Transmitted)", gray)

            # 4. Transmit over UART
            # We send the Magic Sequence first, then the raw pixel data
            # This is a blocking operation; the loop waits here until data is pushed to the buffer
            ser.write(b'\xAA\x55\xDE\xAD') 
            ser.write(gray.tobytes())
            
            frame_count += 1
            print(f"Sent Frame {frame_count}")

            # Exit on 'q' key
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
                
    except KeyboardInterrupt:
        print("\nStopping...")

    # Cleanup
    cap.release()
    ser.close()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()