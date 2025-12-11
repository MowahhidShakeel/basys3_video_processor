import cv2
import serial
import argparse
import time
import numpy as np

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Process and stream video over UART")
    parser.add_argument("--video_path", type=str, help="Path to the input .mp4 video file")
    parser.add_argument("--port", type=str, default="COM3", help="UART port")
    parser.add_argument("--baudrate", type=int, default=300000, help="UART baud rate")
    parser.add_argument("--output_video", type=str, default="modified_video.mp4", help="Path to save the modified video")
    args = parser.parse_args()

    # Open the input video
    cap = cv2.VideoCapture(args.video_path)
    if not cap.isOpened():
        print("Error: Could not open video file.")
        return

    # Get original FPS and set target (we'll stream at approx. original FPS, but can adjust sleep if needed)
    original_fps = cap.get(cv2.CAP_PROP_FPS)
    frame_delay = 1.0 / original_fps if original_fps > 0 else 0.033  # Default to ~30 FPS

    # Define resized dimensions and format
    width, height = 320, 240

    # Set up VideoWriter for modified video (save as grayscale, but convert to 3-channel for compatibility)
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')  # or 'XVID' for .avi
    out = cv2.VideoWriter(args.output_video, fourcc, original_fps, (width, height), isColor=False)
    if not out.isOpened():
        print("Error: Could not open output video writer.")
        cap.release()
        return

    # Set up UART serial connection
    try:
        ser = serial.Serial(args.port, args.baudrate, timeout=1)
        print(f"Connected to UART on {args.port} at {args.baudrate} baud.")
    except serial.SerialException as e:
        print(f"Error: Could not open serial port: {e}")
        cap.release()
        out.release()
        return

    frame_count = 0
    start_time = time.time()

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        # Resize frame
        resized = cv2.resize(frame, (width, height))

        # Convert to grayscale (8-bit)
        gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)

        # Save to output video (grayscale directly)
        out.write(gray)

        # Flatten to raw bytes (row-major order, 8-bit per pixel)
        raw_bytes = gray.tobytes()

        # Transmit over UART
        ser.write(b'\xAA\x55\xDE\xAD')  # Magic start sequence
        ser.write(raw_bytes)
        print(f"Sent frame {frame_count} ({len(raw_bytes)} bytes)")

        # Control frame rate
        time.sleep(frame_delay)

        frame_count += 1

    # Cleanup
    cap.release()
    out.release()
    ser.close()

    end_time = time.time()
    actual_fps = frame_count / (end_time - start_time) if (end_time - start_time) > 0 else 0
    print(f"Processing complete. Modified video saved to {args.output_video}")
    print(f"Processed {frame_count} frames at approx. {actual_fps:.2f} FPS")

if __name__ == "__main__":
    main()